# Pragmas.
use strict;
use warnings;

# Modules.
use Mock::Person::SK qw(middle_male);
use List::MoreUtils qw(any);
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $ret1 = middle_male();
like($ret1, qr{^\w+$}, 'Middle male must be one word.');

# Test.
my @middle_males = @Mock::Person::SK::middle_male;
my $ret2 = any { $ret1 eq $_ } @middle_males;
is($ret2, 1, 'Middle male is from middle male names list.');
