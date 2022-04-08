use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Plack Data::Printer application.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Plack-App-Data-Printer';
perl_version 5.008;
readme_from 'Printer.pm';
recursive_author_tests('xt');
requires 'Data::Printer' => 1.0;
requires 'Error::Pure' => 0;
requires 'Plack::Component' => 0;
requires 'Plack::Util::Accessor' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Plack-App-Data-Printer/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Plack-App-Data-Printer';
resources 'repository' => 'git://github.com/michal-josef-spacek/Plack-App-Data-Printer';
test_requires 'English' => 0;
test_requires 'File::Object' => 0;
test_requires 'HTTP::Request' => 0;
test_requires 'Plack::Test' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.03';

# Run.
WriteAll();
