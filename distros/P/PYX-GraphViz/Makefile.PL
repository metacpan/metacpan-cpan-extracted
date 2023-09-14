use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'GraphViz output for PYX handling.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.07;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'PYX-GraphViz';
readme_from 'lib/PYX/GraphViz.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.05;
requires 'Error::Pure' => 0.15;
requires 'GraphViz' => 0;
requires 'PYX::Parser' => 0.02;
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/PYX-GraphViz/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/PYX-GraphViz';
resources 'repository' => 'git://github.com/michal-josef-spacek/PYX-GraphViz';
test_requires 'English' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.05';

# Run.
WriteAll();
