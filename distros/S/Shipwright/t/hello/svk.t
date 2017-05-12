use strict;
use warnings;

use Test::More;

if ( ! $ENV{SHIPWRIGHT_TEST_EXTRA} ) {
    plan skip_all => 'SHIPWRIGHT_TEST_EXTRA is not set';
}

plan tests => 10;

use Shipwright;
use File::Temp qw/tempdir/;
use File::Copy;
use File::Copy::Recursive qw/rcopy/;
use File::Spec::Functions qw/catfile catdir updir/;
use Cwd qw/getcwd abs_path/;

use Shipwright::Test;
Shipwright::Test->init;

SKIP: {
    skip "svk: no svk found or env SHIPWRIGHT_TEST_SVK not set", Test::More->builder->expected_tests
      if skip_svk();

    my $cwd = getcwd;

    create_svk_repo();

    my $repo = '//__shipwright/hello';

    my $shipwright = Shipwright->new(
        repository => "svk:$repo",
        source => 'file:' . catfile( 't', 'hello', 'Foo-Bar-v0.01.tar.gz' ),
        follow => 0,
        log_level => 'FATAL',
        force => 1,
    );
    isa_ok( $shipwright->backend, 'Shipwright::Backend::SVK' );

    # init
    $shipwright->backend->initialize();
    my @dirs = map { s{/?\s*$}{}; $_ } sort `svk ls $repo`;
    is_deeply(
        [@dirs],
        [ '__default_builder_options', 'bin', 'etc', 'inc', 'shipwright', 't' ],
        'initialize works'
    );

    # source
    my $source_dir = $shipwright->source->run();

    # import

    $shipwright->backend->import( name => 'hello', source => $source_dir );
    ok( grep( {/Makefile\.PL/} `svk ls $repo/sources/Foo-Bar/vendor` ),
        'imported ok' );

    my $script_dir = tempdir( 'shipwright_XXXXXX', CLEANUP => 1, TMPDIR => 1 );
    copy( catfile( 't', 'hello', 'scripts', 'build' ),       $script_dir );
    copy( catfile( 't', 'hello', 'scripts', 'require.yml' ), $script_dir );

    $shipwright->backend->import(
        name         => 'hello',
        source       => $source_dir,
        build_script => $script_dir,
    );
    ok( grep( {/Makefile\.PL/} `svk cat $repo/scripts/Foo-Bar/build` ),
        'build script ok' );

    # import another dist

    chdir $cwd;
    $shipwright = Shipwright->new(
        repository => "svk:$repo",
        source => 'file:' . catfile( 't', 'hello', 'Foo-Bar-v0.01.tar.gz' ),
        name   => 'howdy',
        follow => 0,
        log_level => 'FATAL',
        force => 1,
    );

    $source_dir = $shipwright->source->run();
    like( $source_dir, qr/\bhowdy\b/, 'source name looks ok' );
    $shipwright->backend->import( name => 'hello', source => $source_dir );
    ok( grep( {/Makefile\.PL/} `svk ls $repo/sources/howdy/vendor` ),
        'imported ok' );
    $script_dir = tempdir( 'shipwright_XXXXXX', CLEANUP => 1, TMPDIR => 1 );
    copy( catfile( 't', 'hello', 'scripts', 'build' ), $script_dir );
    copy( catfile( 't', 'hello', 'scripts', 'howdy_require.yml' ),
        catfile( $script_dir, 'require.yml' ) );

    $shipwright->backend->import(
        name         => 'hello',
        source       => $source_dir,
        build_script => $script_dir,
    );
    ok( grep( {/Makefile\.PL/} `svk cat $repo/scripts/howdy/build` ),
        'build script ok' );

    my $tempdir = tempdir( 'shipwright_XXXXXX', CLEANUP => 1, TMPDIR => 1 );
    rcopy(
        catfile( 't',      'hello', 'shipwright' ),
        catfile( $tempdir, 'shipwright' )
    );

    # check to see if update_order works
    like(
        `svk cat $repo/shipwright/order.yml`,
        qr/Foo-Bar.*howdy/s,
        'original order is right'
    );

    system( 'svk import '
          . catfile( $tempdir, 'shipwright' )
          . " $repo/shipwright -m ''" );
    like(
        `svk cat $repo/shipwright/order.yml`,
        qr/howdy.*Foo-Bar/s,
        'imported wrong order works'
    );

    $shipwright->backend->update_order;
    like(
        `svk cat $repo/shipwright/order.yml`,
        qr/Foo-Bar.*howdy/s,
        'updated order works'
    );

}

