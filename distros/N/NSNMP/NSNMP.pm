use strict;
package NSNMP;
# Copyright (c) 2003-2004 AirWave Wireless, Inc.

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:

#    1. Redistributions of source code must retain the above
#    copyright notice, this list of conditions and the following
#    disclaimer.
#    2. Redistributions in binary form must reproduce the above
#    copyright notice, this list of conditions and the following
#    disclaimer in the documentation and/or other materials provided
#    with the distribution.
#    3. The name of the author may not be used to endorse or
#    promote products derived from this software without specific
#    prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS
# OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
# GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
use vars qw($error $VERSION);
$VERSION = '0.50';

=head1 NAME

NSNMP - fast, flexible, low-level, pure-Perl SNMP library

=head1 SYNOPSIS

    $bytes = NSNMP->encode(type => $type, request_id => $request_id,
                          varbindlist => [
                            [$ber_encoded_oid, $vtype, $value],
                            ...
                          ],
                          # and optionally:
                          community => $com, error_status => $status,
                          error_index => $index);
    $decoded = NSNMP->decode($bytes);
    ($decoded->snmp_version, $decoded->community, $decoded->type,
     $decoded->request_id, $decoded->error_status,
     $decoded->error_index, $decoded->varbindlist);
    $errname = NSNMP->error_description($decoded->error_status);
    $comprehensible_oid =
        NSNMP->decode_oid(($decoded->varbindlist)[0]->[0]);
    $ber_encoded_oid = NSNMP->encode_oid('1.3.6.1.2.1.1.5.0');

=head1 DESCRIPTION

If you want something well-tested and production-quality, you probably
want L<Net::SNMP|Net::SNMP>; if you just want to get and set some
values with SNMP, you probably want L<NSNMP::Simple|NSNMP::Simple>.
This module is for you if you want something fast, something suitable
for dumping packet contents, or something suitable for writing an SNMP
agent.

This is an SNMP message encoding and decoding library, providing very
low-level facilities; you pretty much need to read the SNMP RFCs to
use it.  It is, however, very fast (it's more than an order of
magnitude faster than Net::SNMP 4.1.2, and it can send a request and
parse a response in only slightly more time than the snmpd from
net-snmp-5.0.6 takes to parse the request and send a response), and
it's relatively complete --- the interface is flexible enough that you
can use it to write SNMP management applications, SNMP agents, and
test suites for SNMP implementations.

It doesn't export anything.

=head1 MODULE CONTENTS

=head2 Constants

This module defines a number of constants for BER and SNMP type tags
and error names.

=head3 BER and SNMP types

These are one-byte strings:
INTEGER, OCTET_STRING, NULL, OBJECT_IDENTIFIER, SEQUENCE,
IpAddress, Counter32, Gauge32, TimeTicks,
GET_REQUEST, GET_NEXT_REQUEST, GET_RESPONSE, SET_REQUEST.

=cut

use constant INTEGER => "\x02";
use constant OCTET_STRING => "\x04";
use constant NULL => "\x05";
use constant OBJECT_IDENTIFIER => "\x06";
# UNIVERSAL, constructed, tag 10000b (16 decimal):
use constant SEQUENCE => "\x30";
use constant IpAddress => "\x40";
use constant Counter32 => "\x41";
use constant Gauge32 => "\x42";
use constant TimeTicks => "\x43";
use constant GET_REQUEST => "\xa0";  # context-specific, constructed, zero tag
use constant GET_NEXT_REQUEST => "\xa1";
use constant GET_RESPONSE => "\xa2";
use constant SET_REQUEST => "\xa3";

=head3 SNMP error names

These are small integers: noError, tooBig, noSuchName, badValue,
readOnly, genErr.

=cut

my @error_names = qw(noError tooBig noSuchName badValue readOnly genErr);
for my $index (0..$#error_names) {
  constant->import($error_names[$index] => $index);
}

=head2 NSNMP->error_description($error_status)

Returns one of the strings 'noError', 'noSuchName', etc.

=cut

sub error_description {
  my ($class, $error_status_number) = @_;
  return $error_names[$error_status_number];
}

