#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

use Bread::Board;
use MongoDBx::Bread::Board::Container;

my $HOST = $ENV{MONGOD} || "mongodb://localhost:27017";

eval { MongoDB::Connection->new( host => $HOST ) };
plan skip_all => $@ if $@;

{
    package FooConsumer;
    use Moose;

    has 'foo_collection' => ( is => 'rw' );
}

my $c = container 'MyProject' => as {

    service 'foobar' => (
        class        => 'FooConsumer',
        dependencies => {
            foo_collection => 'MyMongoDB/test/foo'
        }
    );

    container(
        MongoDBx::Bread::Board::Container->new(
            name            => 'MyMongoDB',
            host            => $HOST,
            database_layout => {
                test     => [qw[ foo bar ]],
                test_too => [qw[ baz gorch ]]
            }
        )
    );
};

my $conn = $c->resolve( service => '/MyProject/MyMongoDB/connection' );
isa_ok($conn, 'MongoDB::Connection');

my $test = $c->resolve( service => '/MyProject/MyMongoDB/test_dbh' );
isa_ok($test, 'MongoDB::Database');

my $foo = $c->resolve( service => '/MyProject/MyMongoDB/test/foo' );
isa_ok($foo, 'MongoDB::Collection');

my $bar = $c->resolve( service => '/MyProject/MyMongoDB/test/bar' );
isa_ok($bar, 'MongoDB::Collection');

my $test_too = $c->resolve( service => '/MyProject/MyMongoDB/test_too_dbh' );
isa_ok($test_too, 'MongoDB::Database');

my $baz = $c->resolve( service => '/MyProject/MyMongoDB/test_too/baz' );
isa_ok($baz, 'MongoDB::Collection');

my $gorch = $c->resolve( service => '/MyProject/MyMongoDB/test_too/gorch' );
isa_ok($gorch, 'MongoDB::Collection');

my $foobar = $c->resolve( service => '/MyProject/foobar' );
isa_ok($foobar, 'FooConsumer');
isa_ok($foobar->foo_collection, 'MongoDB::Collection');

done_testing();