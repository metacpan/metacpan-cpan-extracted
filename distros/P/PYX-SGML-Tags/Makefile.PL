use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Processing PYX data or file and write as SGML via Tags.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.07;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'PYX-SGML-Tags';
readme_from 'Tags.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.05;
requires 'Error::Pure' => 0.15;
requires 'PYX::Parser' => 0.05;
requires 'PYX::Utils' => 0.01;
requires 'Tags::Output::Raw' => 0.10;
requires 'perl' => '5.6.2';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/PYX-SGML-Tags/issues',
resources 'homepage' => 'https://github.com/michal-josef-spacek/PYX-SGML-Tags';
resources 'repository' => 'git://github.com/michal-josef-spacek/PYX-SGML-Tags';
test_requires 'English' => 0;
test_requires 'Error::Pure::Utils' => 0.15;
test_requires 'File::Object' => 0.07;
test_requires 'Tags::Output::Raw' => 0;
test_requires 'Tags::Output::Indent' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Unicode::UTF8' => 0;
tests_recursive;
version '0.06';

# Run.
WriteAll();
