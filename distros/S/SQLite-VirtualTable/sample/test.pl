#!/usr/bin/perl;

use DBI;
use SQLite::VirtualTable;

$dbh = DBI->connect('dbi:SQLite:dbname=/tmp/db.sqlite', '', '');

# this is just for running further tests by hand in the debugger!

print "$dbh\n";
