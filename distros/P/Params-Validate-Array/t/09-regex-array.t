use strict;
use warnings;

use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );

use PVTests::Regex_Array;
PVTests::Regex_Array::run_tests();
