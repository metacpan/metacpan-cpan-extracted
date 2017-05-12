# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-Prizm.t'

# Not very exciting testing

use Test;
BEGIN { plan tests => 3 };
eval "use Net::Prizm";
ok($@ eq '');

no Net::Prizm;
eval "use Net::Prizm qw(PrizmElement)";
ok($@ eq '');

no Net::Prizm;
eval "use Net::Prizm qw(BadClass)";
ok($@ ne '');


