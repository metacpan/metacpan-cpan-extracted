# Pragmas.
use strict;
use warnings;

# Modules.
use Mock::Person::SK qw(middle_female);
use List::MoreUtils qw(any);
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $ret1 = middle_female();
like($ret1, qr{^\w+$}, 'Middle female must be one word.');

# Test.
my @middle_females = @Mock::Person::SK::middle_female;
my $ret2 = any { $ret1 eq $_ } @middle_females;
is($ret2, 1, 'Middle female is from middle female names list.');
