#!/usr/bin/perl
package SVN::Mirror;
our $VERSION = '0.75';
use SVN::Core;
use SVN::Repos;
use SVN::Fs;
use File::Spec::Unix;
use strict;

=head1 NAME

SVN::Mirror - Mirror remote repository to local Subversion repository

=head1 SYNOPSIS

 my $m = SVN::Mirror->new (source => $url,
			   repos => '/path/to/repository',
			   target_path => '/mirror/project1'
			   repos_create => 1,
			   skip_to => 100
			  );
 $m->init;
 $m->run;

=head1 DESCRIPTION

SVN::Mirror allows you to mirror remote repository to your local
subversion repository. Supported types of remote repository are:

=over

=item Subversion

with the L<SVN::Mirror::Ra> backend.

=item CVS, Perforce

with the L<SVN::Mirror::VCP> backend through the L<VCP> framework.

=back

=cut

use File::Spec;
use URI::Escape;
use SVN::Simple::Edit;

use SVN::Mirror::Ra;

sub _schema_class {
    my ($url) = @_;
    die "no source specificed" unless $url;
    return 'SVN::Mirror::Ra' if $url =~ m/^(https?|file|svn(\+.*?)?):/;
    if ($url =~ m/^git:/) {
	eval {
	    require SVN::Mirror::Git; 1
	} and return 'SVN::Mirror::Git';
	warn "SVK required for git support.\n";
    }
    if ($url =~ m/^(p4|cvs|arch)/) {
	eval {
	    require SVN::Mirror::VCP; 1
	} and return 'SVN::Mirror::VCP';
	warn "VCP required.  Please install VCP and VCP::Dest::svk.\n";
    }

    die "schema for $url not handled\n";
}

sub new {
    my $class = shift;
    my $self = {};
    %$self = @_;

    return bless $self, $class unless $class eq __PACKAGE__;

    # XXX: legacy argument to be removed.
    $self->{repospath} ||= $self->{target};
    $self->{repos_create} ||= $self->{target_create};

    die "no repository specified" unless $self->{repospath} || $self->{repos};

    die "no source specified" unless $self->{source} || $self->{get_source};

    $self->{pool} ||= SVN::Pool->new (undef);
    if ($self->{repos_create} && !-e $self->{repospath}) {
	$self->{repos} = SVN::Repos::create($self->{repospath},
					    undef, undef, undef, undef, $self->{pool});
    }
    elsif ($self->{repos}) {
	$self->{repospath} = $self->{repos}->path;
    }

    $self->{repos} ||= SVN::Repos::open ($self->{repospath}, $self->{pool});
    my $fs = $self->{fs} = $self->{repos}->fs;

    my $root = $fs->revision_root ($fs->youngest_rev);
    $self->{target_path} = File::Spec::Unix->canonpath("/$self->{target_path}");

    if ($root->check_path ($self->{target_path}) != $SVN::Node::none) {
	$self->{rsource} = $root->node_prop ($self->{target_path}, 'svm:rsource');
	$self->{source} ||= $root->node_prop ($self->{target_path}, 'svm:source')
	    or die "no source found on $self->{target_path}";
    }

    return _schema_class ($self->{rsource} || $self->{source})->new (%$self);
}

