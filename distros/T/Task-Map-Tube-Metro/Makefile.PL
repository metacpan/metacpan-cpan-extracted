# Pragmas.
use strict;
use warnings;

# Modules.
use inc::Module::Install;

# Definition.
abstract 'Install the Map::Tube concrete metro modules.';
author 'Michal Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.08;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
license 'artistic_2';
name 'Task-Map-Tube-Metro';
readme_from 'Metro.pm';
recursive_author_tests('xt');
requires 'Map::Tube::Barcelona' => 0.37;
requires 'Map::Tube::Beijing' => 0.01;
requires 'Map::Tube::Berlin' => 0.14;
requires 'Map::Tube::Bucharest' => 0.08;
requires 'Map::Tube::Budapest' => 0.04;
requires 'Map::Tube::Delhi' => 0.43;
requires 'Map::Tube::Dnipropetrovsk' => 0.05;
requires 'Map::Tube::Glasgow' => 0.07;
requires 'Map::Tube::Kazan' => 0.04;
requires 'Map::Tube::Kharkiv' => 0.05;
requires 'Map::Tube::Kiev' => 0.05;
requires 'Map::Tube::KoelnBonn' => 0.09;
requires 'Map::Tube::KualaLumpur' => 0.05;
requires 'Map::Tube::London' => 0.75;
requires 'Map::Tube::Lyon' => 0.06;
requires 'Map::Tube::Malaga' => 0.15;
requires 'Map::Tube::Minsk' => 0.05;
requires 'Map::Tube::Moscow' => 0.07;
requires 'Map::Tube::NYC' => 0.33;
requires 'Map::Tube::Nanjing' => 0.04;
requires 'Map::Tube::NizhnyNovgorod' => 0.03;
requires 'Map::Tube::Novosibirsk' => 0.03;
requires 'Map::Tube::Prague' => 0.13;
requires 'Map::Tube::SaintPetersburg' => 0.06;
requires 'Map::Tube::Samara' => 0.06;
requires 'Map::Tube::Singapore' => 0.03;
requires 'Map::Tube::Sofia' => 0.07;
requires 'Map::Tube::Tbilisi' => 0.04;
requires 'Map::Tube::Tokyo' => 0.22;
requires 'Map::Tube::Vienna' => 0.07;
requires 'Map::Tube::Warsaw' => 0.06;
requires 'Map::Tube::Yekaterinburg' => 0.05;
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=Task-Map-Tube-Metro';
resources 'homepage' => 'https://github.com/tupinek/Task-Map-Tube-Metro';
resources 'repository' => 'git://github.com/tupinek/Task-Map-Tube-Metro';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.12';

# Run.
WriteAll();
