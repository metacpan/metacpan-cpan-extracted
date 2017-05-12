use Test::More;
use Test::Mojo;

use FindBin;
use lib "$FindBin::Bin/lib";

use_ok 'Mojolicious::Plugin::REST';

my $t = Test::Mojo->new('MyRest');

# all test cases tests if the route was intalled correctly...

# get request to collection returns correct collection...
$t->get_ok('/api/v1/dogs')->status_is(200)
    ->json_is( { data => [ { id => 1, name => 'bo' }, { id => 2, name => 'boo' } ] } );

# post request to collection responds with item just added...
$t->post_ok( '/api/v1/dogs' => json => { id => 3, name => 'bu' } )->status_is(200)
    ->json_is( { data => { id => 3, name => 'bu' } } );

# get request to indiviaul item returns that item...
$t->get_ok('/api/v1/dogs/1')->status_is(200)->json_is( { data => { id => 1, name => 'bo' } } );

# put request to individial item returns that item...
$t->put_ok( '/api/v1/dogs/1' => json => { name => 'bu' } )->status_is(200)
    ->json_is( { data => { id => 1, name => 'bu' } } );

# delete request to individial item returns that item...
$t->delete_ok('/api/v1/dogs/1')->status_is(200)->json_is( { data => { id => 1, name => 'bo' } } );

done_testing;
