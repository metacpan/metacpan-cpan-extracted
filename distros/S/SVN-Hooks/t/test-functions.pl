use strict;
use warnings;
use Cwd;
use File::Temp qw/tempdir/;
use File::Spec::Functions;
use File::Path;
use File::Copy;
use URI::file;
use Config;

# Make sure the svn messages come in English.
# https://www.gnu.org/software/gettext/manual/html_node/Locale-Environment-Variables.html
$ENV{LC_ALL} = 'C';
delete $ENV{LANGUAGE};

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

sub svn_version {
    open my $pipe, '-|', "svn --version" or die;
    my $version = <$pipe>;
    local $/ = undef;           # slurp mode to read everything else up
    <$pipe>;
    close $pipe or die;
    if ($version =~ /version ([\d\.]+)/) {
        return $1;
    } else {
        die "Couldn't grok version from 'svn --version' command output: '$version'";
    }
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
    my $script = catfile($dir, 'script.bat');
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

my $pathsep = $^O eq 'MSWin32' ? ';' : ':';
my $bliblib = catdir('blib', 'lib');

sub set_hook {
    my ($text) = @_;
    my $hookdir = catdir($T, 'repo', 'hooks');
    my $hookscript = catfile($hookdir, 'svn-hooks.pl');
    open my $fd, '>', $hookscript
	or die "Can't create $hookscript: $!";
    my $debug = exists $ENV{DBG} ? '-d' : '';
    print $fd <<"EOS";
#!$Config{perlpath} $debug
use strict;
use warnings;
EOS

    # Subversion hooks are invoked with an empty PATH. This means that
    # if the user doesn't define it explicitly, bare commands will be
    # invoked with execvp, which usually works as if the PATH was
    # ":/bin:/usr/bin". During the tests we try to set up the hooks so
    # that they will use the PATH as it is in the test environment.
    if (defined $ENV{PATH} and length $ENV{PATH}) {
	my $path = $ENV{PATH};
	$path =~ s/\\$//;
	print $fd "BEGIN { \$ENV{PATH} = '$path' }\n";
    }

    if (defined $ENV{PERL5LIB} and length $ENV{PERL5LIB}) {
	foreach my $path (reverse split "$pathsep", $ENV{PERL5LIB}) {
	    print $fd "use lib '$path';\n";
	}
    }

    print $fd <<"EOS";
use lib '$bliblib';
use SVN::Hooks;
EOS
    print $fd $text, "\n\n";

    if ($^O eq 'MSWin32') {
	print $fd 'my $hook = shift; run_hook($hook, @ARGV);';
    } else {
	print $fd 'run_hook($0, @ARGV);';
    }
    print $fd "\n";
    close $fd;
    chmod 0755 => $hookscript;

    foreach my $hook (qw/post-commit post-lock post-refprop-change post-unlock pre-commit
			 pre-lock pre-revprop-change pre-unlock start-commit/) {
	my $hookfile = catfile($hookdir, $hook);
	if ($^O eq 'MSWin32') {
	    $hookfile .= '.cmd';
	    open my $fd, '>', $hookfile
		or die "Can't create $hookfile: $!";
	    print $fd "\@echo off\n";
	    print $fd "$^X $hookscript $hook %1 %2 %3 %4 %5\n";
	    close $fd;
	    chmod 0755 => $hookfile;
	} else {
	    symlink $hookscript => $hookfile;
	}
    }
}

sub set_conf {
    my ($text) = @_;
    my $hooksconf = catfile($T, 'repo', 'conf', 'svn-hooks.conf');
    open my $fd, '>', $hooksconf
	or die "Can't create $hooksconf: $!";
    print $fd $text, "\n1;\n";
    close $fd;
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

    my $repo    = catfile($T, 'repo');
    my $wc      = catfile($T, 'wc');

    system("svnadmin create $repo");

    set_hook('');

    set_conf('');

    my $repouri = URI::file->new($repo);

    system("svn co -q $repouri $wc");

    return $T;
}

1;
