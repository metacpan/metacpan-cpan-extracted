use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Random::Day::InTheFuture;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $obj = Random::Day::InTheFuture->new;
my $ret = $obj->random_year(2050);
isa_ok($ret, 'DateTime');
like($ret, qr{^2050-\d\d-\d\dT00:00:00$},
	'Random date for concrete year (2050).');

# Test.
$obj = Random::Day::InTheFuture->new;
eval {
	$obj->random_year(2020);
};
is($EVAL_ERROR, "Year is lesser than minimal year.\n",
	"Year is lesser than minimal year (2020).");
clean();

# Test.
$obj = Random::Day::InTheFuture->new;
eval {
	$obj->random_year(2222);
};
is($EVAL_ERROR, "Year is greater than maximal year.\n",
	"Year is greater than maximal year (2222).");
clean();
