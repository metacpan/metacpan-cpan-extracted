use inc::Module::Install;

name           'Moose-Test';
all_from       'lib/Moose/Test.pm';

requires 'Path::Class';

build_requires 'Test::More';
build_requires 'Mouse';

WriteAll;

