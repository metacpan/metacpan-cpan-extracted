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
my $ret = $obj->random_day_month_year(10, 10, 2014);
isa_ok($ret, 'DateTime');
like($ret, qr{^2014-10-10T00:00:00$},
	'Right date from day, month and year informations.');

# Test.
$obj = Random::Day->new;
eval {
	$obj->random_day_month_year(-10, 10, 2014);
};
is($EVAL_ERROR, "Day isn't positive number.\n",
	"Test on negative number.");
clean();

# Test.
$obj = Random::Day->new;
eval {
	$obj->random_day_month_year(0, 10, 2014);
};
is($EVAL_ERROR, "Day cannot be a zero.\n",
	"Day cannot be a zero.");
clean();

# Test.
$obj = Random::Day->new;
eval {
	$obj->random_day_month_year('foo', 10, 2014);
};
is($EVAL_ERROR, "Day isn't positive number.\n",
	"Test on string.");
clean();

# Test.
$obj = Random::Day->new;
eval {
	$obj->random_day_month_year(40, 10, 2014);
};
is($EVAL_ERROR, "Cannot create DateTime object.\n",
	'Cannot create DateTime object.');
clean();
