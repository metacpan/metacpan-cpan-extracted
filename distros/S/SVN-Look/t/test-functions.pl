# Copyright (C) 2008-2011 by CPqD

use strict;
use warnings;
use Cwd;
use File::Temp qw/tempdir/;
use File::Spec::Functions;
use File::Path;
use File::Copy;
use URI::file;

# Make sure the svn messages come in English.
$ENV{LC_MESSAGES} = 'C';

sub can_svn {
  CMD:
    for my $cmd (qw/svn svnadmin svnlook/) {
	eval {
	    open my $pipe, '-|', "$cmd --version" or die;
	    local $/ = undef;		# slurp mode
	    <$pipe>;
	    close $pipe or die;
	};
	return 0 if $@;
    }
    return 1;
}

our $T;

sub newdir {
    my $num = 1 + Test::Builder->new()->current_test();
    my $dir = catdir($T, $num);
    mkdir $dir;
    $dir;
}

sub do_script {
    my ($dir, $cmd) = @_;
    my $script = catfile($dir, 'script');
    my $stdout = catfile($dir, 'stdout');
    my $stderr = catfile($dir, 'stderr');
    {
	open my $fd, '>', $script or die;
	print $fd $cmd;
	close $fd;
	chmod 0755, $script;
    }
    copy(catfile($T, 'repo', 'hooks', 'svn-hooks.pl')   => catfile($dir, 'svn-hooks.pl'));
    copy(catfile($T, 'repo', 'conf',  'svn-hooks.conf') => catfile($dir, 'svn-hooks.conf'));

    system("$script 1>$stdout 2>$stderr");
}

sub read_file {
    my ($file) = @_;
    open my $fd, '<', $file or die "Can't open '$file': $!\n";
    local $/ = undef;		# slurp mode
    return <$fd>;
}

sub work_ok {
    my ($tag, $cmd) = @_;
    my $dir = newdir();
    ok((do_script($dir, $cmd) == 0), $tag)
	or diag("work_ok command failed with following stderr:\n",
		scalar(read_file(catfile($dir, 'stderr'))));
}

sub work_nok {
    my ($tag, $error_expect, $cmd) = @_;
    my $dir = newdir();
    my $exit = do_script($dir, $cmd);
    if ($exit == 0) {
	fail($tag);
	diag("work_nok command worked but it shouldn't!\n");
	return;
    }

    my $stderr = scalar(read_file(catfile($dir, 'stderr')));

    if (! ref $error_expect) {
	ok(index($stderr, $error_expect) >= 0, $tag)
	    or diag("work_nok:\n  '$stderr'\n    does not contain\n  '$error_expect'\n");
    }
    elsif (ref $error_expect eq 'Regexp') {
	like($stderr, $error_expect, $tag);
    }
    else {
	fail($tag);
	diag("work_nok: invalid second argument to test.\n");
    }
}

sub get_author {
    my ($t) = @_;
    my $repo = catfile($t, 'repo');
    open my $cmd, '-|', "svnlook info $repo"
	or die "Can't exec svn info\n";
    chomp(my $author = <$cmd>);
    local $/ = undef; <$cmd>;
    close $cmd;
    return $author;
}

sub reset_repo {
    my $cleanup = exists $ENV{REPO_CLEANUP} ? $ENV{REPO_CLEANUP} : 1;
    $T = tempdir('t.XXXX', DIR => getcwd(), CLEANUP => $cleanup);

    my $repo = catfile($T, 'repo');
    my $wc   = catfile($T, 'wc');

    system("svnadmin create $repo");

    my $repouri = URI::file->new($repo);

    system("svn co -q $repouri $wc");

    return $T;
}

1;
