# Pragmas.
use strict;
use warnings;

# Modules.
use Mock::Person::SK qw(first_male);
use List::MoreUtils qw(any);
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $ret1 = first_male();
like($ret1, qr{^\w+$}, 'First male must be one word.');

# Test.
my @first_males = @Mock::Person::SK::first_male;
my $ret2 = any { $ret1 eq $_ } @first_males;
is($ret2, 1, 'First male is from first male names list.');
