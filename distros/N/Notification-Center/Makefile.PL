use inc::Module::Install;

name     'Notification-Center';
all_from 'lib/Notification/Center.pm';
author   'Robert Boone <rlb@cpan.org>';
license  'Perl';

requires 'Moose';
requires 'Set::Object';

build_requires 'Test::More';
build_requires 'Bread::Board';

auto_install;

WriteAll;

