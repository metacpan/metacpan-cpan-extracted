#!/usr/bin/env perl

use strict;
use warnings;

use SQL::SplitStatement;

use Test::More tests => 4;

my $sql_code;
my $splitter;
my @statements;

$sql_code = <<'SQL';
BEGIN;
UPDATE accounts SET balance = balance - 100.00
    WHERE name = 'Alice';
SAVEPOINT my_savepoint;
UPDATE accounts SET balance = balance + 100.00
    WHERE name = 'Bob';
-- oops ... forget that and use Wally's account
ROLLBACK TO my_savepoint;
UPDATE accounts SET balance = balance + 100.00
    WHERE name = 'Wally';
COMMIT;
SQL

$splitter = SQL::SplitStatement->new;
@statements = $splitter->split( $sql_code );

cmp_ok(
    @statements, '==', 7,
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

$sql_code = <<'SQL';
CREATE TABLE table1;
-- Now wait...
START TRANSACTION;
SELECT @A:=SUM(salary) FROM table1 WHERE type=1;
UPDATE table2 SET summary=@A WHERE type=1;
COMMIT;
DROP table1;

BEGIN ISOLATION LEVEL SERIALIZABLE;
UPDATE accounts SET balance = balance - 100.00
    WHERE name = 'Alice';
SAVEPOINT my_savepoint;
UPDATE accounts SET balance = balance + 100.00
    WHERE name = 'Bob';
-- oops ... forget that and use Wally's account
ROLLBACK TO my_savepoint;
UPDATE accounts SET balance = balance + 100.00
    WHERE name = 'Wally';
COMMIT;

DROP TABLE accounts;
SQL

$splitter = SQL::SplitStatement->new;
@statements = $splitter->split( $sql_code );

cmp_ok(
    @statements, '==', 14,
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
