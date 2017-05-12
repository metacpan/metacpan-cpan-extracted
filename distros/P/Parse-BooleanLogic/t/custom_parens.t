
use strict;
use warnings;

use Test::More tests => 9;
BEGIN { require "t/utils.pl" };

use_ok 'Parse::BooleanLogic';

my $parser = Parse::BooleanLogic->new( parens => [qw({ })] );

parse_cmp
    $parser,
    '',
    [],
;

parse_cmp
    $parser,
    'x = 10',
    [{ operand => 'x = 10' }],
;

parse_cmp
    $parser,
    '(x = 10)',
    [{ operand => '(x = 10)' }],
;
parse_cmp
    $parser,
    '{x = 10}',
    [[{ operand => 'x = 10' }]],
;

parse_cmp
    $parser,
    '{x = 10} OR y = "Y"',
    [
        [{ operand => 'x = 10' }],
        'OR',
        { operand => 'y = "Y"' }
    ],
;

parse_cmp
    $parser,
    'just a string',
    [{ operand => 'just a string' }],
;

parse_cmp
    $parser,
    '"quoted string {with parens}"',
    [{ operand => '"quoted string {with parens}"' }],
;

parse_cmp
    $parser,
    'string OR string',
    [{ operand => 'string' }, 'OR', { operand => 'string' }],
;

