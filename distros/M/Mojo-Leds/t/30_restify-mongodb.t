package Test::Skel::Test;
use Mojo::Base 'Mojo::Leds::Rest::MongoDB';

sub baz {
    shift->render_json( { a => 1 } );
}

sub bac {
    my $c = shift;
    $c->render_json( { a => $c->param('opt') } );
}

package main;

use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use Mojo::File 'path';
use lib;

my $site = path(__FILE__)->sibling('site');
my $lib  = $site->child('lib')->to_string;
my $www  = $site->child('www')->to_string;
lib->import($lib);
lib->import($www);

my $t = Test::Mojo->new('Skel');
push @{ $t->app->renderer->paths }, $www;

plan skip_all => <<EOF unless $t->app->config->{mongo_uri};
    Set env TEST_MONGODB to a valid mongodb connection string
EOF

my $app = $t->app;
my $r   = $app->routes;

$app->plugin('Restify::OtherActions');

my $rest = $r->under('/rest')->to( namespace => 'Test::Skel', cb => sub { 1 } );
$app->restify->routes(
    $rest,
    ['test'],
    {
        collection_method_map => {
            get  => 'list',
            post => 'create',
            put  => 'listupdate'
        }
    }
);

my @ids;

# add a record and got id
push @ids,
  $t->post_ok( '/rest/test' => json => { fld => 'value0' } )->status_is(200)
  ->json_is( '/fld' => 'value0' )->tx->res->json->{_id};

# get id
$t->get_ok( "/rest/test/" . $ids[0] )->status_is(200)
  ->json_is( '/_id' => $ids[0] );

# patch a record
$t->patch_ok( "/rest/test/" . $ids[0] => json => { fld => 'value00' } )
  ->status_is(200)->json_is( '/_id' => $ids[0] );

# get patched record
$t->get_ok( "/rest/test/" . $ids[0] )->status_is(200)
  ->json_is( '/fld' => 'value00' );

# add a field
$t->patch_ok( "/rest/test/" . $ids[0] => json => { fld1 => 'abcdef' } )
  ->status_is(200)->json_is( '/_id' => $ids[0] );

# get patched record
$t->get_ok( "/rest/test/" . $ids[0] )->status_is(200)
  ->json_is( '/fld' => 'value00' )->json_is( '/fld1' => 'abcdef' );

# update/replace record
$t->put_ok( "/rest/test/" . $ids[0] => json => { fld => 'value0' } )
  ->status_is(200)->json_is( '/_id' => $ids[0] );

# get patched record
$t->get_ok( "/rest/test/" . $ids[0] )->status_is(200)
  ->json_is( '/fld' => 'value0' )->json_hasnt('/fld1');

# multiple add - listupdate
my @m_adds;
push @m_adds, { fld => "value$_" } foreach ( 1 .. 49 );
my $added = $t->put_ok( '/rest/test' => json => \@m_adds )->status_is(200)
  ->json_is( '/0/fld' => 'value1' )->tx->res->json;
push @ids, $_->{_id} foreach (@$added);

# get 10th-element using filters - q[]
$t->get_ok( "/rest/test?q[_id]=" . $ids[10] )->status_is(200)
  ->json_is( '/0/fld' => 'value10' );
$t->get_ok( "/rest/test?q[fld]=" . 'value10' )->status_is(200)
  ->json_is( '/0/fld' => 'value10' );

# get value20-value29 - qre[]
$t->get_ok( "/rest/test?qre[fld]=" . 'value2[0-9]' )->status_is(200)
  ->json_is( '/8/fld' => 'value28' );

# get first 3 elements of value20-value29 - limit
$t->get_ok( "/rest/test?limit=3&qre[fld]=" . 'value2[0-9]' )->status_is(200)
  ->json_hasnt('/3')->json_is( '/2/fld' => 'value22' );

# get 3 page 2, as above but with page - page
$t->get_ok( "/rest/test?page=2&limit=3&qre[fld]=" . 'value2[0-9]' )
  ->status_is(200)->json_hasnt('/6')->json_is( '/2/fld' => 'value25' );

# sort 1 (default)
$t->get_ok( "/rest/test?sort[fld]=1&skip=3&limit=3&qre[fld]=" . 'value2[0-9]' )
  ->status_is(200)->json_hasnt('/6')->json_is( '/2/fld' => 'value25' );

# sort -1
$t->get_ok( "/rest/test?sort[fld]=-1&skip=3&limit=3&qre[fld]=" . 'value2[0-9]' )
  ->status_is(200)->json_hasnt('/6')->json_is( '/2/fld' => 'value24' );

# with_count
$t->get_ok(
    "/rest/test?rc=1&sort[fld]=-1&skip=3&limit=3&qre[fld]=" . 'value2[0-9]' )
  ->status_is(200)->json_is( '/count' => 10 )
  ->json_is( '/recs/2/fld' => 'value24' );

# delete ids
$t->delete_ok("/rest/test/$_")->status_is(204) foreach (@ids);

# call list
$t->get_ok("/rest/test")->status_is(200);

# call list failed because it aspect a record with _id => list
$t->get_ok("/rest/test/list/")->status_is(404);

# call alternative methods
$t->get_ok("/rest/test/list/baz")->status_is(200)->json_is( '/a' => 1 );

# with parameters
$t->get_ok("/rest/test/list/bac/2")->status_is(200)->json_is( '/a' => 2 );

done_testing();

1;
