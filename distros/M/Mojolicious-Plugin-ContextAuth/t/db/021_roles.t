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

my $context = $db->add(
    'context' =>
        context_name => 'project_a'
);

my $role = $db->add(
    'role' =>
        role_name  => 'role_a',
        context_id => $context->context_id,
);

my $role_two = $db->add(
    'role' =>
        role_name  => 'role_b',
        context_id => $context->context_id,
);

my $resource = $db->add(
    resource =>
        resource_name => 'customer',
);

my $permission = $db->add(
    permission =>
        permission_name => 'write',
        resource_id     => $resource->resource_id,
);

ok $permission;

{
    my @roles = $permission->roles();

    ok !@roles;
    is $permission->error, '';
}

ok $permission->set_roles(
    roles => [
        $role->role_id,
    ],
);

is $permission->error, '';

{
    my @roles = $permission->roles();

    is_deeply \@roles, [$role->role_id];
    is $permission->error, '';
}

ok $permission->set_roles(
    roles   => [
        $role->role_id,
        $role_two->role_id,
    ],
);

is $permission->error, '';

{
    my @roles = $permission->roles();

    is_deeply {
        map{ $_ => 1 }@roles
    }, {
        $role->role_id => 1,
        $role_two->role_id => 1,
    };

    is $permission->error, '';
}

{
    my $permission = Mojolicious::Plugin::ContextAuth::DB::Permission->new( dbh => $db->dbh );
    ok !$permission->roles;
    is $permission->error, 'Need permission id';
}

{
    my $permission = Mojolicious::Plugin::ContextAuth::DB::Permission->new( dbh => $db->dbh, permission_id => {} );
    ok !$permission->roles;
    is $permission->error, 'Invalid permission id';
}

unlink $file, $file . '-shm', $file . '-wal';

done_testing;
