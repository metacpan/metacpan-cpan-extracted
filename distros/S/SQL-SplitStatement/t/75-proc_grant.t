#!/usr/bin/env perl

use strict;
use warnings;

use SQL::SplitStatement;

use Test::More tests => 2;

# Bug report by Alexander Sennhauser <as@open.ch>

my $sql_code = <<'SQL';
GRANT CREATE PROCEDURE TO test;
CREATE OR REPLACE PACKAGE UTIL IS
   PROCEDURE VERIFY_USER(P_USER_NAME IN VARCHAR2);
END UTIL;
/
CREATE TABLE foo (
    foo_field_1 VARCHAR,
    foo_field_2 VARCHAR
);
revoke CREATE PROCEDURE TO test;
CREATE TABLE bar (
    bar_field_1 VARCHAR,
    bar_field_2 VARCHAR
)
SQL

my $splitter;
my @statements;

$splitter = SQL::SplitStatement->new(
    keep_terminator       => 1,
    keep_extra_spaces     => 1,
    keep_comments         => 1,
    keep_empty_statements => 1
);

@statements = $splitter->split( $sql_code );

cmp_ok(
    @statements, '==', 5,
    'Statements correctly split'
);

is (
    join( '', @statements ), $sql_code,
    'SQL code verbatim rebuilt'
);
