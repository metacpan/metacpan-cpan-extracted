use inc::Module::Install;
name 'ShipIt-Step-CheckYAMLChangeLog';
all_from 'lib/ShipIt/Step/CheckYAMLChangeLog.pm';
perl_version '5.006';

requires 'ShipIt';
requires 'Module::Changes' => '0.02';

build_requires 'Test::More' => '0.70';

use_standard_tests(without => 'pod_coverage');
auto_include;
WriteAll;
