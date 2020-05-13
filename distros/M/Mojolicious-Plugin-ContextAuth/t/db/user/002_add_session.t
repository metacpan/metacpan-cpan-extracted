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

$new_user->add_session(
    'session_id_123'
);

my $session_id = $db->dbh->db->select('corbac_user_sessions' => ['session_id'])->hash;

is $session_id->{session_id}, 'session_id_123';

unlink $file, $file . '-shm', $file . '-wal';

done_testing;
