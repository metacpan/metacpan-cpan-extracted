
use inc::Module::Install;


name 'Regexp-NumRange';
all_from 'lib/Regexp/NumRange.pm';

requires 'Exporter'                      => '5.53';
test_requires 'Test::More'               => '0.96';
test_requires 'Math::Cartesian::Product' => '1.006';


WriteAll;

