#!/usr/bin/env perl

use v5.10;

use strict;
use warnings;

use Mojolicious::Plugin::ContextAuth::DB;
use Mojolicious::Plugin::ContextAuth::DB::Context;

use Mojo::File qw(path);
use Mojo::Util qw(camelize);
use Test::More;

my $file = path(__FILE__)->sibling($$ . '.db')->to_string;

my $db = Mojolicious::Plugin::ContextAuth::DB->new(
    dsn => 'sqlite:' . $file,
);

my $context = Mojolicious::Plugin::ContextAuth::DB::Context->new(
    dbh => $db->dbh,
);

my $new_context = $context->add(
    context_name  => 'test',
);

my $new_context_2 = $context->add(
    context_name => 'test2',
);

{
    my $context_found = $context->load( $new_context->context_id );
    ok $context_found;
    isa_ok $context_found, 'Mojolicious::Plugin::ContextAuth::DB::Context';
    is $context_found->context_name, $new_context->context_name;
}

{
    my $context_found = $context->load( $new_context_2->context_id );
    ok $context_found;
    isa_ok $context_found, 'Mojolicious::Plugin::ContextAuth::DB::Context';
    is $context_found->context_name, $new_context_2->context_name;
}

ok $new_context->delete;


{
    my $context_found = $context->load( $new_context->context_id );
    ok !$context_found;
}

{
    my $context_found = $context->load( $new_context_2->context_id );
    ok $context_found;
    isa_ok $context_found, 'Mojolicious::Plugin::ContextAuth::DB::Context';
    is $context_found->context_name, $new_context_2->context_name;
}

ok $context->delete( $new_context_2->context_id );

{
    my $context_found = $context->load( $new_context->context_id );
    ok !$context_found;
}

{
    my $context_found = $context->load( $new_context_2->context_id );
    ok !$context_found;
}

ok !$new_context->delete;

ok !$context->delete;
is $context->error, 'Need context id';

ok !$context->delete( $db );
is $context->error, 'Invalid context id';

{
    $db->dbh->db->query( "DROP TABLE corbac_role_permissions");
    $db->dbh->db->query( "DROP TABLE corbac_user_context_roles");
    $db->dbh->db->query( "DROP TABLE corbac_roles");
    $db->dbh->db->query( "DROP TABLE corbac_contexts");
    ok !$context->delete( 123 );
    like $context->error, qr/\ACannot delete context:/;
}

unlink $file, $file . '-shm', $file . '-wal';

done_testing;
