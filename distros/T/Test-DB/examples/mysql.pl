#!/usr/bin/env perl

use strict;
use warnings;

use feature 'say';

use Test::DB;

my $testdb = Test::DB->new;

# creates DB
my $mydb = $testdb->mysql->create;

# do stuff in test DB
$mydb->dbh->do('create table `users` (id int primary key)');
$mydb->dbh->do('select * from `users`');

# destroys DB
$mydb->destroy;

# no mas
say join ' ', 'done with', $mydb->database;
