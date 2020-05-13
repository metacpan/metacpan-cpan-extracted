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

ok ! $role->load(1);

{
    my $error;
    eval {
        $role->load;
    } or $error = 1;
    ok $error;
}

{
    my $error;
    eval {
        $role->load( $db );
    } or $error = 1;
    ok $error;
}

{
    ok !$role->load( undef );
    is $role->error, 'Need id';
}

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

unlink $file, $file . '-shm', $file . '-wal';

done_testing;
