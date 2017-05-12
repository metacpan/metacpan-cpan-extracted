# Pragmas.
use strict;
use warnings;

# Modules.
use inc::Module::Install;

# Definition.
abstract 'Install the HL7 modules.';
author 'Michal Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.08;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Task-HL7';
readme_from 'HL7.pm';
recursive_author_tests('xt');
requires 'App::HL7::Dump' => 0.02;
requires 'App::HL7::Send' => 0.01;
requires 'Net::HL7' => 0.81;
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=Task-HL7';
resources 'homepage' => 'https://github.com/tupinek/Task-HL7';
resources 'repository' => 'git://github.com/tupinek/Task-HL7';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.02';

# Run.
WriteAll();
