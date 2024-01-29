use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Mo::utils::CSS qw(check_array_css_color);
use Test::MockObject;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $self = {
	'key' => 'foo',
};
eval {
	check_array_css_color($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' must be a array.\n",
	"Parameter 'key' must be a array.");
clean();

# Test.
$self = {
	'key' => ['foo'],
};
eval {
	check_array_css_color($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' has bad color name.\n",
	"Parameter 'key' has bad color name.");
clean();

# Test.
$self = {
	'key' => [
		'red',
		'#F00', '#FF0000', '#FF000000',
		'rgb(255,0,0)', 'rgba(255,0,0,0.3)',
		'hsl(120, 100%, 50%)', 'hsla(120, 100%, 50%, 0.3)',
	],
};
my $ret = check_array_css_color($self, 'key');
is($ret, undef, 'Right structure.');

# Test.
$self = {};
$ret = check_array_css_color($self, 'key');
is($ret, undef, 'Right not exist key.');
