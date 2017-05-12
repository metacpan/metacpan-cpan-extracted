# Pragmas.
use strict;
use warnings;

# Modules.
use inc::Module::Install;

# Definition.
abstract 'Install the Tags modules.';
author 'Michal Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.08;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Task-Tags';
readme_from 'Tags.pm';
recursive_author_tests('xt');
requires 'Tags' => 0.06;
requires 'Tags::Element' => 0.02;
requires 'Tags::Output::Indent' => 0.05;
requires 'Tags::Output::LibXML' => 0.02;
requires 'Tags::Output::PYX' => 0.03;
requires 'Tags::Output::Structure' => 0.04;
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=Task-Tags';
resources 'homepage' => 'https://github.com/tupinek/Task-Tags';
resources 'repository' => 'git://github.com/tupinek/Task-Tags';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.06';

# Run.
WriteAll();