sub has_local {
    my ($repos, $spec) = @_;
    my $fs = $repos->fs;
    my $root = $fs->revision_root ($fs->youngest_rev);
    local $@;
    # XXX: 
    my %mirrored = map {
			 my $m = SVN::Mirror->new (target_path => $_,
						   repos => $repos,
						   pool => SVN::Pool->new,
						   get_source => 1);
			 eval { $m->init };
			 $@ ? () : (join(':', $m->{source_uuid}, $m->{source_path}) => $_)
		     } list_mirror ($repos);
    # XXX: gah!
    my ($specanchor) =
	map { (m|[/:]$| ?
	       substr ($spec, 0, length ($_)) eq $_
	       : substr ("$spec/", 0, length($_)+1) eq "$_/")
		  ? $_ : () } keys %mirrored;
    return unless $specanchor;
    my $path = $mirrored{$specanchor};
    $spec =~ s/^\Q$specanchor\E//;
    my $m = SVN::Mirror->new (target_path => $path,
			     repos => $repos,
			     pool => SVN::Pool->new,
			     get_source => 1);
    eval { $m->init () };
    return if $@;
    if ($spec) {
	$spec = "/$spec" if substr ($spec, 0, 1) ne '/';
	$spec = '' if $spec eq '/';
    }
    return wantarray ? ($m, $spec) : $m;
}

sub list_mirror {
    my ($repos) = @_;
    my $fs = $repos->fs;
    my $root = $fs->revision_root ($fs->youngest_rev);
    die "please upgrade the mirror state\n"
	if grep {m/^svm:mirror:/} keys %{$root->node_proplist ('/')};

    my $prop = $root->node_prop ('/', 'svm:mirror') or return;
    return $prop =~ m/^(.*)$/mg;
}

sub is_mirrored {
    my ($repos, $path) = @_;
    my ($mpath) = map { substr ("$path/", 0, length($_)+1) eq "$_/" ? $_ : () } list_mirror ($repos);
    return unless $mpath;
    $path =~ s/^\Q$mpath\E//;

    my $m = SVN::Mirror->new (target_path => $mpath,
			      repos => $repos,
			      pool => SVN::Pool->new,
			      get_source => 1) or die $@;
    eval { $m->init };
    undef $@, return if $@;
    return wantarray ? ($m, $path) : $m;
}

sub load_fromrev {
    my ($self) = @_;
    my $fromrev;
    # try without lock first
    if (defined ($fromrev = $self->_do_load_fromrev)) {
	return $self->{fromrev} = $fromrev;
    }
    $self->lock('mirror');
    $fromrev = $self->_do_load_fromrev;
    $self->unlock('mirror');
    $self->{fromrev} = $fromrev if defined $fromrev;
    return $fromrev;
}

sub _do_load_fromrev {
    my $self = shift;
    my $fs = $self->{fs};
    my $root = $fs->revision_root ($fs->youngest_rev);
    my $changed = $root->node_created_rev ($self->{target_path});
    my $prop = $fs->revision_prop ($changed, 'svm:headrev');
    return unless $prop;
    my %revs = map {split (':', $_)} $prop =~ m/^.*$/mg;
    my $uuid = $self->{rsource_uuid} || $self->{source_uuid};
    return $revs{$uuid};
}

sub find_local_rev {
    my ($self, $rrev, $uuid) = @_;

    # if uuid is the repository we talk to directly, return
    # null for revisions larger than what we have
    $uuid ||= $self->{source_uuid};
    return if $uuid eq ($self->{rsource_uuid} || $self->{source_uuid})
	&& $rrev > ($self->{working} || $self->{fromrev});

    my $pool = SVN::Pool->new_default ($self->{pool});
    my $fs = $self->{repos}->fs;

    my $rev = $self->_find_local_rev($rrev, $uuid);
    return $rev if defined $rev;

    # try again with iterative, for the case that the source revision
    # is something we are not mirroring.
    my $old_pool = SVN::Pool->new;
    my $new_pool = SVN::Pool->new;

    my $hist = $fs->revision_root ($fs->youngest_rev)->
	node_history ($self->{target_path}, $old_pool);

    while ($hist = $hist->prev (1, $new_pool)) {
	$rev = ($hist->location ($new_pool))[1];
	my %rev = $self->find_remote_rev($rev, $self->{repos});
	my $lrev = $rev{$uuid};
        $old_pool->clear;
        ($old_pool, $new_pool) = ($new_pool, $old_pool);

	# 0 would be the init change we had. not good for any use.
        next unless $lrev;
	return $rev if $rrev >= $lrev;
    }
    return;
}

