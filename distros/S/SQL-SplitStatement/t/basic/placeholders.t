#!/usr/bin/env perl

use strict;
use warnings;

use SQL::SplitStatement;

use Test::More tests => 15;

my $expected_placeholders = [0, 2, 0, 3, 4, 0, 4, 0, 0, 2, 0, 3, 4];

my $sql_code = <<'SQL';
CREATE TABLE state (id, "?name?");
INSERT INTO  state (id, "?name?") VALUES (?, ?);
-- Comment with question mark?
CREATE TABLE city (id, name, state_id);
INSERT INTO  city (id, name, state_id) VALUES (?, ?, ?);

/* Comment with $1, $2 etc. */
PREPARE fooplan (int, text, bool, numeric) AS
    INSERT INTO foo VALUES($1, $2, $3, $4);
EXECUTE fooplan(1, 'Hunter Valley', 't', 200.00);

--Comment with :foo, :bar, :baz, :qux etc.
PREPARE fooplan (int, text, bool, numeric) AS
    INSERT INTO foo VALUES(:foo, :bar, :baz, :qux);
EXECUTE fooplan(1, 'Hunter Valley', 't', 200.00);

CREATE TABLE state (id, "?name?");
INSERT INTO  state (id, "?name?") VALUES (:1, :2);
-- Comment with :1, :2, :3
CREATE TABLE city (id, name, state_id);
INSERT INTO  city (id, name, state_id) VALUES (:1, :2, :3);

CREATE OR REPLACE FUNCTION artificial_test(
    fib_for integer
) RETURNS integer AS $rocco$
BEGIN
/* Comment with $1, $2 etc. */
    PREPARE fooplan (int, text, bool, numeric) AS
        INSERT INTO foo VALUES($1, $2, $3, $4);
    EXECUTE fooplan(1, 'Hunter Valley', 't', 200.00);
    RETURN 1;
END;
$rocco$LANGUAGE plpgsql;

SQL

my ( $statements, $placeholders );
my @endings;

my $splitter = SQL::SplitStatement->new;

( $statements, $placeholders )
    = $splitter->split_with_placeholders( $sql_code );

cmp_ok(
    @$statements, '==', 13,
    'Statements correctly split'
);

@endings = qw|
    "?name?")
    ?)
    state_id)
    ?)
    $4)
    200.00)
    :qux)
    200.00)
    "?name?")
    :2)
    state_id)
    :3)
    plpgsql
|;

like(
    $statements->[$_], qr/\Q$endings[$_]\E$/, 'Statement ' . ($_+1) . ' check'
) for 0..$#endings;

is_deeply(
    $placeholders, $expected_placeholders,
    'Placeholders count'
);
