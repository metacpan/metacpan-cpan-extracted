use inc::Module::Install;
name 'Module-Install-ShareFile';
all_from 'lib/Module/Install/ShareFile.pm';
readme_pod_from 'lib/Module/Install/ShareFile.pm';

requires 'Module::Install', '1.00';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
test_requires 'Test::Requires';
auto_set_repository;
#auto_include;
WriteAll;
