#!/usr/bin/env perl

use strict;
use warnings;

use SQL::SplitStatement;

use Test::More tests => 2;

# This is artificial, not valid SQL.
my $sql = <<'SQL';
statement1;
DECLARE
BEGIN
    statement2;
END;
CREATE
-- another comment
BEGIN
    CREATE
    BegiN
        statement3    ;
    END;
    CREATE
    bEgIn
        CREATE -- Inlined random comment
        BEGIN
            statement4    ;
            statement5;
            statement6
        end;
    END    ;
EnD;
-- a comment;

/* A
multiline
comment */
DECLARE BEGIN statement7 END
SQL
chop( my $clean_sql = $sql );

my $sql_splitter = SQL::SplitStatement->new(
    keep_comments => 1
);

my @statements = $sql_splitter->split($sql);

cmp_ok (
    scalar(@statements), '==', 4,
    'number of atomic statements'
);

is (
    join( ";\n", @statements ), $clean_sql,
    'SQL code successfully rebuilt'
);
