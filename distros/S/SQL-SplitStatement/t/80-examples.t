#!/usr/bin/env perl

use strict;
use warnings;

use SQL::SplitStatement;

use Test::More tests => 3;

my $sql_splitter = SQL::SplitStatement->new({
    keep_terminator       => 1,
    keep_empty_statements => 1
});

my @statements = $sql_splitter->split( 'SELECT 1;' );

cmp_ok (
    scalar(@statements), '==', 2,
    'number of atomic statements w/ semicolon'
);

is (
    join( '', @statements ), 'SELECT 1;',
    'SQL code successfully rebuilt w/ semicolon'
);

my $sql = <<'SQL';
CREATE TABLE foo (
    foo_field_1 VARCHAR,
    foo_field_2 VARCHAR
);
-- Comment with semicolon;
CREATE TABLE bar (
    bar_field_1 VARCHAR,
    bar_field_2 VARCHAR
);
SQL

my $verbatim_splitter = SQL::SplitStatement->new({
    keep_terminator       => 1,
    keep_extra_spaces     => 1,
    keep_comments         => 1,
    keep_empty_statements => 1
});

my @verbatim_statements = $verbatim_splitter->split($sql);

is (
    join( '', @verbatim_statements ), $sql,
    'SQL code verbatim rebuilt'
);
#$sql eq join '', @verbatim_statements;
