use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Random::Day;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Random::Day->new;
my $ret = $obj->random_month_year(2, 2022);
isa_ok($ret, 'DateTime');
like($ret, qr{^\d\d\d\d-02-\d\dT00:00:00$},
	'Random date for concrete month.');

# Test.
$obj = Random::Day->new;
eval {
	$obj->random_month_year(40, 2022);
};
is($EVAL_ERROR, "Cannot create DateTime object.\n",
	'Cannot create DateTime object.');
clean();
