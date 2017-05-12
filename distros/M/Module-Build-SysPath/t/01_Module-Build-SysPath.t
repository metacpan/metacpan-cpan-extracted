#!/usr/bin/perl

use strict;
use warnings;

#use Test::More 'no_plan';
use Test::More tests => 7;
use Test::Dirs 0.03;

use File::Find::Rule;
use File::Path 'make_path';
use File::Temp;

use FindBin qw($Bin);
use lib File::Spec->catfile($Bin, 'lib');
use lib File::Spec->catfile($Bin, '..', 'lib');

BEGIN {
    use_ok ( 'Module::Build::SysPath' ) or exit;
}

exit main();

sub main {
    my $src1      = File::Spec->catdir($Bin, 'tdirs', 'Acme-Test-SysPath');
    my $src1_inst = File::Spec->catdir($Bin, 'tdirs', 'Acme-Test-SysPath.installed');
    my $tmp_dir   = temp_copy_ok($src1, 'copy Acme::Test::SysPath to tmp folder');
    my $dest_dir  = File::Temp->newdir();
    
    # workaround for a fresh checkout and distdir where empty folders are not copied
    if (not -e File::Spec->catdir($src1_inst, 'var', 'cache', 'acme-cache')) {
        diag 'creating missing empty folders';
        foreach my $folder_type (qw(cache lock log run spool)) {
            my $empty_folder = File::Spec->catdir($src1_inst, 'var', $folder_type, 'acme-'.$folder_type);
            diag(File::Spec->catfile($empty_folder));
            make_path($empty_folder);
        }
        make_path(File::Spec->catdir($src1_inst, 'var', 'lib', 'acme-state'));
        make_path(File::Spec->catdir($src1_inst, 'var', 'www', 'empty'));
    }
    
    my $inc       = join(' ', map { '-I'.$_ } @INC);
    my $build_out = `cd $tmp_dir && $^X $inc Build.PL --destdir=$dest_dir 2>&1`;
    like($build_out, qr/Acme-Test-SysPath/, 'Build.PL output');
    
    my $install_out = `cd $tmp_dir && $^X Build install`;
    note $install_out;
    
    my ($packlist) = File::Find::Rule->file->name('.packlist')->in($dest_dir);
    dir_cleanup_ok($packlist, 'cleanup auto/');
    
    SKIP: {
        my ($man_folder) = File::Find::Rule->directory->name('man')->in($dest_dir);
        skip 'no man on this os'
            if not $man_folder;
        
        dir_cleanup_ok($man_folder, 'cleanup man');
    };
    
    my ($pm_folder) = File::Find::Rule->file->name('SysPath.pm')->in($dest_dir);
    dir_cleanup_ok($pm_folder, 'cleanup SysPath.pm');
    
    is_dir($dest_dir, $src1_inst, 'Acme::Test::SysPath install folders');

    return 0;
}

