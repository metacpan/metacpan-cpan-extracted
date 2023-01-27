use strict;
use warnings;

use Random::Day::InThePast;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Random::Day::InThePast->new;
my $ret = $obj->random;
like($ret, qr{^\d\d\d\d-\d\d-\d\dT00:00:00$}, 'Random on default object.');
