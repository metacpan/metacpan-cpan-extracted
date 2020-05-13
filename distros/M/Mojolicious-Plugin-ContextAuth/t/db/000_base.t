#!/usr/bin/env perl

use strict;
use warnings;

use Mojolicious::Plugin::ContextAuth::DB;

use Mojo::File qw(path);
use Test::More;

my $file = path(__FILE__)->sibling($$ . '.db')->to_string;

my $db = Mojolicious::Plugin::ContextAuth::DB->new(
    dsn => 'sqlite:' . $file,
);

isa_ok $db, 'Mojolicious::Plugin::ContextAuth::DB';
can_ok $db, qw/new login dsn dbh add get update delete login user_from_session/;

unlink $file;

done_testing;
