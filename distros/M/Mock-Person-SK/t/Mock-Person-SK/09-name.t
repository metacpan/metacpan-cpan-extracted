# Pragmas.
use strict;
use warnings;

# Modules.
use Mock::Person::SK qw(name);
use List::MoreUtils qw(any);
use Test::More 'tests' => 13;
use Test::NoWarnings;

# Test.
my $ret1 = name();
like($ret1, qr{^\w+\ \w+\ \w+$}, 'Default name must be three words.');

# Test.
my @ret = split m/\ /ms, $ret1;
my @first_males = @Mock::Person::SK::first_male;
my $ret2 = any { $ret[0] eq $_ } @first_males;
is($ret2, 1, 'First name is really from first male names.');

# Test.
my @middle_males = @Mock::Person::SK::middle_male;
$ret2 = any { $ret[1] eq $_ } @middle_males;
is($ret2, 1, 'Middle name is really from middle male names.');

# Test.
my @last_males = @Mock::Person::SK::last_male;
$ret2 = any { $ret[2] eq $_ } @last_males;
is($ret2, 1, 'Last name is really from last male names.');

# Test.
$ret1 = name('male');
like($ret1, qr{^\w+\ \w+\ \w+$}, 'Male name must be three words.');

# Test.
@ret = split m/\ /ms, $ret1;
$ret2 = any { $ret[0] eq $_ } @first_males;
is($ret2, 1, 'First name is really from first male names.');

# Test.
$ret2 = any { $ret[1] eq $_ } @middle_males;
is($ret2, 1, 'Middle name is really from middle male names.');

# Test.
$ret2 = any { $ret[2] eq $_ } @last_males;
is($ret2, 1, 'Last name is really from last male names.');

# Test.
$ret1 = name('female');
like($ret1, qr{^\w+\ \w+\ \w+$}, 'Female name must be three words.');

# Test.
@ret = split m/\ /ms, $ret1;
my @first_females = @Mock::Person::SK::first_female;
$ret2 = any { $ret[0] eq $_ } @first_females;
is($ret2, 1, 'First name is really from first female names.');

# Test.
my @middle_females = @Mock::Person::SK::middle_female;
$ret2 = any { $ret[1] eq $_ } @middle_females;
is($ret2, 1, 'Middle name is really from middle female names.');

# Test.
my @last_females = @Mock::Person::SK::last_female;
$ret2 = any { $ret[2] eq $_ } @last_females;
is($ret2, 1, 'Last name is really from last female names.');
