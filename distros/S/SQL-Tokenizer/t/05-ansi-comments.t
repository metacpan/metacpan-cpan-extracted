use strict;
use warnings;

use Test::More;

use SQL::Tokenizer;

use constant SPACE => ' ';
use constant COMMA => ',';
use constant NL    => "\n";

my $query;
my @query;
my @tokenized;

my @tests = (
    {
        description => q{ANSI comments},
        query       => <<COMPLEX_SQL,
DROP TABLE test; -- drop table
CREATE TABLE test (id INT, name VARCHAR); -- create table
-- insert data
INSERT INTO test (id, name) VALUES (1, 't');
INSERT INTO test (id, name) VALUES (2, '''quoted''');
COMPLEX_SQL

        wanted => [
            'DROP',   SPACE,             'TABLE',  SPACE,
            'test',   ';',               SPACE,    q{-- drop table},
            NL,       'CREATE',          SPACE,    'TABLE',
            SPACE,    'test',            SPACE,    '(',
            'id',     SPACE,             'INT',    COMMA,
            SPACE,    'name',            SPACE,    'VARCHAR',
            ')',      ';',               SPACE,    q{-- create table},
            NL,       q{-- insert data}, NL,       'INSERT',
            SPACE,    'INTO',            SPACE,    'test',
            SPACE,    '(',               'id',     COMMA,
            SPACE,    'name',            ')',      SPACE,
            'VALUES', SPACE,             '(',      '1',
            COMMA,    SPACE,             q{'t'},   ')',
            ';',      NL,                'INSERT', SPACE,
            'INTO',   SPACE,             'test',   SPACE,
            '(',      'id',              COMMA,    SPACE,
            'name',   ')',               SPACE,    'VALUES',
            SPACE,    '(',               '2',      COMMA,
            SPACE,    q{'''quoted'''},   ')',      ';',
            NL,
        ],
    },
);

plan tests => scalar @tests;

foreach my $test (@tests) {
    my @tokenized = SQL::Tokenizer->tokenize( $test->{query} );
    is_deeply( \@tokenized, $test->{wanted}, $test->{description} );
}
