use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Random::Day::InThePast;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $obj = Random::Day::InThePast->new;
my $ret = $obj->random_year(2020);
isa_ok($ret, 'DateTime');
like($ret, qr{^2020-\d\d-\d\dT00:00:00$},
	'Random date for concrete year (2020).');

# Test.
$obj = Random::Day::InThePast->new;
eval {
	$obj->random_year(1890);
};
is($EVAL_ERROR, "Year is lesser than minimal year.\n",
	"Year is lesser than minimal year (1890).");
clean();

# Test.
$obj = Random::Day::InThePast->new;
eval {
	$obj->random_year(2040);
};
is($EVAL_ERROR, "Year is greater than maximal year.\n",
	"Year is greater than maximal year (2040).");
clean();
