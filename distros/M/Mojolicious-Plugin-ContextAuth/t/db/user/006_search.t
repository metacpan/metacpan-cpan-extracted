#!/usr/bin/env perl

use v5.10;

use strict;
use warnings;

use Mojolicious::Plugin::ContextAuth::DB;
use Mojolicious::Plugin::ContextAuth::DB::User;

use Mojo::File qw(path);
use Mojo::Util qw(camelize);
use Test::More;

use feature 'postderef';
no warnings 'experimental::postderef';

my $file = path(__FILE__)->sibling($$ . '.db')->to_string;

my $db = Mojolicious::Plugin::ContextAuth::DB->new(
    dsn => 'sqlite:' . $file,
);

my $user = Mojolicious::Plugin::ContextAuth::DB::User->new(
    dbh => $db->dbh,
);

my $new_user = $user->add(
    username => 'test',
    user_password => 'test',
);

my $new_user_2 = $user->add(
    username => 'hello',
    user_password => 'test',
);

my @searches = (
    {
        data    => {},
        success => 1,
        check   => [ $new_user, $new_user_2 ],
    },
    {
        data    => {
            username => 'test'
        },
        success => 1,
        check   => [ $new_user ],
    },
    {
        data    => {
            username => { LIKE => 'te%' },
        },
        success => 1,
        check   => [ $new_user ],
    },
    {
        data    => {
            username => { LIKE => 'te%' },
            user_password => 'A simple project',
        },
        success => 1,
        check   => [],
    },
    {
        data    => {
            arg3 => 'test',
        },
        success => 0,
        error   => 'Cannot search for users',
    },
);

for my $search ( @searches ) {
    state $cnt++;

    my @users = $user->search( $search->{data}->%* );

    if ( $search->{success} ) {
        check( \@users, $search->{check}, $cnt );
        is $user->error, '';
    }
    else {
        ok !@users;
        is $user->error, $search->{error};
    }
}

unlink $file, $file . '-shm', $file . '-wal';

done_testing;

sub check {
    my ($got, $expected, $cnt) = @_;

    is_deeply {
        map{ $_ => 1 }$got->@*,
    }, {
        map{ $_->user_id => 1 }$expected->@*,
    }, "Deeply $cnt";
}