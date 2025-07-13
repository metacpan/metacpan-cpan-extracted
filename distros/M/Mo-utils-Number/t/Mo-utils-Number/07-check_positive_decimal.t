use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean err_msg_hr);
use Mo::utils::Number qw(check_positive_decimal);
use Readonly;
use Test::More 'tests' => 15;
use Test::NoWarnings;

Readonly::Array our @BAD_NUMBERS => qw(
	-10
	-10.2
	foo
	0
);
Readonly::Array our @RIGHT_NUMBERS => qw(
	0.1
	10.2345
	2
	100
);

# Test.
my ($self, $ret);
foreach my $number (@RIGHT_NUMBERS) {
	$self = {
		'key' => $number,
	};
	$ret = check_positive_decimal($self, 'key');
	is($ret, undef, 'Right number is present ('.$number.').');
}

# Test.
$self = {};
$ret = check_positive_decimal($self, 'key');
is($ret, undef, 'Right not exist key.');

# Test.
$self = {
	'key' => undef,
};
$ret = check_positive_decimal($self, 'key');
is($ret, undef, "Value is undefined, that's ok.");

foreach my $number (@BAD_NUMBERS) {
	$self = {
		'key' => $number,
	};
	eval {
		check_positive_decimal($self, 'key');
	};
	is($EVAL_ERROR, "Parameter 'key' must be a positive decimal number.\n",
		"Parameter 'key' must be a positive decimal number. Value is '$number'.");
	my $err_msg_hr = err_msg_hr();
	is($err_msg_hr->{'Value'}, $number, 'Test error parameter (Value: '.$number.').');
	clean();
}
