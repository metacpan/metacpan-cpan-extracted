#!/opt/Perl5.6.0/bin/perl -w -I.

use strict;
use SVGGraph;

my @a = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20);
my @b = (-5, 2, 1, 5, 8, 8, 9, 5, 4, 10, 2, 1, 5, 8, 8, 9, 5, 4, 10, 5);
my @c = (6, -4, 2, 1, 5, 8, 8, 9, 5, 4, 10, 2, 1, 5, 8, 8, 9, 5, 4, 10);
my @d = (1, 2, 3, 4, 9, 8, 7, 6, 5, 12, 30, 23, 12, 17, 13, 23, 12, 10, 20, 11);
my @e = (3, 1, 2, -3, -4, -9, -8, -7, 6, 5, 12, 30, 23, 12, 17, 13, 23, 12, 10, 20);

my $SVGGraph = new SVGGraph;
print "Content-type: image/svg-xml\n\n";
print $SVGGraph->CreateGraph(	{
	'graphtype' => 'spline', ### verticalbars or spline
	'imageheight' => 500, ### The total height of the whole svg image
	'barwidth' => 4, ### Width of the bar or dot in pixels
	'horiunitdistance' => 30, ### This is the distance in pixels between 1 x-unit
	'title' => 'Financial Results Q1 2002',
	'titlestyle' => 'font-size:24;fill:#FF0000;',
	'xlabel' => 'Week',
	'xlabelstyle' => 'font-size:32;fill:darkblue',
	'ylabel' => 'Revenue (x1000 USD)',
	'ylabelstyle' => 'font-size:16;fill:brown',
	'legendoffset' => '10, 10' ### In pixels from top left corner 'x, y'
	},
	[\@a, \@b, 'Bananas', '#FF0000'],
	[\@a, \@c, 'Apples', '#006699'],
	[\@a, \@d, 'Strawberries', '#FF9933'],
	[\@a, \@e, 'Melons', 'green']
);
