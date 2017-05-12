# Pragmas.
use strict;
use warnings;

# Modules.
use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Random::Day;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = Random::Day->new;
my $ret = $obj->get;
like($ret, qr{^\d\d\d\d-\d\d-\d\dT00:00:00$}, 'Get on default object.');
