use inc::Module::Install;
name 'Template-Plugin-Timer';
license 'MIT';
all_from 'lib/Template/Plugin/Timer.pm';

requires $_ for (qw/
    Template
    Benchmark::Timer
/);

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
