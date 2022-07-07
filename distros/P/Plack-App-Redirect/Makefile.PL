use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Plack application for redirection.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Plack-App-Redirect';
perl_version 5.008;
readme_from 'Redirect.pm';
recursive_author_tests('xt');
requires 'Plack::Response' => 0;
requires 'Plack::Request' => 0;
requires 'Plack::Util::Accessor' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Plack-App-Redirect/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Plack-App-Redirect';
resources 'repository' => 'git://github.com/michal-josef-spacek/Plack-App-Redirect';
test_requires 'HTTP::Request' => 0;
test_requires 'Plack::Test' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.02';

# Run.
WriteAll();
