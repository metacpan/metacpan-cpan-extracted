#!/usr/bin/env perl

use v5.10;

use strict;
use warnings;

use Mojolicious::Plugin::ContextAuth::DB;
use Mojolicious::Plugin::ContextAuth::DB::Role;
use Mojolicious::Plugin::ContextAuth::DB::Context;

use Mojo::File qw(path);
use Mojo::Util qw(camelize);
use Test::More;

my $file = path(__FILE__)->sibling($$ . '.db')->to_string;

my $db = Mojolicious::Plugin::ContextAuth::DB->new(
    dsn => 'sqlite:' . $file,
);

my $role = Mojolicious::Plugin::ContextAuth::DB::Role->new(
    dbh => $db->dbh,
);

my $context = Mojolicious::Plugin::ContextAuth::DB::Context->new(
    dbh => $db->dbh,
)->add(
    context_name => 'project_a'
);

my $new_role = $role->add(
    role_name  => 'test',
    context_id => $context->context_id,
);

ok $role->load( $new_role->role_id );
isa_ok $new_role, 'Mojolicious::Plugin::ContextAuth::DB::Role';
is $new_role->role_name, 'test';

{
    my $updated_role = $new_role->update(
        role_name        => 'ernie',
        role_description => 'bert',
    );

    ok $updated_role;
    isa_ok $updated_role, 'Mojolicious::Plugin::ContextAuth::DB::Role';
    is $updated_role->role_name, 'ernie';
    isnt $updated_role->role_description, $new_role->role_description;
}

{
    my $updated_role = $role->update(
        $new_role->role_id,
        role_name        => 'sheldon',
        role_description => 'cooper',
    );

    ok $updated_role;
    isa_ok $updated_role, 'Mojolicious::Plugin::ContextAuth::DB::Role';
    is $updated_role->role_name, 'sheldon';
    isnt $updated_role->role_description, $new_role->role_description;
}

{
    my $updated_role = $role->update(
        $new_role->role_id,
        role_description => 'just a role',
    );

    ok $updated_role;
    isa_ok $updated_role, 'Mojolicious::Plugin::ContextAuth::DB::Role';
    is $updated_role->role_description, 'just a role';
    isnt $updated_role->role_description, $new_role->role_description;
}

{
    ok !$new_role->update(
        role_name => ''
    );

    is $new_role->error, 'Invalid parameter';
}

{
    ok !$new_role->update(
        role_name => 'test 1391',
        arg3      => 123,
    );

    is $new_role->error, 'Invalid parameter';
}

{
    ok !$role->update(
        $new_role->role_id => 
            role_name => 'test 1391',
            arg3      => 123,
    );

    is $role->error, 'Invalid parameter';
}

{
    ok !$role->update(
        123 => 
            role_name => 'test 1391',
    );

    is $role->error, 'No role updated';
}

{
    ok $role->update(
        $new_role->role_id => 
            role_description => 'a short description',
    );

    is $role->error, '';
}

{
    ok !$role->update(
        $new_role->role_id => 
            role_name => 'a',
    );

    is $role->error, 'Invalid parameter';
}

{
    ok !$role->update(
        $new_role->role_id => 
            role_name => 'a' x 500,
    );

    is $role->error, 'Invalid parameter';
}


unlink $file, $file . '-shm', $file . '-wal';

done_testing;
