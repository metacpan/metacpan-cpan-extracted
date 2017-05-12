# Pragmas.
use strict;
use warnings;

# Modules.
use inc::Module::Install;

# Definition.
abstract 'Install the Graph::Writer modules.';
author 'Michal Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.08;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Task-Graph-Writer';
readme_from 'Writer.pm';
recursive_author_tests('xt');
requires 'Graph::Graph6' => 4;
requires 'Graph::Writer' => 2.07,
requires 'Graph::Writer::Cytoscape' => 1.00;
requires 'Graph::Writer::DSM' => 0.006;
requires 'Graph::Writer::DrGeo' => 0.01;
requires 'Graph::Writer::TGXML' => 0.01;
requires 'Graph::Writer::GraphViz' => 0.11;
requires 'perl' => '5.6.0';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=Task-Graph-Writer';
resources 'homepage' => 'https://github.com/tupinek/Task-Graph-Writer';
resources 'repository' => 'git://github.com/tupinek/Task-Graph-Writer';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.02';

# Run.
WriteAll();
