use strict;
use warnings;

use Test::More tests => 1;

my $sql_code = <<'SQL';
CREATE TABLE parent(a, b, c   , d    );
CREATE TABLE child (x, y, "w;", "z;z");
/* C-style comment; */
CREATE TRIGGER "check;delete;parent;" BEFORE DELETE ON parent WHEN
    EXISTS (SELECT 1 FROM child WHERE old.a = x AND old.b = y)
BEGIN
    SELECT RAISE(ABORT, 'constraint failed;'); -- Inlined SQL comment
END;
-- Standalone SQL; comment; w/ semicolons;
INSERT INTO parent (a, b, c, d) VALUES ('pippo;', 'pluto;', NULL, NULL);
SQL

use SQL::SplitStatement;

my $sql_splitter = SQL::SplitStatement->new;

my @statements = $sql_splitter->split($sql_code);

cmp_ok (
    scalar @statements, '==', 4,
    'number of atomic statements'
);

#use Data::Dumper::Perltidy;
#diag Dumper \@statements;
# Adjusted to match @statements, not \@statements.
# @statements = (
#     'CREATE TABLE parent(a, b, c   , d    )',
#     'CREATE TABLE child (x, y, "w;", "z;z")',
#     'CREATE TRIGGER "check;delete;parent;" BEFORE DELETE ON parent WHEN
#     EXISTS (SELECT 1 FROM child WHERE old.a = x AND old.b = y)
# BEGIN
#     SELECT RAISE(ABORT, \'constraint failed;\');
# END',
#     'INSERT INTO parent (a, b, c, d) VALUES (\'pippo;\', \'pluto;\', NULL, NULL)'
# );
