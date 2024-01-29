use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Mo::utils::CSS qw(check_css_unit);
use Readonly;
use Test::More 'tests' => 21;
use Test::NoWarnings;

Readonly::Array our @RIGTH_UNITS => qw(123cm 123mm 123in 123px 123pt 123pc 123em
	123ex 123ch 123rem 123vw 123vh 123vmin 123vmax 10%);

# Test.
my $self = {
	'key' => 'foo',
};
eval {
	check_css_unit($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' doesn't contain number.\n",
	"Parameter 'key' doesn't contain number.");
clean();

# Test.
$self = {
	'key' => '123',
};
eval {
	check_css_unit($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' doesn't contain unit.\n",
	"Parameter 'key' doesn't contain unit.");
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
clean();

# Test.
my $ret;
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
