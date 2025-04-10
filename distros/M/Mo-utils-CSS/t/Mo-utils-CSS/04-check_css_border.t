use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean err_msg_hr);
use Mo::utils::CSS qw(check_css_border);
use Readonly;
use Test::More 'tests' => 69;
use Test::NoWarnings;

Readonly::Array our @RIGTH_BORDERS => (
	# Global values.
	'inherit',
	'initial',
	'revert',
	'revert-layer',
	'unset',

	# [width] style [color]
	'solid',
	'2px solid',
	'solid red',
	'thin solid',
	'2px solid red',
	'thin solid red',
	'medium dashed blue',
	'thick dotted green',
	'1em double #00ff00',
	'1em double #F00',
	'1em double #FF000000',
	'1rem double rgb(255,0,0)',
	'1em double rgba(255,0,0,0.3)',
	'1em double hsl(120, 100%, 50%)',
	'1em double hsl(120, 99.5%, 50.5%)',
	'1em double hsla(120, 100%, 50%, 0.3)',
	'1em double hsla(120, 99.5%, 50.5%, 0.3)',
);
Readonly::Hash our %BAD_BORDERS => (
	# Common issues.
	'0.3em 0 9px solid red' => "Parameter 'key' has bad border style.",
	'bad' => "Parameter 'key' has bad border style.",
	'2px red' => "Parameter 'key' hasn't border style.",

	# Bad width.
	'123 solid' => "Parameter 'key' doesn't contain unit name.",
	'123xx solid' => "Parameter 'key' contain bad unit.",
	'px solid' => "Parameter 'key' doesn't contain unit number.",

	# Bad color.
	'solid foo' => "Parameter 'key' has bad color name.",
	'solid #1' => "Parameter 'key' has bad rgb color (bad length).",
	'solid #GGG' => "Parameter 'key' has bad rgb color (bad hex number).",
	'solid rgb(255,0)' => "Parameter 'key' has bad rgb color (bad number of arguments).",
	'solid rgb(255,0,256)' => "Parameter 'key' has bad rgb color (bad number).",
	'solid rgba(255,0,0)' => "Parameter 'key' has bad rgba color (bad number of arguments).",
	'solid rgba(255,0,0,1.5)' => "Parameter 'key' has bad rgba alpha.",
	'solid rgba(255,0,256,0.3)' => "Parameter 'key' has bad rgba color (bad number).",
	'solid hsl(120,100%)' => "Parameter 'key' has bad hsl color (bad number of arguments).",
	'solid hsl(370,100%,50%)' => "Parameter 'key' has bad hsl degree.",
	'solid hsl(120,100,50%)' => "Parameter 'key' has bad hsl percent (missing %).",
	'solid hsl(120,120%,50%)' => "Parameter 'key' has bad hsl percent.",
	'solid hsla(120,100%,50%)' => "Parameter 'key' has bad hsla color (bad number of arguments).",
	'solid hsla(120,100%,50%,1.5)' => "Parameter 'key' has bad hsla alpha.",
	'solid hsla(120,100,50%,0.3)' => "Parameter 'key' has bad hsla percent (missing %).",
	'solid hsla(120,120%,50%,0.3)' => "Parameter 'key' has bad hsla percent.",
);

# Test.
my ($ret, $self);
foreach my $right_border (@RIGTH_BORDERS) {
	$self = {
		'key' => $right_border,
	};
	$ret = check_css_border($self, 'key');
	is($ret, undef, 'Right CSS border is present ('.$right_border.').');
}

# Test.
$self = {
	'key' => undef,
};
$ret = check_css_border($self, 'key');
is($ret, undef, 'Right CSS border is present (undef).');

# Test.
$self = {};
$ret = check_css_border($self, 'key');
is($ret, undef, 'Right CSS border is present (key is not exists).');

# Test.
foreach my $bad_border (sort keys %BAD_BORDERS) {
	$self = {
		'key' => $bad_border,
	};
	eval {
		check_css_border($self, 'key');
	};
	is($EVAL_ERROR, $BAD_BORDERS{$bad_border}."\n",
		$BAD_BORDERS{$bad_border}." Value is '$bad_border'.");
	my $err_msg_hr = err_msg_hr();
	is($err_msg_hr->{'Value'}, $bad_border, 'Test error parameter (Value: '.$bad_border.').');
	clean();
}
