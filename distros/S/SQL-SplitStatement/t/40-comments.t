#!/usr/bin/env perl

use strict;
use warnings;

use SQL::SplitStatement;

use Test::More tests => 6;

my $sql = <<'SQL';
/* Multiline
C-Style
Comment! */
CREATE TABLE t1 (a, b); --inline comment; with semicolons;
-- standalone comment
CREATE TABLE t2 (a, b);
-- standalone comment w/ trailing spaces              
CREATE TABLE t3 (a, b) /* inlined C-style comments... */
/* ... before terminator */     ;
CREATE TABLE last;
-- Trailing standalone comment
SQL

my $splitter;
my @statements;

$splitter = SQL::SplitStatement->new;
@statements = $splitter->split($sql);

cmp_ok (
    scalar(@statements), '==', 4,
    'number of atomic statements w/o comments'
);

isnt (
    join( '', @statements ), $sql,
    q[SQL code don't rebuild w/o comments]
);

$splitter = SQL::SplitStatement->new({
    keep_comments => 1
});
@statements = $splitter->split($sql);

# We have an extra statement made solely by comments.
# It's not recognized as an empty statement, that's right.
cmp_ok (
    scalar(@statements), '==', 5,
    'number of atomic statements w/ comments'
);

isnt (
    join( '', @statements ), $sql,
    q[SQL code don't rebuild only w/ comments]
);

$splitter = SQL::SplitStatement->new({
    keep_terminator   => 1,
    keep_extra_spaces => 1,
    keep_comments     => 1
});
@statements = $splitter->split($sql);

cmp_ok (
    scalar(@statements), '==', 5,
    'number of atomic statements w/ comments'
);

is (
    join( '', @statements ), $sql,
    q[SQL code rebuilt w/ comments, semicolon and spaces]
);
