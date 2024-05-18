use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean err_msg_hr);
use Mo::utils::CSS qw(check_css_color);
use Readonly;
use Test::More 'tests' => 59;
use Test::NoWarnings;

Readonly::Array our @RIGTH_COLORS => (
	'red',
	'#F00', '#FF0000', '#FF000000',
	'rgb(255,0,0)', 'rgba(255,0,0,0.3)',
	'hsl(120, 100%, 50%)', 'hsla(120, 100%, 50%, 0.3)',
);

# Test.
my ($ret, $self);
foreach my $right_color (@RIGTH_COLORS) {
	$self = {
		'key' => $right_color,
	};
	$ret = check_css_color($self, 'key');
	is($ret, undef, 'Right CSS color is present ('.$right_color.').');
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

# Test.
$self = {
	'key' => 'xxx',
};
eval {
	check_css_color($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' has bad color name.\n",
	"Parameter 'key' has bad color name.");
my $err_msg_hr = err_msg_hr();
is($err_msg_hr->{'Value'}, 'xxx', 'Test error parameter (Value: xxx).');
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
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'Value'}, '#1', 'Test error parameter (Value: #1).');
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
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'Value'}, '#GGG', 'Test error parameter (Value: #GGG).');
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
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'Value'}, 'rgb(255,0)',
	'Test error parameter (Value: rgb(255,0)).');
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
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'Value'}, 'rgb(255,0,0,0.5)',
	'Test error parameter (Value: rgb(255,0,0,0.5)).');
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
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'Value'}, 'rgb(255,0,256)',
	'Test error parameter (Value: rgb(255,0,256)).');
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
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'Value'}, 'rgb(255,0,bad)',
	'Test error parameter (Value: rgb(255,0,bad)).');
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
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'Value'}, 'rgba(255,0,0)',
	'Test error parameter (Value: rgba(255,0,0)).');
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
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'Value'}, 'rgba(255,0,0,0.5,5)',
	'Test error parameter (Value: rgba(255,0,0,0.5,5)).');
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
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'Value'}, 'rgba(255,0,0,1.5)',
	'Test error parameter (Value: rgba(255,0,0,1.5)).');
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
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'Value'}, 'rgba(255,0,0,bad)',
	'Test error parameter (Value: rgba(255,0,0,bad)).');
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
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'Value'}, 'rgba(255,0,256,0.3)',
	'Test error parameter (Value: rgba(255,0,256,0.3)).');
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
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'Value'}, 'rgba(255,0,bad,0.3)',
	'Test error parameter (Value: rgba(255,0,bad,0.3)).');
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
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'Value'}, 'hsl(120,100%)',
	'Test error parameter (Value: hsl(120,100%)).');
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
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'Value'}, 'hsl(120,100%,50%,0.5)',
	'Test error parameter (Value: hsl(120,100%,50%,0.5)).');
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
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'Value'}, 'hsl(370,100%,50%)',
	'Test error parameter (Value: hsl(370,100%,50%)).');
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
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'Value'}, 'hsl(bad,100%,50%)',
	'Test error parameter (Value: hsl(bad,100%,50%)).');
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
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'Value'}, 'hsl(120,100,50%)',
	'Test error parameter (Value: hsl(120,100,50%)).');
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
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'Value'}, 'hsl(120,120%,50%)',
	'Test error parameter (Value: hsl(120,120%,50%)).');
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
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'Value'}, 'hsl(120,bad,50%)',
	'Test error parameter (Value: hsl(120,bad,50%)).');
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
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'Value'}, 'hsla(120,100%,50%)',
	'Test error parameter (Value: hsla(120,100%,50%)).');
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
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'Value'}, 'hsla(120,100%,50%,0.5,5)',
	'Test error parameter (Value: hsla(120,100%,50%,0.5,5)).');
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
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'Value'}, 'hsla(120,100%,50%,1.5)',
	'Test error parameter (Value: hsla(120,100%,50%,1.5)).');
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
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'Value'}, 'hsla(120,100%,50%,bad)',
	'Test error parameter (Value: hsla(120,100%,50%,bad)).');
clean();
