use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Mo::utils qw(check_string_begin);
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $self = {
	'key' => 'http://example/foo',
};
eval {
	check_string_begin($self, 'key', 'http://example.com/');
};
is($EVAL_ERROR, "Parameter 'key' must begin with defined string base.\n",
	"Parameter 'key' must begin with defined string base.");
clean();

# Test.
$self = {
	'key' => 'http://example.com/foo',
};
my $ret = check_string_begin($self, 'key', 'http://example.com/');
is($ret, undef, 'Right string is present (http://example.com/foo).');

# Test.
$self = {
	'key' => undef,
};
$ret = check_string_begin($self, 'key', 'http://example.com/');
is($ret, undef, "Value is undefined, that's ok.");

# Test.
$self = {
	'key' => 'http://example.com/foo',
};
eval {
	check_string_begin($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' must have defined string base.\n",
	"Parameter 'key' must have defined string base.");
clean();
