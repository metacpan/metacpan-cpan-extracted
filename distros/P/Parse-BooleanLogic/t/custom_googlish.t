use strict;
use warnings;

use Test::More tests => 4;
BEGIN { require "t/utils.pl" };

use_ok 'Parse::BooleanLogic';

my $parser = Parse::BooleanLogic->new( operators => ['', 'OR'] );

parse_cmp
    $parser,
    'x y',
    [ { operand => 'x' }, '', { operand => 'y' } ],
;

parse_cmp
    $parser,
    'test from:me subject:"like this"',
    [ { operand => 'test' }, '', { operand => 'from:me' }, '', { operand => 'subject:"like this"' } ],
;

parse_cmp
    $parser,
    'test (from:me OR to:me)',
    [ { operand => 'test' }, '', [{ operand => 'from:me' }, 'OR', { operand => 'to:me' }] ],
;

