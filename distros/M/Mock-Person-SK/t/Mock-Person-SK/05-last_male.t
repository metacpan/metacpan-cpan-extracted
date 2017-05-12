# Pragmas.
use strict;
use warnings;

# Modules.
use Mock::Person::SK qw(last_male);
use List::MoreUtils qw(any);
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $ret1 = last_male();
like($ret1, qr{^\w+$}, 'Last male must be one word.');

# Test.
my @last_males = @Mock::Person::SK::last_male;
my $ret2 = any { $ret1 eq $_ } @last_males;
is($ret2, 1, 'Last male is from last male names list.');
