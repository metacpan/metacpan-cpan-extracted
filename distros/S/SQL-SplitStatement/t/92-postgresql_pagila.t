#!/usr/bin/env perl

use strict;
use warnings;

use SQL::SplitStatement;

use Test::More tests => 38;

my $filename;
my $sql_code;

my $splitter;
my @statements;
my @endings;

$splitter = SQL::SplitStatement->new;

$filename = 't/data/pagila-schema.sql';
open my $fh, '<', $filename
    or die "Can't open file $filename: ", $!;
$sql_code = do { local $/; <$fh> };

@statements = $splitter->split( $sql_code );

cmp_ok(
    @statements, '==', 225,
    'Statements correctly split'
);

@endings = (
    qw|
        'UTF8'
        off
        false
        warning
        off
        schema'
        plpgsql
        postgres
        pg_catalog
        1
        postgres
        ''
        false
    |,
    ( ')', 'postgres' ) x 3,
    qw|IMMUTABLE postgres ) postgres 1 postgres ) postgres 1 postgres|,
    ( ')', 'postgres' ) x 3,
    qw|a.last_name|
);

like( $statements[$_], qr/\Q$endings[$_]\E$/, 'Statement ' . ($_+1) . ' check' )
    for 0..$#endings;

$splitter->keep_extra_spaces(1);
$splitter->keep_empty_statements(1);
$splitter->keep_terminator(1);
$splitter->keep_comments(1);

@statements = $splitter->split( $sql_code );

is(
    join( '', @statements ), $sql_code,
    'SQL code correctly rebuilt'
);
