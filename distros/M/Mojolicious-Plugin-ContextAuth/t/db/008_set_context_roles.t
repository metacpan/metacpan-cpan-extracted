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
)->add(
    username => 'test',
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

my $role_b = $db->add(
    'role' =>
        role_name  => 'role_b',
        context_id => $context->context_id,
);

{
    my @roles = $user->context_roles(
        context_id => $context->context_id,
    );

    ok !@roles;
    is $user->error, '';
}

ok $user->set_context_roles(
    context_id => $context->context_id,
    roles      => [
        $role_a->role_id,
    ],
);

is $user->error, '';

{
    my @roles = $user->context_roles(
        context_id => $context->context_id,
    );

    is_deeply \@roles, [ $role_a->role_id ];
    is $user->error, '';
}

ok $user->set_context_roles(
    context_id => $context->context_id,
    roles      => [
        $role_a->role_id,
        $role_b->role_id,
    ],
);

is $user->error, '';

{
    my @roles = $user->context_roles(
        context_id => $context->context_id,
    );

    is_deeply {
        map{ $_ => 1 }@roles
    }, {
        $role_a->role_id => 1,
        $role_b->role_id => 1,
    };

    is $user->error, '';
}

ok $user->set_context_roles(
    context_id => $context->context_id,
    roles      => [
        $role_b->role_id,
    ],
);

is $user->error, '';

{
    my @roles = $user->context_roles(
        context_id => $context->context_id,
    );

    is_deeply \@roles, [ $role_b->role_id ];
    is $user->error, '';
}

ok $user->set_context_roles(
    context_id => $context->context_id,
    roles      => [],
);

is $user->error, '';

{
    my @roles = $user->context_roles(
        context_id => $context->context_id,
    );

    ok !@roles;
}


ok !$user->set_context_roles(
    context_id => $context->context_id,
);

is $user->error, "need context_id and roles";


ok !$user->set_context_roles(
    roles => [],
);

is $user->error, "need context_id and roles";

{
    my @roles = $user->context_roles(
        context_id => $context->context_id,
        roles      => [ 123 ],
    );

    ok !@roles;
    is $user->error, '';
}


ok !$user->set_context_roles(
    context_id => $context->context_id,
    roles      => {},
);

like $user->error, qr/\ATransaction error:/;

unlink $file, $file . '-shm', $file . '-wal';

done_testing;
