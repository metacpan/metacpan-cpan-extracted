#!/usr/bin/env perl

use strict;
use warnings;

use SQL::SplitStatement;

use Test::More tests => 22;

my $sql_code = <<'SQL';
BEGIN;

CREATE LANGUAGE 'plpgsql' HANDLER plpgsql_call_handler
    LANCOMPILER 'PL/pgSQL';

SAVEPOINT my_savepoint;

PREPARE some_insert(integer, integer) AS
INSERT  INTO fib_cache (num, fib)
VALUES  (?, ?);

ROLLBACK TO my_savepoint;

EXECUTE some_insert(fib_for, ret);

CREATE OR REPLACE FUNCTION fib_fast(
    fib_for integer
) RETURNS integer AS $$
DECLARE
    ret integer := 0;
    nxt integer := 1;
    tmp integer;
BEGIN
    FOR num IN 1..fib_for LOOP
        tmp := ret;
        ret := nxt;
        nxt := tmp + nxt;
    END LOOP;
    RETURN ret;
END;
$$ LANGUAGE plpgsql;

COMMIT;

START TRANSACTION;
DROP FUNCTION fib_fast(integer);
COMMIT;

BEGIN ISOLATION LEVEL SERIALIZABLE;

CREATE FUNCTION somefunc() RETURNS integer AS $$
label
DECLARE
    quantity integer := 30;
BEGIN
    RAISE NOTICE 'Quantity here is %', quantity;  -- Prints 30
    quantity := 50;
    --
    -- Create a subblock
    --
    DECLARE
        quantity integer := 80;
    BEGIN
        RAISE NOTICE 'Quantity here is %', quantity;  -- Prints 80
        RAISE NOTICE 'Outer quantity here is %', outerblock.quantity;  -- Prints 50
    END;

    RAISE NOTICE 'Quantity here is %', quantity;  -- Prints 50

    RETURN quantity;
END label;
$$ LANGUAGE plpgsql;

COMMIT;

DROP FUNCTION somefunc(integer);

CREATE TABLE t1 (a integer PRIMARY KEY);

CREATE FUNCTION test_exception() RETURNS boolean LANGUAGE plpgsql AS
$$BEGIN
   INSERT INTO t1 (a) VALUES (1);
   INSERT INTO t1 (a) VALUES (2);
   INSERT INTO t1 (a) VALUES (1);
   INSERT INTO t1 (a) VALUES (3);
   RETURN TRUE;
EXCEPTION
   WHEN integrity_constraint_violation THEN
      RAISE NOTICE 'Rollback to savepoint';
      RETURN FALSE;
END;$$;

BEGIN;

SELECT test_exception();

SQL

my $splitter;
my @statements;
my @endings;
my ($statement, $placeholders);

$splitter = SQL::SplitStatement->new;

@statements = $splitter->split( $sql_code );

cmp_ok(
    @statements, '==', 19,
    'Statements correctly split'
);

$splitter = SQL::SplitStatement->new;
$splitter->keep_extra_spaces(1);
$splitter->keep_empty_statements(1);
$splitter->keep_terminator(1);
$splitter->keep_comments(1);
@statements = $splitter->split( $sql_code );

is(
    join( '', @statements ), $sql_code,
    'SQL code correctly rebuilt'
);

($statement, $placeholders)
    = $splitter->split_with_placeholders( $sql_code );

cmp_ok(
    $placeholders->[3], '==', 2,
    'Statements correctly split'
);

@endings = qw|
    BEGIN
    'PL/pgSQL'
    my_savepoint
    ?)
    my_savepoint
    ret)
    plpgsql
    COMMIT
    TRANSACTION
    fib_fast(integer)
    COMMIT
    SERIALIZABLE
    plpgsql
    COMMIT
    somefunc(integer)
    KEY)
    END;$$
    BEGIN
    test_exception()
|;

$splitter->keep_extra_spaces(0);
$splitter->keep_empty_statements(0);
$splitter->keep_terminators(0);
$splitter->keep_comments(0);
@statements = $splitter->split( $sql_code );

like( $statements[$_], qr/\Q$endings[$_]\E$/, 'Statement ' . ($_+1) . ' check' )
    for 0..$#endings;

