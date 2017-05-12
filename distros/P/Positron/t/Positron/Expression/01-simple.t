#!/usr/bin/perl

use 5.008;
use strict;
use warnings;

use Test::More;
use Test::Exception;
use Positron::Environment;

BEGIN {
    require_ok('Positron::Expression');
}

my $environment = Positron::Environment->new({
    one => 'eins',
    two => [1],
    three => { a => 'z' },
});

is(Positron::Expression::evaluate(undef, $environment), undef, 'Undef');
is(Positron::Expression::evaluate('', $environment), undef, 'Empty expression'); # TODO: error instead?
# dies_ok {
#     Positron::Expression::evaluate('', $environment);
# } 'Empty string is a syntax error';

is(Positron::Expression::evaluate('0', $environment), 0, 'Literal number (integer)');
is(Positron::Expression::evaluate('0.1', $environment), 0.1, 'Literal number (float)');

is(Positron::Expression::evaluate('"a"', $environment), 'a', 'Literal string');
is(Positron::Expression::evaluate("'a'", $environment), 'a', 'Literal string (apostrophes)');
is(Positron::Expression::evaluate('`a`', $environment), 'a', 'Literal string (backticks)');

is(Positron::Expression::evaluate('one', $environment), 'eins', 'Variable substitution: scalar');
is_deeply(Positron::Expression::evaluate('two', $environment), [1], 'Variable substitution: array');
is_deeply(Positron::Expression::evaluate('three', $environment), { a => 'z' }, 'Variable substitution: hash');

done_testing();
