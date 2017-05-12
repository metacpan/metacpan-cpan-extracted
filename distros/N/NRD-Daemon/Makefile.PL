use inc::Module::Install;

name 'NRD-Daemon';
version_from 'lib/NRD/Daemon.pm';
license 'gpl';
author  'Jose Luis Martinez (jlmartinez@capside.com)';
abstract 'Nagios Result Distributor';

requires 'Net::Server';
requires 'Net::CIDR';
requires 'JSON';
requires 'Scalar::Util';

recommends 'JSON::XS';
recommends 'Crypt::CBC';
recommends 'Crypt::Blowfish';

test_requires 'Test::Simple';
test_requires 'Clone';
test_requires 'Parallel::Forker';
test_requires 'Test::Memory::Cycle';
test_requires 'Crypt::CBC';
test_requires 'Crypt::Blowfish';


install_script 'bin/send_nrd';
install_script 'bin/nrd';

WriteAll;
