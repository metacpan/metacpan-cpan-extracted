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

{
    my $user = Mojolicious::Plugin::ContextAuth::DB::User->new(
        dbh => $db->dbh,
    );

    my @roles = $user->context_roles( context_id => 123 );

    ok !@roles;
    is $user->error, 'Need user id';
}

{
    my @roles = $user->context_roles();

    ok !@roles;
    is $user->error, 'Need context_id';
}

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

{
    my @roles = $user->context_roles(
        context_id => $context->context_id,
    );

    is_deeply \@roles, [ $role_a->role_id ];
    is $user->error, '';
}

{
    my $tmp_user = Mojolicious::Plugin::ContextAuth::DB::User->new( dbh => $db->dbh );
    ok !$tmp_user->set_context_roles;
    is $tmp_user->error, 'Need user id';
}

{
    my $tmp_user = Mojolicious::Plugin::ContextAuth::DB::User->new( dbh => $db->dbh, user_id => {} );
    ok !$tmp_user->set_context_roles;
    is $tmp_user->error, 'Invalid user id';
}

{
    my $tmp_user = Mojolicious::Plugin::ContextAuth::DB::User->new( dbh => $db->dbh );
    ok !$tmp_user->set_context_roles( user_id => {} );
    is $tmp_user->error, 'Invalid user id';

    ok !$tmp_user->set_context_roles( user_id => 123, context_id => {}, roles => [] );
    is $tmp_user->error, 'Invalid context id';
}

{
    my $tmp_user = Mojolicious::Plugin::ContextAuth::DB::User->new( dbh => $db->dbh );
    ok !$tmp_user->context_roles( user_id => {} );
    is $tmp_user->error, 'Invalid user id';

    ok !$tmp_user->context_roles( user_id => 123, context_id => {} );
    is $tmp_user->error, 'Invalid context id';
}

{
    $db->dbh->db->query("DROP TABLE corbac_user_context_roles");
    my $tmp_user = Mojolicious::Plugin::ContextAuth::DB::User->new( dbh => $db->dbh );
    ok !$tmp_user->set_context_roles( user_id => 123, context_id => 123, roles => [] );
    like $tmp_user->error, qr/\ATransaction error/;

    ok !$tmp_user->context_roles( user_id => 123, context_id => 123 );
    like $tmp_user->error, qr/\ACannot get context_roles/;
}

unlink $file, $file . '-shm', $file . '-wal';

done_testing;
