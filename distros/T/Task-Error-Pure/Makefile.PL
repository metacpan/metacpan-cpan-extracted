use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Install the Error::Pure modules.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.08;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Task-Error-Pure';
readme_from 'Pure.pm';
recursive_author_tests('xt');
requires 'Error::Pure' => 0.31;
requires 'Error::Pure::ANSIColor' => 0.29;
requires 'Error::Pure::Always' => 0.07;
requires 'Error::Pure::HTTP' => 0.15;
requires 'Error::Pure::HTTP::JSON' => 0.05;
requires 'Error::Pure::JSON' => 0.08;
requires 'Error::Pure::NoDie' => 0.05;
requires 'Error::Pure::Output::ANSIColor' => 0.04;
requires 'Error::Pure::Output::JSON' => 0.11;
requires 'Error::Pure::Output::Tags::HTMLCustomPage' => 0.03;
requires 'Error::Pure::Output::Text' => 0.24;
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Task-Error-Pure/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Task-Error-Pure';
resources 'repository' => 'git://github.com/michal-josef-spacek/Task-Error-Pure';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.04';

# Run.
WriteAll();
