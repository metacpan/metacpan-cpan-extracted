use lib qw( ./blib/lib ../blib/lib );

# Check we can actually load the modules

use Test::More tests => 8;

BEGIN { use_ok( 'SVG::TT::Graph' ); }
BEGIN { use_ok( 'SVG::TT::Graph::Pie' ); }
BEGIN { use_ok( 'SVG::TT::Graph::Line' ); }
BEGIN { use_ok( 'SVG::TT::Graph::Bar' ); }
BEGIN { use_ok( 'SVG::TT::Graph::BarHorizontal' ); }
BEGIN { use_ok( 'SVG::TT::Graph::BarLine' ); }
BEGIN { use_ok( 'SVG::TT::Graph::TimeSeries' ); }
BEGIN { use_ok( 'SVG::TT::Graph::XY' ); }
