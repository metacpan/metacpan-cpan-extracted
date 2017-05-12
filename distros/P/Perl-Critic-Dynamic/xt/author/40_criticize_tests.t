#!perl

##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/tags/Perl-Critic-Dynamic-0.05/xt/author/40_criticize_tests.t $
#     $Date: 2009-11-07 21:52:59 -0800 (Sat, 07 Nov 2009) $
#   $Author: thaljef $
# $Revision: 3711 $
##############################################################################


use strict;
use warnings;
use File::Spec;

#-----------------------------------------------------------------------------

our $VERSION = '0.05';

#-----------------------------------------------------------------------------

use Test::Perl::Critic ( -profile => File::Spec->catfile( qw(xt author 40_perlcriticrc_tests) ) );

#-----------------------------------------------------------------------------

all_critic_ok( qw(t xt) );

###############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
