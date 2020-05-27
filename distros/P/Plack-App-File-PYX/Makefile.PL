use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Plack PYX file application.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Plack-App-File-PYX';
perl_version 5.008;
readme_from 'PYX.pm';
recursive_author_tests('xt');
requires 'Encode' => 0;
requires 'English' => 0;
requires 'Error::Pure' => 0;
requires 'HTTP::Date' => 0;
requires 'Plack::App::File' => 0;
requires 'Plack::Util::Accessor' => 0;
requires 'PYX::SGML::Tags' => 0;
requires 'Tags::Output::Raw' => 0;
requires 'Unicode::UTF8' => 0;
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=Plack-App-File-PYX';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Plack-App-File-PYX';
resources 'repository' => 'git://github.com/michal-josef-spacek/Plack-App-File-PYX';
test_requires 'Error::Pure' => 0;
test_requires 'File::Object' => 0;
test_requires 'HTTP::Request' => 0;
test_requires 'Plack::Test' => 0;
test_requires 'Tags::Output::Indent' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.01';

# Run.
WriteAll();
