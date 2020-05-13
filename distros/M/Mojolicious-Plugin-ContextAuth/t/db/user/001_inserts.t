#!/usr/bin/env perl

use v5.10;

use strict;
use warnings;

use Mojolicious::Plugin::ContextAuth::DB;
use Mojolicious::Plugin::ContextAuth::DB::User;

use Mojo::File qw(path);
use Mojo::Util qw(camelize);
use Test::More;

my $file = path(__FILE__)->sibling($$ . '.db')->to_string;

my $db = Mojolicious::Plugin::ContextAuth::DB->new(
    dsn => 'sqlite:' . $file,
);

my $user = Mojolicious::Plugin::ContextAuth::DB::User->new(
    dbh => $db->dbh,
);

my @tests = (
    {
        data   => {
            username      => 'test',
            user_password => 'hallo',
        },
        result => 1,
    },
    {
        data   => {
            user_password => 'hallo',
        },
        result => 0,
        error  => 'Need username and user_password',
    },
    {
        data   => {
            username      => 'te',
            user_password => 'hallo',
        },
        result => 0,
        error  => 'Invalid parameter',
    },
    {
        data   => {
            username => 'test',
        },
        result => 0,
        error  => 'Need username and user_password',
    },
    {
        data   => {
            username2 => 'test',
        },
        result => 0,
        error  => 'Need username and user_password',
    },
    {
        data   => {
            username      => 'test2',
            user_password => 'hallo2',
            arg3          => 3,
        },
        result => 0,
        error  => 'Invalid parameter',
    },
    {
        data   => {
            username      => 'test2' x 500,
            user_password => 'hallo2',
        },
        result => 0,
        error  => 'Invalid parameter',
    },
);

for my $test ( @tests ) {
    state $testnr++;

    my $object = $user->add( %{ $test->{data} || {} } );
    my $is_ok = $test->{result} ? $object : !$object;
    ok $is_ok, "Test $testnr";

    if( $test->{result} ) {
        my %data = %{ $test->{data} || {} };
        delete $data{user_password};

        isa_ok $object, 'Mojolicious::Plugin::ContextAuth::DB::User', "correct object ($testnr)";
        for my $key ( keys %data ) {
            is $object->$key(), $data{$key}, "value of $key is correct ($testnr)";
        }
    }

    if ( !$test->{result} ) {
        is $user->error, $test->{error}, "error message is correct ($testnr)";
    }
}

unlink $file, $file . '-shm', $file . '-wal';

done_testing;
