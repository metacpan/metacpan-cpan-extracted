#!/usr/bin/perl
use strict;
use warnings;

use SVG::Rasterize;
use SVG;

my $rasterize;

my $svg = SVG->new;
my $g   = $svg->group('stroke' => 'black',
		      'stroke-width' => 3,
		      'fill'         => 'red',
		      'fill-rule'    => 'nonzero');

$g->path('d' => 'M 250,75 L 323,301 131,161 369,161 177,301 z');
$g->path('d' => 'M 600,81 A 107,107 0 0,1 600,295 '.
	        'A 107,107 0 0,1 600,81 z'.
                'M 600,139 A 49,49 0 0,1 600,237 '.
	        'A 49,49 0 0,1 600,139 z');
$g->path('d' => 'M 950,81 A 107,107 0 0,1 950,295 '.
	        'A 107,107 0 0,1 950,81 z'.
                'M 950,139 A 49,49 0 0,0 950,237 '.
	        'A 49,49 0 0,0 950,139 z');

$g = $svg->group('stroke' => 'black',
		 'stroke-width' => 3,
		 'fill'         => 'red',
		 'fill-rule'    => 'evenodd',
		 'transform'    => 'translate(0, 400)');

$g->path('d' => 'M 250,75 L 323,301 131,161 369,161 177,301 z');
$g->path('d' => 'M 600,81 A 107,107 0 0,1 600,295 '.
	        'A 107,107 0 0,1 600,81 z'.
                'M 600,139 A 49,49 0 0,1 600,237 '.
	        'A 49,49 0 0,1 600,139 z');
$g->path('d' => 'M 950,81 A 107,107 0 0,1 950,295 '.
	        'A 107,107 0 0,1 950,81 z'.
                'M 950,139 A 49,49 0 0,0 950,237 '.
	        'A 49,49 0 0,0 950,139 z');

$rasterize = SVG::Rasterize->new;
$rasterize->rasterize(width => 1200, height => 800, svg => $svg);
$rasterize->write(type => 'png', file_name => 'fill_rule.png');

__END__

