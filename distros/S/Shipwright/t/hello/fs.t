use strict;
use warnings;

use Test::More;

if ( ! $ENV{SHIPWRIGHT_TEST_EXTRA} ) {
    plan skip_all => 'SHIPWRIGHT_TEST_EXTRA is not set';
}

plan tests => 38;

use Shipwright;
use File::Temp qw/tempdir/;
use File::Copy;
use File::Copy::Recursive qw/rcopy/;
use File::Spec::Functions qw/catfile catdir updir/;
use File::Path qw/remove_tree/;
use Cwd qw/getcwd abs_path/;
use File::Slurp;

use Shipwright::Test;
Shipwright::Test->init;

my $cwd = getcwd;

my $repo = create_fs_repo();

my %source = (
    'http://example.com/hello.tar.gz'    => 'HTTP',
    'ftp://example.com/hello.tar.gz'     => 'FTP',
    'svn:file:///home/sunnavy/svn/hello' => 'SVN',
    'svk://local/hello'                  => 'SVK',
    'cpan:Foo::Bar'                      => 'CPAN',
    'file:' . catfile( 't', 'hello', 'Foo-Bar-v0.01.tar.gz' ) => 'Compressed',
    'dir:' . catfile( 't', 'hello' ) => 'Directory',
);

for ( keys %source ) {
    my $shipwright = Shipwright->new(
        repository => "fs:$repo",
        source     => $_,
        log_level  => 'FATAL',
    );
    isa_ok( $shipwright,         'Shipwright' );
    isa_ok( $shipwright->source, "Shipwright::Source::$source{$_}" );
}

my $shipwright = Shipwright->new(
    repository => "fs:$repo",
    source     => 'file:' . catfile( 't', 'hello', 'Foo-Bar-v0.01.tar.gz' ),
    follow     => 0,
    log_level  => 'FATAL',
    force      => 1,
);

isa_ok( $shipwright,          'Shipwright' );
isa_ok( $shipwright->backend, 'Shipwright::Backend::FS' );
isa_ok( $shipwright->source,  'Shipwright::Source::Compressed' );

# init
$shipwright->backend->initialize();
my $dh;
opendir $dh, $repo;
my @dirs = sort grep { !/^\./ } readdir $dh;
is_deeply(
    [@dirs],
    [ '__default_builder_options', 'bin', 'etc', 'inc', 'shipwright', 't' ],
    'initialize works'
);

# source
my $source_dir = $shipwright->source->run();
like( $source_dir, qr/\bFoo-Bar\b/, 'source name looks ok' );

for (qw/source backend/) {
    isa_ok( $shipwright->$_->log, 'Log::Log4perl::Logger' );
}

ok( -e catfile( $source_dir, 'lib', 'Foo', 'Bar.pm' ),
    'lib/Foo/Bar.pm exists in the source' );
ok( -e catfile( $source_dir, 'META.yml' ), 'META.yml exists in the source' );

# import

$shipwright->backend->import( name => 'hello', source => $source_dir );
ok( -e catfile( $repo, 'sources', 'Foo-Bar', 'vendor', 'Makefile.PL' ),
    'imported ok' );

my $script_dir = tempdir( 'shipwright_XXXXXX', CLEANUP => 1, TMPDIR => 1 );
copy( catfile( 't', 'hello', 'scripts', 'build' ),       $script_dir );
copy( catfile( 't', 'hello', 'scripts', 'require.yml' ), $script_dir );

$shipwright->backend->import(
    name         => 'hello',
    source       => $source_dir,
    build_script => $script_dir,
);
ok(
    grep( {/Makefile\.PL/}
        read_file( catfile( $repo, 'scripts', 'Foo-Bar', 'build' ) ) ),
    'build script ok'
);

# import another dist

chdir $cwd;
$shipwright = Shipwright->new(
    repository => "fs:$repo",
    source     => 'file:' . catfile( 't', 'hello', 'Foo-Bar-v0.01.tar.gz' ),
    name       => 'howdy',
    follow     => 0,
    log_level  => 'FATAL',
    force      => 1,
);

$source_dir = $shipwright->source->run();
like( $source_dir, qr/\bhowdy\b/, 'source name looks ok' );
$shipwright->backend->import( name => 'hello', source => $source_dir );
ok( -e catfile( $repo, 'sources', 'howdy', 'vendor', 'Makefile.PL' ),
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
ok(
    grep( {/Makefile\.PL/}
        read_file( catfile( $repo, 'scripts', 'howdy', 'build' ) ) ),
    'build script ok'
);

my $tempdir = tempdir( 'shipwright_XXXXXX', CLEANUP => 1, TMPDIR => 1 );
rcopy(
    catfile( 't',      'hello', 'shipwright' ),
    catfile( $tempdir, 'shipwright' )
);

# check to see if update_order works
like(
    scalar( read_file( catfile( $repo, 'shipwright', 'order.yml' ) ) ),
    qr/Foo-Bar.*howdy/s,
    'original order is right'
);

rcopy( catdir( $tempdir, 'shipwright' ), catdir( $repo, 'shipwright' ) );


like(
    scalar( read_file( catfile( $repo, 'shipwright', 'order.yml' ) ) ),
    qr/howdy.*Foo-Bar/s,
    'imported wrong order works'
);

$shipwright->backend->update_order;
like(
    scalar( read_file( catfile( $repo, 'shipwright', 'order.yml' ) ) ),
    qr/Foo-Bar.*howdy/s,
    'updated order works'
);

my $build_base = tempdir( 'shipwright_build_XXXXXX', CLEANUP => 0, TMPDIR => 1 );
rmdir $build_base; # export will create this dir
$shipwright->backend->export( target => $build_base );
my $install_base = tempdir( 'shipwright_install_XXXXXX', CLEANUP => 0, TMPDIR => 1 );

for (
    catfile( $build_base, 'shipwright', 'order.yml', ),
    catfile( $build_base, 'etc',        'shipwright-script-wrapper' ),
    catfile( $build_base, 'sources', 'Foo-Bar', 'vendor', ),
    catfile( $build_base, 'sources', 'Foo-Bar', 'vendor', 'MANIFEST', ),
    catfile( $build_base, 'scripts', 'Foo-Bar', 'build', ),
  )
{
    ok( -e $_, "$_ exists" );
}

chdir( $build_base );
system( "$^X bin/shipwright-builder --install-base $install_base" );
for (
    catfile(
        $install_base, 'lib',
        'perl5',                          'Foo',
        'Bar.pm'
    ),
    catfile(
        $install_base, 'etc',
        'shipwright-script-wrapper'
    ),
  )
{
    ok( -e $_, "$_ exists" );
}

chdir $cwd;
remove_tree( $build_base );
remove_tree( $install_base );
