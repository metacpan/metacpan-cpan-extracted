#
#===============================================================================
#
#         FILE:  01use.t
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Pavel Boldin (), <davinchi@cpan.org>
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  06.04.2009 04:28:42 MSD
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use Test::More tests => 2;                      # last test to print



use_ok('SOAP::DirectI::Parse');
use_ok('SOAP::DirectI::Serialize');
