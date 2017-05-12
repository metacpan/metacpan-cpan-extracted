# Pragmas.
use strict;
use warnings;

# Modules.
use inc::Module::Install;

# Definition.
abstract 'Install the PYX modules.';
author 'Michal Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.08;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Task-PYX';
readme_from 'PYX.pm';
recursive_author_tests('xt');
requires 'App::PYX2XML' => 0.01;
requires 'PYX' => 0.04;
requires 'PYX::GraphViz' => 0.04;
requires 'PYX::Hist' => 0.03;
requires 'PYX::SGML::Raw' => 0.02;
requires 'PYX::SGML::Tags' => 0.01;
requires 'PYX::Sort' => 0.03;
requires 'PYX::Stack' => 0.04;
requires 'PYX::Utils' => 0.04;
requires 'PYX::XMLNorm' => 0.04;
requires 'PYX::XMLSchema::List' => 0.04;
requires 'Tags::Output::PYX' => 0.03;
requires 'XML::MinWriter' => 0.08;
requires 'XML::PYX' => 0.07;
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=Task-PYX';
resources 'homepage' => 'https://github.com/tupinek/Task-PYX';
resources 'repository' => 'git://github.com/tupinek/Task-PYX';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.09';

# Run.
WriteAll();
