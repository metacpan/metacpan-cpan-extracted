# -*- perl -*-

# Check module loading

use strict;

use Test::More tests => 2;

BEGIN { use_ok( 'Statistics::LineFit' ); }

my $lineFit = Statistics::LineFit->new();
isa_ok ($lineFit, 'Statistics::LineFit');

