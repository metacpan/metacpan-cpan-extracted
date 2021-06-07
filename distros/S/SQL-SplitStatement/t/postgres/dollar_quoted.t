#!/usr/bin/env perl

use strict;
use warnings;

use SQL::SplitStatement;

use Test::More tests => 12;
use Test::Differences;

my $sql_code = <<'SQL';
CREATE LANGUAGE 'plpgsql' HANDLER plpgsql_call_handler
    LANCOMPILER 'PL/pgSQL';

PREPARE some_insert(integer, integer) AS
INSERT  INTO fib_cache (num, fib)
VALUES  ($1, $2);

EXECUTE some_insert(fib_for, ret);

DECLARE liahona CURSOR FOR SELECT * FROM films;

CREATE OR REPLACE FUNCTION fib_fast(
    fib_for integer
) RETURNS integer AS $rocco$
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
    PREPARE fooplan (int, text, bool, numeric) AS
        INSERT INTO foo VALUES($1, $2, $3, $4);
    EXECUTE fooplan(1, 'Hunter Valley', 't', 200.00);
    RETURN ret;
END;
$rocco$LANGUAGE plpgsql;

DROP FUNCTION fib_fast(integer);

CREATE FUNCTION somefunc() RETURNS integer AS $$
label
DECLARE
    liahona CURSOR FOR SELECT * FROM films;
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

    PREPARE fooplan (int, text, bool, numeric) AS
        INSERT INTO foo VALUES($1, $2, $3, $4);
    EXECUTE fooplan(1, 'Hunter Valley', 't', 200.00);
/
-- Illegal, just to check that a / inside dollar-quotes can't split the statement
    RETURN quantity;
END label;
$$ LANGUAGE plpgsql;

DECLARE liahona CURSOR FOR SELECT * FROM films;

DROP FUNCTION somefunc(integer);

CREATE FUNCTION funcname (argument-types) RETURNS return-type AS $perl$
    # PL/Perl function body
$perl$ LANGUAGE plperl;

SQL

my $splitter;
my @statements;
my @endings;

$splitter = SQL::SplitStatement->new;

@statements = $splitter->split( $sql_code );

cmp_ok(
    @statements, '==', 10,
    'Statements correctly split'
);


$splitter = SQL::SplitStatement->new;

$splitter->keep_extra_spaces(1);
$splitter->keep_empty_statements(1);
$splitter->keep_terminator(1);
$splitter->keep_comments(1);
@statements = $splitter->split( $sql_code );

eq_or_diff(
    join( '', @statements ), $sql_code,
    'SQL code correctly rebuilt'
);

$splitter->keep_extra_spaces(0);
$splitter->keep_empty_statements(0);
$splitter->keep_terminators(0);
$splitter->keep_comments(0);
@statements = $splitter->split( $sql_code );

@endings = qw|
    'PL/pgSQL'
    $2)
    ret)
    films
    plpgsql
    fib_fast(integer)
    plpgsql
    films
    somefunc(integer)
    plperl
|;

like( $statements[$_], qr/\Q$endings[$_]\E$/, 'Statement ' . ($_+1) . ' check' )
    for 0..$#endings;

