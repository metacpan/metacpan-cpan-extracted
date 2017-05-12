use inc::Module::Install;

name     'Module-Install-AggressiveInclude';
all_from 'lib/Module/Install/AggressiveInclude.pm';
author   q{Jason M Mills <jmmills@cpan.org>};
license  'perl';

build_requires 'Test::More';
requires 'Module::Find';

auto_install;

WriteAll;

