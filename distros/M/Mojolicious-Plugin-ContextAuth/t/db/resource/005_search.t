#!/usr/bin/env perl

use v5.10;

use strict;
use warnings;

use Mojolicious::Plugin::ContextAuth::DB;
use Mojolicious::Plugin::ContextAuth::DB::Resource;

use Mojo::File qw(path);
use Mojo::Util qw(camelize);
use Test::More;

use feature 'postderef';
no warnings 'experimental::postderef';

my $file = path(__FILE__)->sibling($$ . '.db')->to_string;

my $db = Mojolicious::Plugin::ContextAuth::DB->new(
    dsn => 'sqlite:' . $file,
);

my $resource = Mojolicious::Plugin::ContextAuth::DB::Resource->new(
    dbh => $db->dbh,
);

my $new_resource = $resource->add(
    resource_name => 'test',
);

my $new_resource_2 = $resource->add(
    resource_name => 'hello',
    resource_description => 'A simple project',
);

my @searches = (
    {
        data    => {},
        success => 1,
        check   => [ $new_resource, $new_resource_2 ],
    },
    {
        data    => {
            resource_description => 'A simple project',
        },
        success => 1,
        check   => [ $new_resource_2 ],
    },
    {
        data    => {
            resource_name => 'test'
        },
        success => 1,
        check   => [ $new_resource ],
    },
    {
        data    => {
            resource_name => { LIKE => 'te%' },
        },
        success => 1,
        check   => [ $new_resource ],
    },
    {
        data    => {
            resource_name => { LIKE => 'he%' },
            resource_description => 'A simple project',
        },
        success => 1,
        check   => [ $new_resource_2 ],
    },
    {
        data    => {
            resource_name => { LIKE => 'te%' },
            resource_description => 'A simple project',
        },
        success => 1,
        check   => [],
    },
    {
        data    => {
            arg3 => 'test',
        },
        success => 0,
        error   => 'Cannot search for resources',
    },
);

for my $search ( @searches ) {
    state $cnt++;

    my @resources = $resource->search( $search->{data}->%* );

    if ( $search->{success} ) {
        check( \@resources, $search->{check}, $cnt );
        is $resource->error, '';
    }
    else {
        ok !@resources;
        is $resource->error, $search->{error};
    }
}

unlink $file, $file . '-shm', $file . '-wal';

done_testing;

sub check {
    my ($got, $expected, $cnt) = @_;

    is_deeply {
        map{ $_ => 1 }$got->@*,
    }, {
        map{ $_->resource_id => 1 }$expected->@*,
    }, "Deeply $cnt";
}