# -*-perl-*-

use strict;
use warnings;
use Test::More tests => 8;

use PDLA::LiteF;
use PDLA::Types;
use PDLA::Graphics::LUT;

my @names = lut_names();
isnt scalar(@names), 0;  # 1

my @cols = lut_data( $names[0] );
is( scalar(@cols), 4 );                         # 2
is( $cols[0]->nelem, $cols[1]->nelem );  # 3
is( $cols[2]->get_datatype, $PDLA_F );    # 4

TODO: {
local $TODO = 'Fragile test';
# check we can reverse things
my @cols2 = lut_data( $names[0], 1 );
ok( all approx($cols[3]->slice('-1:0'),$cols2[3]) );  # 5
}

# check we know about the intensity ramps
my @ramps = lut_ramps();
isnt scalar(@ramps), 0; # 6

# load in a different intensity ramp
my @cols3 = lut_data( $names[0], 0, $ramps[0] ); 
is( $cols3[0]->nelem, $cols3[1]->nelem ); # 7

TODO: {
local $TODO = 'Fragile test';
ok( all approx($cols[1],$cols3[1]) );      # 8
}