sub _find_local_rev {
    my ($self, $rrev, $uuid, $path) = @_;
    my $fs = $self->{repos}->fs;

    $path ||= $self->{target_path};
    my @rev = (1, $fs->youngest_rev);

    my $id = $fs->revision_root($rev[1])->node_id($path);
    my $pool = SVN::Pool->new_default;

    while ($rev[0] <= $rev[1]) {
	$pool->clear;
	my $rev = int(($rev[0]+$rev[1])/2);
	my $root = $fs->revision_root($rev);
	# In the revision we are looking at, the path must exist and
	# related to the one we know
	if ($root->check_path($path) &&
	    SVN::Fs::check_related($id, $root->node_id($path))) {
	    # normalise the revision so we can hit the headrev prop.
	    # But don't normalise when we are bounded to one revision,
	    # as this is likely the case where no path is touched.
	    my $nrev = $rev;
	    $nrev = ($root->node_history($path)->prev(0)->location)[1]
		unless $rev[0] == $rev[1] || $nrev == $root->node_created_rev ($path);
	    my %rev = $self->find_remote_rev($nrev, $self->{repos});
	    my $found = $rev{$uuid};

	    $rev[0] = $rev + 1, next unless defined $found;
	    return $nrev if $rrev == $found && !$fs->revision_prop ($nrev, 'svm:incomplete');
	    if ($rrev > $found) {
		$rev[0] = $rev+1;
	    }
	    else {
		$rev[1] = $rev-1;
	    }
	}
	else {
	    $rev[0] = $rev+1;
	}
    }
    return;
}

=head2 find_remote_rev



=cut

sub find_remote_rev {
    my ($self, $rev, $repos) = @_;
    $repos ||= $self->{repos};
    my $fs = $repos->fs;
    my $prop = $fs->revision_prop ($rev, 'svm:headrev') or return;
    my %rev = map {split (':', $_, 2)} $prop =~ m/^.*$/mg;
    return %rev if wantarray;
    return ref($self) ? $rev{$self->{source_uuid}} || $rev{$self->{rsource_uuid}} :
	(values %rev)[0];
}

sub delete {
    my ($self, $remove_props) = @_;
    my $fs = $self->{repos}->fs;
    my $newprop = join ('', map {"$_\n"} grep { $_ ne $self->{target_path}}
			list_mirror ($self->{repos}));
    my $txn = $fs->begin_txn ($fs->youngest_rev);
    my $txnroot = $txn->root;
    $txn->change_prop ("svn:author", 'svm');
    $txn->change_prop ("svn:log", "SVM: discard mirror for $self->{target_path}");
    $txnroot->change_node_prop ('/', 'svm:mirror', $newprop);
    if ($remove_props) {
        $txnroot->change_node_prop ($self->{target_path}, 'svm:source', undef);
        $txnroot->change_node_prop ($self->{target_path}, 'svm:uuid', undef);
    }
    my $rev = $self->commit_txn($txn);
    print "Committed revision $rev.\n";
}

# prepare source
sub pre_init {}

sub init {
    my $self = shift;
    my $pool = SVN::Pool->new_default ($self->{pool});

    if ($self->is_initialized) {
        $self->pre_init (0);
	$self->load_state ();
        return 0;
    }

    return $self->do_initialize;
}

sub is_initialized {
    my $self = shift;
    my $headrev = $self->{headrev} ||= $self->{fs}->youngest_rev;
    $self->{root} ||= $self->{fs}->revision_root ($headrev);

    if ($self->{target_path} eq '/') {
        $self->{fs}->revision_root($self->{headrev})->node_prop('/', 'svm:source');
    }
    else {
	# XXX: verify this is a valid mirror too.
        $self->{root}->check_path ($self->{target_path}) != $SVN::Node::none;
    }
}

