##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/Perl-Critic-Dynamic/lib/Perl/Critic/Policy/Dynamic/ValidateAgainstSymbolTable.pm $
#     $Date: 2007-06-15 20:35:56 -0700 (Fri, 15 Jun 2007) $
#   $Author: thaljef $
# $Revision: 1645 $
##############################################################################

package FooBar;

use strict;
use warnings;

use Carp (); # No imports!
use base 'Exporter';

#----------------------------------------------------------------------------

our @EXPORT = qw(always_exported);
our @EXPORT_OK = (@EXPORT, qw(exported_on_demand));

sub always_exported {}
sub exported_on_demand {}
sub main::declared_into_main {}

#############################################################################

package InnerFooBar;

use Carp qw(cluck confess); # With imports!

#----------------------------------------------------------------------------

sub inner_subroutine{}


1;

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
