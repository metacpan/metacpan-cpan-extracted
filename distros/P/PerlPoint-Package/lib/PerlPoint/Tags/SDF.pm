

# = HISTORY SECTION =====================================================================

# ---------------------------------------------------------------------------------------
# version | date     | author   | changes
# ---------------------------------------------------------------------------------------
# 0.03    |18.08.2003| JSTENZEL | A is a basic tag now;
# 0.02    |16.06.2001| JSTENZEL | namespace bugfix;
# 0.01    |31.03.2001| JSTENZEL | new.
# ---------------------------------------------------------------------------------------

# = POD SECTION =========================================================================

=head1 NAME

B<PerlPoint::Tags::SDF> - PerlPoint tag set used by pp2sdf

=head1 VERSION

This manual describes version B<0.03>.

=head1 SYNOPSIS

  # declare tags used by pp2sdf
  use PerlPoint::Tags::SDF;

=head1 DESCRIPTION

This module declares PerlPoint tags used by C<pp2sdf>. Tag declarations
are used by the parser to determine if a used tag is valid, if it needs
options, if it needs a body and so on. Please see \B<PerlPoint::Tags>
for a detailed description of tag declaration.

Every PerlPoint translator willing to handle the tags of this module
can declare this by using the module in the scope where it built the
parser object.

  # declare basic tags
  use PerlPoint::Tags::SDF;

  # load parser module
  use PerlPoint::Parser;

  ...

  # build parser
  my $parser=new PerlPoint::Parser(...);

  ...


=head1 TAGS

B<PerlPoint::Tags::SDF> declares all the tags of B<PerlPoint::Tags::Basic>.

Additionally, the B<PerlPoint::Tags::HTML> tags C<L>, C<PAGEREF>,
C<SECTIONREF>, C<U> and C<XREF> tags are supported. C<pp2sdf> might interprete them
slightly different to C<pp2html>, please read its documentation for details.

=head1 TAG SETS

No sets are currently defined.

=cut


# check perl version
require 5.00503;

# = PACKAGE SECTION (internal helper package) ==========================================

# declare package
package PerlPoint::Tags::SDF;

# declare package version
$VERSION=0.03;

# declare base "class"
use base qw(PerlPoint::Tags);


# = PRAGMA SECTION =======================================================================

# set pragmata
use strict;
use vars qw(%tags %sets);

# = LIBRARY SECTION ======================================================================

# load modules
use PerlPoint::Constants 0.14 qw(:tags);

# declare tags - just combining other declarations
use PerlPoint::Tags::Basic;
use PerlPoint::Tags::HTML qw(L PAGEREF SECTIONREF U XREF);

1;


# = POD TRAILER SECTION =================================================================

=pod

=head1 SEE ALSO

=over 4

=item B<PerlPoint::Tags>

The tag declaration base "class".

=item B<PerlPoint::Tags::Basic>

Basic tags imported by B<PerlPoint::Tags::SDF>.

=item PerlPoint::Tags::HTML

which declares the original C<L>, C<PAGEREF>, C<SECTIONREF>, C<U> and C<XREF> tags.

=back


=head1 SUPPORT

A PerlPoint mailing list is set up to discuss usage, ideas,
bugs, suggestions and translator development. To subscribe,
please send an empty message to perlpoint-subscribe@perl.org.

If you prefer, you can contact me via perl@jochen-stenzel.de
as well.

=head1 AUTHOR

Copyright (c) Jochen Stenzel (perl@jochen-stenzel.de), 1999-2001.
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

