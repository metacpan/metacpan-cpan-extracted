#!/usr/bin/env perl

use v5.10;

use strict;
use warnings;

use Mojolicious::Plugin::ContextAuth::DB;
use Mojolicious::Plugin::ContextAuth::DB::Context;

use Mojo::File qw(path);
use Mojo::Util qw(camelize);
use Test::More;

my $file = path(__FILE__)->sibling($$ . '.db')->to_string;

my $db = Mojolicious::Plugin::ContextAuth::DB->new(
    dsn => 'sqlite:' . $file,
);

my $context = Mojolicious::Plugin::ContextAuth::DB::Context->new(
    dbh => $db->dbh,
);

my @tests = (
    {
        data   => {
            context_name => 'test',
        },
        result => 1,
    },
    {
        data   => {
            context_name        => 'test2',
            context_description => 'desc 1'
        },
        result => 1,
    },
    {
        data   => {
            context_password => 'hallo',
        },
        result => 0,
        error  => 'Need context_name',
    },
    {
        data   => {
            context_description => 'hallo',
        },
        result => 0,
        error  => 'Need context_name',
    },
    {
        data   => {
            context_name2 => 'test',
        },
        result => 0,
        error  => 'Need context_name',
    },
    {
        data   => {
            context_name => 'test2',
            arg3         => 3,
        },
        result => 0,
        error  => 'Invalid parameter',
    },
    {
        data   => {
            context_name => 'test2' x 500,
        },
        result => 0,
        error  => 'Invalid parameter',
    },
    {
        data   => {
            context_name => 't',
        },
        result => 0,
        error  => 'Invalid parameter',
    },
    {
        data   => {
            context_name => '',
        },
        result => 0,
        error  => 'Need context_name',
    },
);

for my $test ( @tests ) {
    state $testnr++;

    my $object = $context->add( %{ $test->{data} || {} } );
    my $is_ok = $test->{result} ? $object : !$object;
    ok $is_ok, "Test $testnr";

    if( $test->{result} ) {
        my %data = %{ $test->{data} || {} };
        delete $data{context_password};

        isa_ok $object, 'Mojolicious::Plugin::ContextAuth::DB::Context', "correct object ($testnr)";
        for my $key ( keys %data ) {
            is $object->$key(), $data{$key}, "value of $key is correct ($testnr)";
        }
    }

    if ( !$test->{result} ) {
        is $context->error, $test->{error}, "error message is correct ($testnr)";
    }
}

unlink $file, $file . '-shm', $file . '-wal';

done_testing;
