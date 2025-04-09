use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean err_msg_hr);
use Mo::utils::Number qw(check_percent);
use Readonly;
use Test::More 'tests' => 13;
use Test::NoWarnings;

Readonly::Hash our %BAD_NUMBERS => (
	'10' => "Parameter 'key' has bad percent value (missing %).",
	'-10' => "Parameter 'key' has bad percent value.",
	'foo' => "Parameter 'key' has bad percent value.",
	'110%' => "Parameter 'key' has bad percent value.",
);
Readonly::Array our @RIGHT_NUMBERS => qw(
	10%
	11.5%
);

# Test.
my ($self, $ret);
foreach my $number (@RIGHT_NUMBERS) {
	$self = {
		'key' => $number,
	};
	$ret = check_percent($self, 'key');
	is($ret, undef, 'Right number is present ('.$number.').');
}

# Test.
$self = {};
$ret = check_percent($self, 'key');
is($ret, undef, 'Right not exist key.');

# Test.
$self = {
	'key' => undef,
};
$ret = check_percent($self, 'key');
is($ret, undef, "Value is undefined, that's ok.");

# Test.
foreach my $bad_percent (sort keys %BAD_NUMBERS) {
	$self = {
		'key' => $bad_percent,
	};
	eval {
		check_percent($self, 'key');
	};
	is($EVAL_ERROR, $BAD_NUMBERS{$bad_percent}."\n",
		$BAD_NUMBERS{$bad_percent}." Value is '$bad_percent'.");
	my $err_msg_hr = err_msg_hr();
	is($err_msg_hr->{'Value'}, $bad_percent, 'Test error parameter (Value: '.$bad_percent.').');
	clean();
}
