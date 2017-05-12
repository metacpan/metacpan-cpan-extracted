#---------------------------------------------------------------------
package inc::My_Build;
#
# Copyright 2007 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 18 Feb 2007
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# Customize Module::Build for PostScript::Calendar
#---------------------------------------------------------------------

use strict;
use Module::Build ();

our @ISA = 'Module::Build';

#=====================================================================
# Package Global Variables:

our $VERSION = '1.02';

#=====================================================================

sub prereq_failures
{
  my $self = shift @_;

  my $out = $self->SUPER::prereq_failures(@_);

  return $out unless $out;

  if (my $attrib = $out->{recommends}{'Astro::MoonPhase'}) {
    $attrib->{message} .= <<"END Astro::MoonPhase";
\n
   Astro::MoonPhase is only required if you want to display the phase
   of the moon on your calendars.  You need at least version 0.60.

   If you install Astro::MoonPhase later, you do NOT need to
   re-install PostScript::Calendar.
END Astro::MoonPhase
  } # end if Astro::MoonPhase failed

  return $out;
} # end prereq_failures

#=====================================================================
# Package Return Value:

1;
