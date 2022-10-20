use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Plack application for running Tags::HTML objects.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Plack-App-Tags-HTML';
perl_version 5.008;
readme_from 'HTML.pm';
recursive_author_tests('xt');
requires 'English' => 0;
requires 'Error::Pure' => 0;
requires 'Plack::Component::Tags::HTML' => 0.06;
requires 'Plack::Util::Accessor' => 0;
requires 'Symbol::Get' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Plack-App-Tags-HTML/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Plack-App-Tags-HTML';
resources 'repository' => 'git://github.com/michal-josef-spacek/Plack-App-Tags-HTML';
test_requires 'File::Object' => 0;
test_requires 'HTTP::Request::Common' => 0;
test_requires 'Plack::Test' => 0;
test_requires 'Tags::HTML' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.08';

# Run.
WriteAll();
