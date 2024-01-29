use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Plack register application.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Plack-App-Register';
perl_version 5.008;
readme_from 'Register.pm';
recursive_author_tests('xt');
requires 'Plack::Component::Tags::HTML' => 0.15;
requires 'Plack::Util::Accessor' => 0;
requires 'Plack::Request' => 0;
requires 'Plack::Response' => 0;
requires 'Plack::Session' => 0;
requires 'Tags::HTML::Container' => 0;
requires 'Tags::HTML::Login::Register' => 0.04;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Plack-App-Register/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Plack-App-Register';
resources 'repository' => 'git://github.com/michal-josef-spacek/Plack-App-Register';
test_requires 'CSS::Struct::Output::Indent' => 0;
test_requires 'HTTP::Request' => 0;
test_requires 'Plack::Test' => 0;
test_requires 'Tags::Output::Indent' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.03';

# Run.
WriteAll();
