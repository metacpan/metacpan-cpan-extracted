use strict;
use warnings;

use File::Spec;
use lib File::Spec->catdir( 't', 'lib' );

BEGIN { $ENV{PERL_NO_VALIDATION} = 1 }

use PVTests::Defaults_Array;
PVTests::Defaults_Array::run_tests();
