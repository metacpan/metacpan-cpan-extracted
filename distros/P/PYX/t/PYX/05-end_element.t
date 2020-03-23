use strict;
use warnings;

use PYX qw(end_element);
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $element = 'element';
my $ret = end_element($element);
is($ret, ')element');
