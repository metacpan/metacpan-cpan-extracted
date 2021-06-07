#!/usr/bin/env perl

use strict;
use warnings;

use SQL::SplitStatement;

use Test::More tests => 7;

my $original_statements = [
    'CREATE TABLE state (id, "?name?")'                      ,
    'INSERT INTO  state (id, "?name?") VALUES (?, ?)'        ,
    'CREATE TABLE city (id, name, state_id)'                 ,
    'INSERT INTO  city (id, name, state_id) VALUES (?, ?, ?)'
];

my $expected_placeholders;

my $sql_code = <<'SQL';
CREATE TABLE state (id, "?name?");
INSERT INTO  state (id, "?name?") VALUES (?, ?);
;    ; -- Two Empty statements
CREATE TABLE city (id, name, state_id);
INSERT INTO  city (id, name, state_id) VALUES (?, ?, ?)
; -- Final empty statement
SQL

my ( $statements, $placeholders );
my $splitter;

$splitter = SQL::SplitStatement->new;

( $statements, $placeholders )
    = $splitter->split_with_placeholders( $sql_code );

cmp_ok(
    @$statements, '==', @$placeholders,
    'Same number of statements and placeholders numbers'
);

cmp_ok(
    @$statements, '==', 4,
    'Count number of statements'
);

is_deeply(
    $statements, $original_statements,
    'Statements correctly split'
);

$expected_placeholders = [0, 2, 0, 3];

is_deeply(
    $placeholders, $expected_placeholders,
    'Placeholders count'
);

$splitter = SQL::SplitStatement->new(
    keep_empty_statements => 1
);

( $statements, $placeholders )
    = $splitter->split_with_placeholders( $sql_code );

cmp_ok(
    @$statements, '==', @$placeholders,
    'Same number of statements and placeholders numbers'
);

cmp_ok(
    @$statements, '==', 7,
    'Count number of statements'
);

$expected_placeholders = [0, 2, 0, 0, 0, 3, 0];

is_deeply(
    $placeholders, $expected_placeholders,
    'Placeholders correctly calculated'
);
