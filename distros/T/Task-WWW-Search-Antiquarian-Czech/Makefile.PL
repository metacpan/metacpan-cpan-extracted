# Pragmas.
use strict;
use warnings;

# Modules.
use inc::Module::Install;

# Definition.
abstract 'Install the WWW::Search modules for Czech antiquarian bookstores.';
author 'Michal Spacek <skim@cpan.org>';
license 'bsd';
name 'Task-WWW-Search-Antiquarian-Czech';
readme_from 'Czech.pm';
requires 'WWW::Search::Antikvariat11CZ' => 0.01;
requires 'WWW::Search::AntikvariatJudaicaCZ' => 0.01;
requires 'WWW::Search::GalerieIlonkaCZ' => 0.01;
requires 'WWW::Search::KacurCZ' => 0.01;
requires 'WWW::Search::MelcerCZ' => 0.01;
requires 'WWW::Search::ValentinskaCZ' => 0.02;
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=Task-WWW-Search-Antiquarian-Czech';
resources 'homepage' => 'https://github.com/tupinek/Task-WWW-Search-Antiquarian-Czech';
resources 'repository' => 'git://github.com/tupinek/Task-WWW-Search-Antiquarian-Czech';
test_requires 'English' => 0;
test_requires 'File::Object' => 0.08;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Pod' => 0;
test_requires 'Test::Pod::Coverage' => 0;
tests_recursive;
version '0.01';

# Run.
WriteAll();
