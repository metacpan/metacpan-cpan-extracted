use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean err_msg_hr);
use Mo::utils::CSS qw(check_css_unit);
use Readonly;
use Test::More 'tests' => 29;
use Test::NoWarnings;

Readonly::Array our @RIGTH_UNITS => qw(123cm 123mm 123in 123px 123pt 123pc 123em
	123ex 123ch 123rem 123vw 123vh 123vmin 123vmax 10% 0.5em .5em);

# Test.
my ($ret, $self);
foreach my $right_unit (@RIGTH_UNITS) {
	$self = {
		'key' => $right_unit,
	};
	$ret = check_css_unit($self, 'key');
	is($ret, undef, 'Right CSS unit is present ('.$right_unit.').');
}

# Test.
$self = {
	'key' => undef,
};
$ret = check_css_unit($self, 'key');
is($ret, undef, 'Right CSS unit is present (undef).');

# Test.
$self = {};
$ret = check_css_unit($self, 'key');
is($ret, undef, 'Right CSS unit is present (key is not exists).');

# Test.
$self = {
	'key' => 'foo',
};
eval {
	check_css_unit($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' doesn't contain unit number.\n",
	"Parameter 'key' doesn't contain unit number.");
my $err_msg_hr = err_msg_hr();
is($err_msg_hr->{'Value'}, 'foo', 'Test error parameter (Value: foo).');
clean();

# Test.
$self = {
	'key' => '123',
};
eval {
	check_css_unit($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' doesn't contain unit name.\n",
	"Parameter 'key' doesn't contain unit name.");
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'Value'}, '123', 'Test error parameter (Value: 123).');
clean();

# Test.
$self = {
	'key' => '123xx',
};
eval {
	check_css_unit($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' contain bad unit.\n",
	"Parameter 'key' contain bad unit.");
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'Unit'}, 'xx', 'Test error parameter (Unit: xx).');
is($err_msg_hr->{'Value'}, '123xx', 'Test error parameter (Value: 123xx).');
clean();

# Test.
$self = {
	'key' => '.em',
};
eval {
	check_css_unit($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' doesn't contain unit number.\n",
	"Parameter 'key' doesn't contain unit number (.em).");
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'Value'}, '.em', 'Test error parameter (Value: .em).');
clean();
