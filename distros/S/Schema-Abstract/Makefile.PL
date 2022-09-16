use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Abstract class for Schema modules.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Schema-Abstract';
perl_version 5.006002;
readme_from 'Abstract.pm';
requires 'Class::Utils' => 0;
requires 'English' => 0;
requires 'Error::Pure' => 0;
requires 'Perl6::Slurp' => 0;
recursive_author_tests('xt');
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Schema-Abstract/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Schema-Abstract';
resources 'repository' => 'git://github.com/michal-josef-spacek/Schema-Abstract';
test_requires 'English' => 0;
test_requires 'File::Object' => 0;
test_requires 'File::Spec::Functions' => 0;
test_requires 'File::Temp' => 0;
test_requires 'IO::Barf' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.04';

# Run.
WriteAll();
