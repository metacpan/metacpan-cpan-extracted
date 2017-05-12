#
# $Id: TXT.pm 49 2009-05-31 13:15:34Z VinsWorldcom $
#
package Net::Frame::Layer::DNS::RR::TXT;
use strict; use warnings;

use Net::Frame::Layer qw(:consts :subs);
our @ISA = qw(Net::Frame::Layer Exporter);

our @AS = qw(
   txtdata
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::Frame::Layer::DNS qw(:subs);

sub new {
   shift->SUPER::new(
      txtdata => 'textdata',
      @_,
   );
}

sub getLength {
   my $self = shift;
   return length($self->txtdata)
}

sub pack {
   my $self = shift;

   $self->raw($self->SUPER::pack('C a*',
      length($self->txtdata), $self->txtdata
   )) or return;

   return $self->raw;
}

sub unpack {
   my $self = shift;

   my ($txtlen, $txtdata) =
      $self->SUPER::unpack('C a*', $self->raw)
         or return;

   $self->txtdata($txtdata);

   $self->payload(substr $self->raw, $txtlen+1);

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
      "$l: txtdata:%s",
         $self->txtdata;

   return $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::DNS::RR::TXT - DNS Resource Record TXT rdata type

=head1 SYNOPSIS

   use Net::Frame::Layer::DNS::RR::TXT;

   my $rdata = Net::Frame::Layer::DNS::RR::TXT->new(
      txtdata => 'textdata',
   );
   $rdata->pack;

   print 'RAW: '.$rdata->dump."\n";

   # Create RR with rdata
   use Net::Frame::Layer::DNS::RR qw(:consts);
   
   my $layer = Net::Frame::Layer::DNS::RR->new(
      type  => NF_DNS_TYPE_TXT
      rdata => $rdata->pack
   );
   $layer->pack;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the DNS Resource 
Record TXT rdata type object.  Users need only use this for encoding.
B<Net::Frame::Layer::DNS::RR> calls this as needed to assist in C<rdata>
decoding.

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<txtdata>

Text data - character string.

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

L<Net::Frame::Layer::DNS>, L<Net::Frame::Layer::DNS::RR>, L<Net::Frame::Layer>

=head1 AUTHOR

Michael Vincent

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012, Michael Vincent

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
