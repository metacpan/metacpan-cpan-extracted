#
#===============================================================================
#
#         FILE: kwalitee.t
#
#  DESCRIPTION: Test Kwalitee
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Pete Houston (cpan@openstrike.co.uk)
# ORGANIZATION: Openstrike
#      VERSION: 1.0
#      CREATED: 29/05/18 23:25:27
#     REVISION: ---
#===============================================================================

use strict;
use warnings;

use Test::More;
use Test::Kwalitee 'kwalitee_ok';
kwalitee_ok();
done_testing();
