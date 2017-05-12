use Test::More qw/no_plan/;
use Test::Mojo;
use File::Path qw/remove_tree/;
use File::Spec::Functions;
use Module::Build;
use FindBin;
use Mojo::Asset::File;
use Mojo::DOM;
use lib "$FindBin::Bin/lib/product/lib";

BEGIN {
    $ENV{MOJO_LOG_LEVEL} ||= 'fatal';
}

my $build = Module::Build->current;
my $tmp_dir = catdir( $build->base_dir, 't', 'tmp' );
remove_tree($tmp_dir) if -e $tmp_dir;

use_ok('product');
my $test = Test::Mojo->new( app => 'product' );
$test->get_ok('/product')->status_is(200)->content_like(
    qr/list of product/, 'It shows
the list of product'
);
my $app_home_public = catdir( $FindBin::Bin, 'lib', 'product', 'public' );
my $cache_file = catfile( $app_home_public, 'product.html' );

SKIP: {
    skip 'weird file testing error in my linux vm', 1;
    is( -e $cache_file, 1, 'It has generated product.html file' );
}
my $dom = Mojo::DOM->new;
$dom->parse( Mojo::Asset::File->new( path => $cache_file )->slurp );
like(
    $dom->at('h2')->text,
    qr/list of product/,
    'It has matched text inside the h1 element'
);
unlink $cache_file;

$test->get_ok('/product/cd')->status_is(200)
    ->content_like( qr/cd/, 'It has type of product' );
$cache_file = catfile( $app_home_public, 'product', 'cd.html' );
is( -e $cache_file, 1, 'It has generated cd.html file' );
$dom->parse( Mojo::Asset::File->new( path => $cache_file )->slurp );
like( $dom->at('b')->text, qr/cd/,
    "It has bold html element in the cached html file" );

$test->get_ok('/product/dvd')->status_is(200)
    ->content_like( qr/dvd/, 'It has dvd as product' );
$cache_file = catfile( $app_home_public, 'product', 'dvd.html' );
is( -e $cache_file, 1, 'It has generated dvd.html file' );
$dom->parse( Mojo::Asset::File->new( path => $cache_file )->slurp );
like( $dom->at('b')->text, qr/dvd/,
    "It has bold html element in the cached html file" );

$test->get_ok('/product/dvd/13')->status_is(200)
    ->content_like( qr/dvd/, 'It has dvd as product' );
$cache_file = catfile( $app_home_public, 'product', 'dvd', '13.html' );
is( -e $cache_file, 1, 'It has generated 13.html file' );
$dom->parse( Mojo::Asset::File->new( path => $cache_file )->slurp );
like( $dom->at('h1')->text,
    qr/13/, " It has h1 html element in the cached html file " );

END {
    remove_tree( catdir( $app_home_public, 'product' ) );
}
