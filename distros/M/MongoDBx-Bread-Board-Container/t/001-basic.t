#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

use MongoDBx::Bread::Board::Container;

my $HOST = $ENV{MONGOD} || "mongodb://localhost:27017";

eval { MongoDB::Connection->new( host => $HOST ) };
plan skip_all => $@ if $@;

my $c = MongoDBx::Bread::Board::Container->new(
    name            => 'MongoDB',
    host            => $HOST,
    database_layout => {
        test     => [qw[ foo bar ]],
        test_too => [qw[ baz gorch ]]
    }
);

my $conn = $c->resolve( service => '/MongoDB/connection' );
isa_ok($conn, 'MongoDB::Connection');

my $test = $c->resolve( service => '/MongoDB/test_dbh' );
isa_ok($test, 'MongoDB::Database');

my $foo = $c->resolve( service => 'MongoDB/test/foo' );
isa_ok($foo, 'MongoDB::Collection');

my $bar = $c->resolve( service => '/MongoDB/test/bar' );
isa_ok($bar, 'MongoDB::Collection');

my $test_too = $c->resolve( service => '/MongoDB/test_too_dbh' );
isa_ok($test_too, 'MongoDB::Database');

my $baz = $c->resolve( service => '/test_too/baz' );
isa_ok($baz, 'MongoDB::Collection');

my $gorch = $c->resolve( service => '/MongoDB/test_too/gorch' );
isa_ok($gorch, 'MongoDB::Collection');

done_testing();