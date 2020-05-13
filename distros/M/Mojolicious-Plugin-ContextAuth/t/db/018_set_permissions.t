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

my $resource = $db->add(
    'resource' =>
        resource_name => 'customer',
);

my $permission_a = $db->add(
    'permission' =>
        permission_name => 'write',
        resource_id     => $resource->resource_id,
);

my $permission_b = $db->add(
    'permission' =>
        permission_name => 'delete',
        resource_id     => $resource->resource_id,
);

{
    my @permissions = $role->permissions();

    ok !@permissions;
    is $role->error, '';
}

ok $role->set_permissions(
    permissions   => [
        $permission_a->permission_id,
    ],
);

is $role->error, '';

{
    my @permissions = $role->permissions(
        role_id => $role->role_id,
    );

    is_deeply \@permissions, [$permission_a->permission_id];
    is $role->error, '';
}

ok $role->set_permissions(
    permissions   => [
        $permission_a->permission_id,
        $permission_b->permission_id,
    ],
);

is $role->error, '';

{
    my @permissions = $role->permissions();

    is_deeply {
        map{ $_ => 1 }@permissions
    }, {
        $permission_a->permission_id => 1,
        $permission_b->permission_id => 1,
    };

    is $role->error, '';
}

ok $role->set_permissions(
    permissions   => [
        $permission_b->permission_id,
    ],
);

is $role->error, '';

{
    my @permissions = $role->permissions();

    is_deeply \@permissions, [$permission_b->permission_id];
    is $role->error, '';
}

ok $role->set_permissions(
    permissions   => [],
);

is $role->error, '';

{
    my @permissions = $role->permissions();

    ok !@permissions;
}


ok !$role->set_permissions();

is $role->error, "Need permissions";


ok !$role->set_permissions(
    permissions   => {},
);

like $role->error, qr/\ATransaction error:/;

{
    my $role = Mojolicious::Plugin::ContextAuth::DB::Role->new( dbh => $db->dbh );
    ok !$role->set_permissions;
    is $role->error, 'Need role id';
}

{
    my $tmp_role = Mojolicious::Plugin::ContextAuth::DB::Role->new( dbh => $db->dbh );
    ok $tmp_role->set_permissions(
        role_id     => $role->role_id,
        permissions => [],
    );
    is $tmp_role->error, '';
}

{
    my $role = Mojolicious::Plugin::ContextAuth::DB::Role->new( dbh => $db->dbh );
    ok !$role->set_permissions(
        role_id => {},
        permissions => [],
    );
    is $role->error, 'Invalid role id';
}

{
    my $cnt_set_permissions = $role->set_permissions(
        permissions   => [
            $permission_a->permission_id,
            123,
        ],
    );

    is $cnt_set_permissions, 1;
    is $role->error, '';
}

{
    my $cnt_set_permissions = $role->set_permissions(
        permissions   => [
            $permission_a->permission_id,
            $permission_b->permission_id,
            123,
        ],
    );

    is $cnt_set_permissions, 2;
    is $role->error, '';
}

{
    my $cnt_set_permissions = $role->set_permissions(
        permissions   => [
            $permission_a->permission_id,
            $permission_b->permission_id,
            {},
        ],
    );

    is $cnt_set_permissions, 2;
    is $role->error, '';
}


{
    $db->dbh->db->query("DROP TABLE corbac_role_permissions");
    my $tmp_role = Mojolicious::Plugin::ContextAuth::DB::Role->new( dbh => $db->dbh );
    ok !$tmp_role->set_permissions(
        role_id => $role->role_id,
        permissions => [],
    );
    like $tmp_role->error, qr/\ATransaction error:/;
}

unlink $file, $file . '-shm', $file . '-wal';

done_testing;
