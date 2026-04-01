use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Transformation from BIBFRAME to MARC XML for NKC demo project.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
install_share 'share';
license 'bsd';
# share/ directory with cc0.
name 'NKC-Transform-BIBFRAME2MARC';
readme_from 'BIBFRAME2MARC.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0;
requires 'Error::Pure' => 0;
requires 'File::Object' => 0;
requires 'File::Share' => 0;
requires 'Perl6::Slurp' => 0;
requires 'XML::LibXML' => 0;
requires 'XML::LibXSLT' => 0;
requires 'perl' => '5.8.0';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/NKC-Transform-BIBFRAME2MARC/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/NKC-Transform-BIBFRAME2MARC';
resources 'repository' => 'git://github.com/michal-josef-spacek/NKC-Transform-BIBFRAME2MARC';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'File::Object' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.06';

# Run.
WriteAll();
