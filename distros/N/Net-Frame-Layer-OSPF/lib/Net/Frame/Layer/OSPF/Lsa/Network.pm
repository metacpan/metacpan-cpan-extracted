#
# $Id: Network.pm 73 2015-01-14 06:42:49Z gomor $
#
package Net::Frame::Layer::OSPF::Lsa::Network;
use strict; use warnings;

use Net::Frame::Layer qw(:consts :subs);
our @ISA = qw(Net::Frame::Layer);

our @AS = qw(
   netmask
);
our @AA = qw(
   routerList
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);
__PACKAGE__->cgBuildAccessorsArray (\@AA);

use Net::Frame::Layer::OSPF qw(:consts);

sub new {
   shift->SUPER::new(
      netmask    => '255.255.255.0',
      routerList => [],
      @_,
   );
}

sub getLength {
   my $self = shift;
   my $len = 4;
   $len += 4 for $self->routerList;
   $len;
}

sub pack {
   my $self = shift;

   my $raw = $self->SUPER::pack('a4', inetAton($self->netmask))
      or return undef;

   for ($self->routerList) {
      $raw .= $self->SUPER::pack('a4', inetAton($_))
         or return undef;
   }

   $self->raw($raw);
}

sub unpack {
   my $self = shift;

   my ($netmask, $payload) = $self->SUPER::unpack('a4 a*', $self->raw)
      or return undef;

   $self->netmask(inetNtoa($netmask));

   my @routerList;
   while ($payload && length($payload) > 3) {
      my $ip;
      ($ip, $payload) = $self->SUPER::unpack('a4 a*', $payload)
         or return undef;
      push @routerList, inetNtoa($ip);
   }
   $self->routerList(\@routerList);

   $self->payload($payload);

   $self;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf = sprintf
      "$l: netmask:%s",
         $self->netmask,
   ;

   for ($self->routerList) {
      $buf .= sprintf "\n$l: router: %s", $_;
   }

   $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::OSPF::Lsa::Network - OSPF Lsa Network type object

=head1 SYNOPSIS

   use Net::Frame::Layer::OSPF::Lsa::Network;

   my $layer = Net::Frame::Layer::OSPF::Lsa::Network->new(
      netmask    => '255.255.255.0',
      routerList => [],
   );
   $layer->pack;

   print 'RAW: '.$layer->dump."\n";

   # Read a raw layer
   my $layer = Net::Frame::Layer::OSPF::Lsa::Network->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the OSPF Lsa::Network object.

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<netmask>

Previous attributes set and get scalar values.

=item B<routerList> ( [ B<IP address>, ... ] )

This attribute takes an array ref of IP addresses.

=back

The following are inherited attributes. See B<Net::Frame::Layer> for more information.

=over 4

=item B<raw>

=item B<payload>

=item B<nextLayer>

=back

=head1 METHODS

=over 4

=item B<new>

=item B<new> (hash)

Object constructor. You can pass attributes that will overwrite default ones. See B<SYNOPSIS> for default values.

=back

The following are inherited methods. Some of them may be overriden in this layer, and some others may not be meaningful in this layer. See B<Net::Frame::Layer> for more information.

=over 4

=item B<layer>

=item B<computeLengths>

=item B<computeChecksums>

=item B<pack>

=item B<unpack>

=item B<encapsulate>

=item B<getLength>

=item B<getPayloadLength>

=item B<print>

=item B<dump>

=back

=head1 CONSTANTS

No constants here.

=head1 SEE ALSO

L<Net::Frame::Layer::OSPF>, L<Net::Frame::Layer>

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
