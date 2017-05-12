use inc::Module::Install;
include 'Module::AutoInstall';

name 'ShipIt-Step-ApplyYAMLChangeLogVersion';
all_from 'lib/ShipIt/Step/ApplyYAMLChangeLogVersion.pm';
perl_version '5.006';

requires 'Dist::Joseki' => '0.08';
requires 'ShipIt';

build_requires 'Test::More' => '0.70';

process_templates(
    first_year => 2007,
    rest_from  => "$ENV{HOME}/.mitlib/standard_pod",
    start_tag  => '{%',
    end_tag    => '%}',
);

use_standard_tests(without => 'pod_coverage');
auto_install;
auto_include;
WriteAll;
