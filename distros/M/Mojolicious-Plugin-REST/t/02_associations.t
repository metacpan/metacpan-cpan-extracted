use Test::More;
use Test::Mojo;

use FindBin;
use lib "$FindBin::Bin/lib";

my $t = Test::Mojo->new('MyAssociations');

# get request to collection returns correct collection...
$t->get_ok('/api/v1/users/1/features')->status_is(200)
    ->json_is( { data => [ { id => 1, name => 'mysql' }, { id => 2, name => 'mails' } ] } );

# post request to collection returns added item
$t->post_ok( '/api/v1/users/1/features' => json => { id => 3, name => 'newfeature' } )->status_is(200)
    ->json_is( { data => { id => 3, name => 'newfeature' } } );

# get request to individual item returns that item
$t->get_ok('/api/v1/users/1/features/1')->status_is(200)
    ->json_is( { data => { id => 1, features => [ { id => 'mysql' }, { id => 'mails' } ] } } );

# put request to individual item returns that item
$t->put_ok('/api/v1/users/1/features/10')->status_is(200)->json_is( { data => { id => 1, feature => { id => 10 } } } );

# delete request to individual item returns that item
$t->put_ok('/api/v1/users/1/features/10')->status_is(200)->json_is( { data => { id => 1, feature => { id => 10 } } } );

done_testing;
