use inc::Module::Install;
include 'Module::AutoInstall';

name 'ShipIt-Step-Twitter';
all_from 'lib/ShipIt/Step/Twitter.pm';
perl_version '5.006';

requires 'Net::Twitter';
requires 'ShipIt';
requires 'YAML';

test_requires 'Test::More' => '0.70';
extra_tests;

auto_install;
auto_include;
WriteAll;
