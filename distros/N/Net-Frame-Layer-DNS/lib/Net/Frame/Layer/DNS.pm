#
# $Id: DNS.pm 49 2013-03-04 13:15:34Z VinsWorldcom $
#
package Net::Frame::Layer::DNS;
use strict; use warnings;

our $VERSION = '1.04';

use Net::Frame::Layer qw(:consts :subs);
use Exporter;
our @ISA = qw(Net::Frame::Layer Exporter);

our %EXPORT_TAGS = (
   consts => [qw(
      NF_DNS_QR_QUERY
      NF_DNS_QR_RESPONSE
      NF_DNS_OPCODE_QUERY
      NF_DNS_OPCODE_IQUERY
      NF_DNS_OPCODE_STATUS
      NF_DNS_OPCODE_NOTIFY
      NF_DNS_OPCODE_UPDATE
      NF_DNS_FLAGS_AA
      NF_DNS_FLAGS_TC
      NF_DNS_FLAGS_RD
      NF_DNS_FLAGS_RA
      NF_DNS_FLAGS_Z
      NF_DNS_FLAGS_AD
      NF_DNS_FLAGS_CD
      NF_DNS_RCODE_NOERROR
      NF_DNS_RCODE_FORMATERROR
      NF_DNS_RCODE_SERVERFAILURE
      NF_DNS_RCODE_NAMEERROR
      NF_DNS_RCODE_NOTIMPLEMENTED
      NF_DNS_RCODE_REFUSED
      NF_DNS_RCODE_YXDOMAIN
      NF_DNS_RCODE_YXRRSET
      NF_DNS_RCODE_NXRRSET
      NF_DNS_RCODE_NOTAUTH
      NF_DNS_RCODE_NOTZONE
   )],
   subs => [qw(
      dnsAton
      dnsNtoa
   )],
);
our @EXPORT_OK = (
   @{$EXPORT_TAGS{consts}},
   @{$EXPORT_TAGS{subs}},
);

use constant NF_DNS_QR_QUERY             => 0;
use constant NF_DNS_QR_RESPONSE          => 1;
use constant NF_DNS_OPCODE_QUERY         => 0;
use constant NF_DNS_OPCODE_IQUERY        => 1;
use constant NF_DNS_OPCODE_STATUS        => 1;
use constant NF_DNS_OPCODE_NOTIFY        => 4;
use constant NF_DNS_OPCODE_UPDATE        => 5;
use constant NF_DNS_FLAGS_AA             => 0x40;
use constant NF_DNS_FLAGS_TC             => 0x20;
use constant NF_DNS_FLAGS_RD             => 0x10;
use constant NF_DNS_FLAGS_RA             => 0x08;
use constant NF_DNS_FLAGS_Z              => 0x04;
use constant NF_DNS_FLAGS_AD             => 0x02;
use constant NF_DNS_FLAGS_CD             => 0x01;
use constant NF_DNS_RCODE_NOERROR        => 0;
use constant NF_DNS_RCODE_FORMATERROR    => 1;
use constant NF_DNS_RCODE_SERVERFAILURE  => 2;
use constant NF_DNS_RCODE_NAMEERROR      => 3;
use constant NF_DNS_RCODE_NOTIMPLEMENTED => 4;
use constant NF_DNS_RCODE_REFUSED        => 5;
use constant NF_DNS_RCODE_YXDOMAIN       => 6;
use constant NF_DNS_RCODE_YXRRSET        => 7;
use constant NF_DNS_RCODE_NXRRSET        => 8;
use constant NF_DNS_RCODE_NOTAUTH        => 9;
use constant NF_DNS_RCODE_NOTZONE        => 10;

