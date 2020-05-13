#!/usr/bin/env perl

use v5.10;

use strict;
use warnings;

use Mojolicious::Plugin::ContextAuth::DB;

use Mojo::File qw(path);
use Mojo::Util qw(camelize);
use Test::More;

my $file = path(__FILE__)->sibling($$ . '.db')->to_string;

my $db = Mojolicious::Plugin::ContextAuth::DB->new(
    dsn => 'sqlite:' . $file,
);

my $user = $db->add(
    user =>
        username => 'test',
        user_password => 'hallo',
);

my $user_two = $db->add(
    user =>
        username => 'test_two',
        user_password => 'hallo',
);

my $context = $db->add(
    'context' =>
        context_name => 'project_a'
);

my $role = $db->add(
    'role' =>
        role_name  => 'role_a',
        context_id => $context->context_id,
);

{
    my @users = $role->context_users(
        context_id => $context->context_id,
    );

    ok !@users;
    is $role->error, '';
}

ok $role->set_context_users(
    context_id => $context->context_id,
    users   => [
        $user->user_id,
    ],
);

is $role->error, '';

{
    my @users = $role->context_users(
        context_id => $context->context_id,
    );

    is_deeply \@users, [$user->user_id];
    is $role->error, '';
}

ok $role->set_context_users(
    context_id => $context->context_id,
    users   => [
        $user->user_id,
        $user_two->user_id,
    ],
);

is $role->error, '';

{
    my @users = $role->context_users(
        context_id => $context->context_id,
    );

    is_deeply {
        map{ $_ => 1 }@users
    }, {
        $user->user_id => 1,
        $user_two->user_id => 1,
    };

    is $role->error, '';
}

{
    my $role = Mojolicious::Plugin::ContextAuth::DB::Role->new( dbh => $db->dbh );
    ok !$role->context_users;
    is $role->error, 'Need role id';
}

{
    my $role = Mojolicious::Plugin::ContextAuth::DB::Role->new( dbh => $db->dbh );
    ok !$role->context_users( role_id => {} );
    is $role->error, 'Invalid role id';
}

{
    my $tmp_role = Mojolicious::Plugin::ContextAuth::DB::Role->new( dbh => $db->dbh );
    my @users = $tmp_role->context_users(
        context_id => $context->context_id,
        role_id    => $role->role_id,
    );

    is_deeply {
        map{ $_ => 1 }@users
    }, {
        $user->user_id => 1,
        $user_two->user_id => 1,
    };

    is $tmp_role->error, '';
}


{
    ok !$role->context_users();
    is $role->error, 'No context id given';
}


{
    ok !$role->context_users(
        context_id => [],
    );
    is $role->error, 'Invalid context id';
}


{
    ok !$role->context_users(
        context_id => {},
    );
    is $role->error, 'Invalid context id';
}


{
    $db->dbh->db->query("DROP TABLE corbac_user_context_roles");
    my $role = Mojolicious::Plugin::ContextAuth::DB::Role->new( dbh => $db->dbh );
    ok !$role->context_users( role_id => 123, context_id => 123 );
    like $role->error, qr/\ACannot get list of context users/;
}

unlink $file, $file . '-shm', $file . '-wal';

done_testing;
