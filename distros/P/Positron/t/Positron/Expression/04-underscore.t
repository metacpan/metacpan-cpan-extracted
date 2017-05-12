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
    _ => 'underscore',
});

is_deeply(Positron::Expression::evaluate('_', $environment), $environment->{'data'}, 'Underscore is the environment again');
is_deeply(Positron::Expression::evaluate('_.one', $environment), 'eins', 'Underscore before dot is idempotent');

done_testing();
