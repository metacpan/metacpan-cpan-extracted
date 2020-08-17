#!/usr/bin/env perl

use strict;
use warnings;

use feature 'say';

use Test::DB;

my $testdb = Test::DB->new;

# creates DB
my $sldb = $testdb->create(
  database => 'sqlite',
);

# do stuff in test DB
$sldb->dbh->do('create table users (id int primary key)');
$sldb->dbh->do('select * from users');

# destroys DB
$sldb->destroy;

# no mas
say join ' ', 'done with', $sldb->database;
