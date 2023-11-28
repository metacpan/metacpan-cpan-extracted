use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Mo::utils qw(check_regexp);
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $self = {
	'key' => 'http://example.com/foo',
};
eval {
	check_regexp($self, 'key', qr{^http://example\.com/\d+$});
};
is($EVAL_ERROR, "Parameter 'key' does not match the specified regular expression.\n",
	"Parameter 'key' does not match the specified regular expression.");
clean();

# Test.
$self = {
	'key' => 'http://example.com/1',
};
my $ret = check_regexp($self, 'key', qr{^http://example\.com/\d+$});
is($ret, undef, 'Right string is present (http://example.com/1).');

# Test.
$self = {
	'key' => undef,
};
$ret = check_regexp($self, 'key', qr{^http://example\.com/\d+$});
is($ret, undef, "Value is undefined, that's ok.");

# Test.
$self = {
	'key' => 'http://example.com/foo',
};
eval {
	check_regexp($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' must have defined regexp.\n",
	"Parameter 'key' must have defined regexp.");
clean();
