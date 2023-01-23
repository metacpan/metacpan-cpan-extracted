use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Look for year or years range in string and update years';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'String-UpdateYears';
readme_from 'UpdateYears.pm';
recursive_author_tests('xt');
requires 'Exporter' => 0;
requires 'Readonly' => 0;
requires 'perl' => '5.6.2';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/String-UpdateYears/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/String-UpdateYears';
resources 'repository' => 'git://github.com/michal-josef-spacek/String-UpdateYears';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Unicode::UTF8' => 0;
tests_recursive;
version '0.01';

# Run.
WriteAll();
