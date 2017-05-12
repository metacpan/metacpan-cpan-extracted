#
# $Id: Write.pm 2014 2015-03-04 06:16:57Z gomor $
#
package Net::Write;
use strict;
use warnings;

require v5.6.1;

our $VERSION = '1.10';

1;

__END__

=head1 NAME

Net::Write - a portable interface to open and send raw data to network

=head1 DESCRIPTION

B<Net::Write> provides a portable interface to open a network interface, and be able to write raw data directly to the network. It juste provides three methods when a B<Net::Write> object has been created for an interface: B<open>, B<send>, B<close>.

It is possible to open a network interface to send frames at layer 2 (you craft a frame from link layer), or at layer 3 (you craft a frame from network layer), or at layer 4 (you craft a frame from transport layer).

NOTE: not all operating systems support all layer opening. Currently, Windows only supports opening and sending at layer 2. Other Unix systems should be able to open and send at all layers.

=head1 SEE ALSO

L<Net::Write::Layer>, L<Net::Write::Layer2>, L<Net::Write::Layer3>, L<Net::Write::Layer4>

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
