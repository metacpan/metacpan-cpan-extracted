#!/usr/bin/env perl

use strict;
use warnings;

use SQL::SplitStatement;

use Test::More tests => 9;

my $sql_code = <<'SQL';
CREATE OR REPLACE PACKAGE UTIL IS
   PROCEDURE VERIFY_USER(P_USER_NAME IN VARCHAR2);
END UTIL;
/

CREATE OR REPLACE PACKAGE BODY OS_UTIL IS
   PROCEDURE VERIFY_USER(P_USER_NAME IN VARCHAR2) IS
      a_user varchar2(30);
   BEGIN
      SELECT user INTO a_user FROM dual;
      IF upper(a_user) != upper(p_user_name) THEN
         RAISE_APPLICATION_ERROR(
            -20004,
            'This code can be run as user <' || p_user_name || '> only!'
         );
      END IF;
   END;
END OS_UTIL;
/

CREATE TRIGGER check_salary
              BEFORE INSERT OR UPDATE OF sal, job ON emp
              FOR EACH ROW
              WHEN (new.job != 'PRESIDENT')
          DECLARE
              minsal   NUMBER;
              maxsal   NUMBER;
          BEGIN
              /* Get salary range for a given job from table sals. */
              SELECT losal, hisal INTO minsal, maxsal FROM sals
                  WHERE job = :new.job;
              /* If salary is out of range, increase is negative, *
               * or increase exceeds 10%, raise an exception.     */
              IF (:new.sal < minsal OR :new.sal > maxsal) THEN
                  raise_application_error(-20225, 'Salary out of range');
              ELSIF (:new.sal < :old.sal) THEN
                  raise_application_error(-20320, 'Negative increase');
              ELSIF (:new.sal > 1.1 * :old.sal) THEN
                  raise_application_error(-20325, 'Increase exceeds 10%');
              END IF;
          END;

begin
    dbms_java.grant_permission
    ('RT_TEST',
     'java.io.FilePermission',
     '/usr/bin/ps',
     'execute');

    dbms_java.grant_permission
    ('RT_TEST',
     'java.lang.RuntimePermission',
     '*',
     'writeFileDescriptor' );
end;
/

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
END; -- nested

begin
    dbms_java.grant_permission
    ('RT_TEST',
     'java.io.FilePermission',
     '/usr/bin/ps',
     'execute');

    dbms_java.grant_permission
    ('RT_TEST',
     'java.lang.RuntimePermission',
     '*',
     'writeFileDescriptor' );
end;

DECLARE
      PROCEDURE P1 IS
      BEGIN
         dbms_output.put_line('From procedure p1');
         p2;
      END P1;
      PROCEDURE P2 IS
      BEGIN
         dbms_output.put_line('From procedure p2');
         p3;
      END P2;
      PROCEDURE P3 IS
      BEGIN
         dbms_output.put_line('From procedure p3');
      END P3;
BEGIN
     p1;
END;


CREATE OR REPLACE PACKAGE UTIL IS
   PROCEDURE VERIFY_USER(P_USER_NAME IN VARCHAR2);
END UTIL;
/
SQL

my $splitter;
my @statements;
my @endings;

$splitter = SQL::SplitStatement->new;
@statements = $splitter->split( $sql_code );

cmp_ok(
    @statements, '==', 8,
    'Statements correctly split'
);
@endings = qw|
    UTIL
    OS_UTIL
    END
    end
    END
    end
    END
    UTIL
|;

like( $statements[$_], qr/\Q$endings[$_]\E$/, 'Statement ' . ($_+1) . ' check' )
    for 0..$#endings;

