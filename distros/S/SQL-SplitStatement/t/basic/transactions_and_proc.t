#!/usr/bin/env perl

use strict;
use warnings;

use SQL::SplitStatement;

use Test::More tests => 2;

my $sql_code = <<'SQL';
BEGIN;
UPDATE accounts SET balance = balance - 100.00
    WHERE name = 'Alice';
SAVEPOINT my_savepoint;

DECLARE
   s PLS_INTEGER;
BEGIN
  FOR i in 1..100 LOOP
    s := (i * (i + 1) * (2*i +1)) / 6; -- sum of squares
    INSERT INTO sqr_root_sum VALUES (i, SQRT(i), i*i, s );
  END LOOP;
END;
/

UPDATE accounts SET balance = balance + 100.00
    WHERE name = 'Bob';
-- oops ... forget that and use Wally's account
ROLLBACK TO my_savepoint;

-- including OR REPLACE is more convenient when updating a subprogram
CREATE OR REPLACE PROCEDURE award_bonus (emp_id NUMBER, bonus NUMBER) AS
   commission        REAL;
   comm_missing EXCEPTION;
BEGIN  -- executable part starts here
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


UPDATE accounts SET balance = balance + 100.00
    WHERE name = 'Wally';
COMMIT;
SQL

my $splitter;
my @statements;

$splitter = SQL::SplitStatement->new;
@statements = $splitter->split( $sql_code );

cmp_ok(
    @statements, '==', 10,
    'Statements correctly split'
);

$splitter = SQL::SplitStatement->new({
    keep_extra_spaces     => 1,
    keep_empty_statements => 1,
    keep_terminator       => 1,
    keep_comments         => 1
});
@statements = $splitter->split( $sql_code );

is(
    join( '', @statements ), $sql_code,
    'SQL code correctly rebuilt'
);
