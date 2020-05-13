#!/usr/bin/env perl

use v5.10;

use strict;
use warnings;

use Mojolicious::Plugin::ContextAuth::DB;
use Mojolicious::Plugin::ContextAuth::DB::Role;
use Mojolicious::Plugin::ContextAuth::DB::Context;

use Mojo::File qw(path);
use Mojo::Util qw(camelize);
use Test::More;

my $file = path(__FILE__)->sibling($$ . '.db')->to_string;

my $db = Mojolicious::Plugin::ContextAuth::DB->new(
    dsn => 'sqlite:' . $file,
);

my $role = Mojolicious::Plugin::ContextAuth::DB::Role->new(
    dbh => $db->dbh,
);

my $context = Mojolicious::Plugin::ContextAuth::DB::Context->new(
    dbh => $db->dbh,
)->add(
    context_name => 'project_a'
);

my @tests = (
    {
        data   => {
            role_name  => 'test',
            context_id => $context->context_id,
        },
        result => 1,
    },
    {
        data   => {
            role_name        => 'test2',
            role_description => 'hallo',
            context_id       => $context->context_id,
        },
        result => 1,
    },
    {
        data   => {
            role_name        => 'test3',
            role_description => 'hallo',
            context_id       => $context->context_id,
            is_valid         => 1,
        },
        result => 1,
    },
    {
        data   => {
            role_name        => 'test4',
            role_description => 'hallo',
            context_id       => $context->context_id,
            is_valid         => 0,
        },
        result => 1,
    },
    {
        data   => {
            role_name        => 'test5',
            role_description => 'hallo',
            context_id       => $context->context_id,
        },
        result => 1,
    },
    {
        data   => {
            role_name => 'test',
        },
        result => 0,
        error  => 'Need role_name and context_id',
    },
    {
        data   => {
            role_name  => 'test',
            context_id => 123,
        },
        result => 0,
        error  => 'Invalid parameter',
    },
    {
        data   => {
            role_password => 'hallo',
        },
        result => 0,
        error  => 'Need role_name and context_id',
    },
    {
        data   => {
            role_name => 'test',
        },
        result => 0,
        error  => 'Need role_name and context_id',
    },
    {
        data   => {
            role_name2 => 'test',
        },
        result => 0,
        error  => 'Need role_name and context_id',
    },
    {
        data   => {
            context_id => 'test',
        },
        result => 0,
        error  => 'Need role_name and context_id',
    },
    {
        data   => {
            role_name  => 'test2',
            arg3       => 3,
            context_id => 123,
        },
        result => 0,
        error  => 'Invalid parameter',
    },
    {
        data   => {
            role_name  => 'test2' x 500,
            context_id => 123,
        },
        result => 0,
        error  => 'Invalid parameter',
    },
    {
        data   => {
            role_name  => 'te',
            context_id => $context->context_id,
        },
        result => 0,
        error  => 'Invalid parameter',
    },
);

for my $test ( @tests ) {
    state $testnr++;

    my $object = $role->add( %{ $test->{data} || {} } );
    my $is_ok = $test->{result} ? $object : !$object;
    ok $is_ok, "Test $testnr";

    if( $test->{result} ) {
        my %data = %{ $test->{data} || {} };
        delete $data{role_password};

        isa_ok $object, 'Mojolicious::Plugin::ContextAuth::DB::Role', "correct object ($testnr)";
        for my $key ( keys %data ) {
            is $object->$key(), $data{$key}, "value of $key is correct ($testnr)";
        }
    }

    if ( !$test->{result} ) {
        is $role->error, $test->{error}, "error message is correct ($testnr)";
    }
}

unlink $file, $file . '-shm', $file . '-wal';

done_testing;
