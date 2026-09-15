#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
#use Test::More tests => 10;
use Test::Differences;

use File::Temp;
use File::Path 'make_path';
use Capture::Tiny 'capture_merged';
use Cwd;
use Shell::Guess;

use FindBin '$Bin';
use lib File::Spec->catfile($Bin, '..', 'lib');
use lib File::Spec->catfile($Bin, 'libs', 'v1', 'lib');
use lib File::Spec->catfile($Bin, 'libs', 'v2', 'lib');
use lib File::Spec->catfile($Bin, 'libs', 'v3', 'lib');
use lib File::Spec->catfile($Bin, 'libs', 'v4', 'lib');

our @system_args;
BEGIN {
    *CORE::GLOBAL::system = sub {
        @system_args = @_;
        return 0;
    };
}

BEGIN {
    use_ok ( 'Sys::Path' ) or exit;
    use_ok ( 'Sys::Path::SPc' ) or exit;
}

exit main();

sub main {
    my $tmp_dir     = File::Temp->newdir();
    my $prefix      = File::Spec->catdir($tmp_dir, 'usr');
    my $sysconf     = File::Spec->catdir($tmp_dir, 'etc');
    my $localstate  = File::Spec->catdir($tmp_dir, 'var');
    my $srv         = File::Spec->catdir($tmp_dir, 'srv');
    
    Sys::Path::SPc->prefix($prefix);
    Sys::Path::SPc->localstatedir($localstate);
    Sys::Path::SPc->sysconfdir($sysconf);
    Sys::Path::SPc->srvdir($srv);
    
    is(Sys::Path::SPc->prefix, $prefix, 'tmp setters');
    is(Sys::Path::SPc->localstatedir, $localstate, 'tmp setters');
    is(Sys::Path::SPc->sysconfdir, $sysconf, 'tmp setters');
    is(Sys::Path::SPc->srvdir, $srv, 'tmp setters');
    
    # Create every configured directory so later file operations can run.
    foreach my $path_type (Sys::Path::SPc->_path_types) {
        make_path(Sys::Path::SPc->$path_type);
    }
    
    use_ok('TestDR::build');
    use_ok('TestDR::makefile');
    use_ok('TestDR::F::F2::t');

    like(Sys::Path->find_distribution_root('TestDR::build'), qr/v1$/, 'find_distribution_root()');
    like(Sys::Path->find_distribution_root('TestDR::makefile'), qr/v2$/, 'find_distribution_root()');
    like(Sys::Path->find_distribution_root('TestDR::F::F2::t'), qr/v3$/, 'find_distribution_root()');
    like(
        Sys::Path->find_distribution_root('TestDR::broken'),
        qr/v4$/,
        'find_distribution_root locates a module without loading it',
    );
    is(Sys::Path->find_distribution_root('TestDR::non-existing'), File::Spec->canonpath(cwd), 'start at cwd for the rest');
    my $prompt_reply;
    my $output = capture_merged {
        $prompt_reply = Sys::Path->prompt_cfg_file_changed('src', 'dst', sub { 'Y' })
    };
    note $output;
    ok($prompt_reply, 'prompt test');
    $output = capture_merged {
        $prompt_reply = Sys::Path->prompt_cfg_file_changed('src', 'dst', sub { 'N' })
    };
    ok(!$prompt_reply, 'prompt test');

    my $shell = File::Spec->catfile('path', 'to', 'login-shell');
    my @answers = qw(Z N);
    {
        no warnings 'redefine';
        local *Shell::Guess::login_shell = sub {
            return TestShellGuess->new($shell);
        };
        capture_merged {
            Sys::Path->prompt_cfg_file_changed(
                'src', 'dst', sub { shift @answers }
            );
        };
    }
    is_deeply(\@system_args, [$shell], 'Z starts the detected login shell');
    
    mkdir(File::Spec->catfile(Sys::Path::SPc->sharedstatedir, 'syspath'));
    Sys::Path->install_checksums(
        'a' => 123,
        'b' => 987,
    );
    ok(-f File::Spec->catfile($tmp_dir, 'var', 'lib', 'syspath', 'install-checksums.json'));
    eq_or_diff({
            Sys::Path->install_checksums()
        }, {
            'a' => 123,
            'b' => 987,
        },
        'read back the install-checksums.json'
    );
    
    return 0;
}

{
    package TestShellGuess;

    sub new {
        my ($class, $location) = @_;
        return bless { location => $location }, $class;
    }

    sub default_location {
        my $self = shift;
        return $self->{location};
    }
}
