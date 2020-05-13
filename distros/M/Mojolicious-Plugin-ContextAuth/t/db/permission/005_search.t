#!/usr/bin/env perl

use v5.10;

use strict;
use warnings;

use Mojolicious::Plugin::ContextAuth::DB;
use Mojolicious::Plugin::ContextAuth::DB::Resource;
use Mojolicious::Plugin::ContextAuth::DB::Permission;

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
)->add(
    resource_name => 'res1',
);

my $permission = Mojolicious::Plugin::ContextAuth::DB::Permission->new(
    dbh => $db->dbh,
);

my $new_permission = $permission->add(
    permission_name => 'test',
    resource_id     => $resource->resource_id,
);

my $new_permission_2 = $permission->add(
    permission_name => 'hello',
    resource_id     => $resource->resource_id,
    permission_description => 'A simple project',
);

my @searches = (
    {
        data    => {},
        success => 1,
        check   => [ $new_permission, $new_permission_2 ],
    },
    {
        data    => {
            permission_description => 'A simple project',
        },
        success => 1,
        check   => [ $new_permission_2 ],
    },
    {
        data    => {
            permission_name => 'test'
        },
        success => 1,
        check   => [ $new_permission ],
    },
    {
        data    => {
            permission_name => { LIKE => 'te%' },
        },
        success => 1,
        check   => [ $new_permission ],
    },
    {
        data    => {
            permission_name => { LIKE => 'he%' },
            permission_description => 'A simple project',
        },
        success => 1,
        check   => [ $new_permission_2 ],
    },
    {
        data    => {
            permission_name => { LIKE => 'te%' },
            permission_description => 'A simple project',
        },
        success => 1,
        check   => [],
    },
    {
        data    => {
            arg3 => 'test',
        },
        success => 0,
        error   => 'Cannot search for permissions',
    },
);

for my $search ( @searches ) {
    state $cnt++;

    my @permissions = $permission->search( $search->{data}->%* );

    if ( $search->{success} ) {
        check( \@permissions, $search->{check}, $cnt );
        is $permission->error, '';
    }
    else {
        ok !@permissions;
        is $permission->error, $search->{error};
    }
}

unlink $file, $file . '-shm', $file . '-wal';

done_testing;

sub check {
    my ($got, $expected, $cnt) = @_;

    is_deeply {
        map{ $_ => 1 }$got->@*,
    }, {
        map{ $_->permission_id => 1 }$expected->@*,
    }, "Deeply $cnt";
}