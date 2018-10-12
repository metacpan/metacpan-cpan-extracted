#
#===============================================================================
#
#         FILE: 001module_load.t
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 10/07/2018 03:27:10 AM
#     REVISION: ---
#===============================================================================

use strict;
use warnings;

use Test::More tests => 4;                      # last test to print

require_ok( 'PiFlash::State' );
require_ok( 'PiFlash::Command' );
require_ok( 'PiFlash::Inspector' );
require_ok( 'PiFlash' );

1;
