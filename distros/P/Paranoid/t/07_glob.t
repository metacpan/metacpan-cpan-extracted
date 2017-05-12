#!/usr/bin/perl -T

use Test::More tests => 23;
use Paranoid;
use Paranoid::Glob;
use Paranoid::Debug;

#PDEBUG = 20;

psecureEnv();

use strict;
use warnings;

my ( $obj, @files );

mkdir 't/{asdfa-sdfas}';
symlink '{asdfa-sdfas}',   't/test-foo';
symlink 't/{asdfa-sdfas}', 't/test-bar';

ok( $obj = new Paranoid::Glob, 'glob object new 1' );

$obj = Paranoid::Glob->new( globs => ['./t/*'], );

ok( defined $obj, 'glob object new 2' );
ok( grep( qr/99_pod.t/, @$obj ),        'file found 1' );
ok( grep( qr/99_pod.t/, $obj->exists ), 'file found 2' );

$obj = Paranoid::Glob->new( literals => ['./t/*'], );
is( scalar @$obj,        1,       'literal test 1' );
is( $$obj[0],            './t/*', 'literal test 2' );
is( scalar $obj->exists, 0,       'literal test 3' );

$obj = Paranoid::Glob->new( globs => ['./t/*'], );
ok( grep( qr/\{/, @$obj ), 'file found 3' );

$obj = Paranoid::Glob->new( literals => ['./t/{asdfa-sdfas}'], );
is( scalar @$obj, 1, 'file found 4' );
is( $$obj[0], './t/{asdfa-sdfas}', 'file found 5' );

$obj = Paranoid::Glob->new( globs => ['./t/{asdfa-sdfas,foo}'], );
is( scalar $obj->exists, 0, 'file found 4' );

$obj = Paranoid::Glob->new( globs => ['./t/*'], );
ok( scalar $obj->directories, 'directories found 1' );
is( scalar $obj->symlinks, 2, 'symlinks found 1' );
ok( grep( /test-bar/, $obj->symlinks ),    'symlinks found 2' );
ok( grep( /test-foo/, $obj->directories ), 'directory symlink 1' );
ok( !grep( /test-bar/, $obj->directories ), 'directory symlink 2' );

# Cleanup
rmdir 't/{asdfa-sdfas}';
unlink qw(t/test-foo t/test-bar);

foreach (
    qw(t/test_glob1 t/test_glob2 t/test_glob1/foo t/test_glob1/bar
    t/test_glob2/roo t/test_glob1/foo/.hidden)
    ) {
    mkdir $_;
}
symlink '../../test_glob1/foo', 't/test_glob2/roo/link';

$obj = Paranoid::Glob->new( globs => ['./t/test_glob*'], );
is( @$obj, 2, 'test glob 1' );
ok( $obj->recurse, 'recurse 1' );
is( @$obj, 6, 'recurse 2' );
ok( $obj->recurse( 0, 1 ), 'recurse 3' );
is( @$obj, 7, 'recurse 4' );
ok( $obj->recurse( 1, 1 ), 'recurse 5' );
is( @$obj, 8, 'recurse 6' );

# Cleanup
unlink 't/test_glob2/roo/link';
foreach (
    reverse qw(t/test_glob1 t/test_glob2 t/test_glob1/foo t/test_glob1/bar
    t/test_glob2/roo t/test_glob1/foo/.hidden)
    ) {
    rmdir $_;
}

