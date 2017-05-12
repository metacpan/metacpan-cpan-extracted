# Pragmas.
use strict;
use warnings;

# Modules.
use inc::Module::Install;

# Definition.
abstract 'Install the Mock::Person modules.';
author 'Michal Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.08;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Task-Mock-Person';
readme_from 'Person.pm';
recursive_author_tests('xt');
requires 'Mock::Person' => '1.1.0';
requires 'Mock::Person::CZ' => 0.04;
requires 'Mock::Person::DE' => 0.05;
requires 'Mock::Person::EN' => 0.04;
requires 'Mock::Person::JP' => 0.07;
requires 'Mock::Person::SK' => 0.04;
requires 'Mock::Person::SK::ROM' => 0.02;
requires 'Mock::Person::SV' => 0.03;
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=Task-Mock-Person';
resources 'homepage' => 'https://github.com/tupinek/Task-Mock-Person';
resources 'repository' => 'git://github.com/tupinek/Task-Mock-Person';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.03';

# Run.
WriteAll();
