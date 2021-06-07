#!/usr/bin/env perl

use strict;
use warnings;

use SQL::SplitStatement;

use Test::More tests => 5;

my $sql = <<'SQL';
CREATE TABLE foo (
    foo_field_1 VARCHAR,
    foo_field_2 VARCHAR
);

CREATE TABLE bar (
    bar_field_1 VARCHAR,
    bar_field_2 VARCHAR
);
SQL

chomp ( my $clean_sql = <<'SQL' );
CREATE TABLE foo (
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
    scalar(@statements), '==', 3,
    'number of atomic statements w/ semicolon'
);

is (
    join( '', @statements ), $sql,
    'SQL code rebuilt w/ semicolon'
);

$sql_splitter->keep_terminators(0);
@statements = $sql_splitter->split($sql);

is (
    join( ';', @statements ), $sql,
    'SQL code rebuilt w/o semicolon'
);

@statements = $sql_splitter->new->split($sql);

cmp_ok (
    scalar(@statements), '==', 2,
    'number of atomic statements w/o semicolon'
);

is (
    join( '', @statements ), $clean_sql,
    'SQL code rebuilt w/o semicolon'
);
