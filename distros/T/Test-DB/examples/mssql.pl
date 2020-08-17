#!/usr/bin/env perl

use strict;
use warnings;

use feature 'say';

use Test::DB;

my $testdb = Test::DB->new;

# creates DB
my $pgdb = $testdb->create(
  database => 'mssql',
);

# do stuff in test DB
$pgdb->dbh->do('create table [users] ([id] int primary key)');
$pgdb->dbh->do('select * from [users]');

# destroys DB
$pgdb->destroy;

# no mas
say join ' ', 'done with', $pgdb->database;
