use inc::Module::Install;

name     'Template-Plugin-Devel-StackTrace';
all_from 'lib/Template/Plugin/Devel/StackTrace.pm';
author   'Samuel Kaufman <skaufman@cpan.org>';

build_requires 'Test::More';
requires 'Devel::StackTrace';
requires 'Template' => '2.22';

auto_install;

WriteAll;

