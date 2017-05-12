#
# $Id: DescL2.pm 2002 2015-02-15 16:50:35Z gomor $
#
package Net::Packet::DescL2;
use strict;
use warnings;

require Net::Packet::Desc;
our @ISA = qw(Net::Packet::Desc);
__PACKAGE__->cgBuildIndices;

no strict 'vars';

require Net::Write::Layer2;

sub new {
   my $self = shift->SUPER::new(@_);

   my $nwrite = Net::Write::Layer2->new(
      dev => $self->[$__dev],
   );
   $nwrite->open;

   $self->[$___io] = $nwrite;

   $self;
}

1;

__END__
   
=head1 NAME

Net::Packet::DescL2 - object for a link layer (layer 2) descriptor

=head1 SYNOPSIS

   require Net::Packet::DescL2;

   # Usually, you use it to send ARP frames, that is crafted from ETH layer
   my $d2 = Net::Packet::DescL2->new(
      dev => 'eth0',
   );

   $d2->send($rawStringToNetwork);

=head1 DESCRIPTION

See also B<Net::Packet::Desc> for other attributes and methods.

=head1 METHODS

=over 4

=item B<new>

Create the object, using default B<$Env> object values for B<dev>, B<ip>, B<ip6> and B<mac> (see B<Net::Packet::Env>). When the object is created, the B<$Env> global object has its B<desc> attributes set to it. You can avoid this behaviour by setting B<noDescAutoSet> in B<$Env> object (see B<Net::Packet::Env>).

Default values for attributes:

dev: $Env->dev

ip:  $Env->ip

ip6: $Env->ip6

mac: $Env->mac

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
