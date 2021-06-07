#!/usr/bin/env perl

use strict;
use warnings;

use SQL::SplitStatement;

use Test::More tests => 4;

my $sql = <<'SQL';
CREATE TABLE begin (
    declare VARCHAR,
    function VARCHAR
);

CREATE TABLE procedure (
    begin VARCHAR,
    declare VARCHAR
);

DECLARE
   s PLS_INTEGER;
BEGIN
  FOR i in 1..100 LOOP
    s := (i * (i + 1) * (2*i +1)) / 6; -- sum of squares
    INSERT INTO sqr_root_sum VALUES (i, SQRT(i), i*i, s );
  END LOOP;
END;
/

CREATE TABLE declare (
    declare VARCHAR,
    function VARCHAR
);

CREATE TABLE function (
    declare VARCHAR,
    begin VARCHAR
);
SQL

chomp ( my $clean_sql = <<'SQL' );
CREATE TABLE begin (
    declare VARCHAR,
    function VARCHAR
)CREATE TABLE procedure (
    begin VARCHAR,
    declare VARCHAR
)DECLARE
   s PLS_INTEGER;
BEGIN
  FOR i in 1..100 LOOP
    s := (i * (i + 1) * (2*i +1)) / 6; -- sum of squares
    INSERT INTO sqr_root_sum VALUES (i, SQRT(i), i*i, s );
  END LOOP;
ENDCREATE TABLE declare (
    declare VARCHAR,
    function VARCHAR
)CREATE TABLE function (
    declare VARCHAR,
    begin VARCHAR
)
SQL

my $sql_splitter = SQL::SplitStatement->new({
    keep_terminators      => 1,
    keep_extra_spaces     => 1,
    keep_empty_statements => 1,
    keep_comments         => 1
});

my @statements;

@statements = $sql_splitter->split($sql);

cmp_ok (
    scalar(@statements), '==', 6,
    'number of atomic statements w/ semicolon'
);

is (
    join( '', @statements ), $sql,
    'SQL code rebuilt w/ semicolon'
);

$sql_splitter->keep_terminators(0);
$sql_splitter->keep_extra_spaces(0);
@statements = $sql_splitter->split($sql);

cmp_ok (
    scalar(@statements), '==', 6,
    'number of atomic statements w/o semicolon'
);

is (
    join( '', @statements ), $clean_sql,
    'SQL code rebuilt w/o semicolon'
);
