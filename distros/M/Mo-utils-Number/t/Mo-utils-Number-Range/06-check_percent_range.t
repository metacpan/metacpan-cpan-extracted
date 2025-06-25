use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean err_msg_hr);
use Mo::utils::Number::Range qw(check_percent_range);
use Readonly;
use Test::More 'tests' => 16;
use Test::NoWarnings;

Readonly::Array our @BAD_RANGES => (
	# Bad values.
	['foo', 0, 100, "Parameter 'key' has bad percent value."],
	['110%', 0, 200, "Parameter 'key' has bad percent value."],
	[0, 10, 30, "Parameter 'key' has bad percent value (missing %)."],

	# Right values, but in bad range.
	['0%', 10, 30, "Parameter 'key' must be a percent between 10% and 30%."],
	['40%', 20, 30, "Parameter 'key' must be a percent between 20% and 30%."],
);
Readonly::Array our @RIGHT_RANGES => (
	['0%', 0, 100],
	['100%', 0, 100],
	['10%', 0, 50],
);

# Test.
my ($self, $ret);
foreach my $range_ar (@RIGHT_RANGES) {
	$self = {
		'key' => $range_ar->[0],
	};
	$ret = check_percent_range($self, 'key', $range_ar->[1], $range_ar->[2]);
	is($ret, undef, 'Right range is present ('.$self->{'key'}.' in range '.$range_ar->[1].'-'.$range_ar->[2].'%).');
}

# Test.
$self = {};
$ret = check_percent_range($self, 'key');
is($ret, undef, 'Right not exist key.');

# Test.
$self = {
	'key' => undef,
};
$ret = check_percent_range($self, 'key');
is($ret, undef, "Value is undefined, that's ok.");

foreach my $range_ar (@BAD_RANGES) {
	$self = {
		'key' => $range_ar->[0],
	};
	eval {
		check_percent_range($self, 'key', $range_ar->[1], $range_ar->[2]);
	};
	is($EVAL_ERROR, $range_ar->[3]."\n", $range_ar->[3]." Value is '".$range_ar->[0]."'.");
	my $err_msg_hr = err_msg_hr();
	is($err_msg_hr->{'Value'}, $range_ar->[0], 'Test error parameter (Value: '.$range_ar->[0].').');
	clean();
}
