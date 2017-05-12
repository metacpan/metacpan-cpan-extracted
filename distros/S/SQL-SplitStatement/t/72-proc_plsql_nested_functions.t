#!/usr/bin/env perl

use strict;
use warnings;

use SQL::SplitStatement;

use Test::More tests => 5;

my $sql_code;
my $splitter;
my @statements;
my @endings;

$sql_code = <<'SQL';
CREATE OR REPLACE FUNCTION nested(some_date DATE) RETURN VARCHAR2 IS
 yrstr VARCHAR2(4);
 
-- beginning of nested function in declaration section 
FUNCTION turn_around (
  year_string VARCHAR2)
  RETURN VARCHAR2
IS
 
BEGIN
  yrstr := TO_CHAR(TO_NUMBER(year_string)*2);
  RETURN yrstr;
END;
-- end of nested function in declaration section
 
-- beginning of named function
BEGIN
  yrstr := TO_CHAR(some_date, 'YYYY');
  yrstr := turn_around(yrstr);
  RETURN yrstr; 
END nested;

CREATE PaCkaGe BODY emp_actions AS  -- body
   CURSOR desc_salary RETURN EmpRecTyp IS
      SELECT empno, sal FROM emp ORDER BY sal DESC;
   PROCEDURE hire_employee (
      ename  VARCHAR2,
      job    VARCHAR2,
      mgr    NUMBER,
      sal    NUMBER,
      comm   NUMBER,
      deptno NUMBER) IS
   BEGIN
      INSERT INTO emp VALUES (empno_seq.NEXTVAL, ename, job,
         mgr, SYSDATE, sal, comm, deptno);
   END hire_employee;

   PROCEDURE fire_employee (emp_id NUMBER) IS
   BEGIN
      DELETE FROM emp WHERE empno = emp_id;
   END fire_employee;
   
   FUNCTION nested(some_date DATE) RETURN VARCHAR2 IS
        yrstr VARCHAR2(4);
         
        -- beginning of nested function in declaration section 
        FUNCTION turn_around (
          year_string VARCHAR2)
          RETURN VARCHAR2
        IS
         
        BEGIN
          yrstr := TO_CHAR(TO_NUMBER(year_string)*2);
          RETURN yrstr;
        END;
        -- end of nested function in declaration section
         
        -- beginning of named function
        BEGIN
          yrstr := TO_CHAR(some_date, 'YYYY');
          yrstr := turn_around(yrstr);
          RETURN yrstr; 
   END nested;

END;


CREATE PACKAGE BODY emp_actions2 AS
     number_hired INT;  -- visible only in this package

     /* Fully define subprograms specified in package. */
     FUNCTION hire_employee (
        ename  VARCHAR2,
        job    VARCHAR2,
        mgr    REAL,
        sal    REAL,
        comm   REAL,
        deptno REAL) RETURN INT IS
        new_empno INT;
     BEGIN
        SELECT empno_seq.NEXTVAL INTO new_empno 
        FROM dual;
        INSERT INTO emp VALUES (new_empno, ename, job,
           mgr, SYSDATE, sal, comm, deptno);
        number_hired := number_hired + 1;
        RETURN new_empno;
     END hire_employee;

   FUNCTION nested(some_date DATE) RETURN VARCHAR2 IS
        yrstr VARCHAR2(4);
         
        -- beginning of nested function in declaration section 
        FUNCTION turn_around (
          year_string VARCHAR2)
          RETURN VARCHAR2
        IS
         
        BEGIN
          yrstr := TO_CHAR(TO_NUMBER(year_string)*2);
          RETURN yrstr;
        END;
        -- end of nested function in declaration section
         
        -- beginning of named function
        BEGIN
          yrstr := TO_CHAR(some_date, 'YYYY');
          yrstr := turn_around(yrstr);
          RETURN yrstr; 
   END nested;

BEGIN  -- initialization part starts here
     INSERT INTO emp_audit 
     VALUES (SYSDATE, USER, 'EMP_ACTIONS');
     number_hired := 0;
END emp_actions2;

SQL

$splitter = SQL::SplitStatement->new;

@statements = $splitter->split( $sql_code );

cmp_ok(
    @statements, '==', 3,
    'Statements split'
);

$splitter->keep_extra_spaces(1);
$splitter->keep_empty_statements(1);
$splitter->keep_terminators(1);
$splitter->keep_comments(1);

@statements = $splitter->split( $sql_code );

is(
    join( '', @statements ), $sql_code,
    'SQL code rebuilt'
);

@endings = qw|
    nested
    END
    emp_actions2
|;

$splitter->keep_extra_spaces(0);
$splitter->keep_empty_statements(0);
$splitter->keep_terminators(0);
$splitter->keep_comments(0);
@statements = $splitter->split( $sql_code );

like( $statements[$_], qr/\Q$endings[$_]\E$/, 'Statement ' . ($_+1) . ' check' )
    for 0..$#endings;

