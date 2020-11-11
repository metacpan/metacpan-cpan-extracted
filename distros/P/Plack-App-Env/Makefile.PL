use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Plack env dump application.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Plack-App-Env';
perl_version 5.008;
readme_from 'Env.pm';
recursive_author_tests('xt');
requires 'Data::Printer' => 0;
requires 'Plack::Component' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Plack-App-Env/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Plack-App-Env';
resources 'repository' => 'git://github.com/michal-josef-spacek/Plack-App-Env';
test_requires 'CPAN::Version' => 0;
test_requires 'Error::Pure' => 0;
test_requires 'File::Object' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.06';

# Run.
WriteAll();
