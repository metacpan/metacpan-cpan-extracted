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

{
    my $error;
    eval {
        $permission->load;
    } or $error = 1;

    ok $error;
}

{
    my $error;
    eval {
        $permission->load( $db );
    } or $error = 1;

    ok $error;
}

{
    $permission->load(undef);
    ok $permission->error, "Need id";
}

ok ! $permission->load(1);

my $new_permission = $permission->add(
    permission_name => 'test',
    resource_id     => $resource->resource_id, 
);

ok $permission->load($new_permission->permission_id );
isa_ok $new_permission, 'Mojolicious::Plugin::ContextAuth::DB::Permission';
is $new_permission->permission_name, 'test';

unlink $file, $file . '-shm', $file . '-wal';

done_testing;
