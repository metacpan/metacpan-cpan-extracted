#
# $Id: SOA.pm 49 2009-05-31 13:15:34Z VinsWorldcom $
#
package Net::Frame::Layer::DNS::RR::SOA;
use strict; use warnings;

use Net::Frame::Layer qw(:consts :subs);
our @ISA = qw(Net::Frame::Layer Exporter);

our @AS = qw(
   mname
   rname
   serial
   refresh
   retry
   expire
   minimum
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::Frame::Layer::DNS qw(:subs);

sub new {
   shift->SUPER::new(
      mname   => 'localhost',
      rname   => 'administrator.localhost',
      serial  => 0,
      refresh => 0,
      retry   => 0,
      expire  => 0,
      minimum => 0,
      @_,
   );
}

sub getLength {
   my $self = shift;

   my $mnamelen = 1;
   my $rnamelen = 1;
   if (length($self->mname) > 0) {
      $mnamelen = length($self->mname) + 2
   }
   if (length($self->rname) > 0) {
      $rnamelen = length($self->rname) + 2
   }
   return $mnamelen + $rnamelen + 20 # 4 bytes x 5 values (serial, refresh ...)
}

sub pack {
   my $self = shift;

   my $mname = Net::Frame::Layer::DNS::dnsAton($self->mname);
   my $rname = Net::Frame::Layer::DNS::dnsAton($self->rname);

   $self->raw($self->SUPER::pack('H*H*NNNNN',
      $mname,
      $rname,
      $self->serial,
      $self->refresh,
      $self->retry,
      $self->expire,
      $self->minimum
   )) or return;

   return $self->raw;
}

sub unpack {
   my $self = shift;

   my ($mname, $ptr) = dnsNtoa($self->raw);
   my ($rname, $ptr1) = dnsNtoa(substr $self->raw, $ptr);

   $self->mname($mname);
   $self->rname($rname);

   my ($serial, $refresh, $retry, $expire, $minimum, $payload) =
      $self->SUPER::unpack('NNNNN a*', (substr $self->raw, $ptr+$ptr1))
         or return;

   $self->serial($serial);
   $self->refresh($refresh);
   $self->retry($retry);
   $self->expire($expire);
   $self->minimum($minimum);

   $self->payload($payload);

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
      "$l: mname:%s  rname:%s\n".
      "$l: serial:%d  refresh:%d  retry:%d\n".
      "$l: expire:%d  minimum:%d",
         $self->mname, $self->rname,
         $self->serial, $self->refresh, $self->retry,
         $self->expire, $self->minimum;

   return $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::DNS::RR::SOA - DNS Resource Record SOA rdata type

=head1 SYNOPSIS

   use Net::Frame::Layer::DNS::RR::SOA;

   my $rdata = Net::Frame::Layer::DNS::RR::SOA->new(
      mname   => 'localhost',
      rname   => 'administrator.localhost',
      serial  => 0,
      refresh => 0,
      retry   => 0,
      expire  => 0,
      minimum => 0,
   );
   $rdata->pack;

   print 'RAW: '.$rdata->dump."\n";

   # Create RR with rdata
   use Net::Frame::Layer::DNS::RR qw(:consts);
   
   my $layer = Net::Frame::Layer::DNS::RR->new(
      type  => NF_DNS_TYPE_SOA
      rdata => $rdata->pack
   );
   $layer->pack;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the DNS Resource 
Record SOA rdata type object.  Users need only use this for encoding.
B<Net::Frame::Layer::DNS::RR> calls this as needed to assist in C<rdata>
decoding.

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<mname>

The name of the name server that was the original or primary source of
data for this zone.

=item B<rname>

A name which specifies the mailbox of the person responsible for this
zone.

=item B<serial>

The version number of the original copy of the zone.

=item B<refresh>

Time interval before the zone should be refreshed.

=item B<retry>

Time interval that should elapse before a failed refresh should be
retried.

=item B<expire>

Time value that specifies the upper limit on the time interval that can 
elapse before the zone is no longer authoritative.

=item B<minimum>

Minimum TTL that should be exported with any RR from this zone.

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
