#!/usr/bin/env perl

use strict;
use warnings;

use SQL::SplitStatement;

use Test::More tests => 2;

my $sql_code = <<'SQL';
CREATE TABLE sqr_root_sum (num NUMBER, sq_root NUMBER(6,2),
                           sqr NUMBER, sum_sqrs NUMBER);
DECLARE
   s  PLS_INTEGER; -- inline sql comment
   s2 PLS_INTEGER;
   /* Multiline
   C-style
   comment */
BEGIN
  s2 := 10*i;
  FOR i in 1..100 LOOP
    s := (i * (i + 1) * (2*i +1)) / 6; -- sum of squares
    INSERT INTO sqr_root_sum VALUES (i, SQRT(i), i*i, s*s2);
  END LOOP;
END;
/
DROP TABLE sqr_root_sum
SQL

my $splitter;
my @statements;

$splitter = SQL::SplitStatement->new;
@statements = $splitter->split($sql_code);

cmp_ok (
    scalar(@statements), '==', 3,
    'Correct number of atomic statements'
);

$splitter->keep_extra_spaces(1);
$splitter->keep_empty_statements(1);
$splitter->keep_terminator(1);
$splitter->keep_comments(1);

@statements = $splitter->split( $sql_code );

is(
    join( '', @statements ), $sql_code,
    'SQL code correctly rebuilt'
);
