# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-Soma.t'

# Not very exciting testing

use Test;
BEGIN { plan tests => 3 };
eval "use Net::Soma";
ok($@ eq '');

no Net::Soma;
eval "use Net::Soma qw(ApplicationDef)";
ok($@ eq '');

no Net::Soma;
eval "use Net::Soma qw(BadClass)";
ok($@ ne '');


