use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean err_msg_hr);
use Mo::utils::Number::Range qw(check_positive_natural_range);
use Readonly;
use Test::More 'tests' => 16;
use Test::NoWarnings;

Readonly::Array our @BAD_RANGES => (
	# Bad values.
	['foo', -10, 10, "Parameter 'key' must be a positive natural number."],
	[1.2, -10, 10, "Parameter 'key' must be a positive natural number."],
	[0, -10, 10, "Parameter 'key' must be a positive natural number."],

	# Right values, but in bad range.
	[5, 10, 30, "Parameter 'key' must be a positive natural number between 10 and 30."],
	[40, 20, 30, "Parameter 'key' must be a positive natural number between 20 and 30."],
);
Readonly::Array our @RIGHT_RANGES => (
	[1, -10, 10],
	[10, 10, 20],
	[20, 10, 20],
);

# Test.
my ($self, $ret);
foreach my $range_ar (@RIGHT_RANGES) {
	$self = {
		'key' => $range_ar->[0],
	};
	$ret = check_positive_natural_range($self, 'key', $range_ar->[1], $range_ar->[2]);
	is($ret, undef, 'Right range is present ('.$self->{'key'}.' in range '.$range_ar->[1].'-'.$range_ar->[2].'%).');
}

# Test.
$self = {};
$ret = check_positive_natural_range($self, 'key');
is($ret, undef, 'Right not exist key.');

# Test.
$self = {
	'key' => undef,
};
$ret = check_positive_natural_range($self, 'key');
is($ret, undef, "Value is undefined, that's ok.");

foreach my $range_ar (@BAD_RANGES) {
	$self = {
		'key' => $range_ar->[0],
	};
	eval {
		check_positive_natural_range($self, 'key', $range_ar->[1], $range_ar->[2]);
	};
	is($EVAL_ERROR, $range_ar->[3]."\n", $range_ar->[3]." Value is '".$range_ar->[0]."'.");
	my $err_msg_hr = err_msg_hr();
	is($err_msg_hr->{'Value'}, $range_ar->[0], 'Test error parameter (Value: '.$range_ar->[0].').');
	clean();
}
