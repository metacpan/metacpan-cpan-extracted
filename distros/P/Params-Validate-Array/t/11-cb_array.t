use strict;
use warnings;

use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );

use PVTests::Callbacks_Array;
PVTests::Callbacks_Array::run_tests();
