# Pragmas.
use strict;
use warnings;

# Modules.
use Mock::Person::EN qw(last_male);
use List::MoreUtils qw(any);
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $ret1 = last_male();
like($ret1, qr{^\w+\ ?\w+?$}, 'Last male must be one or two words.');

# Test.
my @last_males = @Mock::Person::EN::last_male;
my $ret2 = any { $ret1 eq $_ } @last_males;
is($ret2, 1, 'Last male is from last male names list.');
