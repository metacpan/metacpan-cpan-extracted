use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Tags helper for change password.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Tags-HTML-ChangePassword';
perl_version 5.008;
readme_from 'ChangePassword.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0;
requires 'Error::Pure' => 0;
requires 'List::Util' => 1.33;
requires 'Readonly' => 0;
requires 'Tags::HTML' => 0;
requires 'Tags::HTML::Messages' => 0.09;
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Tags-HTML-ChangePassword/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Tags-HTML-ChangePassword';
resources 'repository' => 'git://github.com/michal-josef-spacek/Tags-HTML-ChangePassword';
test_requires 'CSS::Struct::Output::Raw' => 0;
test_requires 'CSS::Struct::Output::Structure' => 0;
test_requires 'Data::Message::Simple' => 0;
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0;
test_requires 'Tags::Output::Raw' => 0;
test_requires 'Tags::Output::Structure' => 0;
test_requires 'Test::MockObject' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.03';

# Run.
WriteAll();
