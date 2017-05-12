use inc::Module::Install;
include 'Module::AutoInstall';

name 'Module-Install-Homepage';
all_from 'lib/Module/Install/Homepage.pm';

homepage 'http://search.cpan.org/dist/Module-Install-Homepage/';
bugtracker 'http://rt.cpan.org/Public/Dist/Display.html?Name=Module-Install-Homepage';
auto_set_repository;

requires 'Module::Install';

test_requires 'Test::More' => '0.70';
extra_tests;

author_requires 'ShipIt';
author_requires 'ShipIt::Step::DistClean';
author_requires 'ShipIt::Step::DistTestExtra';
author_requires 'ShipIt::Step::Manifest';
author_requires 'ShipIt::Step::Twitter';
author_requires 'Test::Compile';
author_requires 'Test::Perl::Critic';
author_requires 'Test::Pod';
author_requires 'Test::Spelling';
author_requires 'Pod::Wordlist::hanekomu';
author_requires 'Test::Pod::Coverage';
# author_requires 'Test::Kwalitee';  # # Attempt to free unreferenced scalar
author_requires 'Test::YAML::Meta';
author_requires 'Test::Portability::Files';
author_requires 'Test::Synopsis';

auto_install;
auto_include;
WriteAll;
