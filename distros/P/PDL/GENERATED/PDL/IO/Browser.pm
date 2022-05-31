#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::IO::Browser;

our @EXPORT_OK = qw(browse );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::IO::Browser ;






#line 1 "browser.pd"


=head1 NAME

PDL::IO::Browser -- 2D data browser for PDL

=head1 DESCRIPTION

cursor terminal browser for ndarrays.

=head1 SYNOPSIS

 use PDL::IO::Browser;

=cut

use strict;
use warnings;
#line 44 "Browser.pm"






=head1 FUNCTIONS

=cut




#line 948 "../../blib/lib/PDL/PP.pm"



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
#line 92 "Browser.pm"



#line 950 "../../blib/lib/PDL/PP.pm"

*browse = \&PDL::browse;
#line 99 "Browser.pm"





#line 56 "browser.pd"


=head1 AUTHOR

Copyright (C) Robin Williams 1997 (rjrw@ast.leeds.ac.uk).
All rights reserved. There is no warranty. You are allowed
to redistribute this software / documentation under certain
conditions. For details, see the file COPYING in the PDL
distribution. If this file is separated from the PDL distribution,
the copyright notice should be included in the file.


=cut
#line 119 "Browser.pm"




# Exit with OK status

1;
