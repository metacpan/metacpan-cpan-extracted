use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Transformation from MARC XML to BIBFRAME for NKC demo project.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
install_share 'share';
license 'bsd';
name 'NKC-Transform-MARC2BIBFRAME';
readme_from 'MARC2BIBFRAME.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0;
requires 'Error::Pure' => 0;
requires 'File::Spec::Functions' => 0;
requires 'File::Share' => 0;
requires 'XML::LibXML' => 0;
requires 'XML::LibXSLT' => 0;
requires 'perl' => '5.8.0';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/NKC-Transform-MARC2BIBFRAME/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/NKC-Transform-MARC2BIBFRAME';
resources 'repository' => 'git://github.com/michal-josef-spacek/NKC-Transform-MARC2BIBFRAME';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.04';

# Run.
WriteAll();
