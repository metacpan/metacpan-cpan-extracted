#!/usr/bin/perl

use 5.008;
use strict;
use warnings;

use Test::More;
use Positron::Environment;

BEGIN {
    require_ok('Positron::Expression');
}

my $environment = Positron::Environment->new({
    one => 'eins',
    two => [1],
    three => { a => 'z' },
    e_list => [],
    e_hash => {},
});

# ternaries / booleans
is(Positron::Expression::evaluate('2 ? 3', $environment), 3, "'And' with truth");
is(Positron::Expression::evaluate('0 ? 3', $environment), 0, "'And' with falsehood");
is(Positron::Expression::evaluate('2 : 3', $environment), 2, "'Or' with truth");
is(Positron::Expression::evaluate('0 : 3', $environment), 3, "'Or' with falsehood");

is(Positron::Expression::evaluate('2 ? 3 : 4', $environment), 3, "Ternary with truth");
is(Positron::Expression::evaluate('0 ? 3 : 4', $environment), 4, "Ternary with falsehood");

is(Positron::Expression::evaluate('0 ? 2 ? 3', $environment), 0, "Triple 'and' with falsehood");
is(Positron::Expression::evaluate('1 ? 0 ? 3', $environment), 0, "Triple 'and' with middle falsehood");
is(Positron::Expression::evaluate('1 ? 2 ? 3', $environment), 3, "Triple 'and' with truth");

is(Positron::Expression::evaluate('0 : 2 : 3', $environment), 2, "Triple 'or' with falsehood");
is(Positron::Expression::evaluate('1 : 0 : 3', $environment), 1, "Triple 'or' with middle falsehood");
is(Positron::Expression::evaluate('1 : 2 : 3', $environment), 1, "Triple 'or' with truth");

ok(Positron::Expression::evaluate('!0', $environment), "Not zero");
ok(Positron::Expression::evaluate('!""', $environment), "Not empty string");
ok(Positron::Expression::evaluate('!e_list', $environment), "Not empty list");
ok(Positron::Expression::evaluate('!e_hash', $environment), "Not empty hash");
ok(!Positron::Expression::evaluate('!3', $environment), "Not three");
ok(!Positron::Expression::evaluate('!"a"', $environment), "Not full string");
ok(!Positron::Expression::evaluate('!two', $environment), "Not full list");
ok(!Positron::Expression::evaluate('!three', $environment), "Not full hash");

ok(!Positron::Expression::evaluate('!!0', $environment), "Not not zero");
ok(Positron::Expression::evaluate('!!3', $environment), "Not not three");
done_testing();
