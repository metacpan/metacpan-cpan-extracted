#!/usr/bin/env perl

use strict;
use warnings;

use SQL::SplitStatement;

use Test::More tests => 57;

my $filename;
my $sql_code;

my $splitter;
my @statements;
my @endings;

$splitter = SQL::SplitStatement->new;

$filename = 't/data/sakila-schema.sql';
open my $fh, '<', $filename
    or die "Can't open file $filename: ", $!;
$sql_code = do { local $/; <$fh> };

@statements = $splitter->split( $sql_code );

cmp_ok(
    @statements, '==', 55,
    'Statements correctly split'
);

@endings = (
    q[UNIQUE_CHECKS=0]         ,
    q[FOREIGN_KEY_CHECKS=0]    ,
    q[SQL_MODE='TRADITIONAL']  ,
    ( 'sakila'       ) x  3    ,
    ( 'CHARSET=utf8' ) x 10    ,
    q[;;]                      ,
    ( 'END'          ) x  3    ,
    q[;]                       ,
    ( 'CHARSET=utf8' ) x  6    ,
    q[country.country_id]      ,
    q[film.film_id]            ,
    q[film.film_id]            ,
    q[country.country_id]      ,
    q[c.city]                  ,
    q[DESC]                    ,
    q[a.last_name]             ,
    q[//]                      ,
    q[END]                     ,
    ( ';', '$$', 'END' ) x  5  ,
    q[;]                       ,
    q[SQL_MODE=@OLD_SQL_MODE]  ,
    q[=@OLD_FOREIGN_KEY_CHECKS],
    q[=@OLD_UNIQUE_CHECKS]
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
