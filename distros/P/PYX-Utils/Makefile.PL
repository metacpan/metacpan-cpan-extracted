use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'A perl module for PYX common utilities';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.07;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'PYX-Utils';
readme_from 'Utils.pm';
recursive_author_tests('xt');
requires 'Exporter' => 0;
requires 'HTML::Entities' => 0;
requires 'Readonly' => 0;
requires 'perl' => '5.8.0';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/PYX-Utils/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/PYX-Utils';
resources 'repository' => 'git://github.com/michal-josef-spacek/PYX-Utils';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.07';

# Run.
WriteAll();
