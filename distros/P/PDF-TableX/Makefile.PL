use inc::Module::Install;

name     'PDF-TableX';
all_from 'lib/PDF/TableX.pm';
author   'Grzegorz Papkala <grzegorzpapkala@gmail.com>';
license  'perl';

requires 			 'PDF::API2';
requires			 'Moose';
requires			 'MooseX::Types';
requires			 'MooseX::Types::Moose';
requires 			 'Moose::Role';
build_requires 'Test::More';
repository     'https://github.com/grzegorzpapkala/PDF-TableX';

auto_install;

WriteAll;

