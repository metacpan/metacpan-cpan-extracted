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
        data   => ($db->login('test','hallo') // undef),
        result => 1,
    },
    {
        data   => undef,
        result => 0,
        error  => 'Need session id',
    },
    {
        data   => 'invalid_session_id' . $$,
        result => 0,
        error  => 'No session found',
    },
);

for my $test ( @tests ) {
    state $testnr++;

    my $user = $db->user_from_session( $test->{data} );
    my $is_ok = $test->{result} ? $user : !$user;
    ok $is_ok, "User from session $testnr";

    if ( !$test->{result} ) {
        is $db->error, $test->{error}, "error message is correct ($testnr)";
    }
    else {
        isa_ok $user, 'Mojolicious::Plugin::ContextAuth::DB::User', "object ok ($testnr)";
    }
}

unlink $file, $file . '-shm', $file . '-wal';

done_testing;
