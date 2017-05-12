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

my @tests= (
    {
        description => qq{one C style scaped single quote},
        query       => 'INSERT INTO table VALUES( \'scaped \\\' single quote\', \'no quote\' )',
        wanted      => [
            'INSERT', SPACE, 'INTO', SPACE, 'table', SPACE, 'VALUES', '(', SPACE,
            q{'scaped \' single quote'},
            COMMA, SPACE, q{'no quote'}, SPACE, ')'
        ],
    },

    {
        description => qq{no quotes inside string},
        query       => 'INSERT INTO table VALUES( \'no quote\', \'no quote either\' )',
        wanted      => [
            'INSERT', SPACE, 'INTO', SPACE, 'table', SPACE, 'VALUES', '(', SPACE, q{'no quote'},
            COMMA, SPACE, q{'no quote either'},
            SPACE, ')'
        ],
    },

    {
        description => qq{more than one C style escaped single quotes inside string},
        query =>
          q{INSERT INTO logs (program, message) VALUES (:program, 'Something \' with \' a \' lot \' of \' scaped quotes')},
        wanted => [
            'INSERT',   SPACE,    'INTO',    SPACE,
            'logs',     SPACE,    '(',       'program',
            COMMA,      SPACE,    'message', ')',
            SPACE,      'VALUES', SPACE,     '(',
            ':program', COMMA,    SPACE,
            q{'Something \' with \' a \' lot \' of \' scaped quotes'},
            ')'
        ],
    },

    {
        description => qq{more than one C style escaped single quotes inside string, with extra backslashes},
        query =>
          q{INSERT INTO logs (program, message) VALUES (:program, 'Something \' with \' a \' lot \' of \' scaped quotes\\\\\\\\\\\\\\\\')},
        wanted => [
            'INSERT',   SPACE,    'INTO',    SPACE,
            'logs',     SPACE,    '(',       'program',
            COMMA,      SPACE,    'message', ')',
            SPACE,      'VALUES', SPACE,     '(',
            ':program', COMMA,    SPACE,
            q{'Something \' with \' a \' lot \' of \' scaped quotes\\\\\\\\\\\\\\\\'},
            ')'
        ],
    },

    {
        description => qq{SQL style escaped single quotes},
        query       => q{INSERT INTO logs (program) VALUES ('single''quote')},
        wanted      => [
            'INSERT', SPACE, 'INTO', SPACE, 'logs', SPACE, '(', 'program', ')', SPACE, 'VALUES',
            SPACE, '(', q{'single''quote'}, ')'
        ],
    },

    {
        description => qq{SQL style escaped single quotes with surrounding spaces},
        query       => q{INSERT INTO logs (program) VALUES ('single '' quote '' ')},
        wanted      => [
            'INSERT', SPACE, 'INTO', SPACE, 'logs', SPACE, '(', 'program', ')', SPACE, 'VALUES',
            SPACE, '(', q{'single '' quote '' '}, ')'
        ],
    },

    {
        description => qq{C style escaped single quote at end of string},
        query       => q{INSERT INTO logs (program) VALUES ('single '' quote \'')},
        wanted      => [
            'INSERT', SPACE, 'INTO', SPACE, 'logs', SPACE, '(', 'program', ')', SPACE, 'VALUES',
            SPACE, '(', q{'single '' quote \''}, ')'
        ],
    },

    {
        description => qq{multiple SQL style escaped single quotes at end of string},
        query       => q{INSERT INTO logs (program) VALUES ('single '' quote ''''')},
        wanted      => [
            'INSERT', SPACE, 'INTO', SPACE, 'logs', SPACE, '(', 'program', ')', SPACE, 'VALUES',
            SPACE, '(', q{'single '' quote '''''}, ')'
        ],
    },
);

plan tests => scalar @tests;

foreach my $test (@tests) {
    my @tokenized= SQL::Tokenizer->tokenize( $test->{query} );
    is_deeply( \@tokenized, $test->{wanted}, $test->{description} );
}
