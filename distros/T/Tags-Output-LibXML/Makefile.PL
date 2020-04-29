use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'LibXML output for Tags.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.01;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Tags-Output-LibXML';
readme_from 'LibXML.pm';
recursive_author_tests('xt');
requires 'Error::Pure' => 0.05;
requires 'Readonly' => 0;
requires 'Tags::Output' => 0.02;
requires 'XML::LibXML' => 0;
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=Tags-Output-LibXML';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Tags-Output-LibXML';
resources 'repository' => 'git://github.com/michal-josef-spacek/Tags-Output-LibXML';
test_requires 'English' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.03';

# Run.
WriteAll();
