#
# Router Solicitation message wrapper, compliant to RFC 4861
# pvenegas@infoweapons.com
#
#
# $Id: RouterSolicitation.pm 45 2014-04-09 06:32:08Z gomor $
#
package Net::Frame::Layer::ICMPv6::RouterSolicitation;
use strict; use warnings;

use Net::Frame::Layer qw(:consts :subs);
our @ISA = qw(Net::Frame::Layer);

our @AS = qw(
   reserved
);
our @AA = qw(
   options
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);
__PACKAGE__->cgBuildAccessorsArray (\@AA);

use Net::Frame::Layer::ICMPv6 qw(:consts);
use Bit::Vector;
use Net::Frame::Layer::ICMPv6::Option;

sub new {
   shift->SUPER::new(
      reserved => 0,
      options  => [],
      @_,
   );
}

sub getOptionsLength {
   my $self = shift;
   my $len = 0;
   $len += $_->getLength for $self->options;
   return $len;
}

sub getLength {
   my $self = shift;
   return 4 + $self->getOptionsLength;
}

sub pack {
   my $self = shift;

   my $raw = $self->SUPER::pack('L', $self->reserved)
      or return;

   for ($self->options) {
      $raw .= $_->pack;
   }

   return $self->raw($raw);
}

sub _unpackOptions {
   my $self = shift;
   my ($payload) = @_;
 
   my @options = ();
   while (defined($payload) && length($payload)) {
      my $opt = Net::Frame::Layer::ICMPv6::Option->new(raw => $payload)->unpack;
      push @options, $opt;
      $payload = $opt->payload;
      $opt->payload(undef);
   }
   $self->options(\@options);
   return $payload;
}

sub unpack {
   my $self = shift;

   my ($reserved, $payload) =
      $self->SUPER::unpack('L a*', $self->raw)
         or return;

   $self->reserved($reserved);
   $self->payload($payload);

   if (defined($payload) && length($payload)) {
      $payload = $self->_unpackOptions($payload);
   }

   $self->payload($payload);

   return $self;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf = sprintf "$l: reserved: 0x%02x",
      $self->reserved;

   for ($self->options) {
      $buf .= "\n" . $_->print;
   }

   return $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::ICMPv6::RouterSolicitation - ICMPv6 Router Solicitation type object

=head1 SYNOPSIS

   use Net::Frame::Layer::ICMPv6::RouterSolicitation;

   my $layer = Net::Frame::Layer::ICMPv6::RouterSolicitation->new(
      reserved      => 0,
   );
   $layer->pack;

   print 'RAW: '.$layer->dump."\n";

   # Read a raw layer
   my $layer = Net::Frame::Layer::ICMPv6::RouterSolicitation->new(
      raw => $raw,
   );

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the ICMPv6 Router Solicitation object.

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

Refer to RFC 4861 for information on these attributes

=over 4

=item B<reserved>

=item B<options>

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

=item B<getOptionsLength>

Returns the length in bytes of options, 0 if none.

=back

The following are inherited methods. Some of them may be overridden in this layer, and some others may not be meaningful in this layer. See B<Net::Frame::Layer> for more information.

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

L<Net::Frame::Layer::ICMPv6>, L<Net::Frame::Layer>

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret
Paolo Vanni Venegas

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2014, Patrice E<lt>GomoRE<gt> Auffret
Copyright (c) 2009-2014, Paolo Vanni Venegas

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
