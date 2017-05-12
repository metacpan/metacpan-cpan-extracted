# Pragmas.
use strict;
use warnings;

# Modules.
use Mock::Person::EN qw(name);
use List::MoreUtils qw(any);
use Test::More 'tests' => 13;
use Test::NoWarnings;

# Test.
$Mock::Person::EN::TYPE = 'three';
my $ret1 = name();
like($ret1, qr{^\w+\ \w+\ \w+\ ?\w+?$},
	'Default name must be three or four words.');

# Test.
my @ret = split m/\ /ms, $ret1;
if (@ret == 4) {
	@ret = split m/\ /ms, $ret1, 3;
}
my @first_males = @Mock::Person::EN::first_male;
my @first_females = @Mock::Person::EN::first_female;
my $ret2 = any { $ret[0] eq $_ } @first_males, @first_females;
is($ret2, 1, 'First name is really from first male/female names.');

# Test.
my @middle_males = @Mock::Person::EN::middle_male;
my @middle_females = @Mock::Person::EN::middle_female;
$ret2 = any { $ret[1] eq $_ } @middle_males, @middle_females;
is($ret2, 1, 'Middle name is really from middle male/female names.');

# Test.
my @last_males = @Mock::Person::EN::last_male;
$ret2 = any { $ret[2] eq $_ } @last_males;
is($ret2, 1, 'Last name is really from last male names.');

# Test.
$ret1 = name('male');
like($ret1, qr{^\w+\ \w+\ \w+\ ?\w+?$},
	'Male name must be three or four words.');

# Test.
@ret = split m/\ /ms, $ret1;
if (@ret == 4) {
	@ret = split m/\ /ms, $ret1, 3;
}
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
like($ret1, qr{^\w+\ \w+\ \w+\ ?\w+?$}, 'Female name must be three words.');

# Test.
@ret = split m/\ /ms, $ret1;
if (@ret == 4) {
	@ret = split m/\ /ms, $ret1, 3;
}
$ret2 = any { $ret[0] eq $_ } @first_females;
is($ret2, 1, 'First name is really from first female names.');

# Test.
$ret2 = any { $ret[1] eq $_ } @middle_females;
is($ret2, 1, 'Middle name is really from middle female names.');

# Test.
my @last_females = @Mock::Person::EN::last_female;
$ret2 = any { $ret[2] eq $_ } @last_females;
is($ret2, 1, 'Last name is really from last female names.');
