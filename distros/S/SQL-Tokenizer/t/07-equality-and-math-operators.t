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
        description => qq{equality and math operators},
        query =>
q{SELECT a * 2, b / 3, c % 4 FROM table WHERE a <> b AND b >= c AND d <= c AND d <> a},
        wanted => [
            'SELECT', SPACE, 'a',     SPACE, '*',    SPACE,
            '2',      COMMA, SPACE,   'b',   SPACE,  '/',
            SPACE,    '3',   COMMA,   SPACE, 'c',    SPACE,
            '%',      SPACE, '4',     SPACE, 'FROM', SPACE,
            'table',  SPACE, 'WHERE', SPACE, 'a',    SPACE,
            '<>',     SPACE, 'b',     SPACE, 'AND',  SPACE,
            'b',      SPACE, '>=',    SPACE, 'c',    SPACE,
            'AND',    SPACE, 'd',     SPACE, '<=',   SPACE,
            'c',      SPACE, 'AND',   SPACE, 'd',    SPACE,
            '<>',     SPACE, 'a'
        ],
    },
);

plan tests => scalar @tests;

foreach my $test (@tests) {
    my @tokenized = SQL::Tokenizer->tokenize($test->{query});
    is_deeply(\@tokenized, $test->{wanted}, $test->{description});
}
