use strict;
use warnings;

use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Random::Day::InTheFuture;
use Test::More 'tests' => 9;
use Test::NoWarnings;

# Test.
my $obj = Random::Day::InTheFuture->new;
my $year_plus = (localtime)[5] + 1901;
my $ret = $obj->random_day_month_year(10, 10, $year_plus);
isa_ok($ret, 'DateTime');
like($ret, qr{^$year_plus-10-10T00:00:00$},
	'Right date from day, month and year informations (10-10-'.$year_plus.').');

# Test.
$obj = Random::Day::InTheFuture->new;
eval {
	$obj->random_day_month_year(-10, 10, 2014);
};
is($EVAL_ERROR, "Day isn't positive number.\n",
	"Test on negative number.");
clean();

# Test.
$obj = Random::Day::InTheFuture->new;
eval {
	$obj->random_day_month_year(0, 10, 2014);
};
is($EVAL_ERROR, "Day cannot be a zero.\n",
	"Day cannot be a zero.");
clean();

# Test.
$obj = Random::Day::InTheFuture->new;
eval {
	$obj->random_day_month_year('foo', 10, 2014);
};
is($EVAL_ERROR, "Day isn't positive number.\n",
	"Test on string.");
clean();

# Test.
$obj = Random::Day::InTheFuture->new;
eval {
	$obj->random_day_month_year(40, 10, 2014);
};
is($EVAL_ERROR, "Cannot create DateTime object.\n",
	'Cannot create DateTime object.');
clean();

# Test.
$obj = Random::Day::InTheFuture->new;
my $year_minus = (localtime)[5] + 1899;
eval {
	$obj->random_day_month_year(10, 10, $year_minus);
};
is($EVAL_ERROR, "Begin of expected month is lesser than minimal date.\n",
	'Begin of expected month is lesser than minimal date (10-10-'.$year_minus.').');
clean();

# Test.
$obj = Random::Day::InTheFuture->new;
eval {
	$obj->random_day_month_year(10, 10, 2100);
};
is($EVAL_ERROR, "End of expected month is greater than maximal date.\n",
	'End of expected month is greater than maximal date (10-10-2100).');
clean();
