# Pragmas.
use strict;
use warnings;

# Modules.
use Mock::Person::SK qw(first_female);
use List::MoreUtils qw(any);
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $ret1 = first_female();
like($ret1, qr{^\w+$}, 'First female must be one word.');

# Test.
my @first_females = @Mock::Person::SK::first_female;
my $ret2 = any { $ret1 eq $_ } @first_females;
is($ret2, 1, 'First female is from first female names list.');
