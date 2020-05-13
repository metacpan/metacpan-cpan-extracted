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

my $context_b = $db->add(
    'context' =>
        context_name => 'project_b'
);

my $role_a = $db->add(
    'role' =>
        role_name  => 'role_a',
        context_id => $context->context_id,
);

{
    my @contexts = $user->contexts();

    ok !@contexts;
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
    my @contexts = $user->contexts();

    is_deeply \@contexts, [
        $context->context_id,
    ];
    is $user->error, '';
}

ok $user->set_context_roles(
    context_id => $context_b->context_id,
    roles      => [
        $role_a->role_id,
    ],
);

is $user->error, '';

{
    my @contexts = $user->contexts();

    is_deeply {
        map { $_ => 1 } @contexts
    }, {
        $context->context_id => 1,
        $context_b->context_id => 1,
    };
    is $user->error, '';
}

{
    my $tmp_user = Mojolicious::Plugin::ContextAuth::DB::User->new( dbh => $db->dbh );

    ok !$tmp_user->contexts;
    is $tmp_user->error, 'Need user id';

    ok !$tmp_user->contexts( user_id => {} );
    is $tmp_user->error, 'Invalid user id';
}

{
    $db->dbh->db->query("DROP TABLE corbac_user_context_roles");
    my $tmp_user = Mojolicious::Plugin::ContextAuth::DB::User->new( dbh => $db->dbh );
    ok !$tmp_user->contexts( user_id => 123 );
    like $tmp_user->error, qr/\ACannot get contexts/;
}

unlink $file, $file . '-shm', $file . '-wal';

done_testing;
