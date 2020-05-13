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

ok !$user->delete;
ok $user->error, "Need user id";

my $new_user = $user->add(
    username      => 'test',
    user_password => 'hallo', 
);

my $new_user_2 = $user->add(
    username      => 'test2',
    user_password => 'hallo', 
);

{
    my $user_found = $user->load( $new_user->user_id );
    ok $user_found;
    isa_ok $user_found, 'Mojolicious::Plugin::ContextAuth::DB::User';
    is $user_found->username, $new_user->username;
}

{
    my $user_found = $user->load( $new_user_2->user_id );
    ok $user_found;
    isa_ok $user_found, 'Mojolicious::Plugin::ContextAuth::DB::User';
    is $user_found->username, $new_user_2->username;
}

ok $new_user->delete;


{
    my $user_found = $user->load( $new_user->user_id );
    ok !$user_found;
}

{
    my $user_found = $user->load( $new_user_2->user_id );
    ok $user_found;
    isa_ok $user_found, 'Mojolicious::Plugin::ContextAuth::DB::User';
    is $user_found->username, $new_user_2->username;
}

ok $user->delete( $new_user_2->user_id );

{
    my $user_found = $user->load( $new_user->user_id );
    ok !$user_found;
}

{
    my $user_found = $user->load( $new_user_2->user_id );
    ok !$user_found;
}

ok !$new_user->delete;

ok !$user->delete(undef);
is $user->error, 'Need user id';

ok !$user->delete( $db );
is $user->error, 'Invalid user id';

{
    $db->dbh->db->query( "DROP TABLE corbac_user_sessions");
    $db->dbh->db->query( "DROP TABLE corbac_user_context_roles");
    $db->dbh->db->query( "DROP TABLE corbac_users");
    ok !$user->delete( 123 );
    like $user->error, qr/\ACannot delete user:/;
}

unlink $file, $file . '-shm', $file . '-wal';

done_testing;
