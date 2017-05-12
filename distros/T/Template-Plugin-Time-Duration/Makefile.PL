use inc::Module::Install;

name     'Template-Plugin-Time-Duration';
all_from 'lib/Template/Plugin/Time/Duration.pm';
author   q{Cory G Watson <gphat@cpan.org>};
license  'perl';

build_requires 'Test::More';

requires 'Template';
requires 'Time::Duration';

WriteAll;

