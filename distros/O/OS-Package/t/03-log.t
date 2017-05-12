use Test::More;

use OS::Package::Log;

isa_ok($LOGGER, 'Log::Log4perl::Logger');

done_testing;