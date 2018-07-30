#
#===============================================================================
#
#         FILE: vars.t
#
#  DESCRIPTION: Test that there are no unused vars
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Pete Houston (pete), cpan@openstrike.co.uk
# ORGANIZATION: Openstrike
#      CREATED: 13/06/18 16:02:48
#===============================================================================

use strict;
use warnings;

use Test::More;
use Test::Vars 0.012;

all_vars_ok ();
