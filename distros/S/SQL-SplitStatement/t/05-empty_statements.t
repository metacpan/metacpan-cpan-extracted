#!/usr/bin/env perl

use strict;
use warnings;

use SQL::SplitStatement;

use Test::More tests => 5;

my $sql = <<'SQL';
DELIMITER $strange$
CREATE TABLE foo (
    foo_field_1 VARCHAR,
    foo_field_2 VARCHAR
)$strange$

CREATE TABLE bar (
    bar_field_1 VARCHAR,
    bar_field_2 VARCHAR
)$strange$

$strange$

SQL

chomp ( my $clean_sql = <<'SQL' );
DELIMITER $strange$CREATE TABLE foo (
    foo_field_1 VARCHAR,
    foo_field_2 VARCHAR
)CREATE TABLE bar (
    bar_field_1 VARCHAR,
    bar_field_2 VARCHAR
)
SQL

my $sql_splitter = SQL::SplitStatement->new({
    keep_terminator       => 1,
    keep_extra_spaces     => 1,
    keep_empty_statements => 1
});

my @statements;

@statements = $sql_splitter->split($sql);

cmp_ok (
    scalar(@statements), '==', 5,
    'number of atomic statements w/ terminator'
);

is (
    join( '', @statements ), $sql,
    'SQL code rebuilt w/ terminator'
);

$sql_splitter->keep_terminators(0);
@statements = $sql_splitter->split($sql);

is (
    $statements[0] . join( '$strange$', @statements[1..$#statements] ),
    $sql,
    'SQL code rebuilt w/o terminator'
);

@statements = $sql_splitter->new->split($sql);

cmp_ok (
    scalar(@statements), '==', 3,
    'number of atomic statements w/o terminator'
);

is (
    join( '', @statements ), $clean_sql,
    'SQL code rebuilt w/o terminator'
);
