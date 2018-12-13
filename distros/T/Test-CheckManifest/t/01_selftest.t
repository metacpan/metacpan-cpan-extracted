#!/usr/bin/perl

use strict;
use warnings;
use File::Spec;
use File::Basename;
use Test::More;

eval "use Test::CheckManifest tests => 10";
plan skip_all => "Test::CheckManifest required" if $@;

#$Test::CheckManifest::VERBOSE = 0;

# create a directory and a file 
my $home = dirname(File::Spec->rel2abs($0));

my $dir   = File::Spec->catdir($home,'.git');
my $dir2  = File::Spec->catdir($home,'test');
my $file1 = File::Spec->catfile($dir,'test.txt');
my $file2 = File::Spec->catfile($home,'test.svn');
my $file3 = File::Spec->catfile($dir2,'hallo.txt');


mkdir $dir;

my $fh;
open $fh ,'>',$file1 and close $fh;
open $fh ,'>',$file2 and close $fh;

Test::CheckManifest::_not_ok_manifest('expected: Manifest not ok');
ok_manifest({filter => [qr/\.(?:svn|git|build)/]},'Filter: \.(?:svn|git|build)');
Test::CheckManifest::_not_ok_manifest({exclude => ['/.git/']},'expected: Manifest not ok (Exclude /.git/)');

mkdir $dir2;
open $fh ,'>',$file3 and close $fh;
Test::CheckManifest::_not_ok_manifest({filter => [qr/\.svn/]},'Filter: \.svn');
Test::CheckManifest::_not_ok_manifest({exclude => ['/.git/']},'expected: Manifest not ok (Exclude /.git/) [2]');
Test::CheckManifest::_not_ok_manifest({filter => [qr/\.git/], exclude => ['/.git/']},'expected: Manifest not ok (exclude OR filter)');
Test::CheckManifest::_not_ok_manifest({filter  => [qr/\.git/],
                                       bool    => 'and',
                                       exclude => ['/t/test']}, 'filter AND exclude');

Test::CheckManifest::_not_ok_manifest({
    filter  => [qr/\.git|blib/],
    exclude => ['/t/test'],
    verbose => 1,
}, 'filter OR exclude - test.svn is missing in MANIFEST');

unlink $file2;

ok_manifest({
    filter  => [qr/\.(git|build)/],
    exclude => ['/t/test'],
}, 'filter OR exclude');

unlink $file3;

ok_manifest({filter => [qr/\.git/, qr/\.svn/, qr/\.build/ ]},'Filter \.git or \.svn');

unlink $file1;
rmdir  $dir;
rmdir  $dir2;


