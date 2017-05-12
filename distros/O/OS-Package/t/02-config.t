use Test::More;

use OS::Package::Config;

isa_ok($OSPKG_CONFIG, 'Hash::AsObject');

done_testing;
