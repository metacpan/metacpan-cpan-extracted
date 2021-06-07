#!/usr/bin/env perl

use strict;
use warnings;

use SQL::SplitStatement;

use Test::More tests => 16;

my $sql_code;
my $splitter;
my @statements;

$sql_code = <<'SQL';
CREATE TABLE sqr_root_sum (num NUMBER, sq_root NUMBER(6,2),
                           sqr NUMBER, sum_sqrs NUMBER);

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
END emp_actions;

DECLARE
   s PLS_INTEGER;
BEGIN
  FOR i in 1..100 LOOP
    s := (i * (i + 1) * (2*i +1)) / 6; -- sum of squares
    INSERT INTO sqr_root_sum VALUES (i, SQRT(i), i*i, s );
  END LOOP;
END;
/

DROP TABLE sqr_root_sum

SQL

$splitter = SQL::SplitStatement->new;

@statements = $splitter->split( $sql_code );

cmp_ok(
    @statements, '==', 4,
    'Statements split'
);

$splitter->keep_extra_spaces(1);
$splitter->keep_empty_statements(1);
$splitter->keep_terminator(1);
$splitter->keep_comments(1);

@statements = $splitter->split( $sql_code );

is(
    join( '', @statements ), $sql_code,
    'SQL code rebuilt'
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
    @statements, '==', 5,
    'Statements split'
);

is(
    join( '', @statements ), $sql_code,
    'SQL code rebuilt'
);

$sql_code = <<'SQL';
CREATE TABLE sqr_root_sum (num NUMBER, sq_root NUMBER(6,2),
                           sqr NUMBER, sum_sqrs NUMBER);

CREATE OR REPLACE PACKAGE BODY emp_actions_w_init AS  -- body
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

BEGIN  -- initialization part starts here
   INSERT INTO emp_audit VALUES (SYSDATE, USER, 'EMP_ACTIONS');
   number_hired := 0;
END emp_actions_w_init;
/

DECLARE
   s PLS_INTEGER;
BEGIN
  FOR i in 1..100 LOOP
    s := (i * (i + 1) * (2*i +1)) / 6; -- sum of squares
    INSERT INTO sqr_root_sum VALUES (i, SQRT(i), i*i, s );
  END LOOP;
END;
/

DROP TABLE sqr_root_sum

SQL

$splitter = SQL::SplitStatement->new;

@statements = $splitter->split( $sql_code );

cmp_ok(
    @statements, '==', 4,
    'Statements w/ initialization split'
);

$splitter->keep_extra_spaces(1);
$splitter->keep_empty_statements(1);
$splitter->keep_terminator(1);
$splitter->keep_comments(1);

@statements = $splitter->split( $sql_code );

is(
    join( '', @statements ), $sql_code,
    'SQL code w/ initialization rebuilt'
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
    @statements, '==', 5,
    'Statements w/ initialization split'
);

is(
    join( '', @statements ), $sql_code,
    'SQL code w/ initialization rebuilt'
);

$sql_code = <<'SQL';
CREATE TABLE sqr_root_sum (num NUMBER, sq_root NUMBER(6,2),
                           sqr NUMBER, sum_sqrs NUMBER);

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
END;
/

DECLARE
   s PLS_INTEGER;
BEGIN
  FOR i in 1..100 LOOP
    s := (i * (i + 1) * (2*i +1)) / 6; -- sum of squares
    INSERT INTO sqr_root_sum VALUES (i, SQRT(i), i*i, s );
  END LOOP;
END;
/

DROP TABLE sqr_root_sum

SQL

$splitter = SQL::SplitStatement->new;

@statements = $splitter->split( $sql_code );

cmp_ok(
    @statements, '==', 4,
    'Statements w/o package name split'
);

$splitter->keep_extra_spaces(1);
$splitter->keep_empty_statements(1);
$splitter->keep_terminator(1);
$splitter->keep_comments(1);

@statements = $splitter->split( $sql_code );

is(
    join( '', @statements ), $sql_code,
    'SQL code w/o package name rebuilt'
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
    @statements, '==', 5,
    'Statements w/o package name split'
);

is(
    join( '', @statements ), $sql_code,
    'SQL code w/o package name rebuilt'
);

$sql_code = <<'SQL';
CREATE TABLE sqr_root_sum (num NUMBER, sq_root NUMBER(6,2),
                           sqr NUMBER, sum_sqrs NUMBER);

CREATE OR REPLACE PACKAGE BODY emp_actions_w_init AS  -- body
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

BEGIN  -- initialization part starts here
   INSERT INTO emp_audit VALUES (SYSDATE, USER, 'EMP_ACTIONS');
   number_hired := 0;
END;
/

DECLARE
   s PLS_INTEGER;
BEGIN
  FOR i in 1..100 LOOP
    s := (i * (i + 1) * (2*i +1)) / 6; -- sum of squares
    INSERT INTO sqr_root_sum VALUES (i, SQRT(i), i*i, s );
  END LOOP;
END;
/

DROP TABLE sqr_root_sum

SQL

$splitter = SQL::SplitStatement->new;

@statements = $splitter->split( $sql_code );

cmp_ok(
    @statements, '==', 4,
    'Statements  w/o package name w/ initialization split'
);

$splitter->keep_extra_spaces(1);
$splitter->keep_empty_statements(1);
$splitter->keep_terminator(1);
$splitter->keep_comments(1);

@statements = $splitter->split( $sql_code );

is(
    join( '', @statements ), $sql_code,
    'SQL code w/o package name w/ initialization rebuilt'
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
    @statements, '==', 5,
    'Statements w/o package name w/ initialization split'
);

is(
    join( '', @statements ), $sql_code,
    'SQL code w/o package name w/ initialization rebuilt'
);
