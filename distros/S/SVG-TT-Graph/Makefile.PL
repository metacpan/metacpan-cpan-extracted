use strict;
use warnings;
use inc::Module::Install;

name     'SVG-TT-Graph';
all_from 'lib/SVG/TT/Graph.pm';

test_requires 'Test::More';

requires 'Template'        => 2.08;
requires 'DateTime'        => 0.1;
requires 'HTTP::Date'      => 0.1;

recommends 'XML::Tidy';
recommends 'Compress::Zlib';

resources bugtracker => 'https://github.com/ranguard/svg-tt-graph/issues';
resources repository => 'git://github.com/ranguard/svg-tt-graph.git';

WriteAll;
