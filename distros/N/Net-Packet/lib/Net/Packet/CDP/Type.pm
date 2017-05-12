#
# $Id: Type.pm 2002 2015-02-15 16:50:35Z gomor $
#
package Net::Packet::CDP::Type;
use strict;
use warnings;

require Net::Packet::Layer4;
our @ISA = qw(Net::Packet::Layer4);

our @AS = qw(
   type
   length
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

no strict 'vars';

sub getLength { shift->[$__length] }

1;

__END__

=head1 NAME

Net::Packet::CDP::Type - base class for Cisco Discovery Protocol extension headers

=head1 DESCRIPTION

This is the base class for B<Net::Packet::CDP> various extension headers. For other attributes and methods, see B<Net::Packet::Layer> and B<Net::Packet::Layer4>.

It just provides those extension headers with inheritable attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<type> - 16 bits

=item B<length> - 16 bits

=back

=head1 CONSTANTS

See B<Net::Packet::CDP> CONSTANTS.

=over 4

=back

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2004-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=head1 RELATED MODULES

L<NetPacket>, L<Net::RawIP>, L<Net::RawSock>

=cut
