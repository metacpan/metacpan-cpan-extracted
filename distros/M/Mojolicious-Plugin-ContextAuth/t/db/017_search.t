#!/usr/bin/env perl

use v5.10;

use strict;
use warnings;

use Mojolicious::Plugin::ContextAuth::DB;
use Mojolicious::Plugin::ContextAuth::DB::Role;

use Mojo::File qw(path);
use Mojo::Util qw(camelize);
use Test::More;

use feature 'postderef';
no warnings 'experimental::postderef';

my $file = path(__FILE__)->sibling($$ . '.db')->to_string;

my $db = Mojolicious::Plugin::ContextAuth::DB->new(
    dsn => 'sqlite:' . $file,
);

my $role = Mojolicious::Plugin::ContextAuth::DB::Role->new(
    dbh => $db->dbh,
);

my $context = $db->add(
    context => 
        context_name => 'project_a'
);

my $new_role = $role->add(
    role_name  => 'test',
    context_id => $context->context_id,
);

my $new_role_2 = $role->add(
    role_name  => 'hello',
    context_id => $context->context_id,
);

my @searches = (
    {
        data    => {},
        success => 1,
        check   => [ $new_role, $new_role_2 ],
    },
    {
        data    => {
            context_id => $context->context_id,
        },
        success => 1,
        check   => [ $new_role, $new_role_2 ],
    },
    {
        data    => {
            role_name => 'test'
        },
        success => 1,
        check   => [ $new_role ],
    },
    {
        data    => {
            role_name => { LIKE => 'te%' },
        },
        success => 1,
        check   => [ $new_role ],
    },
    {
        data    => {
            role_name => { LIKE => 'te%' },
            context_id => 123,
        },
        success => 1,
        check   => [],
    },
    {
        data    => {
            arg3 => 'test',
        },
        success => 0,
        error   => 'Cannot search for roles',
    },
);

for my $search ( @searches ) {
    state $cnt++;

    my @roles = $db->search( 'role' => $search->{data}->%* );

    if ( $search->{success} ) {
        check( \@roles, $search->{check} );
        is $db->error, '';
    }
    else {
        ok !@roles;
        is $db->error, $search->{error};
    }
}

unlink $file, $file . '-shm', $file . '-wal';

done_testing;

sub check {
    my ($got, $expected) = @_;

    is_deeply {
        map{ $_ => 1 }$got->@*,
    }, {
        map{ $_->role_id => 1 }$expected->@*,
    };
}