sub do_initialize {
    my $self = shift;

    $self->pre_init (1);

    my $txn = $self->{fs}->begin_txn ($self->{headrev});
    my $txnroot = $txn->root;
    $self->mkpdir ($txnroot, $self->{target_path});

    my $source = $self->init_state ($txn);
    my %mirrors = map { ($_ => 1) }
                  split(/\n/, $txnroot->node_prop ('/', 'svm:mirror') || '');
    $mirrors{$self->{target_path}}++;

    $txnroot->change_node_prop ('/', 'svm:mirror', join("\n", (grep length, sort keys %mirrors), ''));
    $txnroot->change_node_prop ($self->{target_path}, 'svm:source', $source);
    $txnroot->change_node_prop ($self->{target_path}, 'svm:uuid', $self->{source_uuid});

    my $rev = $self->commit_txn($txn);
    print "Committed revision $rev.\n";

    $self->{fs}->change_rev_prop ($rev, "svn:author", 'svm');
    $self->{fs}->change_rev_prop
        ($rev, "svn:log", "SVM: initializing mirror for $self->{target_path}");

    return $rev;
}

sub relocate {
    my $self = shift;
    my $pool = SVN::Pool->new_default ($self->{pool});
    my $headrev = $self->{headrev} = $self->{fs}->youngest_rev;
    $self->{root} = $self->{fs}->revision_root ($headrev);

    $self->is_initialized
        or die "Cannot relocate uninitialized path $self->{target_path}";

    $self->pre_init (0);
    $self->load_state ();

    my $ra = $self->_new_ra (url => $self->{source});
    my $ra_uuid = $ra->get_uuid;
    die "Local and remote UUID differ." unless ($ra_uuid eq $self->{source_uuid} or $ra_uuid eq $self->{rsource_uuid});

    # Get latest revprops
    my $old_prevs = $self->{fs}->revision_proplist(
        $self->find_local_rev($self->{fromrev}) , $pool
    );

    my $rev = $self->do_initialize;
    $self->{fs}->change_rev_prop ($rev, $_ => $old_prevs->{$_})
        for sort grep /^svm:/, keys %$old_prevs;

    $self->{fs}->change_rev_prop ($rev, 'svm:incomplete' => '*');

    return $rev;
}

sub mergeback {
    my ($self, $fromrev, $path, $rev) = @_;

    # verify $path is copied from $self->{target_path}

    # concat batch merge?
    my $msg = $self->{fs}->revision_prop ($rev, 'svn:log');
    $msg .= "\n\nmerged from rev $rev of repository ".$self->{fs}->get_uuid;

    my $editor = $self->get_merge_back_editor ('', $msg,
					       sub {warn "committed via RA"});

    # dir_delta ($path, $fromrev, $rev) for commit_editor
    SVN::Repos::dir_delta($self->{fs}->revision_root ($fromrev), $path,
			  $SVN::Core::VERSION ge '0.36.0' ? '' : undef,
			  $self->{fs}->revision_root ($rev), $path,
			  $editor, undef,
			  1, 1, 0, 1
			 );
}

sub mkpdir {
    my ($self, $root, $dir) = @_;
    my @dirs = File::Spec::Unix->splitdir($self->{target_path});
    my $path = '';
    my $new;

    while (@dirs) {
	$path = File::Spec::Unix->join($path, shift @dirs);
	my $kind = $self->{root}->check_path ($path);
	if ($kind == $SVN::Core::node_none) {
	    $root->make_dir ($path, SVN::Pool->new);
	    $new = 1;
	}
	elsif ($kind != $SVN::Core::node_dir) {
	    die "something is in the way of mirror root($path)";
	}
    }
    return $new;
}

