BEGIN {
    use Test::More;

    # prereq tests
    my %mods = (
        'DBIx::Class'                                => 0,
        'Mojolicious::Plugin::Restify::OtherActions' => 0,
        'Mojolicious::Plugin::DBIC'                  => 0,
        'DBD::SQLite'                                => 0,
    );
    while ( my ( $k, $v ) = each %mods ) {
        eval "use $k $v";
        delete $mods{$k} unless ($@);
    }
    plan skip_all => "Install ["
      . join( ', ', keys(%mods) )
      . "] to run this test"
      if ( keys %mods );
}

package Test::Skel::Test;
use Mojo::Base 'Mojo::Leds::Rest::DBIx';

sub baz {
    shift->render_json( { a => 1 } );
}

sub bac {
    my $c = shift;
    $c->render_json( { a => $c->param('opt') } );
}

# TABLE: test
package Test::Skel::Schema::Result::Test;
use Mojo::Base 'DBIx::Class::Core';

__PACKAGE__->table("test");
__PACKAGE__->add_columns(
    "id",
    {
        data_type         => "integer",
        extra             => { unsigned => 1 },
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    "fld",
    { data_type => "varchar", is_nullable => 0, size => 50 },
    "fld1",
    { data_type => "varchar", is_nullable => 1, size => 50 },
);
__PACKAGE__->set_primary_key("id");
$INC{'Test/Skel/Schema/Result/Test.pm'} = 1;    # module is already loaded.

# DB Schema
package Test::Skel::Schema;
use Mojo::Base 'DBIx::Class::Schema';

# it not possible to call load_namespaces here, manual registration
my $class = 'Test::Skel::Schema::Result::Test';
__PACKAGE__->register_class( 'test', $class->new );
$INC{'Test/Skel/Schema.pm'} = 1;                #  module is already loaded.

package main;

use Mojo::Base -strict;

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

my $app = $t->app;
my $r   = $app->routes;

$app->plugin(
    'DBIC' => {
        schema => {
            'Test::Skel::Schema' => 'dbi:SQLite:dbname=:memory:'
        }
    }
);

# create table test
$app->schema->deploy( { add_drop_table => 1 } );

# load restify
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
  ->json_is( '/fld' => 'value0' )->tx->res->json->{id};

# get id
$t->get_ok( "/rest/test/" . $ids[0] )->status_is(200)
  ->json_is( '/id' => $ids[0] );

# patch a record
$t->patch_ok( "/rest/test/" . $ids[0] => json => { fld => 'value00' } )
  ->status_is(200)->json_is( '/id' => $ids[0] );

# get patched record
$t->get_ok( "/rest/test/" . $ids[0] )->status_is(200)
  ->json_is( '/fld' => 'value00' );

# add a field
$t->patch_ok( "/rest/test/" . $ids[0] => json => { fld1 => 'abcdef' } )
  ->status_is(200)->json_is( '/id' => $ids[0] );

# get patched record
$t->get_ok( "/rest/test/" . $ids[0] )->status_is(200)
  ->json_is( '/fld' => 'value00' )->json_is( '/fld1' => 'abcdef' );

# update/replace record
$t->put_ok( "/rest/test/" . $ids[0] => json => { fld => 'value0' } )
  ->status_is(200)->json_is( '/id' => $ids[0] );

# get patched record
$t->get_ok( "/rest/test/" . $ids[0] )->status_is(200)
  ->json_is( '/fld' => 'value0' )->json_is( '/fld1', undef );

# multiple add - listupdate
my @m_adds;
push @m_adds, { fld => "value$_" } foreach ( 1 .. 49 );
my $added = $t->put_ok( '/rest/test' => json => \@m_adds )->status_is(200)
  ->json_is( '/0/fld' => 'value1' )->tx->res->json;
push @ids, $_->{id} foreach (@$added);

# get 10th-element using filters - q[]
$t->get_ok( "/rest/test?q[id]=" . $ids[10] )->status_is(200)
  ->json_is( '/0/fld' => 'value10' );
$t->get_ok( "/rest/test?q[fld]=" . 'value10' )->status_is(200)
  ->json_is( '/0/fld' => 'value10' );

# get value2, value20-value29 - qre[]
$t->get_ok( "/rest/test?qre[fld]=" . 'value2%' )->status_is(200)
  ->json_is( '/9/fld' => 'value28' );

# get first 3 elements of value20-value29 - limit
$t->get_ok( "/rest/test?limit=3&qre[fld]=" . 'value2%' )->status_is(200)
  ->json_hasnt('/3')->json_is( '/2/fld' => 'value21' );

# get 3 page 2, as above but with page - page
$t->get_ok( "/rest/test?page=2&limit=3&qre[fld]=" . 'value2%' )->status_is(200)
  ->json_hasnt('/3')->json_is( '/2/fld' => 'value24' );

# sort 1 (default)
$t->get_ok( "/rest/test?sort[fld]=1&skip=3&limit=3&qre[fld]=" . 'value2%' )
  ->status_is(200)->json_hasnt('/3')->json_is( '/2/fld' => 'value24' );

# sort -1
$t->get_ok( "/rest/test?sort[fld]=-1&skip=3&limit=3&qre[fld]=" . 'value2%' )
  ->status_is(200)->json_hasnt('/3')->json_is( '/2/fld' => 'value24' );

# with_count
$t->get_ok(
    "/rest/test?rc=1&sort[fld]=-1&skip=3&limit=3&qre[fld]=" . 'value2%' )
  ->status_is(200)->json_is( '/count' => 11 )
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
