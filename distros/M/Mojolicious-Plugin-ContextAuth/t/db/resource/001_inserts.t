#!/usr/bin/env perl

use v5.10;

use strict;
use warnings;

use Mojolicious::Plugin::ContextAuth::DB;
use Mojolicious::Plugin::ContextAuth::DB::Resource;

use Mojo::File qw(path);
use Mojo::Util qw(camelize);
use Test::More;

my $file = path(__FILE__)->sibling($$ . '.db')->to_string;

my $db = Mojolicious::Plugin::ContextAuth::DB->new(
    dsn => 'sqlite:' . $file,
);

my $resource = Mojolicious::Plugin::ContextAuth::DB::Resource->new(
    dbh => $db->dbh,
);

my @tests = (
    {
        data   => {
            resource_name => 'test',
        },
        result => 1,
    },
    {
        data   => {
            resource_name        => 'test2',
            resource_description => 'hallo',
        },
        result => 1,
    },
    {
        data   => {
            resource_name  => 'test3',
            resource_label => 'hallo',
        },
        result => 1,
    },
    {
        data   => {
            resource_name        => 'test4',
            resource_description => 'hallo',
            resource_label       => 'hallo',
        },
        result => 1,
    },
    {
        data   => {
            resource_name => 'test',
        },
        result => 0,
        error  => 'Invalid parameter',
    },
    {
        data   => {
            resource_password => 'hallo',
        },
        result => 0,
        error  => 'Need resource_name',
    },
    {
        data   => {
            resource_name2 => 'test',
        },
        result => 0,
        error  => 'Need resource_name',
    },
    {
        data   => {
            resource_name => 'test2',
            arg3          => 3,
        },
        result => 0,
        error  => 'Invalid parameter',
    },
    {
        data   => {
            resource_name => 'test2' x 500,
        },
        result => 0,
        error  => 'Invalid parameter',
    },
    {
        data   => {
            resource_name => 'te',
        },
        result => 0,
        error  => 'Invalid parameter',
    },
);

for my $test ( @tests ) {
    state $testnr++;

    my $object = $resource->add( %{ $test->{data} || {} } );
    my $is_ok = $test->{result} ? $object : !$object;
    ok $is_ok, "Test $testnr";

    if( $test->{result} ) {
        if ( $resource->error ) {
            diag $resource->error;
        }

        my %data = %{ $test->{data} || {} };
        delete $data{resource_password};

        isa_ok $object, 'Mojolicious::Plugin::ContextAuth::DB::Resource', "correct object ($testnr)";
        for my $key ( keys %data ) {
            is $object->$key(), $data{$key}, "value of $key is correct ($testnr)";
        }
    }

    if ( !$test->{result} ) {
        is $resource->error, $test->{error}, "error message is correct ($testnr)";
    }
}

unlink $file, $file . '-shm', $file . '-wal';

done_testing;
