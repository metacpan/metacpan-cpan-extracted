use strict;
use warnings;

use PYX qw(start_element);
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
my $element = 'element';
my @attr = ();
my ($ret) = start_element($element, @attr);
is($ret, '(element');

# Test.
@attr = ('par', 'val');
($ret, my $ret2) = start_element($element, @attr);
is($ret, '(element');
is($ret2, 'Apar val');

# Test.
@attr = ('par', "val\nval");
($ret, $ret2) = start_element($element, @attr);
is($ret, '(element');
is($ret2, 'Apar val\nval');
