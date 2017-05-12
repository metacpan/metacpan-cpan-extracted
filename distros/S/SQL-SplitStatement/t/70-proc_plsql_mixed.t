#!/usr/bin/env perl

use strict;
use warnings;

use SQL::SplitStatement;

use Test::More tests => 9;

my $sql_code = <<'SQL';
CREATE TABLE sqr_root_sum (num NUMBER, sq_root NUMBER(6,2),
                           sqr NUMBER, sum_sqrs NUMBER);
DECLARE
   s PLS_INTEGER;
BEGIN
  FOR i in 1..100 LOOP
    s := (i * (i + 1) * (2*i +1)) / 6; -- sum of squares
    INSERT INTO sqr_root_sum VALUES (i, SQRT(i), i*i, s );
  END LOOP;
END;



/



CREATE TABLE temp (tempid NUMBER(6), tempsal NUMBER(8,2), tempname VARCHAR2(25));

DECLARE
  total   NUMBER(9) := 0;
  counter NUMBER(6) := 0;
  CURSOR company_cur (id_in IN NUMBER)
    RETURN company%ROWTYPE IS SELECT * FROM company;
BEGIN
  LOOP
    counter := counter + 1;
    total := total + counter * counter;
    -- exit loop when condition is true
    EXIT WHEN total > 25000;  
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('Counter: ' || TO_CHAR(counter) || ' Total: ' || TO_CHAR(total));
END;
    .
/
-- including OR REPLACE is more convenient when updating a subprogram
CREATE OR REPLACE procEDURE award_bonus (emp_id NUMBER, bonus NUMBER) AS
   commission        REAL;
   comm_missing EXCEPTION;
begIN  -- executable part starts here
   SELECT commission_pct / 100 INTO commission FROM employees
    WHERE employee_id = emp_id;
   IF commission IS NULL THEN
      RAISE comm_missing;
   ELSE
      UPDATE employees SET salary = salary + bonus*commission 
      WHERE employee_id = emp_id;
   END IF;
EXCEPTION  -- exception-handling part starts here
   WHEN comm_missing THEN
      DBMS_OUTPUT.PUT_LINE('This employee does not receive a commission.');
      commission := 0;
   WHEN OTHERS THEN
      NULL; -- for other exceptions do nothing
END award_bonus;
/
CALL award_bonus(150, 400);

SQL

my $splitter;
my @statements;
my @endings;

$splitter = SQL::SplitStatement->new;

@statements = $splitter->split( $sql_code );

cmp_ok(
    @statements, '==', 6,
    'Statements correctly split'
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

# Let's try again, with a different constructor

$splitter = SQL::SplitStatement->new(
    keep_extra_spaces     => 1,
    keep_empty_statements => 1,
    keep_terminator       => 1,
    keep_comments         => 1
);

$sql_code .= ';ALTER TABLE temp';

@statements = $splitter->split( $sql_code );

cmp_ok(
    @statements, '==', 8,
    'Statements correctly split'
);

is(
    join( '', @statements ), $sql_code,
    'SQL code correctly rebuilt'
);

@endings = qw|
    NUMBER)
    END
    VARCHAR2(25))
    END
    award_bonus
|;

$splitter->keep_extra_spaces(0);
$splitter->keep_empty_statements(0);
$splitter->keep_terminators(0);
$splitter->keep_comments(0);
@statements = $splitter->split( $sql_code );

like( $statements[$_], qr/\Q$endings[$_]\E$/, 'Statement ' . ($_+1) . ' check' )
    for 0..$#endings;
