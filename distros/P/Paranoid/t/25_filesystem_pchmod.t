#!/usr/bin/perl -T

use Test::More tests => 19;
use Paranoid;
use Paranoid::Debug;
use Paranoid::Filesystem qw(:all);
use Paranoid::Glob;

#PDEBUG = 20;

psecureEnv();

use strict;
use warnings;

no warnings qw(qw);

my ( $rv, @stat, %errors );

# Test pchmod & family
my %data = (
    'ug+rwx'   => 0770,
    'u+rwxs'   => 04700,
    'ugo+rwxt' => 01777,
    );
foreach ( keys %data ) {
    $rv = ptranslatePerms($_);
    is( $rv, $data{$_}, "perms match ($_)" );
}
foreach ( '', qw(0990 xr+uG) ) {
    $rv = ptranslatePerms($_);
    is( $rv, undef, "perms undef ($_)" );
}

mkdir './t/test_chmod';
system('touch ./t/test_chmod/foo ./t/test_chmod/bar');
ok( pchmod(
        Paranoid::Glob->new(
            globs => [
                qw(./t/test_chmod/foo
                    ./t/test_chmod/bar)
                ]
            ),
        'o+rwx',
        %errors
        ),
    'pchmod 1'
    );
@stat = stat('./t/test_chmod/foo');
$rv   = $stat[2] & 0007;
is( $rv, 0007, 'pchmod 2' );
ok( !pchmod(
        Paranoid::Glob->new(
            globs => [
                qw(./t/test_chmod/foo ./t/test_chmod/bar
                    ./t/test_chmod/roo)
                ]
            ),
        'o+rwx',
        %errors
        ),
    'pchmod 3'
    );
ok( pchmod( './t/test_chmod/*', 0700 ), 'pchmod 4' );
ok( !pchmod( './t/test_chmod/roooo', 0755, %errors ), 'pchmod 5' );

mkdir './t/test_chmod2',     0777;
mkdir './t/test_chmod2/foo', 0777;
mkdir './t/test_chmod2/roo', 0777;
symlink '../../test_chmod', './t/test_chmod2/foo/bar';

ok( pchmodR( './t/test_chmod2/*', 0750, 0, %errors ), 'pchmodR 1' );
@stat = stat('./t/test_chmod/foo');
$rv   = $stat[2] & 07777;
is( $rv, 0700, 'pchmodR 2' );
@stat = stat('./t/test_chmod2/foo');
$rv   = $stat[2] & 07777;
is( $rv, 0750, 'pchmodR 3' );
ok( pchmodR( './t/test_chmod2/*', 'o+rx' ), 'pchmodR 4' );
@stat = stat('./t/test_chmod2/foo');
$rv   = $stat[2] & 07777;
is( $rv, 0755, 'pchmodR 5' );
ok( pchmodR( './t/test_chmod2/*', 0755, 1 ), 'pchmodR 6' );
@stat = stat('./t/test_chmod/foo');
$rv   = $stat[2] & 07777;
is( $rv, 0755, 'pchmodR 7' );
ok( !pchmodR( './t/test_chmod2/roooo', 0755, 1, %errors ), 'pchmodR 7' );

system('rm -rf ./t/test_chmod* 2>/dev/null');

