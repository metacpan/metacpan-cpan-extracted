#
# $Id: PPPLCP.pm 5 2015-01-14 06:47:16Z gomor $
#
package Net::Frame::Layer::PPPLCP;
use strict; use warnings;

our $VERSION = '1.01';

use Net::Frame::Layer qw(:consts);
use Exporter;
our @ISA = qw(Net::Frame::Layer Exporter);

our %EXPORT_TAGS = (
   consts => [qw(
      NF_PPPLCP_HDR_LEN
      NF_PPPLCP_CODE_ECHO_REQUEST
      NF_PPPLCP_CODE_ECHO_REPLY
   )],
);
our @EXPORT_OK = (
   @{$EXPORT_TAGS{consts}},
);

use constant NF_PPPLCP_HDR_LEN           => 8;
use constant NF_PPPLCP_CODE_ECHO_REQUEST => 0x09;
use constant NF_PPPLCP_CODE_ECHO_REPLY   => 0x0a;

our @AS = qw(
   code
   identifier
   length
   magicNumber
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub new {
   shift->SUPER::new(
      code        => NF_PPPLCP_CODE_ECHO_REQUEST,
      identifier  => 1,
      length      => NF_PPPLCP_HDR_LEN,
      magicNumber => 0xffffffff,
      @_,
   );
}

sub getLength { shift->length }

sub getPayloadLength { shift->getLength - NF_PPPLCP_HDR_LEN }

sub pack {
   my $self = shift;

   $self->raw($self->SUPER::pack('CCnN',
      $self->code,
      $self->identifier,
      $self->length,
      $self->magicNumber,
   )) or return undef;

   $self->raw;
}

sub unpack {
   my $self = shift;

   my ($code, $identifier, $length, $magicNumber, $payload) =
      $self->SUPER::unpack('CCnN a*', $self->raw)
         or return undef;

   $self->code($code);
   $self->identifier($identifier);
   $self->length($length);
   $self->magicNumber($magicNumber);

   $self->payload($payload);

   $self;
}

sub encapsulate { shift->nextLayer }

sub print {
   my $self = shift;

   my $l = $self->layer;
   sprintf "$l: code:0x%02x  identifier:0x%02x  length:%d  magicNumber:0x%04x",
      $self->code,
      $self->identifier,
      $self->length,
      $self->magicNumber,
   ;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::PPPLCP - PPP Link Control Protocol layer object

=head1 SYNOPSIS

   use Net::Frame::Layer::PPPLCP qw(:consts);

   # Build a layer
   my $layer = Net::Frame::Layer::PPPLCP->new(
      code        => NF_PPPLCP_CODE_ECHO_REQUEST,
      identifier  => 1,
      length      => NF_PPPLCP_HDR_LEN,
      magicNumber => 0xffffffff,
   );
   $layer->pack;

   print 'RAW: '.$layer->dump."\n";

   # Read a raw layer
   my $layer = Net::Frame::Layer::PPPLCP->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the PPPLCP layer.

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<code> - 8 bits

=item B<identifier> - 8 bits

=item B<length> - 16 bits

=item B<magicNumber> - 32 bits

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

Load them: use Net::Frame::Layer::PPPLCP qw(:consts);

=over 4

=item B<NF_PPPLCP_HDR_LEN>

=item B<NF_PPPLCP_CODE_ECHO_REQUEST>

=item B<NF_PPPLCP_CODE_ECHO_REPLY>

=back

=head1 SEE ALSO

L<Net::Frame::Layer>

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
