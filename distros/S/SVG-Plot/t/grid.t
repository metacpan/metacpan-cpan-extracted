use strict;
use SVG::Plot;
use Test::XML::XPath;
use Test::More tests => 2;

# Test that viewbox is worked out correctly whether we specify points
# or pointsets.

my $points = [ [ 2, 2 ], [ 5, 5 ] ];
my $plot = SVG::Plot->new( points => $points );
my $output = $plot->plot;

# margin and scale are both 10 - so we expect an image 40 x 40
like_xpath( $output, '/svg[@width="40"][@height="40"]',
      "viewbox correct with single set of points" );

my $pointsets = [ { points => [ [ 1, 1 ], [ 2, 2] ] },
                  { points => [ [ 10, 10 ], [ 20, 20] ] }
                ];
$plot = SVG::Plot->new( pointsets => $pointsets );
$output = $plot->plot;

# 10 pixels for the margin, 190 for the square with corners (1, 1) and (20, 20)
like_xpath( $output, '/svg[@width="200"][@height="200"]',
      "viewbox correct with multiple pointsets" );
