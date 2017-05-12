#!/usr/bin/env perl

use strict;
use warnings;

use SQL::SplitStatement;

use Test::More tests => 5;

my $sql_code = <<'SQL';

CREATE TABLE test_tab (
    num NUMBER,
    den NUMBER
);

SELECT * from test_tab were 1 = num
/
den;

DROP TABLE test_tab
SQL

my $splitter;
my @statements;
my @endings;

$splitter = SQL::SplitStatement->new(
    slash_terminates => undef
);

@statements = $splitter->split( $sql_code );

cmp_ok(
    @statements, '==', 3,
    'Statements correctly split'
);

$splitter->keep_extra_spaces(1);
$splitter->keep_empty_statements(1);
$splitter->keep_terminator(1);
$splitter->keep_comments(1);
$splitter->slash_terminates(undef);
@statements = $splitter->split( $sql_code );

is(
    join( '', @statements ), $sql_code,
    'SQL code correctly rebuilt'
);

@endings = qw|
    )
    den
    test_tab
|;

$splitter->keep_extra_spaces(0);
$splitter->keep_empty_statements(0);
$splitter->keep_terminators(0);
$splitter->keep_comments(0);
$splitter->slash_terminates(0);
@statements = $splitter->split( $sql_code );

like( $statements[$_], qr/\Q$endings[$_]\E$/, 'Statement ' . ($_+1) . ' check' )
    for 0..$#endings;
