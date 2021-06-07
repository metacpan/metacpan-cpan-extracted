#!/usr/bin/env perl

use strict;
use warnings;

use SQL::SplitStatement;

use Test::More tests => 2;

my $sql = <<'SQL';
CREATE TABLE child( x, y, "w;", "z;z", FOREIGN KEY (x, y) REFERENCES parent (a,b) );
CREATE TABLE parent( a, b, c, d, PRIMARY KEY(a, b) );
CREATE TRIGGER genfkey1_delete_referenced BEFORE DELETE ON "parent" WHEN
    EXISTS (SELECT 1 FROM "child" WHERE old."a" == "x" AND old."b" == "y")
BEGIN
  SELECT RAISE(ABORT, 'constraint failed');
END;
SQL
chop( my $clean_sql = $sql );
chop $clean_sql;

my $sql_splitter = SQL::SplitStatement->new;

my @statements = $sql_splitter->split($sql);

cmp_ok (
    scalar(@statements), '==', 3,
    'number of atomic statements'
);

is (
    join( ";\n", @statements ), $clean_sql,
    'SQL code successfully rebuilt'
);
