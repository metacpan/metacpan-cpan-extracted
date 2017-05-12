use inc::Module::Install;

name     'Module-Install-DBICx-AutoDoc';
all_from 'lib/Module/Install/DBICx/AutoDoc.pm';
author   'Jason M. Mills <jmmills at cpan.org>';
module_name 'Module-Install-DBICx-AutoDoc';
license 'perl';

requires 'DBICx::AutoDoc';

build_requires 'Test::More';

auto_manifest;
auto_install;

WriteAll;

