#
# GENERATED WITH PDL::PP from browser.pd! Don't modify!
#
package PDL::IO::Browser;

our @EXPORT_OK = qw(browse );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   our $VERSION = '0.001';
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::IO::Browser $VERSION;







#line 4 "browser.pd"

=head1 NAME

PDL::IO::Browser -- 2D data browser for PDL

=head1 DESCRIPTION

cursor terminal browser for ndarrays.

=head1 SYNOPSIS

 use PDL::IO::Browser;
 browse sequence 3,2;

=cut

use strict;
use warnings;
#line 45 "Browser.pm"


=head1 FUNCTIONS

=cut






=head2 browse

=for sig

  Signature: (a(n,m))

=head2 browse

=for ref

browse a 2D array using terminal cursor keys

=for usage

 browse $data

This uses the CURSES library to allow one to scroll
around a PDL array using the cursor keys.

=for bad

browse does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

=cut




*browse = \&PDL::browse;







#line 60 "browser.pd"

=head1 AUTHOR

Copyright (C) Robin Williams 1997 (rjrw@ast.leeds.ac.uk).
All rights reserved. There is no warranty. You are allowed
to redistribute this software / documentation under certain
conditions. For details, see the file COPYING in the PDL
distribution. If this file is separated from the PDL distribution,
the copyright notice should be included in the file.

=cut
#line 106 "Browser.pm"

# Exit with OK status

1;
