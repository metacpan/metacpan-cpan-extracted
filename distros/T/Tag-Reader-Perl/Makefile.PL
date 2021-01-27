use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Parse SGML/HTML/XML by each "tag".';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.07;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Tag-Reader-Perl';
readme_from 'Perl.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.02;
requires 'Error::Pure' => 0.05;
requires 'Readonly' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Tag-Reader-Perl/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Tag-Reader-Perl';
resources 'repository' => 'git://github.com/michal-josef-spacek/Tag-Reader-Perl';
test_requires 'English' => 0;
test_requires 'File::Object' => 0.03;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.02';

# Run.
WriteAll();
