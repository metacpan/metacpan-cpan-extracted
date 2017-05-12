# Simple test of the interpol routine

use Test::More tests => 1;
use PDLA::Lite;

use strict;
use warnings;

my $yvalues =  (new PDLA( 0..5))   - 20;

my $xvalues = -(new PDLA (0..5))*.5;

my $x = new PDLA(-2);

is( $x->interpol($xvalues,$yvalues), -16 );
