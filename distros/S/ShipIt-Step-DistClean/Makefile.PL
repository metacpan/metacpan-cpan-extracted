use inc::Module::Install;
name 'ShipIt-Step-DistClean';
all_from 'lib/ShipIt/Step/DistClean.pm';
perl_version '5.006';

requires 'ShipIt';
requires 'Dist::Joseki';

build_requires 'Test::More' => '0.70';

use_standard_tests(without => 'pod_coverage');
auto_include;
WriteAll;
