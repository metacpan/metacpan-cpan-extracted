use inc::Module::Install;

name 'MooseX-Types-CPF';
all_from 'lib/MooseX/Types/CPF.pm';

requires 'MooseX::Types';
requires 'Business::BR::CPF';

build_requires 'Test::Exception';
build_requires 'Test::More';
build_requires 'ok';

WriteAll();
