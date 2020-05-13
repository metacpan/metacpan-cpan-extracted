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

my $new_role_2 = $role->add(
    role_name  => 'test2',
    context_id => $context->context_id,
);

{
    my $role_found = $role->load( $new_role->role_id );
    ok $role_found;
    isa_ok $role_found, 'Mojolicious::Plugin::ContextAuth::DB::Role';
    is $role_found->role_name, $new_role->role_name;
}

{
    my $role_found = $role->load( $new_role_2->role_id );
    ok $role_found;
    isa_ok $role_found, 'Mojolicious::Plugin::ContextAuth::DB::Role';
    is $role_found->role_name, $new_role_2->role_name;
}

ok $new_role->delete;


{
    my $role_found = $role->load( $new_role->role_id );
    ok !$role_found;
}

{
    my $role_found = $role->load( $new_role_2->role_id );
    ok $role_found;
    isa_ok $role_found, 'Mojolicious::Plugin::ContextAuth::DB::Role';
    is $role_found->role_name, $new_role_2->role_name;
}

ok $role->delete( $new_role_2->role_id );

{
    my $role_found = $role->load( $new_role->role_id );
    ok !$role_found;
}

{
    my $role_found = $role->load( $new_role_2->role_id );
    ok !$role_found;
}

ok !$new_role->delete;

ok !$role->delete(undef);
is $role->error, 'Need role id';

ok !$role->delete( $db );
is $role->error, 'Invalid role id';

{
    $db->dbh->db->query( "DROP TABLE corbac_role_permissions");
    $db->dbh->db->query( "DROP TABLE corbac_user_context_roles");
    $db->dbh->db->query( "DROP TABLE corbac_roles");
    ok !$role->delete( 123 );
    like $role->error, qr/\ACannot delete role:/;
}

unlink $file, $file . '-shm', $file . '-wal';

done_testing;
