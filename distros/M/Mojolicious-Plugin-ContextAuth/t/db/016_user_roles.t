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

my $user = $db->add(
    user =>
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
    my @roles = $context->user_roles(
        user_id => $user->user_id,
    );

    ok !@roles;
    is $context->error, '';
}

ok $context->set_user_roles(
    user_id => $user->user_id,
    roles   => [
        $role_a->role_id,
    ],
);

is $context->error, '';

{
    my @roles = $context->user_roles(
        user_id => $user->user_id,
    );

    is_deeply \@roles, [ $role_a->role_id ];
    is $context->error, '';
}

ok $context->set_user_roles(
    user_id => $user->user_id,
    roles   => [
        $role_a->role_id,
        $role_b->role_id,
    ],
);

is $context->error, '';

{
    my @roles = $context->user_roles(
        user_id => $user->user_id,
    );

    is_deeply {
        map{ $_ => 1 }@roles
    }, {
        $role_a->role_id => 1,
        $role_b->role_id => 1,
    };

    is $context->error, '';
}


{
    ok !$context->user_roles(
        user_id => { LIKE => \"arg3" },
    );
    like $context->error, qr/\ACannot get list of user roles:/;
}

{
    ok !$context->user_roles;
    is $context->error, 'No user_id given';
}

{
    ok !$context->user_roles(
        user_id => 123,
    );
    is $context->error, '';
}

{
    my $ctx = Mojolicious::Plugin::ContextAuth::DB::Context->new( dbh => $db->dbh );
    ok !$ctx->user_roles;
    is $ctx->error, 'Need context id';
}

unlink $file, $file . '-shm', $file . '-wal';

done_testing;
