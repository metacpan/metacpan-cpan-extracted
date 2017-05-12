use inc::Module::Install;
name 'ShipIt-Step-CommitMessageWrap';
all_from 'lib/ShipIt/Step/CommitMessageWrap.pm';

requires $_ for (qw/ ShipIt /);

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
