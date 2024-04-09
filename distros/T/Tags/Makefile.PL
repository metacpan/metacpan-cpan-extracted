use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Structure oriented SGML/XML/HTML/etc. elements manipulation.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.03;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Tags';
readme_from 'Tags.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.02;
requires 'Error::Pure' => 0.07;
requires 'Exporter' => 0;
requires 'HTML::Entities' => 0;
requires 'List::Util' => 1.33;
requires 'Readonly' => 0;
requires 'perl' => '5.8.0';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Tags/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Tags';
resources 'repository' => 'git://github.com/michal-josef-spacek/Tags';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0.22;
test_requires 'File::Object' => 0.03;
test_requires 'IO::Scalar' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Warn' => 0;
tests_recursive;
version '0.15';

# Run.
WriteAll();
