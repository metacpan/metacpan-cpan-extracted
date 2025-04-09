use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean err_msg_hr);
use Mo::utils::Number qw(check_natural);
use Readonly;
use Test::More 'tests' => 11;
use Test::NoWarnings;

Readonly::Array our @BAD_NUMBERS => qw(
	10.0001
	-10
	foo
);
Readonly::Array our @RIGHT_NUMBERS => qw(
	0
	2
);

# Test.
my ($self, $ret);
foreach my $number (@RIGHT_NUMBERS) {
	$self = {
		'key' => $number,
	};
	$ret = check_natural($self, 'key');
	is($ret, undef, 'Right number is present ('.$number.').');
}

# Test.
$self = {};
$ret = check_natural($self, 'key');
is($ret, undef, 'Right not exist key.');

# Test.
$self = {
	'key' => undef,
};
$ret = check_natural($self, 'key');
is($ret, undef, "Value is undefined, that's ok.");

foreach my $number (@BAD_NUMBERS) {
	$self = {
		'key' => $number,
	};
	eval {
		check_natural($self, 'key');
	};
	is($EVAL_ERROR, "Parameter 'key' must be a natural number.\n",
		"Parameter 'key' must be a natural number. Value is '$number'.");
	my $err_msg_hr = err_msg_hr();
	is($err_msg_hr->{'Value'}, $number, 'Test error parameter (Value: '.$number.').');
	clean();
}
