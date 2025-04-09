use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean err_msg_hr);
use Mo::utils::Number::Utils qw(sub_check_percent);
use Readonly;
use Test::More 'tests' => 21;
use Test::NoWarnings;

Readonly::Array our @RIGTH_PERCENTS => (
	'20%',
	'20.5%',
);
Readonly::Array our @BAD_PERCENTS => (
	[
		['-', 'key'],
		"Parameter 'key' has bad percent value.",
	],
	[
		['.0', 'key'],
		"Parameter 'key' has bad percent value.",
	],
	[
		['20', 'key'],
		"Parameter 'key' has bad percent value (missing %).",
	],
	[
		['20', 'key', 'foo value'],
		"Parameter 'key' has bad foo value (missing %).",
	],
	[
		['20', 'key', undef, '20 is part of value'],
		"Parameter 'key' has bad percent value (missing %).",
		'20 is part of value',
	],
	[
		['.0%', 'key'],
		"Parameter 'key' has bad percent value.",
	],
	[
		['123.%', 'key'],
		"Parameter 'key' has bad percent value.",
	],
	[
		['101%', 'key'],
		"Parameter 'key' has bad percent value.",
	],
	[
		['bad', 'key'],
		"Parameter 'key' has bad percent value.",
	],
);

# Test.
my $ret;
foreach my $right_percent (@RIGTH_PERCENTS) {
	$ret = sub_check_percent('20%', 'key');
	is($ret, undef, 'Get right percent value ('.$right_percent.').');
}

# Test.
foreach my $bad_percent_ar (@BAD_PERCENTS) {
	eval {
		sub_check_percent(@{$bad_percent_ar->[0]});
	};
	is($EVAL_ERROR, $bad_percent_ar->[1]."\n",
		$bad_percent_ar->[1]." Value is '$bad_percent_ar->[0]->[0]'.");
	my $err_msg_hr = err_msg_hr();
	my $value;
	if (defined $bad_percent_ar->[2]) {
		$value = $bad_percent_ar->[2];
	} else {
		$value = $bad_percent_ar->[0]->[0];
	}
	is($err_msg_hr->{'Value'}, $value,
		'Test error parameter (Value: '.$value.').');
	clean();
}
