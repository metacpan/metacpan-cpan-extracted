use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Plack application for CPAN::Changes object.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Plack-App-CPAN-Changes';
perl_version 5.008;
readme_from 'Changes.pm';
recursive_author_tests('xt');
requires 'Plack::Component::Tags::HTML' => 0;
requires 'Plack::Util::Accessor' => 0;
requires 'Tags::HTML::CPAN::Changes' => 0.06;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Plack-App-CPAN-Changes/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Plack-App-CPAN-Changes';
resources 'repository' => 'git://github.com/michal-josef-spacek/Plack-App-CPAN-Changes';
test_requires 'CPAN::Changes' => 0;
test_requires 'CSS::Struct::Output::Indent' => 0;
test_requires 'HTTP::Request' => 0;
test_requires 'Plack::Test' => 0;
test_requires 'Tags::Output::Indent' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.05';

# Run.
WriteAll();
