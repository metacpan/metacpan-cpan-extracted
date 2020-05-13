#!/usr/bin/env perl

use v5.10;

use strict;
use warnings;

use Mojolicious::Plugin::ContextAuth::DB;
use Mojolicious::Plugin::ContextAuth::DB::User;

use Mojo::File qw(path);
use Mojo::Util qw(camelize);
use Test::More;

my $file = path(__FILE__)->sibling($$ . '.db')->to_string;

my $db = Mojolicious::Plugin::ContextAuth::DB->new(
    dsn => 'sqlite:' . $file,
);

my $user = Mojolicious::Plugin::ContextAuth::DB::User->new(
    dbh => $db->dbh,
);

ok ! $user->load(1);

{
    my $error;
    eval {
        $user->load;
    } or $error = 1;
    ok $error;
}

{
    my $error;
    eval {
        $user->load( $db );
    } or $error = 1;
    ok $error;
}

{
    ok !$user->load( undef );
    is $user->error, 'Need id';
}

my $new_user = $user->add(
    username      => 'test',
    user_password => 'hallo', 
);

my $loaded_user = $user->load( $new_user->user_id );
ok $loaded_user;
isa_ok $loaded_user, 'Mojolicious::Plugin::ContextAuth::DB::User';
is $loaded_user->username, 'test';

unlink $file, $file . '-shm', $file . '-wal';

done_testing;
