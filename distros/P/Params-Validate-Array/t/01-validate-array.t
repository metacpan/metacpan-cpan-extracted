use strict;
use warnings;

use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );

use PVTests::Standard_Array;
PVTests::Standard_Array::run_tests();
