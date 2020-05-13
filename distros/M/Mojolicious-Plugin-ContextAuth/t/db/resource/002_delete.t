#!/usr/bin/env perl

use v5.10;

use strict;
use warnings;

use Mojolicious::Plugin::ContextAuth::DB;
use Mojolicious::Plugin::ContextAuth::DB::Resource;

use Mojo::File qw(path);
use Mojo::Util qw(camelize);
use Test::More;

my $file = path(__FILE__)->sibling($$ . '.db')->to_string;

my $db = Mojolicious::Plugin::ContextAuth::DB->new(
    dsn => 'sqlite:' . $file,
);

my $resource = Mojolicious::Plugin::ContextAuth::DB::Resource->new(
    dbh => $db->dbh,
);

my $new_resource = $resource->add(
    resource_name => 'project_a',
);

my $new_resource_2 = $resource->add(
    resource_name => 'project_b',
);

{
    my $resource_found = $resource->load( $new_resource->resource_id );
    ok $resource_found;
    isa_ok $resource_found, 'Mojolicious::Plugin::ContextAuth::DB::Resource';
    is $resource_found->resource_name, $new_resource->resource_name;
}

{
    my $resource_found = $resource->load( $new_resource_2->resource_id );
    ok $resource_found;
    isa_ok $resource_found, 'Mojolicious::Plugin::ContextAuth::DB::Resource';
    is $resource_found->resource_name, $new_resource_2->resource_name;
}

ok $new_resource->delete;


{
    my $resource_found = $resource->load( $new_resource->resource_id );
    ok !$resource_found;
}

{
    my $resource_found = $resource->load( $new_resource_2->resource_id );
    ok $resource_found;
    isa_ok $resource_found, 'Mojolicious::Plugin::ContextAuth::DB::Resource';
    is $resource_found->resource_name, $new_resource_2->resource_name;
}

ok $resource->delete( $new_resource_2->resource_id );

{
    my $resource_found = $resource->load( $new_resource->resource_id );
    ok !$resource_found;
}

{
    my $resource_found = $resource->load( $new_resource_2->resource_id );
    ok !$resource_found;
}

ok !$new_resource->delete;

ok !$resource->delete;
is $resource->error, 'Need resource id';

ok !$resource->delete( $db );
is $resource->error, 'Invalid resource id';

{
    $db->dbh->db->query( "DROP TABLE corbac_role_permissions");
    $db->dbh->db->query( "DROP TABLE corbac_permissions");
    $db->dbh->db->query( "DROP TABLE corbac_resources");
    ok !$resource->delete( 123 );
    like $resource->error, qr/\ACannot delete resource:/;
}

unlink $file, $file . '-shm', $file . '-wal';

done_testing;
