use strict;
use warnings;

use Person::ID::CZ::RC::Generator;
use Test::More 'tests' => 8;
use Test::NoWarnings;

# Test.
my $obj = Person::ID::CZ::RC::Generator->new;
my $ret = $obj->rc;
like($ret, qr{^\d{9}\d?$}, 'Generate RC number.');

# Test.
foreach my $sex (qw(male female)) {
	my $log = 0;
	while (! $log) {
		$ret = $obj->rc;
		my $month = substr $ret, 2, 2;
		my $addition = $sex eq 'male' ? 0 : 50;
		my $diff = $month - $addition;
		if ($diff > 0 && $diff < 13) {
			ok(1, "Sex '$sex' is ok.");
			$log = 1;
		}
	}
}

# Test.
$obj = Person::ID::CZ::RC::Generator->new(
	'alternate' => 1,
	'sex' => 'female',
);
$ret = $obj->rc;
my $month = substr $ret, 2, 2;
if ($month > 70 && $month < 83) {
	ok(1, 'Alternate female.');
} else {
	ok(0, 'Alternate female.');
}

# Test.
foreach my $checksum (qw(X 0)) {
	my $log = 0;
	while (! $log) {
		$ret = $obj->rc;
		if (length $ret == 10) {
			my $last = substr $ret, 9, 1;
			if ($checksum eq '0') {
				if ($last == 0) {
					ok(1, 'Checksum 0 is ok.');
					$log = 1;
				}
			} else {
				if ($last != 0) {
					ok(1, 'Checksum > 0 is ok.');
					$log = 1;
				}
			}
		}
	}
}

# Test
$obj = Person::ID::CZ::RC::Generator->new(
	'serial' => '123',
);
$ret = $obj->rc;
my $ret_serial = substr $ret, 6, 3;
is($ret_serial, '123', 'Predefined serial.');
