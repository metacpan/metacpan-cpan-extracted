use strict;
use warnings;

use Mock::Person::CZ qw(name_female);
use List::MoreUtils qw(any);
use Test::More 'tests' => 5;
use Test::NoWarnings;

$Mock::Person::CZ::STRICT_NUM_NAMES = 3;

# Test.
my $ret1 = name_female();
like($ret1, qr{^\w+\ \w+\ \w+$}, 'Default female name must be three words.');

# Test.
my @ret = split m/\ /ms, $ret1;
my @first_females = @Mock::Person::CZ::first_female;
my $ret2 = any { $ret[0] eq $_ } @first_females;
is($ret2, 1, 'First female name is really from first female names.');

# Test.
my @middle_females = @Mock::Person::CZ::middle_female;
$ret2 = any { $ret[1] eq $_ } @middle_females;
is($ret2, 1, 'Middle female name is really from middle female names.');

# Test.
my @last_females = @Mock::Person::CZ::last_female;
$ret2 = any { $ret[2] eq $_ } @last_females;
is($ret2, 1, 'Last female name is really from last female names.');
