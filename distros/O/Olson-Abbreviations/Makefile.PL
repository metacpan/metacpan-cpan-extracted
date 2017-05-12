use inc::Module::Install;

name     'Olson-Abbreviations';
all_from 'lib/Olson/Abbreviations.pm';
author   'Evan Carroll <me+cpan@evancarroll.com>';
license  'perl';

requires 'Moose';
requires 'MooseX::ClassAttribute' => '0.25';
requires 'namespace::autoclean';

test_requires 'Test::More';

repository 'git://github.com/EvanCarroll/olson-abbreviations.git';
homepage   'https://github.com/EvanCarroll/olson-abbreviations';

auto_install;

WriteAll;
