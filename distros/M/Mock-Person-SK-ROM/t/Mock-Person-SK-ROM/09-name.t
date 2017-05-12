# Pragmas.
use strict;
use warnings;

# Modules.
use Mock::Person::SK::ROM qw(name);
use List::MoreUtils qw(any);
use Test::More 'tests' => 13;
use Test::NoWarnings;

# Test.
$Mock::Person::SK::ROM::TYPE = 'three';
my $ret1 = name();
like($ret1, qr{^\w+\ \w+\ \w+$}, 'Default name must be three words.');

# Test.
my @ret = split m/\ /ms, $ret1;
my @first_males = @Mock::Person::SK::ROM::first_male;
my @first_females = @Mock::Person::SK::ROM::first_female;
my $ret2 = any { $ret[0] eq $_ } @first_males, @first_females;
is($ret2, 1, 'First name is really from first male names.');

# Test.
my @middle_males = @Mock::Person::SK::ROM::middle_male;
my @middle_females = @Mock::Person::SK::ROM::middle_female;
$ret2 = any { $ret[1] eq $_ } @middle_males, @middle_females;
is($ret2, 1, 'Middle name is really from middle male names.');

# Test.
my @last_males = @Mock::Person::SK::ROM::last_male;
my @last_females = @Mock::Person::SK::ROM::last_female;
$ret2 = any { $ret[2] eq $_ } @last_males, @last_females;
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
$ret2 = any { $ret[0] eq $_ } @first_females;
is($ret2, 1, 'First name is really from first female names.');

# Test.
@middle_females = @Mock::Person::SK::ROM::middle_female;
$ret2 = any { $ret[1] eq $_ } @middle_females;
is($ret2, 1, 'Middle name is really from middle female names.');

# Test.
@last_females = @Mock::Person::SK::ROM::last_female;
$ret2 = any { $ret[2] eq $_ } @last_females;
is($ret2, 1, 'Last name is really from last female names.');
