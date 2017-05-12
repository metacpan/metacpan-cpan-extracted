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
        description => qq{one C style scaped double quote},
        query =>
"INSERT INTO table VALUES( \"scaped \\\" double quote\", \"no quote\" )",
        wanted => [
            'INSERT',      SPACE,
            'INTO',        SPACE,
            'table',       SPACE,
            'VALUES',      '(',
            SPACE,         q{"scaped \" double quote"},
            COMMA,         SPACE,
            q{"no quote"}, SPACE,
            ')'
        ],
    },

    {
        description => qq{no quotes inside string},
        query =>
          "INSERT INTO table VALUES( \"no quote\", \"no quote either\" )",
        wanted => [
            'INSERT',             SPACE,
            'INTO',               SPACE,
            'table',              SPACE,
            'VALUES',             '(',
            SPACE,                q{"no quote"},
            COMMA,                SPACE,
            q{"no quote either"}, SPACE,
            ')'
        ],
    },

    {
        description =>
          qq{more than one C style escaped double quotes inside string},
        query =>
q{INSERT INTO logs (program, message) VALUES (:program, "Something \" with \" a \" lot \" of \" scaped quotes")},
        wanted => [
            'INSERT',   SPACE,    'INTO',    SPACE,
            'logs',     SPACE,    '(',       'program',
            COMMA,      SPACE,    'message', ')',
            SPACE,      'VALUES', SPACE,     '(',
            ':program', COMMA,    SPACE,
            q{"Something \" with \" a \" lot \" of \" scaped quotes"},
            ')'
        ],
    },

    {
        description => qq{SQL style escaped double quotes},
        query       => q{INSERT INTO logs (program) VALUES ("double""quote")},
        wanted      => [
            'INSERT', SPACE, 'INTO', SPACE, 'logs', SPACE, '(', 'program', ')',
            SPACE, 'VALUES', SPACE, '(', q{"double""quote"}, ')'
        ],
    },

    {
        description =>
          qq{SQL style escaped double quotes with surrounding spaces},
        query  => q{INSERT INTO logs (program) VALUES ("double "" quote "" ")},
        wanted => [
            'INSERT', SPACE, 'INTO', SPACE, 'logs', SPACE, '(', 'program', ')',
            SPACE, 'VALUES', SPACE, '(', q{"double "" quote "" "}, ')'
        ],
    },

    {
        description => qq{C style escaped double quote at end of string},
        query  => q{INSERT INTO logs (program) VALUES ("single "" quote \"")},
        wanted => [
            'INSERT', SPACE, 'INTO', SPACE, 'logs', SPACE, '(', 'program', ')',
            SPACE, 'VALUES', SPACE, '(', q{"single "" quote \""}, ')'
        ],
    },

    {
        description =>
          qq{multiple SQL style escaped double quotes at end of string},
        query  => qq{INSERT INTO logs (program) VALUES ("double "" quote """"")},
        wanted => [
            'INSERT', SPACE, 'INTO', SPACE, 'logs', SPACE, '(', 'program', ')',
            SPACE, 'VALUES', SPACE, '(', qq{"double "" quote """""}, ')'
        ],
    },
);

plan tests => scalar @tests;

foreach my $test (@tests) {
    my @tokenized = SQL::Tokenizer->tokenize( $test->{query} );
    is_deeply( \@tokenized, $test->{wanted}, $test->{description} );
}
