#
# $Id: rdata.pm 49 2009-05-31 13:15:34Z VinsWorldcom $
#
package Net::Frame::Layer::DNS::RR::rdata;
use strict; use warnings;

use Net::Frame::Layer qw(:consts :subs);
our @ISA = qw(Net::Frame::Layer Exporter);

our @AS = qw(
   rdata
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::Frame::Layer::DNS;

sub unpack {
   my $self = shift;

   # must include rdlength on calls to DNS::RR::rdata
   my ($rdlength, $rdata) =
      $self->SUPER::unpack('n a*', $self->raw)
         or return;

   $self->rdata(CORE::unpack "H*", (substr $rdata, 0, $rdlength));

   $self->payload(substr $self->raw, $rdlength+2);

   return $self;
}

sub encapsulate {
   my $self = shift;

   return $self->nextLayer if $self->nextLayer;

   if ($self->payload) {
      return 'DNS::RR';
   }

   NF_LAYER_NONE;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf = sprintf
      "$l: rdata:%s",
         $self->rdata;

   return $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::DNS::RR::rdata - DNS Resource Record generic rdata type

=head1 SYNOPSIS

   use Net::Frame::Layer::DNS::RR::rdata;

=head1 DESCRIPTION

This modules implements the decoding of a DNS Resource Record with an 
rdata type for which there isn't a decoder.  B<Net::Frame::Layer::DNS::RR> 
calls this as needed to assist in C<rdata> decoding.

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

The following are inherited attributes. See B<Net::Frame::Layer> for more information.

=over 4

=item B<raw>

=item B<payload>

=item B<nextLayer>

=back

=head1 METHODS

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

L<Net::Frame::Layer::DNS>, L<Net::Frame::Layer::DNS::RR>, L<Net::Frame::Layer>

=head1 AUTHOR

Michael Vincent

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012, Michael Vincent

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
