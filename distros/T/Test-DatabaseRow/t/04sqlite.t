#!/usr/bin/perl -w

########################################################################
# this tests with a "real" database if we have the DBD::SQLite
# module installed
########################################################################

use strict;

# check if we can use DBD::SQLite
BEGIN {
  unless (eval "use DBD::SQLite; 1") {
    print "1..0 # Skipped: no DBD::SQLite\n";
    exit;
  }
}

use Test::More tests => 1;

use Test::DatabaseRow;
use DBI;
use File::Temp qw(tempdir);

my $dir = tempdir( CLEANUP => 1 );
chdir($dir)
  or die "Can't change directory to temp dir";
END {
  chdir('..');  # needed so deleting temp dir works on Windows
}
my $dbh = DBI->connect("dbi:SQLite:dbname=dbfile","","");

$dbh->do(<<'SQL');
CREATE TABLE perlmongers (
  first_name STRING,
  nick STRING
);
SQL

my %data = (
  "Andrew"  => "Zefram",
  "Dagfinn" => "Ilmari",
  "Mark"    => "Trelane",
  "Leon"    => "acme",
);

$dbh->do(<<'SQL', {}, $_, $data{$_}) foreach keys %data;
INSERT INTO perlmongers (first_name, nick) VALUES (?, ?)
SQL

row_ok(
  dbh => $dbh,
  tests => [ nick => "Trelane" ],
  sql => [ <<'SQL', "Mark"]);
    SELECT *
      FROM perlmongers
     WHERE first_name = ?
SQL
