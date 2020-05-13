#!/usr/bin/env perl

use v5.10;

use strict;
use warnings;

use Mojolicious::Plugin::ContextAuth::DB;
use Mojolicious::Plugin::ContextAuth::DB::Permission;

use Mojo::File qw(path);
use Mojo::Util qw(camelize);
use Test::More;

my $file = path(__FILE__)->sibling($$ . '.db')->to_string;

my $db = Mojolicious::Plugin::ContextAuth::DB->new(
    dsn => 'sqlite:' . $file,
);

my $permission = Mojolicious::Plugin::ContextAuth::DB::Permission->new(
    dbh => $db->dbh,
);

my $resource = $db->add(
    'resource' => resource_name => 'project_a',
);

my $new_permission = $permission->add(
    permission_name => 'test',
    resource_id     => $resource->resource_id, 
);

ok $permission->load( $new_permission->permission_id );
isa_ok $new_permission, 'Mojolicious::Plugin::ContextAuth::DB::Permission';
is $new_permission->permission_name, 'test';

{
    my $updated_permission = $new_permission->update(
        permission_name => 'ernie',
    );

    ok $updated_permission;
    isa_ok $updated_permission, 'Mojolicious::Plugin::ContextAuth::DB::Permission';
    is $updated_permission->permission_name, 'ernie';
    isnt $updated_permission->permission_name, $new_permission->permission_name;
}

{
    my $updated_permission = $permission->update(
        $new_permission->permission_id,
        permission_name => 'sheldon',
    );

    ok $updated_permission;
    isa_ok $updated_permission, 'Mojolicious::Plugin::ContextAuth::DB::Permission';
    is $updated_permission->permission_name, 'sheldon';
    isnt $updated_permission->permission_name, $new_permission->permission_name;
}

{
    my $updated =  $new_permission->update(
        permission_label => 'changed label',
    );

    is $updated->permission_label, 'changed label';
    is $new_permission->error, '';
}

{
    ok !$new_permission->update(
        permission_name => '',
    );

    is $new_permission->error, 'Invalid parameter';
}

{
    ok !$new_permission->update(
        permission_name => 'te'
    );

    is $new_permission->error, 'Invalid parameter'
}

{
    ok !$new_permission->update(
        permission_name => 'te' x 500,
    );

    is $new_permission->error, 'Invalid parameter'
}

{
    ok !$new_permission->update(
        permission_name => 'te' x 50,
        arg3            => 123,
    );

    is $new_permission->error, 'Invalid parameter'
}

{
    ok !$permission->update( 123, permission_name => 'non-existent-permission' );
    is $permission->error, 'No permission updated';
}

{
    ok $permission->update(
        $new_permission->permission_id,
            permission_name => 'non-existent-permission',
    );
    is $permission->error, '';
}


unlink $file, $file . '-shm', $file . '-wal';

done_testing;
