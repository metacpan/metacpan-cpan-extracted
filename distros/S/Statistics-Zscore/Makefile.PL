use inc::Module::Install;
name 'Statistics-Zscore';
all_from 'lib/Statistics/Zscore.pm';

requires 'Statistics::Lite';
build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
