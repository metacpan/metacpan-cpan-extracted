#!/usr/bin/perl -T

use Test::More tests => 14;
use Paranoid;
use Paranoid::Debug;
use Paranoid::Filesystem;
use Paranoid::Glob;

#PDEBUG = 20;

psecureEnv();

use strict;
use warnings;

no warnings qw(qw);

my ( @stat, %errors, $glob );

ok( !ptouch( './t/test_mkdir/foo', undef ), 'ptouch missing 1' );
mkdir './t/test_touch';
ok( ptouch( './t/test_touch/foo', undef,   %errors ), 'ptouch single 1' );
ok( ptouch( './t/test_touch/foo', 1000000, %errors ), 'ptouch single 2' );
@stat = stat('./t/test_touch/foo');
is( $stat[8], 1000000, 'ptouch checking atime 1' );
is( $stat[9], 1000000, 'ptouch checking mtime 1' );
ok( ptouch('./t/test_touch/bar'), 'ptouch single 4' );

mkdir './t/test_touch2';
mkdir './t/test_touch2/foo';
symlink '../../test_touch', './t/test_touch2/foo/bar';
ok( ptouchR( './t/test_touch2', 10000000, 0, %errors ),
    'ptouchR nofollow 1' );
@stat = stat('./t/test_touch2');
is( $stat[8], 10000000, 'ptouchR checking atime 1' );
@stat = stat('./t/test_touch2/foo/bar/foo');
is( $stat[8], 1000000, 'ptouchR checking atime 1' );
ok( ptouchR( './t/test_touch2', 10000000, 1 ), 'ptouchR follow 1' );
@stat = stat('./t/test_touch2/foo/bar/foo');
is( $stat[8], 10000000, 'ptouchR checking atime 2' );
is( $stat[9], 10000000, 'ptouchR checking mtime 2' );
ok( !ptouchR(
        Paranoid::Glob->new(
            globs => [ './t/test_touch2', './t/test_touch3/foo/bar' ]
            ),
        undef, 0, %errors
        ),
    'ptouchR glob 1'
    );
ok( exists $errors{'./t/test_touch3/foo/bar'}, 'error message' );

# Cleanup
system('rm -rf ./t/test_touch* 2>&1');

