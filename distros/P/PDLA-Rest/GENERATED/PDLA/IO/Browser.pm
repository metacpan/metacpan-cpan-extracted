
#
# GENERATED WITH PDLA::PP! Don't modify!
#
package PDLA::IO::Browser;

@EXPORT_OK  = qw( PDLA::PP browse );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDLA::Core;
use PDLA::Exporter;
use DynaLoader;



   
   @ISA    = ( 'PDLA::Exporter','DynaLoader' );
   push @PDLA::Core::PP, __PACKAGE__;
   bootstrap PDLA::IO::Browser ;





=head1 NAME

PDLA::IO::Browser -- 2D data browser for PDLA

=head1 DESCRIPTION

cursor terminal browser for piddles.

=head1 SYNOPSIS

 use PDLA::IO::Browser;

=cut








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
around a PDLA array using the cursor keys.





=for bad

browse does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*browse = \&PDLA::browse;



;


=head1 AUTHOR

Copyright (C) Robin Williams 1997 (rjrw@ast.leeds.ac.uk).
All rights reserved. There is no warranty. You are allowed
to redistribute this software / documentation under certain
conditions. For details, see the file COPYING in the PDLA
distribution. If this file is separated from the PDLA distribution,
the copyright notice should be included in the file.


=cut






# Exit with OK status

1;

		   