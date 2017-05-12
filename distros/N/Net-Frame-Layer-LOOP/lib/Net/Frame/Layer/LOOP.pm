#
# $Id: LOOP.pm 4 2015-01-14 06:34:44Z gomor $
#
package Net::Frame::Layer::LOOP;
use strict; use warnings;

our $VERSION = '1.01';

use Net::Frame::Layer qw(:consts);
use Exporter;
our @ISA = qw(Net::Frame::Layer Exporter);

our %EXPORT_TAGS = (
   consts => [qw(
      NF_LOOP_HDR_LEN
      NF_LOOP_FUNCTION_REPLY
   )],
);
our @EXPORT_OK = (
   @{$EXPORT_TAGS{consts}},
);

use constant NF_LOOP_HDR_LEN        => 6;
use constant NF_LOOP_FUNCTION_REPLY => 0x0100;

our @AS = qw(
   skipCount
   function
   receiptNumber
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub new {
   shift->SUPER::new(
      skipCount     => 0,
      function      => NF_LOOP_FUNCTION_REPLY,
      receiptNumber => 0,
      @_,
   );
}

sub getLength { NF_LOOP_HDR_LEN }

sub pack {
   my $self = shift;

   $self->raw($self->SUPER::pack('nnn',
      $self->skipCount,
      $self->function,
      $self->receiptNumber,
   )) or return undef;

   $self->raw;
}

sub unpack {
   my $self = shift;

   my ($skipCount, $function, $receiptNumber, $payload) =
      $self->SUPER::unpack('nnn a*', $self->raw)
         or return undef;

   $self->skipCount($skipCount);
   $self->function($function);
   $self->receiptNumber($receiptNumber);

   $self->payload($payload);

   $self;
}

sub encapsulate { shift->nextLayer }

sub print {
   my $self = shift;

   my $l = $self->layer;
   sprintf "$l: skipCount:%d  function:0x%04x  receiptNumber:%d",
      $self->skipCount,
      $self->function,
      $self->receiptNumber,
   ;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::LOOP - LOOP layer object

=head1 SYNOPSIS

   use Net::Frame::Layer::LOOP qw(:consts);

   # Build a layer
   my $layer = Net::Frame::Layer::LOOP->new(
      skipCount     => 0,
      function      => NF_LOOP_FUNCTION_REPLY,
      receiptNumber => 0,
   );
   $layer->pack;

   print 'RAW: '.$layer->dump."\n";

   # Read a raw layer
   my $layer = Net::Frame::Layer::LOOP->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the LOOP layer.

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<skipCount> - 16 bits

=item B<function> - 16 bits

=item B<receiptNumber> - 16 bits

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

Load them: use Net::Frame::Layer::LOOP qw(:consts);

=over 4

=item B<NF_LOOP_HDR_LEN>

=item B<NF_LOOP_FUNCTION_REPLY>

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
