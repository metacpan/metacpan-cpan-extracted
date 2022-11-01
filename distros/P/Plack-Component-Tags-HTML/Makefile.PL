use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Plack component for Tags with HTML output.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Plack-Component-Tags-HTML';
perl_version 5.008;
readme_from 'HTML.pm';
recursive_author_tests('xt');
requires 'CSS::Struct::Output::Raw' => 0;
requires 'Encode' => 0;
requires 'Error::Pure' => 0;
requires 'Plack::Component' => 0;
requires 'Plack::Util::Accessor' => 0;
requires 'Scalar::Util' => 0;
requires 'Tags::HTML::Page::Begin' => 0.13;
requires 'Tags::HTML::Page::End' => 0;
requires 'Readonly' => 0;
requires 'Tags::Output::Raw' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Plack-Component-Tags-HTML/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Plack-Component-Tags-HTML';
resources 'repository' => 'git://github.com/michal-josef-spacek/Plack-Component-Tags-HTML';
test_requires 'HTTP::Request::Common' => 0;
test_requires 'Plack::Test' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.08';

# Run.
WriteAll();