our @AS = qw(
   id
   qr
   opcode
   flags
   rcode
   qdCount
   anCount
   nsCount
   arCount
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

#no strict 'vars';

use Bit::Vector;
use Net::Frame::Layer::DNS::Constants qw(:consts);

my $dns_payload;

$Net::Frame::Layer::UDP::Next->{53} = "DNS";

sub new {
   shift->SUPER::new(
      id      => getRandom16bitsInt(),
      qr      => NF_DNS_QR_QUERY,
      opcode  => NF_DNS_OPCODE_QUERY,
      flags   => NF_DNS_FLAGS_RD,
      rcode   => NF_DNS_RCODE_NOERROR,
      qdCount => 1,
      anCount => 0,
      nsCount => 0,
      arCount => 0,
      @_,
   );
}

sub match {
   my $self = shift;
   my ($with) = @_;
   my $sQr = $self->qr;
   my $sId = $self->id;
   my $wQr = $with->qr;
   my $wId = $with->id;
   if (($sQr == NF_DNS_QR_QUERY)
   &&  ($wQr == NF_DNS_QR_RESPONSE)
   &&  ($sId == $wId)) {
      return 1;
   }
   0;
}

# XXX: may be better, by keying on type also
sub getKey        { shift->layer }
sub getKeyReverse { shift->layer }

sub getLength { 12 }

sub pack {
   my $self = shift;

   my $qr     = Bit::Vector->new_Dec(1, $self->qr);
   my $opcode = Bit::Vector->new_Dec(4, $self->opcode);
   my $flags  = Bit::Vector->new_Dec(7, $self->flags);
   my $rcode  = Bit::Vector->new_Dec(4, $self->rcode);
   my $bvlist = $qr->Concat_List($opcode, $flags, $rcode);

   my $raw = $self->SUPER::pack('nnnnnn',
      $self->id,
      $bvlist->to_Dec,
      $self->qdCount,
      $self->anCount,
      $self->nsCount,
      $self->arCount
   ) or return;

   return $self->raw($raw);
}

sub unpack {
   my $self = shift;

   $dns_payload = $self->raw;

   my ($id, $bv, $qdCount, $anCount, $nsCount, $arCount, $payload) =
      $self->SUPER::unpack('nnnnnn a*', $self->raw)
         or return;

   $self->id($id);

   my $bvlist = Bit::Vector->new_Dec(16, $bv);
   $self->qr    ($bvlist->Chunk_Read(1,15));
   $self->opcode($bvlist->Chunk_Read(4,11));
   $self->flags ($bvlist->Chunk_Read(7, 4));
   $self->rcode ($bvlist->Chunk_Read(4, 0));

   $self->qdCount($qdCount);
   $self->anCount($anCount);
   $self->nsCount($nsCount);
   $self->arCount($arCount);

   $self->payload($payload);

   return $self;
}

sub encapsulate {
   my $self = shift;

   return $self->nextLayer if $self->nextLayer;

   if ($self->payload) {
      return 'DNS::Question';
   }

   NF_LAYER_NONE;
}

sub print {
   my $self = shift;

   my $l = $self->layer;
   my $buf = sprintf
      "$l: id:%d  qr:%d  opcode:%d  flags:0x%02x  rcode:%d\n".
      "$l: qdCount:%d  anCount:%d\n".
      "$l: nsCount:%d  arCount:%d",
         $self->id, $self->qr, $self->opcode, $self->flags, $self->rcode,
         $self->qdCount, $self->anCount,
         $self->nsCount, $self->arCount;

   return $buf;
}

####

sub dnsAton {
   my $self = shift;

   # Weird pack routine.  Queries are encoded by:
   #  <length of characters in bytes to first "."><chars> ...
   # For example:
   #  3www6google3com\0
   #  0377777706676f6f676c6503636f6d00
   #   3 w w w 6 g o o g l e 3 c o m\0
   my $name = '';
   my @parts = split /\./, $self;
   for my $part (@parts) {
      $name .= sprintf "%.2x%s", length($part), CORE::unpack "H*", $part
   }
   $name .= CORE::unpack "H*", "\0";
   return $name
}

sub dnsNtoa {
   my $self = shift;

   my $name = '';
   my $start = 0;
   my $i;
   for ($i = 0; $i < length($self); $i++) {
      # start counts down the letters in section (originally separate by '.')
      if ($start == 0) {
         $start = hex (CORE::unpack "H*", (substr $self, $i, 1));
         # If null, done name
         if ($start == 0) {
            $i+=1;
            last
         }
         # if pointer, done name ...
         if (($start & 0xc0) == 0xc0) {
            # get pointer position
            my $ptr = hex (CORE::unpack "H*", (substr $self, $i+1, 1));
            if ($name ne '') { $name .= "." }
            $name .= "[@" . $ptr . "(";
            $i+=2;
            # resolve pointer if possible
            if (defined($ptr = _getptr($ptr))) {
               $name .= $ptr
            } else {
               $name .= "!ERROR!"
            }
            $name .= ")]";
            # done
            last
         }
         # add . to name to separate
         if ($name ne '') {
            $name .= '.'
         }
         next
      }
      my $t = hex (CORE::unpack "H*", (substr $self, $i, 1));
      # If null, done name
      if ($t == 0) {
         $i+=1;
         last
      }
      # If pointer, done name ...
      if (($t & 0xc0) == 0xc0) {
         # get pointer position
         my $ptr = hex (CORE::unpack "H*", (substr $self, $i+1, 1));
         if ($name ne '') { $name .= "." }
         $name .= "[@" . $ptr . "(";
         $i+=2;
         # resolve pointer if possible
         if (defined($ptr = _getptr($ptr))) {
            $name .= $ptr
         } else {
            $name .= "!ERROR!"
         }
         $name .= ")]";
         # done
         last
      }
      # add next letter to name
      $name .= substr $self, $i, 1;
      $start--
   }

   return ($name, $i)
}

sub _getptr {
   my $ptr = shift;

   if (defined($dns_payload)) {
      my ($name) = dnsNtoa(substr $dns_payload, $ptr);
      return $name
   }
   return undef
}

1;

__END__

=head1 NAME

Net::Frame::Layer::DNS - Domain Name System layer object

=head1 SYNOPSIS

   use Net::Frame::Simple;
   use Net::Frame::Layer::DNS qw(:consts);

   my $dns = Net::Frame::Layer::DNS->new(
      id      => getRandom16bitsInt(),
      qr      => NF_DNS_QR_QUERY,
      opcode  => NF_DNS_OPCODE_QUERY,
      flags   => NF_DNS_FLAGS_RD,
      rcode   => NF_DNS_RCODE_NOERROR,
      qdCount => 1,
      anCount => 0,
      nsCount => 0,
      arCount => 0,
   );

   #
   # Read a raw layer
   #

   my $layer = Net::Frame::Layer::DNS->new(raw => $raw);

   print $layer->print."\n";
   print 'PAYLOAD: '.unpack('H*', $layer->payload)."\n"
      if $layer->payload;

=head1 DESCRIPTION

This modules implements the encoding and decoding of the DNS layer.

RFC: ftp://ftp.rfc-editor.org/in-notes/rfc1035.txt

See also B<Net::Frame::Layer> for other attributes and methods.

=head1 ATTRIBUTES

=over 4

=item B<id>

Identification - used to match request/reply packets.

=item B<qr>

=item B<opcode>

=item B<flags>

=item B<rcode>

Qr, opcode, flags and rcode fields. See B<CONSTANTS>.

=item B<qdCount>

Number of entries in the question list.

=item B<anCount>

Number of entries in the answer resource record that were returned.

=item B<nsCount>

Number of entries in the authority resource record list that were returned.

=item B<arCount>

Number of entries in the additional resource record list that were returned.

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

=item B<getKey>

=item B<getKeyReverse>

These two methods are basically used to increase the speed when using B<recv> method from B<Net::Frame::Simple>. Usually, you write them when you need to write B<match> method.

=item B<match> (Net::Frame::Layer::DNS object)

This method is mostly used internally. You pass a B<Net::Frame::Layer::DNS> layer as a parameter, and it returns true if this is a response corresponding for the request, or returns false if not.

=back

The following are inherited methods. Some of them may be overriden in this layer, and some others may not be meaningful in this layer. See B<Net::Frame::Layer> for more information.

=over 4

=item B<layer>

=item B<computeLengths>

=item B<pack>

=item B<unpack>

=item B<encapsulate>

=item B<getLength>

=item B<getPayloadLength>

=item B<print>

=item B<dump>

=back

=head1 USEFUL SUBROUTINES

Load them: use Net::Frame::Layer::DNS qw(:subs);

=over 4

=item B<dnsAton> (domain name)

Takes domain name and returns the network form.

=item B<dnsNtoa> (domain name network form)

Takes domain name in network format, and returns the domain name human form 
and number of bytes read.  Call with:

   my ($name, $bytesRead) = dnsNtoa( ... ) # returns name, bytes read
   my ($name)             = dnsNtoa( ... ) # returns name only

=back

=head1 CONSTANTS

Load them: use Net::Frame::Layer::DNS qw(:consts);

=over 4

=item B<NF_DNS_QR_QUERY>

=item B<NF_DNS_QR_RESPONSE>

Query / Response flag.

=item B<NF_DNS_OPCODE_QUERY>

=item B<NF_DNS_OPCODE_IQUERY>

=item B<NF_DNS_OPCODE_STATUS>

=item B<NF_DNS_OPCODE_NOTIFY>

=item B<NF_DNS_OPCODE_UPDATE>

Opcode values.

=item B<NF_DNS_FLAGS_AA>

=item B<NF_DNS_FLAGS_TC>

=item B<NF_DNS_FLAGS_RD>

=item B<NF_DNS_FLAGS_RA>

=item B<NF_DNS_FLAGS_Z>

=item B<NF_DNS_FLAGS_AD>

=item B<NF_DNS_FLAGS_CD>

Flag values.

=item B<NF_DNS_RCODE_NOERROR>

=item B<NF_DNS_RCODE_FORMATERROR>

=item B<NF_DNS_RCODE_SERVERFAILURE>

=item B<NF_DNS_RCODE_NAMEERROR>

=item B<NF_DNS_RCODE_NOTIMPLEMENTED>

=item B<NF_DNS_RCODE_REFUSED>

=item B<NF_DNS_RCODE_YXDOMAIN>

=item B<NF_DNS_RCODE_YXRRSET>

=item B<NF_DNS_RCODE_NXRRSET>

=item B<NF_DNS_RCODE_NOTAUTH>

=item B<NF_DNS_RCODE_NOTZONE>

RCode Values.

=back

=head1 LIMITATIONS

While this module can decode DNS compression with pointers, it does not 
automatically encode compression with pointers.

RData encoder / decoders are provided for common RData types, but not 
all RData types.  If an RData type is encountered during decoding for 
which a decoder is not present, the RData is simply displayed as a hex 
stream.

=head1 SEE ALSO

L<Net::Frame::Layer>

For a non B<Net::Frame::Layer> DNS solution in Perl, L<Net::DNS>.

=head1 AUTHOR

Michael Vincent

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012, Michael Vincent

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