# so far I have:
# - a debugging dumper for BER-encoded packets (subject to certain limitations)
# - an OID encoder that's twice as fast as Net::SNMP's, and knowledge that
#   hashing is 25 times faster still
# - knowledge of a lot of "optimized" ways of sorting lists of OIDs that 
#   aren't faster than the obvious way, but also one way that's 3-16
#   times as fast (packing the OIDs and memoizing that packing).
# - an SNMP PDU decoder that more or less works, at about 6800 PDUs per second
#   to just get the metadata, or 3900 PDUs per second to get the
#   contents.  This is much faster than Net::SNMP, but it's around
#   10%-20% slower than my first attempt, because it correctly handles
#   more encodings.  (I hope it correctly handles everything, but I
#   don't know.)
# - an SNMP PDU encoder that also more or less works and is even
#   faster than the decoder.  It doesn't quite work as well, though.
# - some speed.  on my 500MHz notebook, a script to get the sysName
#   10 000 times takes up 6.7 user seconds, 0.57 system seconds, and
#   13.2 wallclock seconds, and the net-snmp snmpd (written in C)
#   was using 40% of the CPU.  (So if we were running on a machine of
#   our own, we'd be doing 1300 requests per second.) By contrast,
#   Net::SNMP can fetch localhost's sysName 1000 times in 9.160 user
#   seconds, 0.050 system seconds, and 10.384 wallclock seconds, or
#   109 requests per second.  So this SNMP implementation is 12 times
#   as fast for this simple task.  Even when I turned off OID
#   translation caching, it only used an extra CPU second or so.

# performance test results:
# [kragen@localhost snmp]$ ./decodetest.pl   # now encode is slow too
# Benchmark: timing 10000 iterations of justbasics, varbindlist_too...
# justbasics:  2 wallclock secs ( 1.31 usr +  0.00 sys =  1.31 CPU) @ 7633.59/s (n=10000)
# varbindlist_too:  2 wallclock secs ( 2.43 usr +  0.00 sys =  2.43 CPU) @ 4115.23/s (n=10000)
# Benchmark: timing 10000 iterations of berdecode_encode, decode_encode, decode_encode_varbindlist, encode, slow_basicdecodes, unpackseq...
# berdecode_encode: 11 wallclock secs (11.20 usr +  0.00 sys = 11.20 CPU) @ 892.86/s (n=10000)
# decode_encode:  3 wallclock secs ( 3.00 usr +  0.00 sys =  3.00 CPU) @ 3333.33/s (n=10000)
# decode_encode_varbindlist:  4 wallclock secs ( 4.13 usr +  0.00 sys =  4.13 CPU) @ 2421.31/s (n=10000)
#     encode:  2 wallclock secs ( 1.67 usr +  0.00 sys =  1.67 CPU) @ 5988.02/s (n=10000)
# (31 microseconds more.  Ouch!)
# slow_basicdecodes:  6 wallclock secs ( 6.63 usr +  0.00 sys =  6.63 CPU) @ 1508.30/s (n=10000)
#  unpackseq:  4 wallclock secs ( 3.83 usr +  0.00 sys =  3.83 CPU) @ 2610.97/s (n=10000)


=head2 NSNMP->decode($message)

Given the bytes of a message (for example, received on a socket, or
returned from C<encode>), C<decode> returns an C<NSNMP::Message> object
on which you can call methods to retrieve various fields of the SNMP
message.

If it can't parse the message, it returns C<undef>.

See RFC 1157 (or a later SNMP RFC) for the meanings of each of these
fields.

My 500MHz laptop can run about 1-1.5 million iterations of a Perl loop
per second, and it can decode almost 8000 small messages per second
with this method.  It can decode a little over half as many if you
also need varbindlists.

The available methods for retrieving message fields follow.

=over

=cut

sub decode {
  my $class = shift;
  my $rv = eval { NSNMP::Message->new(@_) };
  $error = $@ if $@;
  return $rv;
}


