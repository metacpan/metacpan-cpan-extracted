package SVN::Mirror::Git;
our $VERSION = '0.62';
use strict;
use warnings;
use base 'SVN::Mirror';
use base 'Class::Accessor';

use File::Spec::Functions 'catfile';
use File::Path 'mkpath';
use SVK::Util 'read_file';
use SVK::Command::Commit;
use Date::Format qw(time2str);
use File::chdir;
use Time::HiRes 'time';

sub load_commits {
    my ($self) = @_;
    my $head = read_file(catfile($ENV{GIT_DIR}, 'HEAD'));
    my $commit = $head;
    chomp $commit;

    my @history;
    while ($commit) {
	last if $self->{fromrev} && $commit eq $self->{fromrev};
	my $cobj = git_get_commit($commit);
	$commit = $cobj->{parent};
	unshift @history, $cobj
    }

    return \@history;
}

sub gitdir {
    my $self = shift;
    my $subdir = $self->{target_path};
    $subdir =~ s{/}{_}g; # XXX!
    return catfile($self->{repospath}, $subdir.".git");
}

sub run {
    my $self = shift;
    my $subdir = $self->{target_path};
    my $gitdir = $self->gitdir;
    mkpath [$gitdir] or die "Can't mkdir: $!"
	unless -e $gitdir;
    system("rsync -az --progress '$self->{source}/' $gitdir/");
    die if $?;

    local $ENV{'GIT_DIR'} = $gitdir;
    $subdir =~ s{/}{_}g; # XXX!
    my $git_checkout = catfile($self->{repospath}, 'git-tmp', $subdir, 'checkout');
    mkpath [$git_checkout];
    local $ENV{'GIT_INDEX_FILE'} = catfile($self->{repospath}, 'git-tmp', $subdir, 'index');
#die $self->{fromrev};
    my $commits = $self->load_commits;
    return if $#{$commits} < 0;
    if (!$commits->[0]{parent} && $self->{fromrev}) {
	die "something is wrong";
    }

    my $svk_output = '';
    my $fs = $self->{repos}->fs;
    my $svk = SVK->new ( output => \$svk_output,
			 xd => SVK::XD->new
			 ( depotmap => {'' => $self->{repospath}},
			   svkpath => $self->{repospath},
			   checkout => Data::Hierarchy->new ));

    my $yrev = $fs->youngest_rev;
    $svk->{xd}{checkout}->store
	($git_checkout, { depotpath => '/'.$self->{target_path}, revision => $yrev});
    my $pool = SVN::Pool->new_default;
    my $i;
    my ($time_svk, $time_git) = (0, 0);
    for my $commit (@$commits) {
	$pool->clear;
	my $t = time;
	print ++$i."/".($#{$commits}+1).": $commit->{id}\r";
	git_update_to($commit->{id}, $git_checkout);
	my $changed = git_changed($commit->{id});
	my $nt = time;
#	print('git: '.($nt-$t)."sec\n");
	$time_git += $nt-$t;

	my ($author, $time, $tz) = $commit->{author} =~ m/^(.*?)\s(\d+)\s([-+\d]+)$/;
	local $SIG{INT} = 'IGNORE';
	{
	    no warnings 'redefine';
	    local *SVK::Command::Commit::loc = sub { $_[0] }; # XXX for the output match
	    local $CWD = $git_checkout;
	    $svk->commit(-m => $commit->{log}, '--import', '--direct',
			 @$changed);
	}
	die $svk_output
	    unless $svk_output =~ m'Committed revision';
	$svk->up($git_checkout); # just to make sure..
	$yrev = $svk->{xd}{checkout}->get($git_checkout)->{revision};

	$fs->change_rev_prop($yrev, 'svm:headrev', "$self->{source_uuid}:$commit->{id}\n");
	$time = time2str("%Y-%m-%dT%H:%M:%S.00000Z", $time);
	$fs->change_rev_prop($yrev, 'svn:date', $time);
	$fs->change_rev_prop($yrev, 'svn:author', $author);

	$t = time;
#	print('svk: '.($t-$nt)."sec\n");
	$time_svk += $t-$nt;
    }
    print "git: $time_git\nsvk: $time_svk\n";
}


# git functions



sub git_get_commit {
    my $c = shift;
    my $ret = { id => $c };
    open my $fh, "git-cat-file commit $c|";
    while (<$fh>) {
	chomp;
	unless (length $_) {
	    local $/;
	    $ret->{log} = <$fh>;
	    last;
	}
	my ($what, $value) = split (/ /, $_, 2);
	if (exists $ret->{$what}) {
	    if ($what eq 'parent') {
		push @{$ret->{merge}}, $value;
	    }
	    else {
		die "duplicated key $what";
	    }
	}
	else {
	    $ret->{$what} = $value;
	}
    }
    return $ret;
}

sub git_changed {
    my $c = shift;
    open my $fh, "git-diff-tree -r $c|cut -f2|";
    <$fh>;
    my $changed = [];
    while (<$fh>) {
	chomp;
	push @$changed, $_;
    }
    return $changed;
}

sub git_update_to {
    my ($c, $dir) = @_;
    local $CWD = $dir;
    # with --prefix it is slow
    system ("git-read-tree -m $c && git-checkout-cache -f -u -a");
    die if $?;

    # git-ls-files doens't handle fsck dir yet
    open my $fh, "git-ls-files --others|";
    while (<$fh>) {
	chomp;
	unlink $_;
    }
}

# svn::mirror glue
use URI;

sub load_state {
    my ($self) = @_;
    $self->{source_uuid} = $self->{root}->node_prop ($self->{target_path}, 'svm:uuid');
    $self->load_source;
    $self->load_fromrev;
}

sub load_source {
    my $self = shift;
    $self->{source} =~ s{^git://}{};
    $self->{source} =~ s{/$}{};
    my $uri = URI->new($self->{source});
    $self->{source_root} = $uri->scheme.'://'.$uri->host;
    $self->{source_path} = $uri->path;
}

sub init_state {
    my ($self) = @_;
    use Sys::Hostname;
    $self->load_source;
    my $uuid_src = $self->{source};
    $self->{source_uuid} = lc($self->make_uuid($uuid_src));
    warn "If you already have the git archive, symlink its .git it to ".$self->gitdir."\n";
    return 'git://'.$self->{source};
}

sub make_uuid {
    return Win32API::GUID::CreateGuid() if ($^O eq 'MSWin32');
    Data::UUID->new->create_from_name_str(&Data::UUID::NameSpace_DNS, $_[0]);
}




1;
