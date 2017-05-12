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
        description => q{C style comment},
        query       => <<COMPLEX_SQL,
/* drop table */
DROP TABLE test;
/* create table */
CREATE TABLE test (id INT, name VARCHAR);
/* insert data */
INSERT INTO test (id, name) VALUES (1, 't');
INSERT INTO test (id, name) VALUES (2, '''quoted''');
COMPLEX_SQL

        wanted => [
            q{/* drop table */}, NL,
            'DROP',              SPACE,
            'TABLE',             SPACE,
            'test',              ';',
            NL,                  q{/* create table */},
            NL,                  'CREATE',
            SPACE,               'TABLE',
            SPACE,               'test',
            SPACE,               '(',
            'id',                SPACE,
            'INT',               COMMA,
            SPACE,               'name',
            SPACE,               'VARCHAR',
            ')',                 ';',
            NL,                  q{/* insert data */},
            NL,                  'INSERT',
            SPACE,               'INTO',
            SPACE,               'test',
            SPACE,               '(',
            'id',                COMMA,
            SPACE,               'name',
            ')',                 SPACE,
            'VALUES',            SPACE,
            '(',                 '1',
            COMMA,               SPACE,
            q{'t'},              ')',
            ';',                 NL,
            'INSERT',            SPACE,
            'INTO',              SPACE,
            'test',              SPACE,
            '(',                 'id',
            COMMA,               SPACE,
            'name',              ')',
            SPACE,               'VALUES',
            SPACE,               '(',
            '2',                 COMMA,
            SPACE,               q{'''quoted'''},
            ')',                 ';',
            NL,
        ],
    },
    {
        description => q{multi-line C style comment},
        query       => <<COMPLEX_SQL,
/*
    drop table
*/
DROP TABLE test;
/*
    create table
*/
CREATE TABLE test (id INT, name VARCHAR);
/*
    insert data
*/
INSERT INTO test (id, name) VALUES (1, 't');
INSERT INTO test (id, name) VALUES (2, '''quoted''');
COMPLEX_SQL

        wanted => [
            qq{/*\n    drop table\n*/}, NL,
            'DROP',                     SPACE,
            'TABLE',                    SPACE,
            'test',                     ';',
            NL,                         qq{/*\n    create table\n*/},
            NL,                         'CREATE',
            SPACE,                      'TABLE',
            SPACE,                      'test',
            SPACE,                      '(',
            'id',                       SPACE,
            'INT',                      COMMA,
            SPACE,                      'name',
            SPACE,                      'VARCHAR',
            ')',                        ';',
            NL,                         qq{/*\n    insert data\n*/},
            NL,                         'INSERT',
            SPACE,                      'INTO',
            SPACE,                      'test',
            SPACE,                      '(',
            'id',                       COMMA,
            SPACE,                      'name',
            ')',                        SPACE,
            'VALUES',                   SPACE,
            '(',                        '1',
            COMMA,                      SPACE,
            q{'t'},                     ')',
            ';',                        NL,
            'INSERT',                   SPACE,
            'INTO',                     SPACE,
            'test',                     SPACE,
            '(',                        'id',
            COMMA,                      SPACE,
            'name',                     ')',
            SPACE,                      'VALUES',
            SPACE,                      '(',
            '2',                        COMMA,
            SPACE,                      q{'''quoted'''},
            ')',                        ';',
            NL,
        ],
    },
    {
        description => q{multi-line C style comment with CR+LF newline},
        query       => <<COMPLEX_SQL,
/*\r
    drop table\r
*/\r
DROP TABLE test;\r
/*\r
    create table\r
*/\r
CREATE TABLE test (id INT, name VARCHAR);\r
/*\r
    insert data\r
*/\r
INSERT INTO test (id, name) VALUES (1, 't');\r
INSERT INTO test (id, name) VALUES (2, '''quoted''');\r
COMPLEX_SQL

        wanted => [
            qq{/*\r\n    drop table\r\n*/}, NL,
            'DROP',                         SPACE,
            'TABLE',                        SPACE,
            'test',                         ';',
            NL,                             qq{/*\r\n    create table\r\n*/},
            NL,                             'CREATE',
            SPACE,                          'TABLE',
            SPACE,                          'test',
            SPACE,                          '(',
            'id',                           SPACE,
            'INT',                          COMMA,
            SPACE,                          'name',
            SPACE,                          'VARCHAR',
            ')',                            ';',
            NL,                             qq{/*\r\n    insert data\r\n*/},
            NL,                             'INSERT',
            SPACE,                          'INTO',
            SPACE,                          'test',
            SPACE,                          '(',
            'id',                           COMMA,
            SPACE,                          'name',
            ')',                            SPACE,
            'VALUES',                       SPACE,
            '(',                            '1',
            COMMA,                          SPACE,
            q{'t'},                         ')',
            ';',                            NL,
            'INSERT',                       SPACE,
            'INTO',                         SPACE,
            'test',                         SPACE,
            '(',                            'id',
            COMMA,                          SPACE,
            'name',                         ')',
            SPACE,                          'VALUES',
            SPACE,                          '(',
            '2',                            COMMA,
            SPACE,                          q{'''quoted'''},
            ')',                            ';',
            NL,
        ],
    },
);

plan tests => scalar @tests;

foreach my $test (@tests) {
    my @tokenized = SQL::Tokenizer->tokenize( $test->{query} );
    is_deeply( \@tokenized, $test->{wanted}, $test->{description} );
}
