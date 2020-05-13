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

{
    my $error;
    eval {
        $resource->load;
    } or $error = 1;

    ok $error;
}

{
    my $error;
    eval {
        $resource->load( $db );
    } or $error = 1;

    ok $error;
}

{
    $resource->load(undef);
    ok $resource->error, "Need id";
}

{
    $resource->load(0);
    ok $resource->error, "Need id";
}

ok ! $resource->load(1);

my $new_resource = $resource->add(
    resource_name => 'project_a',
    resource_label => 'pr_a',
    resource_description => 'Test description',
);

my $loaded_resource = $resource->load( $new_resource->resource_id );
isa_ok $loaded_resource, 'Mojolicious::Plugin::ContextAuth::DB::Resource';
is $loaded_resource->resource_name, 'project_a';
is $loaded_resource->resource_label, 'pr_a';
is $loaded_resource->resource_description, 'Test description';

unlink $file, $file . '-shm', $file . '-wal';

done_testing;
