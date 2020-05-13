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

$db->add( 'user', username => 'test', user_password => 'hallo' );

my @tests = (
    {
        data   => [ 'test', 'hallo' ],
        result => 1,
    },
    {
        data   => [ 'test', 'hallo2' ],
        result => 0,
        error  => 'Wrong username or password',
    },
    {
        data   => [ 'test2', 'hallo2' ],
        result => 0,
        error  => 'Wrong username or password',
    },
    {
        data   => [ 'test2', 'hallo' ],
        result => 0,
        error  => 'Wrong username or password',
    },
    {
        data   => [ 'test', undef ],
        result => 0,
        error  => 'Need username and password',
    },
    {
        data   => [ undef, 'hallo' ],
        result => 0,
        error  => 'Need username and password',
    },
    {
        data   => [ undef, undef ],
        result => 0,
        error  => 'Need username and password',
    }
);

for my $test ( @tests ) {
    state $testnr++;

    my $logged_in = $db->login( @{ $test->{data} || [] });
    my $is_ok = $test->{result} ? $logged_in : !$logged_in;
    ok $is_ok, "Login $testnr";

    if ( !$test->{result} ) {
        is $db->error, $test->{error}, "error message is correct ($testnr)";
    }
}

unlink $file, $file . '-shm', $file . '-wal';

done_testing;
