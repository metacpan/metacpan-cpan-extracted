# Pragmas.
use strict;
use warnings;

# Modules.
use inc::Module::Install;

# Definition.
abstract 'SGML to PYX parser.';
author 'Michal Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.07;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'SGML-PYX';
readme_from 'PYX.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.06;
requires 'Encode' => 0;
requires 'Error::Pure' => 0.22;
requires 'Tag::Reader::Perl' => 0.01;
requires 'PYX' => 0.05;
requires 'PYX::Utils' => 0.04;
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=SGML-PYX';
resources 'homepage' => 'https://github.com/tupinek/SGML-PYX';
resources 'repository' => 'git://github.com/tupinek/SGML-PYX';
test_requires 'File::Object' => 0.07;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Output' => 1.02;
tests_recursive;
version '0.02';

# Run.
WriteAll();
