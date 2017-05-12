use inc::Module::Install;
name 'POE-Component-RemoteTail';
all_from 'lib/POE/Component/RemoteTail.pm';

requires 'POE';
requires 'POE::Wheel::Run';
requires 'Class::Inspector';
requires 'constant';
requires 'UNIVERSAL::require';
requires 'Debug::STDERR';
build_requires 'Test::More';
build_requires 'YAML';
build_requires 'List::Util';

use_test_base;
auto_include;
WriteAll;
