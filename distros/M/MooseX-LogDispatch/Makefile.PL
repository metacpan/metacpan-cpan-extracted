use inc::Module::Install '0.68';

name 'MooseX-LogDispatch';
all_from 'lib/MooseX/LogDispatch.pm';

build_requires 'IO::Scalar';
build_requires 'Test::More';
build_requires 'Test::Exception';

requires 'Moose';
requires 'Log::Dispatch::Configurator';

auto_install;
WriteAll;
