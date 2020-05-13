#!/usr/bin/env perl

use v5.10;

use strict;
use warnings;

use Mojolicious::Plugin::ContextAuth::DB;
use Mojolicious::Plugin::ContextAuth::DB::Permission;

use Mojo::File qw(path);
use Mojo::Util qw(camelize);
use Test::More;

my $file = path(__FILE__)->sibling($$ . '.db')->to_string;

my $db = Mojolicious::Plugin::ContextAuth::DB->new(
    dsn => 'sqlite:' . $file,
);

my $permission = Mojolicious::Plugin::ContextAuth::DB::Permission->new(
    dbh => $db->dbh,
);

my $resource = $db->add(
    'resource' => resource_name => 'project_a',
);

my @tests = (
    {
        data   => {
            permission_name => 'test',
            resource_id     => $resource->resource_id,
        },
        result => 1,
    },
    {
        data   => {
            resource_id => 'hallo',
        },
        result => 0,
        error  => 'Need permission_name and resource_id',
    },
    {
        data   => {
            permission_name => 'test',
        },
        result => 0,
        error  => 'Need permission_name and resource_id',
    },
    {
        data   => {
            permission_name2 => 'test',
        },
        result => 0,
        error  => 'Need permission_name and resource_id',
    },
    {
        data   => {
            permission_name => 'test2',
            resource_id     => 'hallo2',
            arg3            => 3,
        },
        result => 0,
        error  => 'Invalid parameter',
    },
    {
        data   => {
            permission_name => 'test2' x 500,
            resource_id     => 'hallo2',
        },
        result => 0,
        error  => 'Invalid parameter',
    },
    {
        data   => {
            permission_name => 'te',
            resource_id     => 'hallo2',
        },
        result => 0,
        error  => 'Invalid parameter',
    },
);

for my $test ( @tests ) {
    state $testnr++;

    my $object = $permission->add( %{ $test->{data} || {} } );
    my $is_ok = $test->{result} ? $object : !$object;
    ok $is_ok, "Test $testnr";

    if( $test->{result} ) {
        my %data = %{ $test->{data} || {} };
        delete $data{resource_id};

        isa_ok $object, 'Mojolicious::Plugin::ContextAuth::DB::Permission', "correct object ($testnr)";
        for my $key ( keys %data ) {
            is $object->$key(), $data{$key}, "value of $key is correct ($testnr)";
        }
    }

    if ( !$test->{result} ) {
        is $permission->error, $test->{error}, "error message is correct ($testnr)";
    }
}

unlink $file, $file . '-shm', $file . '-wal';

done_testing;
