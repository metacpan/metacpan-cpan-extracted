##
## File: PDL::VectorValued::Version.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: Vector utilities for PDL: version
##  + <=v1.0.3: this lives in a separate file so that both compile-time and runtime subsystems can use it
##  + >=v1.0.4: use perl-reversion from Perl::Version to maintain shared $VERSION
##======================================================================

package PDL::VectorValued::Version;
our $VERSION = '1.0.21';
#$PDL::VectorValued::VERSION = $VERSION;	##-- use perl-reversion from Perl::Version instead
#$PDL::VectorValued::Dev::VERSION = $VERSION;	##-- use perl-reversion from Perl::Version instead

1; ##-- make perl happy
