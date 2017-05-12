
use strict;
use warnings;

use Test::More tests => 8;
BEGIN { require "t/utils.pl" };

use_ok 'Parse::BooleanLogic';

my $parser = Parse::BooleanLogic->new( operators => [qw(& |)] );

parse_cmp
    $parser,
    'x = 10',
    [{ operand => 'x = 10' }],
;

parse_cmp
    $parser,
    'x | y',
    [ { operand => 'x' }, '|', { operand => 'y' } ],
;

parse_cmp
    $parser,
    'x| y',
    [ { operand => 'x' }, '|', { operand => 'y' } ],
;

parse_cmp
    $parser,
    'x |y',
    [ { operand => 'x' }, '|', { operand => 'y' } ],
;

parse_cmp
    $parser,
    '(x) | (y)',
    [ [{ operand => 'x' }], '|', [{ operand => 'y' }] ],
;

parse_cmp
    $parser,
    '(x)| (y)',
    [ [{ operand => 'x' }], '|', [{ operand => 'y' }] ],
;

parse_cmp
    $parser,
    '(x) |(y)',
    [ [{ operand => 'x' }], '|', [{ operand => 'y' }] ],
;

