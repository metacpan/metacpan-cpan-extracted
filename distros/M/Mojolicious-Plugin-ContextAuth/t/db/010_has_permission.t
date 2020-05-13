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

my $resource = $db->add(
    resource =>
        resource_name => 'Filters',
);

my $permission = $db->add(
    permission =>
        permission_name => 'FilterUpdate',
        resource_id     => $resource->resource_id,
);

ok !$user->has_permission(
    context_id    => $context->context_id,
    permission_id => $permission->permission_id,
);

is $user->error, '';

$user->set_context_roles(
    context_id => $context->context_id,
    roles      => [
        $role_a->role_id,
    ],
);

is $user->error, '';

$permission->set_roles(
    roles => [
        $role_a->role_id,
    ],
);

is $permission->error, '';

ok $user->has_permission(
    context_id    => $context->context_id,
    permission_id => $permission->permission_id,
);

is $user->error, '';

{
    my $tmp_user = Mojolicious::Plugin::ContextAuth::DB::User->new( dbh => $db->dbh );
    ok !$tmp_user->has_permission();
    is $tmp_user->error, 'Need user id';

    ok !$tmp_user->has_permission( user_id => {}, context_id => 123, permission_id => 123 );
    is $tmp_user->error, 'Invalid user id';

    ok !$tmp_user->has_permission( user_id => 123, context_id => {}, permission_id => 123 );
    is $tmp_user->error, 'Invalid context id';

    ok !$tmp_user->has_permission( user_id => 123, context_id => 123, permission_id => [] );
    is $tmp_user->error, 'Invalid permission id';

    ok !$tmp_user->has_permission( user_id => 123, context_id => 123 );
    is $tmp_user->error, 'Need context_id and permission_id';

    ok !$tmp_user->has_permission( user_id => 123, permission_id => 123 );
    is $tmp_user->error, 'Need context_id and permission_id';
}

{
    $db->dbh->db->query("DROP TABLE corbac_user_context_roles");
    ok !$user->has_permission(
        context_id    => 123,
        permission_id => 123,
    );

    like $user->error, qr/\ACannot determine/;
}

unlink $file, $file . '-shm', $file . '-wal';

done_testing;
