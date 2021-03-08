
#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::Bad;

@EXPORT_OK  = qw(  badflag check_badflag badvalue orig_badvalue nbad nbadover ngood ngoodover setbadat setbadif setvaltobad setbadtoval setnantobad setbadtonan copybad isbad isgood  );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;



   
   @ISA    = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::Bad ;





=head1 NAME

PDL::Bad - PDL does not process bad values

=head1 DESCRIPTION

PDL has been compiled with WITH_BADVAL either 0 or undef,
so it does not contain any bad-value support code.
Actually, a number of methods are defined, but they are only
placeholders to make writing other code, that has to handle
WITH_BADVAL being true or false, easier.

Implementation details are given in
L<PDL::BadValues>.

=head1 SYNOPSIS

 use PDL::Bad;
 print "\nBad value support in PDL is turned " .
     $PDL::Bad::Status ? "on" : "off" . ".\n";

 Bad value support in PDL is turned off.

=head1 VARIABLES

There are currently three variables that this module defines
which may be of use.

=over 4

=item $PDL::Bad::Status

Set to 0

=item $PDL::Bad::UseNaN

Set to 0

=item $PDL::Bad::PerPdl

Set to 0

=back

=cut

# really should be a constant
$PDL::Bad::Status = 0;
$PDL::Bad::UseNaN = 0;
$PDL::Bad::PerPdl = 0;

# dummy routines
#
*badflag         = \&PDL::badflag;
*badvalue        = \&PDL::badvalue;
*orig_badvalue   = \&PDL::orig_badvalue;

sub PDL::badflag       { return 0; } # no piddles can contain bad values by design
sub PDL::badvalue      { return undef; }
sub PDL::orig_badvalue { return undef; }

*check_badflag = \&PDL::check_badflag;
sub PDL::check_badflag { return 0; } # no piddles can contain bad values by design

*isbad  = \&PDL::isbad;
*isgood = \&PDL::isgood;

sub PDL::isbad  { return 0; } # no piddles can contain bad values by design
sub PDL::isgood { return 1; } # no piddles can contain bad values by design

*nbadover  = \&PDL::nbadover;
*ngoodover = \&PDL::ngoodover;
*nbad      = \&PDL::nbad;
*ngood     = \&PDL::ngood;

#        Pars => 'a(n); int+ [o]b();',
# collapse the input piddle along it's first dimension and set to 0's
# - using sumover to do the projection as I'm too lazy to do it
#   myself
#
sub PDL::nbadover  { return PDL::sumover( $_[0] * 0 ); }
sub PDL::ngoodover { return PDL::sumover( $_[0] * 0 + 1 ); }

sub PDL::nbad  { return 0; }
sub PDL::ngood { return $_[0]->nelem; }

*setbadat = \&PDL::setbadat;
*setbadif = \&PDL::setbadif;

# As these can't be done inplace we try to keep the
# same behaviour here
#
sub PDL::setbadat { $_[0]->set_inplace(0); return $_[0]->copy; }
sub PDL::setbadif { $_[0]->set_inplace(0); return $_[0]->copy; }

*setvaltobad = \&PDL::setvaltobad;
*setbadtoval = \&PDL::setvaltobad;
*setnantobad = \&PDL::setnantobad;
*setbadtonan = \&PDL::setbadtonan;

# this can be done inplace
# fortunately PDL::copy handles inplace ops
sub PDL::setvaltobad { return $_[0]->copy; }
sub PDL::setbadtoval { return $_[0]->copy; }
sub PDL::setnantobad { return $_[0]->copy; }
sub PDL::setbadtonan { return $_[0]->copy; }

*copybad = \&PDL::copybad;

sub PDL::copybad { return $_[0]->copy; } # ignore the mask







;



# Exit with OK status

1;

		   