#
# $Id: RR.pm 49 2009-05-31 13:15:34Z VinsWorldcom $
#
package Net::Frame::Layer::DNS::RR;
use strict; use warnings;

use Net::Frame::Layer qw(:consts :subs);
our @ISA = qw(Net::Frame::Layer Exporter);

use Net::Frame::Layer::DNS::Constants qw(:consts);
my @consts;
for my $c (sort(keys(%constant::declared))) {
    if ($c =~ /^Net::Frame::Layer::DNS::Constants::/) {
        $c =~ s/^Net::Frame::Layer::DNS::Constants:://;
        push @consts, $c
    }
}
our %EXPORT_TAGS = (
   consts => [@consts]
);
our @EXPORT_OK = (
   @{$EXPORT_TAGS{consts}},
);

our @AS = qw(
   name
   type
   class
   ttl
   rdlength
   rdata
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::Frame::Layer::DNS qw(:subs);
use Net::Frame::Layer::DNS::RR::A;
use Net::Frame::Layer::DNS::RR::AAAA;
use Net::Frame::Layer::DNS::RR::CNAME;
use Net::Frame::Layer::DNS::RR::HINFO;
use Net::Frame::Layer::DNS::RR::MX;
use Net::Frame::Layer::DNS::RR::NS;
use Net::Frame::Layer::DNS::RR::PTR;
use Net::Frame::Layer::DNS::RR::rdata;
use Net::Frame::Layer::DNS::RR::SOA;
use Net::Frame::Layer::DNS::RR::SRV;
use Net::Frame::Layer::DNS::RR::TXT;

sub new {
   shift->SUPER::new(
      name     => 'localhost',
      type     => NF_DNS_TYPE_A,
      class    => NF_DNS_CLASS_IN,
      ttl      => 0,
      rdlength => 0,
      rdata    => '',
      @_,
   );
}

sub getLength {
   my $self = shift;

   # 1 byte leading length, name, 1 byte trailing null, 2 bytes type, 2 bytes class
   # 4 bytes ttl, 2 bytes rdlength, rdata
   if (length($self->name) == 0) {
      return length($self->name) + 11 + length($self->rdata)
   } else {
      return length($self->name) + 12 + length($self->rdata)
   }
}

sub pack {
   my $self = shift;

   my $name = dnsAton($self->name);

   if (($self->rdlength == 0) && (length($self->rdata) > 0)) {
      $self->rdlength(length($self->rdata))
   }

   $self->raw($self->SUPER::pack('H* nnNn a*',
      $name, $self->type, $self->class, $self->ttl, $self->rdlength, $self->rdata
   )) or return;

   return $self->raw;
}

sub unpack {
   my $self = shift;

   my ($name, $ptr1) = dnsNtoa($self->raw);

   my ($type, $class, $ttl, $rdlength, $payload) =
      $self->SUPER::unpack('nnNn a*', (substr $self->raw, $ptr1))
         or return;

   $self->name($name);
   $self->type($type);
   $self->class($class);
   $self->ttl($ttl);
   $self->rdlength($rdlength);

   $self->payload($payload);

   return $self;
}

sub encapsulate {
   my $self = shift;

   return $self->nextLayer if $self->nextLayer;

   if ($self->payload) {
      if ($self->rdlength == 0) {
         return "DNS::RR"
      } elsif ($self->type == NF_DNS_TYPE_A) {
         return "DNS::RR::A"
      } elsif ($self->type == NF_DNS_TYPE_AAAA) {
         return "DNS::RR::AAAA"
      } elsif ($self->type == NF_DNS_TYPE_CNAME) {
         return "DNS::RR::CNAME"
      } elsif ($self->type == NF_DNS_TYPE_HINFO) {
         return "DNS::RR::HINFO"
      } elsif ($self->type == NF_DNS_TYPE_MX) {
         return "DNS::RR::MX"
      } elsif ($self->type == NF_DNS_TYPE_NS) {
         return "DNS::RR::NS"
      } elsif ($self->type == NF_DNS_TYPE_PTR) {
         return "DNS::RR::PTR"
      } elsif ($self->type == NF_DNS_TYPE_SOA) {
         return "DNS::RR::SOA"
      } elsif ($self->type == NF_DNS_TYPE_SRV) {
         return "DNS::RR::SRV"
      } elsif ($self->type == NF_DNS_TYPE_TXT) {
         return "DNS::RR::TXT"
      }  else {
         # must include rdlength on calls to DNS::RR::rdata
         my $temp = $self->SUPER::pack('n a*',
            $self->rdlength, $self->payload
         ) or return;
         $self->payload($temp);
         return "DNS::RR::rdata"
      }
   }

   NF_LAYER_NONE;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf = sprintf
      "$l: name:%s\n".
      "$l: type:%d  class:%d  ttl:%d  rdlength:%d",
         $self->name,
         $self->type, $self->class, $self->ttl, $self->rdlength;

   return $buf;
}

1;

__END__

=head1 NAME

Net::Frame::Layer::DNS::RR - DNS Resource Record type object

=head1 SYNOPSIS

   use Net::Frame::Layer::DNS::RR qw(:consts);

   my $layer = Net::Frame::Layer::DNS::RR->new(
      name     => 'localhost',
      type     => NF_DNS_TYPE_A,
      class    => NF_DNS_CLASS_IN,
      ttl      => 0,
      rdlength => 0,
      rdata    => '',
   );
   $layer->pack;

   print 'RAW: '.$layer->dump."\n";

   # Create RR with rdata
   use Net::Frame::Layer::DNS::RR::A;

   my $rdata = Net::Frame::Layer::DNS::RR::A->new;
   my $layer = Net::Frame::Layer::DNS::RR->new(
      rdata => $rdata->pack,
   );
   $layer->pack;

   # Read a raw layer
   my $layer = Net::Frame::Layer::DNS::RR->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the DNS Resource Record object.

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<name>

Resource name (hostname / domain).

=item B<type>

Record type.  See B<CONSTANTS> for more information.

=item B<class>

Class type.  See B<CONSTANTS> for more information.

=item B<ttl>

Time interval (in seconds) that the resource record may be cached before 
it should be discarded.  Zero (0) means the RR can only be used for the 
current transaction and should not be cached.

=item B<rdlength>

Length in octets of the RDATA field.

=item B<rdata>

String of octets that describes the resource.  Can be created with any 
B<Net::Frame::Layer::DNS::RR::*> modules.  See B<SYNOPSIS> for example.

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

Load them: use Net::Frame::Layer::DNS::RR qw(:consts);

See B<Net::Frame::Layer::DNS::Constants> for more information.

=head1 SEE ALSO

L<Net::Frame::Layer::DNS>, L<Net::Frame::Layer>

=head1 AUTHOR

Michael Vincent

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012, Michael Vincent

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
