# Pragmas.
use strict;
use warnings;

# Modules.
use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Random::Day;
use Test::More 'tests' => 7;
use Test::NoWarnings;

# Test.
my $obj = Random::Day->new;
my $ret = $obj->random_day(10);
isa_ok($ret, 'DateTime');
like($ret, qr{^\d\d\d\d-\d\d-10T00:00:00$}, 'Random date from day.');

# Test.
$obj = Random::Day->new;
eval {
	$obj->random_day(-10);
};
is($EVAL_ERROR, "Day isn't positive number.\n",
	"Test on negative number.");
clean();

# Test.
$obj = Random::Day->new;
$ret = $obj->random_day(10000);
is($ret, undef, 'Unknown day.');

# Test.
$obj = Random::Day->new;
eval {
	$obj->random_day(0);
};
is($EVAL_ERROR, "Day cannot be a zero.\n",
	"Day cannot be a zero.");
clean();

# Test.
$obj = Random::Day->new;
eval {
	$obj->random_day('foo');
};
is($EVAL_ERROR, "Day isn't positive number.\n",
	"Test on string.");
clean();
