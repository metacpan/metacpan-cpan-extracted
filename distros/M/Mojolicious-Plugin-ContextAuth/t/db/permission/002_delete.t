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

my $new_permission_2 = $permission->add(
    permission_name => 'test2',
    resource_id     => $resource->resource_id, 
);

{
    my $permission_found = $permission->load( $new_permission->permission_id );
    ok $permission_found;
    isa_ok $permission_found, 'Mojolicious::Plugin::ContextAuth::DB::Permission';
    is $permission_found->permission_name, $new_permission->permission_name;
}

{
    my $permission_found = $permission->load( $new_permission_2->permission_id );
    ok $permission_found;
    isa_ok $permission_found, 'Mojolicious::Plugin::ContextAuth::DB::Permission';
    is $permission_found->permission_name, $new_permission_2->permission_name;
}

ok $new_permission->delete;


{
    my $permission_found = $permission->load( $new_permission->permission_id );
    ok !$permission_found;
}

{
    my $permission_found = $permission->load( $new_permission_2->permission_id );
    ok $permission_found;
    isa_ok $permission_found, 'Mojolicious::Plugin::ContextAuth::DB::Permission';
    is $permission_found->permission_name, $new_permission_2->permission_name;
}

ok $permission->delete( $new_permission_2->permission_id );

{
    my $permission_found = $permission->load( $new_permission->permission_id );
    ok !$permission_found;
}

{
    my $permission_found = $permission->load( $new_permission_2->permission_id );
    ok !$permission_found;
}

ok !$new_permission->delete;

ok !$permission->delete;
is $permission->error, 'Need permission id';

ok !$permission->delete( $db );
is $permission->error, 'Invalid permission id';

{
    $db->dbh->db->query( "DROP TABLE corbac_role_permissions");
    $db->dbh->db->query( "DROP TABLE corbac_permissions");
    ok !$permission->delete( 123 );
    like $permission->error, qr/\ACannot delete permission:/;
}

unlink $file, $file . '-shm', $file . '-wal';

done_testing;
