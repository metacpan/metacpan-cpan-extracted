use strict;
use warnings;

use Mock::Person::CZ qw(name_male);
use List::MoreUtils qw(any);
use Test::More 'tests' => 5;
use Test::NoWarnings;

$Mock::Person::CZ::STRICT_NUM_NAMES = 3;

# Test.
my $ret1 = name_male();
like($ret1, qr{^\w+\ \w+\ \w+$}, 'Default male name must be three words.');

# Test.
my @ret = split m/\ /ms, $ret1;
my @first_males = @Mock::Person::CZ::first_male;
my $ret2 = any { $ret[0] eq $_ } @first_males;
is($ret2, 1, 'First male name is really from first male names.');

# Test.
my @middle_males = @Mock::Person::CZ::middle_male;
$ret2 = any { $ret[1] eq $_ } @middle_males;
is($ret2, 1, 'Middle male name is really from middle male names.');

# Test.
my @last_males = @Mock::Person::CZ::last_male;
$ret2 = any { $ret[2] eq $_ } @last_males;
is($ret2, 1, 'Last male name is really from last male names.');
