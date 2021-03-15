
#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::IO::Browser;

@EXPORT_OK  = qw( PDL::PP browse );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;



   
   @ISA    = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::IO::Browser ;





=head1 NAME

PDL::IO::Browser -- 2D data browser for PDL

=head1 DESCRIPTION

cursor terminal browser for piddles.

=head1 SYNOPSIS

 use PDL::IO::Browser;

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
around a PDL array using the cursor keys.





=for bad

browse does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*browse = \&PDL::browse;



;


=head1 AUTHOR

Copyright (C) Robin Williams 1997 (rjrw@ast.leeds.ac.uk).
All rights reserved. There is no warranty. You are allowed
to redistribute this software / documentation under certain
conditions. For details, see the file COPYING in the PDL
distribution. If this file is separated from the PDL distribution,
the copyright notice should be included in the file.


=cut






# Exit with OK status

1;

		   