sub upgrade {
    my ($repos) = @_;
    my $fs = $repos->fs;
    my $yrev = $fs->youngest_rev;

    # pre 0.40:
    # svm:mirror:<uuid>:<path> in node_prop of /
    # svm:headrev:<url>

    my $txn = $fs->begin_txn ($yrev);
    my $root = $txn->root;
    my $prop = $root->node_proplist ('/');
    my @mirrors;
    for (grep {m/^svm:mirror:/} keys %$prop) {
	$root->change_node_prop ('/', $_, undef);
	push @mirrors, $prop->{$_};
    }

    unless (@mirrors) {
	print "nothing to upgrade\n";
	$txn->abort;
	return;
    }

    $root->change_node_prop ('/', 'svm:mirror', join ('', map {"$_\n"} @mirrors));

    my $spool = SVN::Pool->new_default;
    for (@mirrors) {
	print "Upgrading $_.\n";
	my $source = join ('', split ('!', $root->node_prop ($_, 'svm:source')));
	my $uuid = $root->node_prop ($_, 'svm:uuid');
	my $hist = $fs->revision_root ($yrev)->node_history ($_);
	my $ipool = SVN::Pool->new_default_sub;
	while ($hist = $hist->prev (0)) {
	    my (undef, $rev) = $hist->location;
            next unless $rev;
	    my $rrev = $fs->revision_prop ($rev, "svm:headrev:$source");
	    if (defined $rrev) {
		$fs->change_rev_prop ($rev, "svm:headrev:$source", undef);
		$fs->change_rev_prop ($rev, "svm:headrev", "$uuid:$rrev\n");
	    }
	    else {
		Carp::carp "no headrev" unless $source =~ m/^(?:cvs|p4)/;
	    }
	    $ipool->clear;
	}
    }

    my $rev = __PACKAGE__->commit_txn($txn);
    $fs->change_rev_prop ($rev, "svn:author", 'svm');
    $fs->change_rev_prop ($rev, "svn:log", 'SVM: upgrading svm mirror state.');
}

sub commit_txn {
    my ($self, $txn) = @_;
    return ($txn->commit)[1];
}

use Sys::Hostname;

sub _lock_token {
    my $token = $_[0]->{target_path};
    $token =~ s/_/__/g;
    $token =~ s{/}{_}g;
    return "svm:lock:$_[1]:$token";
}

sub lock {
    my ($self, $what) = @_;
    my $fs = $self->{fs};
    my $token = $self->_lock_token ($what);
    my $content = hostname.':'.$$;
    my $where = join(' ', (caller(0))[0..2]);
    die $where."\n".$self->{locked}{$what} if exists $self->{locked}{$what};
    # This is not good enough but race condition should result in failed sync
    # without corrupting repository.
    LOCKED:
    {
	while (1) {
	    my $who = $fs->revision_prop (0, $token) or last LOCKED;
	    if ($who eq $content) {
		$self->unlock ($what);
		Carp::confess "recursive lock? $what $where $self->{locked}{$what}";
	    }
	    if ($self->{lock_message}) {
		$self->{lock_message}->($self, $what, $who);
	    }
	    else {
		print "Waiting for $what lock on $self->{target_path}: $who.\n";
	    }
	    sleep 1;
	}
    }
    $fs->change_rev_prop (0, $token, $content);
    $self->{locked}{$what} = $where;
}

sub unlock {
    my ($self, $what) = @_;
    if ($what eq 'force') {
	for (keys %{$self->{fs}->revision_proplist(0)}) {
	    $self->{fs}->change_rev_prop (0, $_, undef);
	}
	delete $self->{locked};
	return;
    }

    my $token = $self->_lock_token ($what);
    if ($self->{locked}{$what}) {
	$self->{fs}->change_rev_prop (0, $token, undef);
	delete $self->{locked}{$what};
    }
}

=head1 AUTHORS

Chia-liang Kao E<lt>clkao@clkao.orgE<gt>

=head1 COPYRIGHT

Copyright 2003-2005 by Chia-liang Kao E<lt>clkao@clkao.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

1;
