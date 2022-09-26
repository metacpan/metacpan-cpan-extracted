use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Mo::utils qw(check_code);

# Test.
my $self = {
	'key' => sub {},
};
my $ret = check_code($self, 'key');
is($ret, undef, 'Right code value.');

# Test.
$self = {
	'key' => 'bad',
};
eval {
	check_code($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' must be a code.\n",
	"Parameter 'key' must be a code.");
clean();
