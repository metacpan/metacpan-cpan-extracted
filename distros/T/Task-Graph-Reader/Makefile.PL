use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Install the Graph::Reader modules.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.08;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Task-Graph-Reader';
readme_from 'Reader.pm';
recursive_author_tests('xt');
requires 'Graph::Reader' => '2.10',
requires 'Graph::Reader::Graph6' => 9;
requires 'Graph::Reader::OID' => 0.05;
requires 'Graph::Reader::TGF' => 0.04;
requires 'Graph::Reader::TGF::CSV' => 0.03;
requires 'Graph::Reader::UnicodeTree' => 0.03;
requires 'Graph::Reader::LoadClassHierarchy' => 0.01;
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://github.com/michal-josef-spacek/Task-Graph-Reader/issues';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Task-Graph-Reader';
resources 'repository' => 'git://github.com/michal-josef-spacek/Task-Graph-Reader';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.04';

# Run.
WriteAll();
