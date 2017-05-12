use strict;
use warnings;

use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );

use PVTests::Defaults_Array;
PVTests::Defaults_Array::run_tests();
