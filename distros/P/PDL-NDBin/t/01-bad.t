# multidimensional binning & histogramming - test bad value support

use strict;
use warnings;
use Test::More tests => 1;
use PDL;

ok( $PDL::Bad::Status ) or BAIL_OUT( 'PDL::NDBin needs bad value support' );
