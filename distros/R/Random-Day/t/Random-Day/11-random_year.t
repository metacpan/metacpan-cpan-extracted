use strict;
use warnings;

use Random::Day;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Random::Day->new;
my $ret = $obj->random_year(2020);
isa_ok($ret, 'DateTime');
like($ret, qr{^2020-\d\d-\d\dT00:00:00$},
	'Random date for concrete year.');
