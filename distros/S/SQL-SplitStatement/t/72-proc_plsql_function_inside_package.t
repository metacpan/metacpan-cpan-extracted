#!/usr/bin/env perl

use strict;
use warnings;

use SQL::SplitStatement;

use Test::More tests => 8;

my $sql_code;
my $splitter;
my @statements;
my @endings;

$sql_code = <<'SQL';
  CREATE PACKAGE emp_actions AS
     /* Declare externally callable subprograms. */
     FUNCTION hire_employee (
        ename  VARCHAR2,
        job    VARCHAR2,
        mgr    REAL,
        sal    REAL,
        comm   REAL,
        deptno REAL) RETURN INT;
  END emp_actions;

CREATE PACKAGE bank_transactions AS
   /* Declare externally visible constant. */
   minimum_balance  CONSTANT REAL := 100.00;
   /* Declare externally callable procedures. */
   PROCEDURE apply_transactions;
   PROCEDURE enter_transaction (
      acct   INT,
      kind   CHAR,
      amount REAL);
END bank_transactions;

CREATE PACKAGE BODY bank_transactions AS
   /* Declare global variable to hold transaction status. */
   new_status  VARCHAR2(70) := 'Unknown';

   /* Use forward declarations because apply_transactions
      calls credit_account and debit_account, which are not
      yet declared when the calls are made. */
   PROCEDURE credit_account (acct INT, credit REAL);
   PROCEDURE debit_account (acct INT, debit REAL);

   /* Fully define procedures specified in package. */
   PROCEDURE apply_transactions IS
   /* Apply pending transactions in transactions table
      to accounts table. Use cursor to fetch rows. */
      CURSOR trans_cursor IS
         SELECT acct_id, kind, amount FROM transactions
            WHERE status = 'Pending'
            ORDER BY time_tag
            FOR UPDATE OF status;  -- to lock rows
   BEGIN
      FOR trans IN trans_cursor LOOP
         IF trans.kind = 'D' THEN
            debit_account(trans.acct_id, trans.amount);
         ELSIF trans.kind = 'C' THEN
            credit_account(trans.acct_id, trans.amount);
         ELSE
            new_status := 'Rejected';
         END IF;
         UPDATE transactions SET status = new_status
            WHERE CURRENT OF trans_cursor;
      END LOOP;
   END apply_transactions;

   PROCEDURE enter_transaction (
   /* Add a transaction to transactions table. */
      acct   INT,
      kind   CHAR,
      amount REAL) IS
   BEGIN
      INSERT INTO transactions
         VALUES (acct, kind, amount, 'Pending', SYSDATE);
   END enter_transaction;

   /* Define local procedures, available only in package. */
   PROCEDURE do_journal_entry (
   /* Record transaction in journal. */
      acct    INT,
      kind    CHAR,
      new_bal REAL) IS
   BEGIN
      INSERT INTO journal
         VALUES (acct, kind, new_bal, sysdate);
      IF kind = 'D' THEN
         new_status := 'Debit applied';
      ELSE
         new_status := 'Credit applied';
      END IF;
   END do_journal_entry;

   PROCEDURE credit_account (acct INT, credit REAL) IS
   /* Credit account unless account number is bad. */
      old_balance REAL;
      new_balance REAL;
   BEGIN
      SELECT balance INTO old_balance FROM accounts
         WHERE acct_id = acct
         FOR UPDATE OF balance;  -- to lock the row
      new_balance := old_balance + credit;
      UPDATE accounts SET balance = new_balance
         WHERE acct_id = acct;
      do_journal_entry(acct, 'C', new_balance);
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         new_status := 'Bad account number';
      WHEN OTHERS THEN
         new_status := SUBSTR(SQLERRM,1,70);
   END credit_account;

   PROCEDURE debit_account (acct INT, debit REAL) IS
   /* Debit account unless account number is bad or
      account has insufficient funds. */
      old_balance REAL;
      new_balance REAL;
      insufficient_funds EXCEPTION;
   BEGIN
      SELECT balance INTO old_balance FROM accounts
         WHERE acct_id = acct
         FOR UPDATE OF balance;  -- to lock the row
      new_balance := old_balance - debit;
      IF new_balance >= minimum_balance THEN
         UPDATE accounts SET balance = new_balance
            WHERE acct_id = acct;
         do_journal_entry(acct, 'D', new_balance);
      ELSE
         RAISE insufficient_funds;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         new_status := 'Bad account number';
      WHEN insufficient_funds THEN
         new_status := 'Insufficient funds';
      WHEN OTHERS THEN
         new_status := SUBSTR(SQLERRM,1,70);
   END debit_account;
END bank_transactions;
/

  CREATE PACKAGE BODY emp_actions AS
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

  BEGIN  -- initialization part starts here
     INSERT INTO emp_audit 
     VALUES (SYSDATE, USER, 'EMP_ACTIONS');
     number_hired := 0;
  END emp_actions;

CREATE TABLE foo (
    foo_field_1 VARCHAR,
    foo_field_2 VARCHAR
)
SQL

$splitter = SQL::SplitStatement->new;

@statements = $splitter->split( $sql_code );

cmp_ok(
    @statements, '==', 5,
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
    @statements, '==', 6,
    'Statements split'
);

is(
    join( '', @statements ), $sql_code,
    'SQL code rebuilt'
);

@endings = qw|
    emp_actions
    bank_transactions
    bank_transactions
    emp_actions
|;

$splitter->keep_extra_spaces(0);
$splitter->keep_empty_statements(0);
$splitter->keep_terminators(0);
$splitter->keep_comments(0);
@statements = $splitter->split( $sql_code );

like( $statements[$_], qr/\Q$endings[$_]\E$/, 'Statement ' . ($_+1) . ' check' )
    for 0..$#endings;

