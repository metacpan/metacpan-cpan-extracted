use inc::Module::Install;
name 'Sledge-SessionManager-Auto';
all_from 'lib/Sledge/SessionManager/Auto.pm';

requires $_ for (qw/ /);

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
