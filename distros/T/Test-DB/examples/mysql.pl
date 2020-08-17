#!/usr/bin/env perl

use strict;
use warnings;

use feature 'say';

use Test::DB;

my $testdb = Test::DB->new;

# creates DB
my $msdb = $testdb->create(
  database => 'mysql',
);

# do stuff in test DB
$msdb->dbh->do('create table `users` (id int primary key)');
$msdb->dbh->do('select * from `users`');

# destroys DB
$msdb->destroy;

# no mas
say join ' ', 'done with', $msdb->database;
