#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
#use Test::More tests => 10;
use Test::Differences;
use Test::Exception;

use File::Temp;
use File::Path 'make_path';
use Capture::Tiny 'capture_merged';
use Cwd;

use FindBin '$Bin';
use lib File::Spec->catfile($Bin, '..', 'lib');
use lib File::Spec->catfile($Bin, 'libs', 'v1', 'lib');
use lib File::Spec->catfile($Bin, 'libs', 'v2', 'lib');
use lib File::Spec->catfile($Bin, 'libs', 'v3', 'lib');

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
    
    # create all folder types
    foreach my $path_type (Sys::Path::SPc->_path_types) {
        make_path(Sys::Path::SPc->$path_type);
    }
    
    use_ok('TestDR::build');
    use_ok('TestDR::makefile');
    use_ok('TestDR::F::F2::t');

    like(Sys::Path->find_distribution_root('TestDR::build'), qr/v1$/, 'find_distribution_root()');
    like(Sys::Path->find_distribution_root('TestDR::makefile'), qr/v2$/, 'find_distribution_root()');
    like(Sys::Path->find_distribution_root('TestDR::F::F2::t'), qr/v3$/, 'find_distribution_root()');
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

