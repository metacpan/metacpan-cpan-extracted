package SNMP::MibProxy;

use warnings;
use strict;


=head1 NAME

SNMP::MibProxy - Simple pass_persist script for Net-SNMP

=head1 VERSION

Version $Revision: 21422 $

=cut

# Version update....
$SNMP::MibProxy::VERSION = sprintf "1.%04d", q$Revision: 21422 $ =~ /(\d+)/g;
 
=head1 SYNOPSIS

The main script is called B<mibProxy>. Please check the documentation
of mibProxy for further details.

=head1 AUTHOR

Nito Martinez, C<< <nito at qindel.es> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-netsnmp-mibproxy at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SNMP-MibProxy>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SNMP::MibProxy

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SNMP-MibProxy>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SNMP-MibProxy>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SNMP-MibProxy>

=item * Search CPAN

L<http://search.cpan.org/dist/SNMP-MibProxy>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 by Qindel Formacion y Servicios SL, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of SNMP::MibProxy