{
  package NSNMP::Message;

  # This package holds decoded SNMP messages (and code for decoding
  # them).  The first couple of routines aren't usually used ---
  # they're the "slow path".  The fast path takes about 150
  # microseconds to decode a message, excluding varbindlist, on my
  # 500MHz laptop.  The slow path takes 500 microseconds to do the
  # same.

  # Given a string beginning with a BER item, split into type, length,
  # value, and remainder
  sub BERitem {
    my ($data) = @_;
    my ($type, $len, $other) = unpack "aCa*", $data;
    if ($len & 0x80) {
      if ($len == 0x82) { ($len, $other) = unpack "na*", $other }
      elsif ($len == 0x81) { ($len, $other) = unpack "Ca*", $other }
      else {
	(my $rawlen, $other) = unpack "a[$len]a*", $other;
	# This would have a problem with values over 2^31.
	# Fortunately, we're in an IP packet.
	$len = unpack "N", "\0" x (4 - $len) . $rawlen;
      }
    }
    return $type, $len, unpack "a[$len]a*", $other;
  }

  sub unpack_integer {
    my ($intstr) = @_;
    return unpack "N", "\0" x (4 - length($intstr)) . $intstr;
  }

  # general BER sequence type unpacking
  sub unpack_sequence {
    my ($sequence) = @_;
    my ($type, $len, $contents, $remainder) = BERitem($sequence);
    return undef, "Unpacking non-sequence" unless ($type & "\x20") ne "\0";
    # unpack individual items...
    return _unpack_sequence_contents($contents);
  }

  sub _unpack_sequence_contents {
    my ($contents) = @_;
    my @rv;
    my ($type, $len, $value);
    while ($contents) {
      ($type, $len, $value, $contents) = BERitem($contents);
      return undef, "Incomplete BER sequence" unless $len == length($value);
      push @rv, $type, $value;
    }
    return \@rv, undef;
  }

  sub _basicdecodes_slow_but_robust {
    my ($data) = @_;
    my ($sequence, $error) = unpack_sequence($data);
    die $error if $error;
    my (undef, $version, undef, $community, $pdu_type, $pdu) = @$sequence;
    ($sequence, $error) = _unpack_sequence_contents($pdu);
    die $error if $error;
    my (undef, $request_id, undef, $error_status,
	undef, $error_index, undef, $varbindlist_str) = @$sequence;
    return (version => unpack_integer($version) + 1, community => $community,
	    pdu_type => $pdu_type, request_id => $request_id,
	    error_status => unpack_integer($error_status),
	    error_index => unpack_integer($error_index),
	    varbindlist_str => $varbindlist_str);
  }

  sub _basicdecodes {
    my ($data) = @_;
    my ($packetlength, $verlen, $version, $community, $pdu_type, $pdulen,
	$request_id, $eslen, $error_status, $eilen, $error_index, $vblen,
	$varbindlist_str) = eval {
	  unpack "xC xCc xc/a aC xc/a xCC xCC xCa*", $data;
	};
    if (not $@ and not (($packetlength | $verlen | $pdulen | $eslen |
			 $eilen | $vblen) & 0x80)) {
      return (version => $version + 1, community => $community,
	      pdu_type => $pdu_type, request_id => $request_id,
	      error_status => $error_status, error_index => $error_index,
	      varbindlist_str => $varbindlist_str);
    }
    # If we're here, it means that we probably have a multibyte length
    # field on our hands --- either that, or a malformed packet.
    return _basicdecodes_slow_but_robust($data);
  }
  sub new {
    my ($class, $data) = @_;
    return bless { data => $data, _basicdecodes($data) }, $class;
  }

=item ->version

Returns the numeric SNMP version: 1, 2, or 3.  (Note that 1 is encoded
as 0 in the packet, and 2 is encoded as 1, etc., but this method
returns the human-readable number, not the weird encoding in the
packet.)

=cut

  sub version { $_[0]{version} }

=item ->community

Returns the community string.

=cut

  sub community { $_[0]{community} }

=item ->type

Returns the type tag of the PDU, such as NSNMP::GET_REQUEST,
NSNMP::GET_RESPONSE, NSNMP::SET_REQUEST, etc.  (See L</Constants>.)

=cut

  sub type { $_[0]{pdu_type} }          # 1-byte string

=item ->request_id

Returns the bytes representing the request ID in the SNMP message.
(This may seem perverse, but often, you don't have to decode them ---
you can simply reuse them in a reply packet, or look them up in a hash
of outstanding requests.  Of course, in the latter case, you might
have to decode them anyway, if the agent was perverse and re-encoded
them in a different way than you sent them out.)

=cut

  sub request_id { $_[0]{request_id} }  # string, not numeric

=item ->error_status, ->error_index

Return the numeric error-status and error-index from the SNMP packet.
In non-error cases, these will be 0.

=cut

  sub error_status { $_[0]{error_status} }
  sub error_index { $_[0]{error_index} }
  sub _decode_varbindlist {
    my ($str) = @_;
    my (@varbinds) = eval { 
      # the unpack issues warnings when failing sometimes
      local $SIG{__WARN__} = sub { };
      unpack "(xcxc/aac/a)*", $str;
    };
    return _slow_decode_varbindlist($str) if $@;
    my @rv;
    while (@varbinds) {
      my ($length, $oid, $type, $value) = splice @varbinds, 0, 4;
      return _slow_decode_varbindlist($str) if $length < 0;
      push @rv, [$oid, $type, $value];
    }
    return \@rv;
  }

  sub _slow_decode_varbindlist {
    my ($str) = @_;
    my ($varbinds, $error) = _unpack_sequence_contents($str);
    die $error if $error;
    my @rv;
    while (@$varbinds) {
      my (undef, $varbind) = splice @$varbinds, 0, 2;
      my ($varbindary, undef) = _unpack_sequence_contents($varbind);
      my (undef, $oid, $type, $value) = @$varbindary;
      push @rv, [$oid, $type, $value];
    }
    return \@rv;
  }

=item ->varbindlist

Returns a list of C<[$oid, $type, $value]> triples.  The type is a BER
type, normally equal to NSNMP::OCTET_STRING or one of the other
constants for BER types. (See L</Constants>.)  The OIDs are still
encoded in BER; you can use C<-E<gt>decode_oid> to get human-readable
versions, as documented below.

=back

=cut

  sub varbindlist {
    @{$_[0]{varbindlist} ||= _decode_varbindlist($_[0]{varbindlist_str})}
  }
}

