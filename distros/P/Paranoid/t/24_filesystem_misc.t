#!/usr/bin/perl -T

use Test::More tests => 12;
use Paranoid;
use Paranoid::Debug;
use Paranoid::Filesystem qw(:all);
use Paranoid::Glob;

#PDEBUG = 20;

psecureEnv();

use strict;
use warnings;

no warnings qw(qw);

my $rv;

# Test pcleanPath
$rv = pcleanPath('/usr/sbin/../ccs/share/../../local/bin');
is( $rv, '/usr/local/bin', 'pcleanPath 1' );
$rv = pcleanPath('t/../foo/bar');
is( $rv, 'foo/bar', 'pcleanPath 2' );
$rv = pcleanPath('../t/../foo/bar');
is( $rv, '../foo/bar', 'pcleanPath 3' );
$rv = pcleanPath('../t/../foo/bar/..');
is( $rv, '../foo', 'pcleanPath 4' );
$rv = pcleanPath('../t/../foo/bar/.');
is( $rv, '../foo/bar', 'pcleanPath 5' );
$rv = pcleanPath('/../.././../t/../foo/bar/.');
is( $rv, '/foo/bar', 'pcleanPath 6' );
ok( !eval '$rv = pcleanPath(undef)', 'pcleanPath 7' );

# Test ptranslateLink
mkdir './t/test_fs';
mkdir './t/test_fs/subdir';
symlink '../test_fs/link', './t/test_fs/link';
symlink 'subdir',          './t/test_fs/ldir';

$rv = ptranslateLink('./t/test_fs/ldir');
is( $rv, './t/test_fs/subdir', 'ptranslateLink 1' );
$rv = ptranslateLink('t/test_fs/ldir');
is( $rv, 't/test_fs/subdir', 'ptranslateLink 2' );

# TODO:  test with optional boolean

# Test pwhich
my $filename = pwhich('ls');
isnt( $filename, undef, 'pwhich 1' );
ok( $filename =~ m#/ls$#sm, 'pwhich 2' );
$filename = pwhich('lslslslslslslslslslsl');
is( $filename, undef, 'pwhich 3' );

system('rm -rf ./t/test_fs*');

