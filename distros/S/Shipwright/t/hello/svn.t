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
    skip "svn: no svn found or env SHIPWRIGHT_TEST_SVN not set", Test::More->builder->expected_tests
      if skip_svn();

    my $cwd = getcwd;

    my $repo = create_svn_repo() . '/hello';

    my $shipwright = Shipwright->new(
        repository => "svn:$repo",
        source => 'file:' . catfile( 't', 'hello', 'Foo-Bar-v0.01.tar.gz' ),
        log_level => 'FATAL',
        follow    => 0,
        force => 1,
    );

    isa_ok( $shipwright->backend, 'Shipwright::Backend::SVN' );

    # init
    $shipwright->backend->initialize();
    my @dirs = map { s{/?\s*$}{}; $_ } sort `svn ls $repo`;
    is_deeply(
        [@dirs],
        [ '__default_builder_options', 'bin', 'etc', 'inc', 'shipwright', 't' ],
        'initialize works'
    );

    # source
    my $source_dir = $shipwright->source->run();

    # import
    $shipwright->backend->import( name => 'hello', source => $source_dir );
    ok( grep( {/Makefile\.PL/} `svn ls $repo/sources/Foo-Bar/vendor` ),
        'imported ok' );

    my $script_dir = tempdir( 'shipwright_XXXXXX', CLEANUP => 1, TMPDIR => 1 );
    copy( catfile( 't', 'hello', 'scripts', 'build' ),       $script_dir );
    copy( catfile( 't', 'hello', 'scripts', 'require.yml' ), $script_dir );

    $shipwright->backend->import(
        name         => 'hello',
        source       => $source_dir,
        build_script => $script_dir,
    );
    ok( grep( {/Makefile\.PL/} `svn cat $repo/scripts/Foo-Bar/build` ),
        'build script ok' );

    # import another dist

    chdir $cwd;
    $shipwright = Shipwright->new(
        repository => "svn:$repo",
        source => 'file:' . catfile( 't', 'hello', 'Foo-Bar-v0.01.tar.gz' ),
        name   => 'howdy',
        follow => 0,
        log_level => 'FATAL',
    );

    $source_dir = $shipwright->source->run();
    like( $source_dir, qr/\bhowdy\b/, 'source name looks ok' );
    $shipwright->backend->import( name => 'hello', source => $source_dir );
    ok( grep( {/Makefile\.PL/} `svn ls $repo/sources/howdy/vendor` ),
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
    ok( grep( {/Makefile\.PL/} `svn cat $repo/scripts/howdy/build` ),
        'build script ok' );

    my $tempdir = tempdir( 'shipwright_XXXXXX', CLEANUP => 1, TMPDIR => 1 );
    rcopy(
        catfile( 't',      'hello', 'shipwright' ),
        catfile( $tempdir, 'shipwright' )
    );

    # check to see if update_order works
    like(
        `svn cat $repo/shipwright/order.yml`,
        qr/Foo-Bar.*howdy/s,
        'order is right'
    );

    system( 'svn delete -m "" ' . " $repo/shipwright" );
    system( 'svn import '
          . catfile( $tempdir, 'shipwright' )
          . " $repo/shipwright -m ''" );
    like(
        `svn cat $repo/shipwright/order.yml`,
        qr/howdy.*Foo-Bar/s,
        'imported wrong order works'
    );

    $shipwright->backend->update_order;
    like(
        `svn cat $repo/shipwright/order.yml`,
        qr/Foo-Bar.*howdy/s,
        'updated order works'
    );
}

