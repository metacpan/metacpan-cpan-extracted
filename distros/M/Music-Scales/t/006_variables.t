# -*- perl -*-

# t/006_variables.t - check that variables are exported

use Test::Simple tests => 3;
use Music::Scales qw(%modes %abbrevs @scales);

ok(keys %modes);
ok(keys %abbrevs);
ok(@scales);

