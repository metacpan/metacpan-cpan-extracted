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

my $new_user = $db->add(
    user =>
        username      => 'test',
        user_password => 'hallo', 
);

isa_ok $new_user, 'Mojolicious::Plugin::ContextAuth::DB::User';
is $new_user->username, 'test';

{
    my $updated_user = $db->update(
        user => $new_user->user_id,
            username      => 'ernie',
            user_password => 'bert',
    );

    ok $updated_user;
    isa_ok $updated_user, 'Mojolicious::Plugin::ContextAuth::DB::User';
    is $updated_user->username, 'ernie';
    isnt $updated_user->user_password, $new_user->user_password;
}

{
    my $updated_user = $db->update(
        user => $new_user->user_id,
            username      => 'sheldon',
            user_password => 'cooper',
    );

    ok $updated_user;
    isa_ok $updated_user, 'Mojolicious::Plugin::ContextAuth::DB::User';
    is $updated_user->username, 'sheldon';
    isnt $updated_user->user_password, $new_user->user_password;
}

{
    my $updated_user = $db->update(
        user => 123,
            username      => 'ernie',
            user_password => 'bert',
    );

    ok !$updated_user;
}

{
    ok !$db->update(
        user => $new_user->user_id,
            username => ''
    );

    is $db->error, 'Invalid parameter'
}


unlink $file, $file . '-shm', $file . '-wal';

done_testing;
