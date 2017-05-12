#!/usr/bin/env perl

use strict;
use warnings;

use SQL::SplitStatement;

use Test::More tests => 7;

# Bug report (Alexander Sennhauser <as@open.ch>):

my $sql_code = <<'SQL';
BEGIN
  dbms_output.put_line('Hi Ma, I can write PL/SQL');
END;

BEGIN
  dbms_output.put_line('Hi Ma, I can write PL/SQL');
END;
/

BEGIN
  dbms_output.put_line('Hi Ma, I can write PL/SQL');
END;
.
/

  CREATE PACKAGE BODY emp_actions AS
     number_hired INT;  -- visible only in this package

    CURSOR trans_cursor IS
         SELECT acct_id, kind, amount FROM transactions
            WHERE status = 'Pending'
            ORDER BY time_tag
            FOR UPDATE OF status;  -- to lock rows

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

  BEGIN  -- initialization part starts here
     INSERT INTO emp_audit 
     VALUES (SYSDATE, USER, 'EMP_ACTIONS');
     number_hired := 0;
  END;

CREATE OR REPLACE FUNCTION to_date_check_null(dateString IN VARCHAR2, dateFormat IN VARCHAR2) 
RETURN DATE IS
BEGIN 
  IF dateString IS NULL THEN
     return NULL;
  ELSE
     return to_date(dateString, dateFormat);
  END IF;
END;
    .
    /

CREATE OR REPLACE FUNCTION to_date_check_null(dateString IN VARCHAR2, dateFormat IN VARCHAR2) 
RETURN DATE IS
BEGIN 
  IF dateString IS NULL THEN
     return NULL;
  ELSE
     return to_date(dateString, dateFormat);
  END IF;
END to_date_check_null;
/

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

@endings = qw|
    END
    END
    END
    END
    END
    to_date_check_null
|;

like( $statements[$_], qr/\Q$endings[$_]\E$/, 'Statement ' . ($_+1) . ' check' )
    for 0..$#endings;

