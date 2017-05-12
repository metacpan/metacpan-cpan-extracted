#
# $Id: SRV.pm 49 2009-05-31 13:15:34Z VinsWorldcom $
#
package Net::Frame::Layer::DNS::RR::SRV;
use strict; use warnings;

use Net::Frame::Layer qw(:consts :subs);
our @ISA = qw(Net::Frame::Layer Exporter);

our @AS = qw(
   priority
   weight
   port
   target
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::Frame::Layer::DNS qw(:subs);

sub new {
   shift->SUPER::new(
      priority => 1,
      weight   => 0,
      port     => 53,
      target   => 'localhost',
      @_,
   );
}

sub getLength {
   my $self = shift;
   return length($self->target) + 6;
}

sub pack {
   my $self = shift;

   my $name = dnsAton($self->target);

   $self->raw($self->SUPER::pack('nnn H*',
      $self->priority, $self->weight, $self->port, $name
   )) or return;

   return $self->raw;
}

sub unpack {
   my $self = shift;

   my ($priority, $weight, $port, $target) =
      $self->SUPER::unpack('nnn a*', $self->raw)
         or return;

   my ($name, $ptr) = dnsNtoa($target);

   $self->priority($priority);
   $self->weight($weight);
   $self->port($port);
   $self->target($name);

   $self->payload(substr $self->raw, $ptr+6);

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
      "$l: priority:%d  weight:%d  port:%d\n".
      "$l: target:%s",
         $self->priority, $self->weight, $self->port,
         $self->target;

   return $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::DNS::RR::SRV - DNS Resource Record SRV rdata type

=head1 SYNOPSIS

   use Net::Frame::Layer::DNS::RR::SRV;

   my $rdata = Net::Frame::Layer::DNS::RR::SRV->new(
      priority => 1,
      weight   => 0,
      port     => 53,
      target   => 'localhost',
   );
   $rdata->pack;

   print 'RAW: '.$rdata->dump."\n";

   # Create RR with rdata
   use Net::Frame::Layer::DNS::RR qw(:consts);
   
   my $layer = Net::Frame::Layer::DNS::RR->new(
      type  => NF_DNS_TYPE_SRV
      rdata => $rdata->pack
   );
   $layer->pack;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the DNS Resource 
Record SRV rdata type object.  Users need only use this for encoding.
B<Net::Frame::Layer::DNS::RR> calls this as needed to assist in C<rdata>
decoding.

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<priority>

Priority of target host, lower are preferred.

=item B<weight>

Weight for entries with the same priority, higher are preferred.

=item B<port>

The port on target host of service.

=item B<target>

Domain name of the target host.

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
