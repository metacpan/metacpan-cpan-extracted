use inc::Module::Install;
name 'SWF-Generator';
all_from 'lib/SWF/Generator.pm';

requires_external_bin 'swfmill';

requires 'Template';
requires 'IPC::Run';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
build_requires 'Test::Exception';
build_requires 'Path::Class';
build_requires 'Path::Class::Dir';
build_requires 'Path::Class::File';
use_test_base;
auto_include;
WriteAll;
