use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Plack application for request of login information.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Plack-App-Login-Request';
perl_version 5.008;
readme_from 'Request.pm';
recursive_author_tests('xt');
requires 'Plack::Component::Tags::HTML' => 0.13;
requires 'Plack::Request' => 0;
requires 'Plack::Response' => 0;
requires 'Plack::Session' => 0;
requires 'Plack::Util::Accessor' => 0;
requires 'Tags::HTML::Container' => 0;
requires 'Tags::HTML::Login::Request' => 0;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Plack-App-Login-Request/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Plack-App-Login-Request';
resources 'repository' => 'git://github.com/michal-josef-spacek/Plack-App-Login-Request';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.03';

# Run.
WriteAll();
