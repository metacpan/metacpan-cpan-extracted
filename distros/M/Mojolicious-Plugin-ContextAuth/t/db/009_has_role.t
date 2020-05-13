#!/usr/bin/env perl

use v5.10;

use strict;
use warnings;

use Mojolicious::Plugin::ContextAuth::DB;
use Mojolicious::Plugin::ContextAuth::DB::User;

use Mojo::File qw(path);
use Mojo::Util qw(camelize);
use Test::More;

my $file = path(__FILE__)->sibling($$ . '.db')->to_string;

my $db = Mojolicious::Plugin::ContextAuth::DB->new(
    dsn => 'sqlite:' . $file,
);

my $user = Mojolicious::Plugin::ContextAuth::DB::User->new(
    dbh => $db->dbh,
)->add(
    username => 'test',
    user_password => 'hallo',
);

my $context = $db->add(
    'context' =>
        context_name => 'project_a'
);

my $role_a = $db->add(
    'role' =>
        role_name  => 'role_a',
        context_id => $context->context_id,
);

my $role_b = $db->add(
    'role' =>
        role_name  => 'role_b',
        context_id => $context->context_id,
);

{
    my @roles = $user->context_roles(
        context_id => $context->context_id,
    );

    ok !@roles;
    is $user->error, '';
}

ok $user->set_context_roles(
    context_id => $context->context_id,
    roles      => [
        $role_a->role_id,
    ],
);

is $user->error, '';

ok $user->has_role(
    context_id => $context->context_id,
    role_id    => $role_a->role_id,
);

is $user->error, '';

ok !$user->has_role(
    context_id => $context->context_id,
    role_id    => $role_b->role_id,
);

is $user->error, '';

ok !$user->has_role();

is $user->error, 'Need context_id';


{
    my $user = Mojolicious::Plugin::ContextAuth::DB::User->new(
        dbh => $db->dbh,
    );

    ok !$user->has_role( context_id => 123 );
    is $user->error, 'Need user id';
}

{
    ok $user->has_role(
        context_id => $context->context_id,
        role       => 'role_a',
    );

    is $user->error, '';
}

{
    ok !$user->has_role(
        context_id => $context->context_id,
        role       => 'role_b',
    );

    is $user->error, '';
}

{
    ok !$user->has_role(
        context_id => $context->context_id,
        role       => 'role_c',
    );

    is $user->error, '';
}

{
    ok !$user->has_role(
        context_id => [],
        role       => 'role_c',
    );

    is $user->error, 'Invalid context id';
}

{
    my $tmp_user = Mojolicious::Plugin::ContextAuth::DB::User->new( dbh => $db->dbh );
    ok !$tmp_user->has_role( user_id => {}, context_id => 123 );
    is $tmp_user->error, 'Invalid user id';

    ok !$tmp_user->has_role( user_id => 123, context_id => {} );
    is $tmp_user->error, 'Invalid context id';
}

{
    $db->dbh->db->query("DROP TABLE corbac_user_context_roles");
    ok !$user->has_role(
        context_id => $context->context_id,
        role       => 'role_c',
    );

    like $user->error, qr/\ACannot determine/;
}

unlink $file, $file . '-shm', $file . '-wal';

done_testing;
