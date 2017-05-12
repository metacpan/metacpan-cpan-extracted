use inc::Module::Install;

name     'Net-LimeLight-Purge';
all_from 'lib/Net/LimeLight/Purge.pm';
author   'Cory G Watson <gphat@cpan.org>';
license  'perl';

build_requires 'Test::More';

requires 'DateTime::Format::ISO8601' => '0.06';
requires 'Moose' => '0.72';
requires 'MooseX::AttributeHelpers' => '0.14';
requires 'SOAP::Lite' => '0.710.08';

WriteAll;

