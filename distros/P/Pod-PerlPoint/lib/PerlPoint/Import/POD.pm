


# = HISTORY SECTION =====================================================================

# ---------------------------------------------------------------------------------------
# version | date     | author   | changes
# ---------------------------------------------------------------------------------------
# 0.01    |09.04.2006| JSTENZEL | new.
# ---------------------------------------------------------------------------------------

# = POD SECTION =========================================================================

=head1 NAME

B<PerlPoint::Import::POD> - a standard PerlPoint import filter for POD

=head1 VERSION

This manual describes version B<0.01>.

=head1 SYNOPSIS

   # command line: process a POD file
   perlpoint ... IMPORT:file.pod

   ...

   # or, in a PerlPoint source:

   // include a POD file with "pod" extension
   \INCLUDE{import=1 file="example.pod"}

   // include a POD file without "pod" extension
   \INCLUDE{import=pod file="example"}

   // import a snippet in POD,
   // which in turn contains some PerlPoint
   \EMBED{import=pod}
   
   =head2 Embedded PerlPoint

   A POD paragraph.

   =for perlpoint It \I<works>!

   \END_EMBED


=head1 DESCRIPTION

Standard import filters are loaded automatically by the Parser
when you import a POD file in one of the ways shown in the
I<SYNOPSIS>.


=head1 FUNCTION

According to the standard import filter API (see C<PerlPoint::Parser>) this
module provides one function, C<importFilter()>. I transforms a POD file
into PerlPoint.

=cut




# check perl version
require 5.00503;

# = PACKAGE SECTION ======================================================================

# declare package
package PerlPoint::Import::POD;

# declare package version
$VERSION=0.01;


# = PRAGMA SECTION =======================================================================

# set pragmata
use strict;


# = LIBRARY SECTION ======================================================================

# load libraries
use Pod::PerlPoint 0.05;

# declare the filter function
sub importFilter
 {
  # declare variables
  my ($pod2pp, $result, $i);

  # get source and sourcefile name
  my ($pod, $sourcefile)=(join('', "\n\n\n", @main::_ifilterText), $main::_ifilterFile);

  # transform it into PerlPoint
  {
   # build a translator object and configure it
   ($pod2pp, $result)=(new Pod::PerlPoint());
   $pod2pp->output_string(\$result);
   $pod2pp->configure(parser40=>($PerlPoint::Parser::VERSION>=0.40));

   # parse file
   my $rc=$pod2pp->parse_string_document($pod);
   $i++, $pod="\n\n=pod\n\n$pod", redo unless $result or $i;

   # report errors, if any
   if (exists $pod2pp->{errata})
    {
     warn "\nPOD error detected in $sourcefile:\n\n";
     foreach (sort {$a <=> $b} keys %{$pod2pp->{errata}})
       {warn "Line $_:\n\n", map {"$_\n"} @{$pod2pp->{errata}{$_}};}

     # flag the error
     die "\n";
    }
  }

  # supply result (add leading newlines to let the parser detect a *new*
  # paragraph and therefore recognize the special paragraph menaing of the
  # dot added by Pod::PerlPoint to the first paragraph)
  "\n\n$result";
 }


# flag successful loading
1;




# = POD TRAILER SECTION =================================================================

=pod

=head1 NOTES

None that far.

=head1 SEE ALSO

=over 4

=item B<Pod::PerlPoint>

The module implementing POD to PerlPoint conversion.

=item B<Bundle::PerlPoint>

A bundle of packages to deal with PerlPoint documents.

=item B<pod2pp>

A standalone POD to PerlPoint translator, distributed
and installed with this module.

=back


=head1 SUPPORT

A PerlPoint mailing list is set up to discuss usage, ideas,
bugs, suggestions and translator development. To subscribe,
please send an empty message to perlpoint-subscribe@perl.org.

If you prefer, you can contact me via perl@jochen-stenzel.de
as well.


=head1 AUTHOR

Copyright (c) Jochen Stenzel (perl@jochen-stenzel.de), 2006.
All rights reserved.

This module is free software, you can redistribute it and/or modify it
under the terms of the Artistic License distributed with Perl version
5.003 or (at your option) any later version. Please refer to the
Artistic License that came with your Perl distribution for more
details.

The Artistic License should have been included in your distribution of
Perl. It resides in the file named "Artistic" at the top-level of the
Perl source tree (where Perl was downloaded/unpacked - ask your
system administrator if you dont know where this is).  Alternatively,
the current version of the Artistic License distributed with Perl can
be viewed on-line on the World-Wide Web (WWW) from the following URL:
http://www.perl.com/perl/misc/Artistic.html


=head1 DISCLAIMER

This software is distributed in the hope that it will be useful, but
is provided "AS IS" WITHOUT WARRANTY OF ANY KIND, either expressed or
implied, INCLUDING, without limitation, the implied warranties of
MERCHANTABILITY and FITNESS FOR A PARTICULAR PURPOSE.

The ENTIRE RISK as to the quality and performance of the software
IS WITH YOU (the holder of the software).  Should the software prove
defective, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR OR
CORRECTION.

IN NO EVENT WILL ANY COPYRIGHT HOLDER OR ANY OTHER PARTY WHO MAY CREATE,
MODIFY, OR DISTRIBUTE THE SOFTWARE BE LIABLE OR RESPONSIBLE TO YOU OR TO
ANY OTHER ENTITY FOR ANY KIND OF DAMAGES (no matter how awful - not even
if they arise from known or unknown flaws in the software).

Please refer to the Artistic License that came with your Perl
distribution for more details.

