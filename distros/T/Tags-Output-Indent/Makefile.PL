use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Indented output for Tags.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.01;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Tags-Output-Indent';
readme_from 'Indent.pm';
recursive_author_tests('xt');
requires 'Error::Pure' => 0.05;
requires 'Indent' => 0.01;
requires 'Indent::Word' => 0.01;
requires 'Indent::Block' => 0.01;
requires 'List::MoreUtils' => 0;
requires 'Readonly' => 0;
requires 'Tags::Output' => 0.10;
requires 'Tags::Utils' => 0.09;
requires 'Tags::Utils::Preserve' => 0.09;
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=Tags-Output-Indent';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Tags-Output-Indent';
resources 'repository' => 'git://github.com/michal-josef-spacek/Tags-Output-Indent';
test_requires 'English' => 0;
test_requires 'File::Object' => 0.01;
test_requires 'IO::Scalar' => 0;
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::Warn' => 0;
tests_recursive;
version '0.08';

# Run.
WriteAll();