sub _encode_oid {
  my ($oid) = @_;
  if ($oid =~ s/^1\.3\./43./) {
    return pack 'w*', split /\./, $oid;
  } else {  # XXX need a test for this
    my ($stupidity, $more_stupidity, @chunks) = split /\./, $oid;
    return pack 'w*', $stupidity * 40 + $more_stupidity, @chunks;
  }
}

sub _decode_oid {  # XXX need a test for this
  my ($encoded) = @_;
  if ($encoded =~ s/\A\x2b/\001\003/) {
    return join '.', unpack 'w*', $encoded;
  } else {
    my ($stupidity, @chunks) = unpack 'w*', $encoded;
    return join '.', int($stupidity/40), $stupidity % 40, @chunks;
  }
}

{
  my %encode_oids;
  my %decode_oids;

=head2 NSNMP->encode_oid($oid)

This method produces the BER-encoded version of the ASCII-represented
OID C<$oid>, which must be a sequence of decimal numbers separated by
periods.  Leading periods are allowed.

=cut

  sub encode_oid {
    my ($class, $oid) = @_;
    if (keys %encode_oids > 1000) {
      %encode_oids = ();
      %decode_oids = ();
    }
    return $encode_oids{$oid} if exists $encode_oids{$oid};
    $oid =~ s/\A\.//;
    return $encode_oids{$oid} if exists $encode_oids{$oid};
    my $encoded = _encode_oid($oid);
    $encode_oids{$oid} = $encoded;
    $decode_oids{$encoded} = $oid;
    return $encoded;
  }

=head2 NSNMP->decode_oid($bytestring)

Given the BER encoding of an OID in C<$bytestring>, this method
produces the OID's ASCII representation, as a sequence of decimal
numbers separated by periods, without a leading period.

=cut

  sub decode_oid {
    my ($class, $encoded) = @_;
    if (keys %encode_oids > 1000) {
      %encode_oids = ();
      %decode_oids = ();
    }
    return $decode_oids{$encoded} if exists $decode_oids{$encoded};
    my $oid = _decode_oid($encoded);
    $encode_oids{$oid} = $encoded;
    $decode_oids{$encoded} = $oid;
    return $oid;
  }
}

