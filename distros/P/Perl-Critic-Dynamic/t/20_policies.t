#!perl

##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/t/20_policies.t $
#     $Date: 2009-10-02 15:31:13 -0700 (Fri, 02 Oct 2009) $
#   $Author: clonezone $
# $Revision: 3676 $
##############################################################################

use 5.006001;

use strict;
use warnings;

use Test::More;
use Test::Perl::Critic::Policy qw<all_policies_ok>;

#-----------------------------------------------------------------------------

our $VERSION = '0.05';

#-----------------------------------------------------------------------------
diag(q< >); # Just to get on a new line
diag('NOTE: these tests will emit a "Compilation of ... failed" warning.');
diag('This is normal, and can be ignored.  Sorry about the noise.');

#-----------------------------------------------------------------------------
# Notice that you can pass arguments to this test, which limit the testing to
# specific policies.  The arguments must be shortened policy names. When using
# prove(1), any arguments that follow '::' will be passed to the test script.

my %args = @ARGV ? ( -policies => [ @ARGV ] ) : ();
all_policies_ok(%args);

#-----------------------------------------------------------------------------
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
