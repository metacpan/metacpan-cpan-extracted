#
# $Id: LinkStateRequest.pm 73 2015-01-14 06:42:49Z gomor $
#
package Net::Frame::Layer::OSPF::LinkStateRequest;
use strict; use warnings;

use Net::Frame::Layer qw(:consts :subs);
our @ISA = qw(Net::Frame::Layer);

our @AS = qw(
   lsType
   linkStateId
   advertisingRouter
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::Frame::Layer::OSPF qw(:consts);

sub new {
   shift->SUPER::new(
      lsType            => 0,
      linkStateId       => '0.0.0.0',
      advertisingRouter => '0.0.0.0',
      @_,
   );
}

sub getLength { 12 }

sub pack {
   my $self = shift;

   $self->raw($self->SUPER::pack('Na4a4',
      $self->lsType, inetAton($self->linkStateId),
      inetAton($self->advertisingRouter),
   )) or return undef;

   $self->raw;
}

sub unpack {
   my $self = shift;

   my ($lsType, $linkStateId, $advertisingRouter, $payload) =
      $self->SUPER::unpack('Na4a4 a*', $self->raw)
         or return undef;

   $self->lsType($lsType);
   $self->linkStateId(inetNtoa($linkStateId));
   $self->advertisingRouter(inetNtoa($advertisingRouter));

   $self->payload($payload);

   $self;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   sprintf "$l: lsType:0x%08x  linkStateId:%s\n".
           "$l: advertisingRouter:%s",
      $self->lsType, $self->linkStateId, $self->advertisingRouter,
   ;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::OSPF::LinkStateRequest - OSPF LinkStateRequest type object

=head1 SYNOPSIS

   use Net::Frame::Layer::OSPF::LinkStateRequest;

   my $layer = Net::Frame::Layer::OSPF::LinkStateRequest->new(
      lsType            => 0,
      linkStateId       => '0.0.0.0',
      advertisingRouter => '0.0.0.0',
   );
   $layer->pack;

   print 'RAW: '.$layer->dump."\n";

   # Read a raw layer
   my $layer = Net::Frame::Layer::OSPF::LinkStateRequest->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the OSPF LinkStateRequest object.

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<lsType>

=item B<linkStateId>

=item B<advertisingRouter>

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
