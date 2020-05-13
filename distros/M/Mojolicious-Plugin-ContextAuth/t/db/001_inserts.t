#!/usr/bin/env perl

use v5.10;

use strict;
use warnings;

use Mojolicious::Plugin::ContextAuth::DB;

use Mojo::File qw(path);
use Mojo::Util qw(camelize);
use Test::More;

my $file = path(__FILE__)->sibling($$ . '.db')->to_string;

my $db = Mojolicious::Plugin::ContextAuth::DB->new(
    dsn => 'sqlite:' . $file,
);

my @tests = (
    {
        object => 'user',
        data   => {
            username      => 'test',
            user_password => 'hallo',
        },
        result => 1,
    },
    {
        object => 'user',
        data   => {
            user_password => 'hallo',
        },
        result => 0,
        error  => 'Need username and user_password',
    },
    {
        object => 'user',
        data   => {
            username => 'test',
        },
        result => 0,
        error  => 'Need username and user_password',
    }
);

for my $test ( @tests ) {
    state $testnr++;

    my $object = $db->add( $test->{object}, %{ $test->{data} || {} } );
    my $is_ok = $test->{result} ? $object : !$object;
    ok $is_ok, "Test $testnr";

    SKIP: {
        my %data = %{ $test->{data} || {} };
        delete $data{user_password};

        skip 'object creation failed', scalar( keys %data ) + 1 if !$test->{result};

        isa_ok $object, 'Mojolicious::Plugin::ContextAuth::DB::' . camelize( $test->{object} ), "correct object ($testnr)";
        for my $key ( keys %data ) {
            is $object->$key(), $data{$key}, "value of $key is correct ($testnr)";
        }
    }

    if ( !$test->{result} ) {
        is $db->error, $test->{error}, "error message is correct ($testnr)";
    }
}

unlink $file, $file . '-shm', $file . '-wal';

done_testing;
