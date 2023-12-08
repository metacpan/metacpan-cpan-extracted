use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Object for copyright years changing in POD.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Pod-CopyrightYears';
readme_from 'CopyrightYears.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0;
requires 'Error::Pure' => 0.30;
requires 'Pod::Abstract' => 0;
requires 'String::UpdateYears' => 0;
requires 'perl' => '5.6.2';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Pod-CopyrightYears/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Pod-CopyrightYears';
resources 'repository' => 'git://github.com/michal-josef-spacek/Pod-CopyrightYears';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'File::Object' => 0.05;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.03';

# Run.
WriteAll();
