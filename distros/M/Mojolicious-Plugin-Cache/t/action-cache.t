use Test::More qw/no_plan/;
use Test::Mojo;
use File::Path qw/remove_tree/;
use CHI;
use File::Spec::Functions;
use Module::Build;
use FindBin;
use lib "$FindBin::Bin/lib/book/lib";
use lib "$FindBin::Bin/lib/user/lib";

BEGIN {
    $ENV{MOJO_LOG_LEVEL} ||= 'fatal';
}

my $build = Module::Build->current;
my $tmp_dir = catdir( $build->base_dir, 't', 'tmp' );
remove_tree($tmp_dir) if -e $tmp_dir;

my $cache_dir = catdir( $tmp_dir, 'cache' );
my $cache = CHI->new( root_dir => $cache_dir, driver => 'File' );

use_ok('Book');
my $test = Test::Mojo->new( app => 'Book' );
$test->get_ok('/books')->status_is(200)->content_is('books');
my $base = 'http://localhost:' . $test->tx->remote_port;
is( $cache->is_valid( $base . '/books' ), 1, 'it has cached /books url' );

$test->get_ok('/book')->status_is(404);
isnt( $cache->is_valid( $base . '/book' ),
    1, 'it has not cached /book with 404 response code' );

use_ok('User');
$test = Test::Mojo->new( app => 'User' );
$test->get_ok('/user')->status_is(200)
    ->content_is( 'users', 'it matches the content from the get request' );
$base = 'http://localhost:' . $test->tx->remote_port;
is( $cache->is_valid( $base . '/user' ), 1, 'it has cached /user url' );

#remove the cache now to test the other responses
$cache->remove( $base . '/user' );
$test->post_form_ok( '/user' => { id => 23 } )->status_is(200)
    ->content_is( 'added 23', 'it made a successful post request' );
isnt( $cache->is_valid( $base . '/user' ),
    1, 'it does not cache response from post request' );

$test->delete_ok('/user/23')->status_is(200)
    ->content_is( 'deleted 23', 'it has made a successful delete request' );
isnt( $cache->is_valid( $base . '/user/23' ),
    1, 'it does not cache response from delete request for /user/23' );

$test->get_ok( $base . '/user/23' )->status_is(200)
    ->content_is( 'showing 23',
    'it has made a successful get request with user id' );
is( $cache->is_valid( $base . '/user/23' ),
    1, 'it cached response from get request for /user/23' );

$test->get_ok('/user/23/email')->status_is(200)
    ->content_is( 'email 23',
    'it has received response for /user/23/email with a get request' );
isnt( $cache->is_valid( $base . '/user/23/email' ),
    1, 'it does not cache response for /user/23/email' );

$test->get_ok('/user/23/name')->status_is(200)
    ->content_is( 'name 23',
    'it has received response for /user/23/name with a get request' );
isnt( $cache->is_valid( $base . '/user/23/name' ),
    1, 'it does not cache response for /user/23/name' );

#cleanup
END {
    remove_tree($tmp_dir);
}
