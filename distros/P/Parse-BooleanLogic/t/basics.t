
use strict;
use warnings;

use Test::More tests => 16;
BEGIN { require "t/utils.pl" };

use_ok 'Parse::BooleanLogic';


my $parser = new Parse::BooleanLogic;

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
    [[{ operand => 'x = 10' }]],
;

parse_cmp
    $parser,
    '(x = 10) OR y = "Y"',
    [
        [{ operand => 'x = 10' }],
        'OR',
        { operand => 'y = "Y"' }
    ],
;

parse_cmp
    $parser,
    ' (x)',
    [
        [{ operand => 'x' }],
    ],
;

parse_cmp
    $parser,
    '(x) OR (y)',
    [
        [{ operand => 'x' }],
        'OR',
        [{ operand => 'y' }]
    ],
;

parse_cmp
    $parser,
    'just a string',
    [{ operand => 'just a string' }],
;

parse_cmp
    $parser,
    '"quoted string"',
    [{ operand => '"quoted string"' }],
;

parse_cmp
    $parser,
    '"quoted string (with parens)"',
    [{ operand => '"quoted string (with parens)"' }],
;

parse_cmp
    $parser,
    'string "quoted" in the middle',
    [{ operand => 'string "quoted" in the middle' }],
;

parse_cmp
    $parser,
    'string OR string',
    [{ operand => 'string' }, 'OR', { operand => 'string' }],
;

parse_cmp
    $parser,
    '"OR" OR string',
    [{ operand => '"OR"' }, 'OR', { operand => 'string' }],
;

parse_cmp
    $parser,
    "recORd = 3",
    [{ operand => "recORd = 3" }],
;

parse_cmp
    $parser,
    "op ORheading = 3",
    [{ operand => "op ORheading = 3" }],
;

parse_cmp
    $parser,
    "operAND",
    [{ operand => "operAND" }],
;
