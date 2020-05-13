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
    resource_name => 'test',
);

ok $resource->load( $new_resource->resource_id );
isa_ok $new_resource, 'Mojolicious::Plugin::ContextAuth::DB::Resource';
is $new_resource->resource_name, 'test';

{
    my $updated_resource = $new_resource->update(
        resource_name => 'ernie',
    );

    ok $updated_resource;
    isa_ok $updated_resource, 'Mojolicious::Plugin::ContextAuth::DB::Resource';
    is $updated_resource->resource_name, 'ernie';
}

{
    my $updated_resource = $resource->update(
        $new_resource->resource_id,
        resource_name        => 'sheldon',
        resource_description => 'cooper',
    );

    ok $updated_resource;
    isa_ok $updated_resource, 'Mojolicious::Plugin::ContextAuth::DB::Resource';
    is $updated_resource->resource_name, 'sheldon';
    isnt $updated_resource->resource_description, $new_resource->resource_description;
}

{
    ok !$new_resource->update(
        resource_name => ''
    );

    is $new_resource->error, 'Invalid parameter';
}

{
    ok !$new_resource->update(
        resource_name => 'te'
    );

    is $new_resource->error, 'Invalid parameter';
}

{
    ok !$new_resource->update(
        resource_name => 'te' x 500,
    );

    is $new_resource->error, 'Invalid parameter';
}

{
    ok $new_resource->update(
        resource_label => 'a test label',
    );

    is $new_resource->error, '';
}

{
    ok !$new_resource->update(
        resource_label => 'a test label',
        arg3           => 123,
    );

    is $new_resource->error, 'Invalid parameter';
}


unlink $file, $file . '-shm', $file . '-wal';

done_testing;
