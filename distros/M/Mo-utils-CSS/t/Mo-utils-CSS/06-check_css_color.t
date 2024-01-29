use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Mo::utils::CSS qw(check_css_color);
use Readonly;
use Test::More 'tests' => 35;
use Test::NoWarnings;

Readonly::Array our @RIGTH_UNITS => (
	'red',
	'#F00', '#FF0000', '#FF000000',
	'rgb(255,0,0)', 'rgba(255,0,0,0.3)',
	'hsl(120, 100%, 50%)', 'hsla(120, 100%, 50%, 0.3)',
);

# Test.
my $self = {
	'key' => 'xxx',
};
eval {
	check_css_color($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' has bad color name.\n",
	"Parameter 'key' has bad color name.");
clean();

# Test.
$self = {
	'key' => '#1',
};
eval {
	check_css_color($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' has bad rgb color (bad length).\n",
	"Parameter 'key' has bad rgb color (bad length).");
clean();

# Test.
$self = {
	'key' => '#GGG',
};
eval {
	check_css_color($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' has bad rgb color (bad hex number).\n",
	"Parameter 'key' has bad rgb color (bad hex number).");
clean();

# Test.
$self = {
	'key' => 'rgb(255,0)',
};
eval {
	check_css_color($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' has bad rgb color (bad number of arguments).\n",
	"Parameter 'key' has bad rgb color (bad number of arguments = 2).");
clean();

# Test.
$self = {
	'key' => 'rgb(255,0,0,0.5)',
};
eval {
	check_css_color($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' has bad rgb color (bad number of arguments).\n",
	"Parameter 'key' has bad rgb color (bad number of arguments = 4).");
clean();

# Test.
$self = {
	'key' => 'rgb(255,0,256)',
};
eval {
	check_css_color($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' has bad rgb color (bad number).\n",
	"Parameter 'key' has bad rgb color (bad number = 256).");
clean();

# Test.
$self = {
	'key' => 'rgb(255,0,bad)',
};
eval {
	check_css_color($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' has bad rgb color (bad number).\n",
	"Parameter 'key' has bad rgb color (bad number = bad).");
clean();

# Test.
$self = {
	'key' => 'rgba(255,0,0)',
};
eval {
	check_css_color($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' has bad rgba color (bad number of arguments).\n",
	"Parameter 'key' has bad rgba color (bad number of arguments = 3).");
clean();

# Test.
$self = {
	'key' => 'rgba(255,0,0,0.5,5)',
};
eval {
	check_css_color($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' has bad rgba color (bad number of arguments).\n",
	"Parameter 'key' has bad rgba color (bad number of arguments = 5).");
clean();

# Test.
$self = {
	'key' => 'rgba(255,0,0,1.5)',
};
eval {
	check_css_color($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' has bad rgba alpha.\n",
	"Parameter 'key' has bad rgba alpha (1.5).");
clean();

# Test.
$self = {
	'key' => 'rgba(255,0,0,bad)',
};
eval {
	check_css_color($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' has bad rgba alpha.\n",
	"Parameter 'key' has bad rgba alpha (bad).");
clean();

# Test.
$self = {
	'key' => 'rgba(255,0,256,0.3)',
};
eval {
	check_css_color($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' has bad rgba color (bad number).\n",
	"Parameter 'key' has bad rgba color (bad number = 256).");
clean();

# Test.
$self = {
	'key' => 'rgba(255,0,bad,0.3)',
};
eval {
	check_css_color($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' has bad rgba color (bad number).\n",
	"Parameter 'key' has bad rgba color (bad number = bad).");
clean();

# Test.
$self = {
	'key' => 'hsl(120,100%)',
};
eval {
	check_css_color($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' has bad hsl color (bad number of arguments).\n",
	"Parameter 'key' has bad hsl color (bad number of arguments = 2).");
clean();

# Test.
$self = {
	'key' => 'hsl(120,100%,50%,0.5)',
};
eval {
	check_css_color($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' has bad hsl color (bad number of arguments).\n",
	"Parameter 'key' has bad hsl color (bad number of arguments = 4).");
clean();

# Test.
$self = {
	'key' => 'hsl(370,100%,50%)',
};
eval {
	check_css_color($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' has bad hsl degree.\n",
	"Parameter 'key' has bad hsl degree (370).");
clean();

# Test.
$self = {
	'key' => 'hsl(bad,100%,50%)',
};
eval {
	check_css_color($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' has bad hsl degree.\n",
	"Parameter 'key' has bad hsl degree (bad).");
clean();

# Test.
$self = {
	'key' => 'hsl(120,100,50%)',
};
eval {
	check_css_color($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' has bad hsl percent (missing %).\n",
	"Parameter 'key' has bad hsl percent (missing % = 100).");
clean();

# Test.
$self = {
	'key' => 'hsl(120,120%,50%)',
};
eval {
	check_css_color($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' has bad hsl percent.\n",
	"Parameter 'key' has bad hsl percent (120%).");
clean();

# Test.
$self = {
	'key' => 'hsl(120,bad,50%)',
};
eval {
	check_css_color($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' has bad hsl percent.\n",
	"Parameter 'key' has bad hsl percent (bad).");
clean();

# Test.
$self = {
	'key' => 'hsla(120,100%,50%)',
};
eval {
	check_css_color($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' has bad hsla color (bad number of arguments).\n",
	"Parameter 'key' has bad hsla color (bad number of arguments = 3).");
clean();

# Test.
$self = {
	'key' => 'hsla(120,100%,50%,0.5,5)',
};
eval {
	check_css_color($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' has bad hsla color (bad number of arguments).\n",
	"Parameter 'key' has bad hsla color (bad number of arguments = 5).");
clean();

# Test.
$self = {
	'key' => 'hsla(120,100%,50%,1.5)',
};
eval {
	check_css_color($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' has bad hsla alpha.\n",
	"Parameter 'key' has bad hsla alpha (1.5).");
clean();

# Test.
$self = {
	'key' => 'hsla(120,100%,50%,bad)',
};
eval {
	check_css_color($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' has bad hsla alpha.\n",
	"Parameter 'key' has bad hsla alpha (bad).");
clean();

# Test.
my $ret;
foreach my $right_unit (@RIGTH_UNITS) {
	$self = {
		'key' => $right_unit,
	};
	$ret = check_css_color($self, 'key');
	is($ret, undef, 'Right CSS color is present ('.$right_unit.').');
}

# Test.
$self = {
	'key' => undef,
};
$ret = check_css_color($self, 'key');
is($ret, undef, 'Right CSS color is present (undef).');

# Test.
$self = {};
$ret = check_css_color($self, 'key');
is($ret, undef, 'Right CSS color is present (key is not exists).');