{
  sub _encode_length {
    if ($_[0] < 128) { return pack "c", $_[0] }
    if ($_[0] < 256) { return "\201" . pack "C", $_[0] }
    return "\202" . pack "n", $_[0];
  }

  sub _encode_varbind {
    my ($oid, $type, $value) = @{$_[0]};
    # 127 is max length to encode in 1 byte
    # OID plus value + 2 length bytes + 2 tag bytes must <= 127
    # to use short form
    if (length($oid) + length($value) < 123) {
      return pack "ac/a*", SEQUENCE,
	pack "ac/a* ac/a*", OBJECT_IDENTIFIER, @{$_[0]};
    } else {
      my $oidlength = _encode_length(length($oid));
      my $valuelength = _encode_length(length($value));
      return join('', SEQUENCE, _encode_length(length($oid) + length($value)
					       + length($oidlength)
					       + length($valuelength) + 2),
		  OBJECT_IDENTIFIER, $oidlength, $oid,
		  $type, $valuelength, $value);
    }
}


=head2 NSNMP->encode(%args)

Returns a string containing an encoded SNMP message, according to the
args specified.  Available args correspond one for one to the
C<NSNMP::Message> methods defined above under C<decode>; they include
the following:

=over 4

=item request_id => $req_id_str

Request ID as a string (not an integer).  Mandatory.

=item varbindlist =E<gt> C<[[$oid, $type, $value], [$oid, $type, $value]...]>

Varbindlist as an ARRAY ref containing (oid, type, value) tuples,
represented also as ARRAY refs.  OIDs, types, and values are assumed
to already be BER-encoded.  You can sensibly pass the results of the
C<-E<gt>varbindlist> method from a decoded message in here, just wrap
it in an ARRAY ref: C<varbindlist =E<gt> [$msg-E<gt>varbindlist]>.
Mandatory.

=item type => $type

PDU type --- normally NSNMP::GET_REQUEST, NSNMP::GET_RESPONSE,
etc.  (See L</Constants>.)  Mandatory.

=item community => $community

Community string.  Default is C<public>.

=item error_status => $error

=item error_index => $index

Error-status and error-index, as integers.  Only meaningful on
response messages.  Default 0.

=item version => $ver

Human-readable version of SNMP: 1, 2, or 3, default 1.  Presently 2
and 3 have features this library doesn't support.

=back

=cut

  my $onebyteint = INTEGER . pack "c", 1;
  sub encode {
    my ($class, %args) = @_;
    my $community = $args{community};
    $community = 'public' if not defined $community;
    my $encoded_varbinds = join '', 
      map { _encode_varbind $_ } @{$args{varbindlist}};
    my $pdu_start = pack 'ac/a* a*C a*C',   # XXX give error on long req IDs
      INTEGER, $args{request_id}, 
      $onebyteint, $args{error_status} || 0, 
      $onebyteint, $args{error_index} || 0,
    my $message_start = pack 'aCC ac/a* a',
      INTEGER, 1, ($args{version} || 1) - 1,
      OCTET_STRING, $community,  # XXX cope with long community strings
      $args{type};
    if (length($encoded_varbinds) + length($pdu_start) + length($message_start)
	< 123) { # 127 max - TL - L - TL = 122
      # for a small GetRequestPDU with two varbinds, this path is 25
      # microseconds shorter.
      return pack 'ac/a*', SEQUENCE, (pack 'a* c/a*', $message_start,
        pack 'a* ac/a*', $pdu_start, SEQUENCE, $encoded_varbinds);
    } else {
      my $pdu_contents = join('', $pdu_start, SEQUENCE,
        _encode_length(length($encoded_varbinds)), $encoded_varbinds);
      my $message_contents = join('', $message_start,
        _encode_length(length($pdu_contents)), $pdu_contents);
      return join('', SEQUENCE, _encode_length(length($message_contents)),
		  $message_contents);
    }
  }
}


=head1 EXAMPLES

Example usage of the main entry points, C<encode>, C<decode>,
C<encode_oid>, and C<decode_oid>, follows:

    my $bytes = NSNMP->encode(
      type => NSNMP::GET_REQUEST, 
      request_id => (pack "N", 38202),
      varbindlist => [
        [NSNMP->encode_oid('.1.3.6.1.2.1.1.5.0'), NSNMP::NULL, ''],
      ],
    );
    $socket->send($bytes);
    my $decoded = NSNMP->decode($bytes);
    # prints "111111\n"
    print(
      ($decoded->version==1),
      ($decoded->community eq 'public'),
      ($decoded->type eq NSNMP::GET_REQUEST),
      ($decoded->request_id eq pack "N", 38202),
      ($decoded->error_status == 0),
      ($decoded->error_index == 0), "\n"
    );
    my @varbinds = $decoded->varbindlist;
    # prints "111\n"
    print(
      (NSNMP->decode_oid($varbinds[0][0]) eq '1.3.6.1.2.1.1.5.0'),
      ($varbinds[0][1] eq NSNMP::NULL),
      ($varbinds[0][2] eq ''),
      "\n",
    );

=head1 FILES

None.

=head1 AUTHOR

Kragen Sitaker E<lt>kragen@pobox.comE<gt>

=head1 BUGS

This documentation does not adequately express the stupidity and
rottenness of the SNMP protocol design.

The ASN.1 BER, in which SNMP packets are encoded, allow the sender
lots of latitude in deciding how to encode things.  This module
doesn't have to deal with that very often, but it does have to deal
with the version, error-status, and error-index fields of SNMP
messages, which are generally encoded in a single byte each.  If the
sender of an SNMP packet encodes them in multiple bytes instead, this
module will fail to decode them, or worse, produce nonsense output.
It should instead handle these packets correctly.

Malformed VarBindLists can cause the C<-E<gt>varbindlist> method to
C<die> with an unhelpful error message.  It should instead return a
helpful error indication of some kind.

It doesn't do much yet; in particular, it doesn't do SNMPv1 traps or
anything from SNMPv2 or v3.

It doesn't even consider doing any of the following: decoding BER
values found in varbind values, understanding MIBs, or anything that
involves sending or receiving packets.  These jobs belong to other
modules, most of which haven't been written yet.

=cut

1;
