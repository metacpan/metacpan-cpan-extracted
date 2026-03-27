use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Transformation from MARC XML to RDA for NKC demo project.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
install_share 'share';
license 'bsd';
name 'NKC-Transform-MARC2RDA';
readme_from 'MARC2RDA.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0;
requires 'File::Share' => 0;
requires 'Perl6::Slurp' => 0;
requires 'XML::Saxon::XSLT3' => 0;
requires 'perl' => '5.8.0';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/NKC-Transform-MARC2RDA/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/NKC-Transform-MARC2RDA';
resources 'repository' => 'git://github.com/michal-josef-spacek/NKC-Transform-MARC2RDA';
test_requires 'File::Object' => 0;
test_requires 'Perl6::Slurp' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.02';

# Run.
WriteAll();
