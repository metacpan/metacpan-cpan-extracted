#!/usr/bin/env perl

use v5.10;

use strict;
use warnings;

use Mojolicious::Plugin::ContextAuth::DB;
use Mojolicious::Plugin::ContextAuth::DB::Context;

use Mojo::File qw(path);
use Mojo::Util qw(camelize);
use Test::More;

my $file = path(__FILE__)->sibling($$ . '.db')->to_string;

my $db = Mojolicious::Plugin::ContextAuth::DB->new(
    dsn => 'sqlite:' . $file,
);

my $user = $db->add(
    user =>
        username => 'test',
        user_password => 'hallo',
);

my $user_two = $db->add(
    user =>
        username => 'test_two',
        user_password => 'hallo',
);

my $context = $db->add(
    'context' =>
        context_name => 'project_a'
);

my $role_a = $db->add(
    'role' =>
        role_name  => 'role_a',
        context_id => $context->context_id,
);

{
    my @users = $context->role_users(
        role_id => $role_a->role_id,
    );

    ok !@users;
    is $context->error, '';
}

ok $context->set_role_users(
    role_id => $role_a->role_id,
    users   => [
        $user->user_id,
        $user_two->user_id,
    ],
);

is $context->error, '';

{
    my @users = $context->role_users(
        role_id => $role_a->role_id,
    );

    is_deeply {
        map{ $_ => 1 }@users
    }, {
        $user->user_id => 1,
        $user_two->user_id => 1,
    };

    is $context->error, '';
}

{
    ok !$context->role_users(
        role_id => { LIKE => \"arg3" },
    );
    like $context->error, qr/\ACannot get list of role users:/;
}

{
    ok !$context->role_users;
    is $context->error, 'No role id given';
}

{
    ok !$context->role_users(
        role_id => 123,
    );
    is $context->error, '';
}

{
    my $ctx = Mojolicious::Plugin::ContextAuth::DB::Context->new( dbh => $db->dbh );
    ok !$ctx->role_users;
    is $ctx->error, 'Need context id';
}

unlink $file, $file . '-shm', $file . '-wal';

done_testing;
