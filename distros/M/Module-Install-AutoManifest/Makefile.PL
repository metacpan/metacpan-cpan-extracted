use inc::Module::Install;

name     'Module-Install-AutoManifest';
all_from 'lib/Module/Install/AutoManifest.pm';
author   'Hans Dieter Pearcey <hdp@cpan.org>';

build_requires 'Test::More';

extra_tests;
WriteAll;
