#!perl

##############################################################################
#     $URL: http://perlcritic.tigris.org/svn/perlcritic/tags/Perl-Critic-Dynamic-0.05/xt/author/98_pod_syntax.t $
#    $Date: 2010-09-24 11:59:12 -0700 (Fri, 24 Sep 2010) $
#   $Author: thaljef $
# $Revision: 3933 $
##############################################################################

use strict;
use warnings;
use Test::More;
use English qw(-no_match_vars);
use Perl::Critic::TestUtils qw{ starting_points_including_examples };

#-----------------------------------------------------------------------------

our $VERSION = '0.05';

#-----------------------------------------------------------------------------

eval 'use Test::Pod 1.00';
plan skip_all => 'Test::Pod 1.00 required for testing POD' if $EVAL_ERROR;
all_pod_files_ok( all_pod_files( starting_points_including_examples() ) );

###############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
