use inc::Module::Install;

name 'MooseX-Types-CNPJ';
all_from 'lib/MooseX/Types/CNPJ.pm';

requires 'MooseX::Types';
requires 'Business::BR::CNPJ';

build_requires 'Test::Exception';
build_requires 'Test::More';
build_requires 'ok';

WriteAll();
