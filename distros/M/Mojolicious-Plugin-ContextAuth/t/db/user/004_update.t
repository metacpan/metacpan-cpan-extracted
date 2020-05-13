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
);

my $new_user = $user->add(
    username      => 'test',
    user_password => 'hallo', 
);

ok $user->load($new_user->user_id);
isa_ok $new_user, 'Mojolicious::Plugin::ContextAuth::DB::User';
is $new_user->username, 'test';

{
    my $updated_user = $new_user->update(
        username      => 'ernie',
        user_password => 'bert',
    );

    ok $updated_user;
    isa_ok $updated_user, 'Mojolicious::Plugin::ContextAuth::DB::User';
    is $updated_user->username, 'ernie';
    isnt $updated_user->user_password, $new_user->user_password;
}

{
    my $updated_user = $user->update(
        $new_user->user_id,
        username      => 'sheldon',
        user_password => 'cooper',
    );

    ok $updated_user;
    isa_ok $updated_user, 'Mojolicious::Plugin::ContextAuth::DB::User';
    is $updated_user->username, 'sheldon';
    isnt $updated_user->user_password, $new_user->user_password;
}

{
    ok !$new_user->update(
        username => 'te'
    );

    is $new_user->error, 'Invalid parameter'
}

{
    ok !$new_user->update(
        username => 'te' x 500
    );

    is $new_user->error, 'Invalid parameter'
}

{
    ok !$new_user->update(
        username => 'tester123',
        arg3     => 1323,
    );

    is $new_user->error, 'Invalid parameter'
}

{
    ok !$new_user->update(
        username => ''
    );

    is $new_user->error, 'Invalid parameter'
}

{
    my $updated_user = $user->update(
        123,
        username      => 'sheldon',
        user_password => 'cooper',
    );

    ok !$updated_user;
}

{
    my $updated_user = $user->update(
        $new_user->user_id,
        username      => 'ray',
    );

    ok $updated_user;
    isa_ok $updated_user, 'Mojolicious::Plugin::ContextAuth::DB::User';
    is $updated_user->username, 'ray';
}


unlink $file, $file . '-shm', $file . '-wal';

done_testing;
