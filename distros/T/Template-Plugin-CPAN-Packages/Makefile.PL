use inc::Module::Install;
include 'Module::AutoInstall';

name 'Template-Plugin-CPAN-Packages';
all_from 'lib/Template/Plugin/CPAN/Packages.pm';
perl_version '5.006';

requires 'Parse::CPAN::Packages';
requires 'Pod::Generated';
requires 'Template';

build_requires 'Test::Differences';
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
