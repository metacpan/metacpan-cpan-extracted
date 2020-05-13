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

my $new_user = $db->add(
    'user' =>
        username      => 'test',
        user_password => 'hallo', 
);

my $new_user_2 = $db->add(
    user =>
        username      => 'test2',
        user_password => 'hallo', 
);

{
    my $user_found = $db->get( user => $new_user->user_id );
    ok $user_found;
    isa_ok $user_found, 'Mojolicious::Plugin::ContextAuth::DB::User';
    is $user_found->username, $new_user->username;
}

{
    my $user_found = $db->get( user => $new_user_2->user_id );
    ok $user_found;
    isa_ok $user_found, 'Mojolicious::Plugin::ContextAuth::DB::User';
    is $user_found->username, $new_user_2->username;
}

ok $db->delete( user => $new_user->user_id );


{
    my $user_found = $db->get( user => $new_user->user_id );
    ok !$user_found;
}

{
    my $user_found = $db->get( user => $new_user_2->user_id );
    ok $user_found;
    isa_ok $user_found, 'Mojolicious::Plugin::ContextAuth::DB::User';
    is $user_found->username, $new_user_2->username;
}

ok $db->delete( user => $new_user_2->user_id );

{
    my $user_found = $db->get( user => $new_user->user_id );
    ok !$user_found;
}

{
    my $user_found = $db->get( user => $new_user_2->user_id );
    ok !$user_found;
}

ok !$db->delete( user => $new_user->user_id );

unlink $file, $file . '-shm', $file . '-wal';

done_testing;
