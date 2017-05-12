#!/usr/bin/perl -w
use strict;
use Test;
BEGIN { plan tests => 941 }
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

use NSNMP;
use NSNMP::Mapper;
use Time::HiRes;
use Data::Dumper;
#use BERdecode;

# unpack dies on negative counts.  If this isn't true, only God knows
# what will happen if we receive some corrupted packet.
{
  my $x = eval { unpack "c/a", "\201xxx" };
  ok($@);
  $x = eval { unpack "(c/a)*", "\201xxx" };
  ok($@);
}

# mapper
{
  my $mapper = NSNMP::Mapper->new(
				 '.1.3.5' => 'a',
				 '.1.2' => 'b',
				 '.1.4.1.5' => 'c',
				 '1.5.6' => 'd',
				);

  # no instance ID
  my ($which, $instance) = $mapper->map('.1.3.5');
  ok($which, 'a');
  ok($instance, undef);

  # instance ID
  ($which, $instance) = $mapper->map('.1.3.5.2.3');
  ok($which, 'a');
  ok($instance, '2.3');

  # doesn't match, but a common RE error could falsely match it
  ($which, $instance) = $mapper->map('.1.3.52.3');
  ok($which, undef);
  ok($instance, undef);

  # matching other than the first item
  ($which, $instance) = $mapper->map('.1.2.3');
  ok($which, 'b');
  ok($instance, '3');

  # matching with instance id of zero
  ($which, $instance) = $mapper->map('.1.4.1.5.0');
  ok($which, 'c');
  ok($instance, '0');

  # matching oid with leading dot against oid with no leading dot
  ($which, $instance) = $mapper->map('.1.5.6.7');
  ok($which, 'd');
  ok($instance, '7');

  # vice versa
  ($which, $instance) = $mapper->map('1.2.3');
  ok($which, 'b');
  ok($instance, '3');
}

# mapper speed
{
  my $m = NSNMP::Mapper->new(
			    (map { ("1.2.3.4.5.$_" => $_) } (1..100))
			   );
  my $start = Time::HiRes::time;
  my ($which, $instance);
  for my $ii (1..10) {
    for my $nn (1..50) {
      ($which, $instance) = $m->map(".1.2.3.4.5.$nn");
    }
  }
  my $end = Time::HiRes::time;
  ok($which, 50);
  ok($instance, undef);
  my $duration = $end - $start;
  # on my first try it was 1.8
  # on my second, it was 0.21
  # on my third, it was 0.035 (70 microseconds per iteration)
  # but instantiating the mapper 500 times cost 1.5 seconds (3 ms each)
  # but even a minimal instantiation (doing almost no work) costs 2.3 ms
  # all this is on a 500MHz PIII.
  ok($duration < 0.1) or print "# $duration too long\n";
}

# encoding length fields
{
  ok( NSNMP::_encode_length(0), "\0" );
  ok( NSNMP::_encode_length(1), "\1" );
  ok( NSNMP::_encode_length(64), "\100" );
  ok( NSNMP::_encode_length(127), "\177" );
  ok( NSNMP::_encode_length(128), "\201\200" );
  ok( NSNMP::_encode_length(129), "\201\201" );
  ok( NSNMP::_encode_length(130), "\201\202" );
  ok( NSNMP::_encode_length(255), "\201\377" );
  ok( NSNMP::_encode_length(256), "\202\1\0" );
  ok( NSNMP::_encode_length(257), "\202\1\1" );
  ok( NSNMP::_encode_length(65535), "\202\377\377" );
}

# decoding packets
{
  # 07:06:45.446652 127.0.0.1.1053 > 127.0.0.1.snmp:  GetRequest(28)  .1.3.6.1.2.1.1.5.0 (DF)
  my $getrequest = pack "H*",
    "302902010004067075626c6963a01c020405ba11a4020100020100300e300c06082b06010201" .  # 38 bytes
    "0105000500";                                                                     # 5 bytes
  # 30 is sequence
  # 29 is PDU content length: 41 decimal.
    # 02 01 00 is INTEGER, 1 byte, value 0.  That's SNMP version 1.
    # 04 06 is OCTET_STRING, 6 bytes: the community string.
      # 70 75 62 6c 69 63 is comm str
    # a0 is GET_REQUEST.
    # 1c is length of the rest of request: 28 bytes.
      # 02 04 is INTEGER, 4 bytes, the request-ID.
      # 05ba11a4 is request-ID, in 32 bits
      # 02 01 00: another integer 0.  Error type, I think.
      # 02 01 00: yet another integer 0.  Error index, I think.
      # 30: sequence, specifically the varbindlist.
      # 0e is length of varbindlist: 14 bytes, entire rest of packet.
	# 30 is sequence: the varbind is a sequence of an OID and a value.
	# 0c is length of varbind: 12 decimal.
	  # 06 08 is type OID, 8 bytes.
	  # 2b 06 01 02 01 01 05 00 is the OID .1.3.6.1.2.1.1.5.0.  The first
	  # two are mashed together.
	  # 05 00 is type NULL, zero bytes.
	  # It appears to occur twice, but the first one is the tail end of the OID.


  # 07:46:21.488087 127.0.0.1.1053 > 127.0.0.1.snmp:  GetRequest(28)  .1.3.6.1.2.1.1.5.0 (DF)
  my $getrequest2 = pack "H*",
    "302902010004067075626c6963a01c02045ece57cf020100020100300e300c06082b06010201" .
    "0105000500";

  #07:06:45.447262 127.0.0.1.snmp > 127.0.0.1.1053:  GetResponse(49)  .1.3.6.1.2.1.1.5.0="localhost.localdomain" (DF)
  my $getresponse = pack "H*", 
    "303e02010004067075626c6963a231020405ba11a40201000201003023302106082b06010201" .  # 38 bytes
    "01050004156c6f63616c686f73742e6c6f63616c646f6d61696e";                           # 26 bytes

#   print Dumper(BERdecode::decode($getrequest));
#   print Dumper(BERdecode::decode ($getresponse));
#   print Dumper(BERdecode::decode($getrequest2));

  my $getresponse2 = pack "H*", 
    "305202010004067075626c6963a245020405ba11a40201000201003037302106082b06010201" .
    "01050004156c6f63616c686f73742e6c6f63616c646f6d61696e301206082b06010201010501" .
    "04067075626c6963";
  #print Dumper (BERdecode::decode ($getresponse2));

  # unpack_sequence: general BER decoding
  my ($sequence, $error) = NSNMP::Message::unpack_sequence($getrequest);
  ok($error, undef);
  ok(@$sequence, 6); # 3 types, 3 strings
  ok($sequence->[0], NSNMP::INTEGER);
  ok($sequence->[1], "\x00");
  ok($sequence->[2], NSNMP::OCTET_STRING);
  ok($sequence->[3], "public");
  ok($sequence->[4], NSNMP::GET_REQUEST);
  ok($sequence->[5], substr($getrequest, 15));

  ($sequence, $error) = NSNMP::Message::unpack_sequence("\0\1rkorkork");
  ok($error, "Unpacking non-sequence");
  ok($sequence, undef);

  ($sequence, $error) =
    NSNMP::Message::unpack_sequence(substr($getrequest, 0, 
					  length($getrequest)-1));
  ok($error, "Incomplete BER sequence");
  ok($sequence, undef);


  my $decoded = NSNMP->decode($getrequest);
  ok($decoded->community, 'public');
  my @varbinds = $decoded->varbindlist;
  ok(@varbinds, 1);
  ok($varbinds[0][0], NSNMP->encode_oid('.1.3.6.1.2.1.1.5.0'));
  ok($varbinds[0][1], NSNMP::NULL());
  # ok($varbinds[0][2], undef);  # value doesn't matter when type is NULL
  ok($decoded->type, NSNMP::GET_REQUEST);
  ok($decoded->request_id, pack 'N', 96080292);

  $decoded = NSNMP->decode($getrequest2);
  ok($decoded->community, 'public');
  @varbinds = $decoded->varbindlist;
  ok(@varbinds, 1);
  ok($varbinds[0][0]. NSNMP->encode_oid('.1.3.6.1.2.1.1.5.0'));
  ok($decoded->request_id, pack 'N', 1590581199);

  $decoded = NSNMP->decode($getresponse);
  ok($decoded->community, 'public');
  @varbinds = $decoded->varbindlist;
  ok(@varbinds, 1);
  ok($varbinds[0][0], NSNMP->encode_oid('.1.3.6.1.2.1.1.5.0'));
  ok($varbinds[0][1], NSNMP::OCTET_STRING());
  ok($varbinds[0][2], 'localhost.localdomain');
  ok($decoded->type, NSNMP::GET_RESPONSE());
  ok($decoded->request_id, pack 'N', 96080292);

  @varbinds = NSNMP->decode($getresponse2)->varbindlist;
  ok(@varbinds, 2);
  ok($varbinds[0][0], NSNMP->encode_oid('.1.3.6.1.2.1.1.5.0'));
  ok($varbinds[0][2], 'localhost.localdomain');
  ok($varbinds[1][0], NSNMP->encode_oid('.1.3.6.1.2.1.1.5.1'));
  ok($varbinds[1][1], NSNMP::OCTET_STRING());
  ok($varbinds[1][2], 'public');
}

# encoding packets
{
  my $packet = NSNMP->encode(type => NSNMP::GET_REQUEST,
			    request_id => (my $request_id = pack "N", 32032),
			    varbindlist => [
					    [NSNMP->encode_oid('.1.2.3.4.5'), NSNMP::NULL(), ''],
					    [NSNMP->encode_oid('.1.3.2.4.5'), NSNMP::NULL(), ''],
					   ],
			   );
  #print unpack("H*", $packet), "\n";
  #print Dumper(BERdecode::decode($packet));
  my $decoded = NSNMP->decode($packet);
  ok( $decoded->version, 1 );                     # default
  ok( $decoded->community, 'public' );            # default
  ok( $decoded->type, NSNMP::GET_REQUEST );
  ok( $decoded->request_id, $request_id );
  ok( $decoded->error_status, NSNMP::noError );  # default
  ok( $decoded->error_index, 0 );                 # default

  my @varbinds = $decoded->varbindlist;
  ok( @varbinds, 2 );
  ok( NSNMP->decode_oid($varbinds[0][0]), '1.2.3.4.5' );  # note no leading dot
  ok( $varbinds[0][1], NSNMP::NULL() );
  ok( NSNMP->decode_oid($varbinds[1][0]), '1.3.2.4.5' );

  # long packet
  $packet = NSNMP->encode(type => NSNMP::GET_RESPONSE,
			 request_id => 'asdf',
			 varbindlist => [
					 [NSNMP->encode_oid('.1.2.3.4.5'), NSNMP::OCTET_STRING, 'x' x 1024],
					],
			);
  # print unpack "H*", $packet;
  # print Dumper(BERdecode::decode($packet));
  $decoded = NSNMP->decode($packet);
  ok($decoded->type, NSNMP::GET_RESPONSE);
  @varbinds = $decoded->varbindlist;
  ok(@varbinds, 1);
  ok($varbinds[0][2], 'x' x 1024);
}

# decoding packets with multibyte length fields
{
  my $packet = pack("H*", "3081cb02010004067075626c6963a281bd020461626862" .
		    "0201000201003081ae3081ab060d2b06010201190402010581e0" .
		    "230481992d77202d4d737472696374202d4d534e4d503a3a5369" .
		    "6d706c65202d4d446174613a3a44756d706572202d6520707269" .
		    "6e7420446174613a3a44756d7065723a3a44756d70657228534e" .
		    "4d503a3a53696d706c652d3e6765745f7461626c652822313237" .
		    "2e302e302e31222c20222e312e3322292c2024534e4d503a3a53" .
		    "696d706c653a3a6572726f722c2024534e4d503a3a6572726f72" .
		    "29");
  my $decoded = NSNMP->decode($packet);
  ok( $decoded->version, 1 );
  ok( $decoded->community, 'public' );
  ok( $decoded->type, NSNMP::GET_RESPONSE );
  ok( $decoded->request_id, 'abhb' );
  ok( $decoded->error_status, 0 );
  ok( $decoded->error_index, 0 );

  my @varbinds = $decoded->varbindlist;
  ok(@varbinds, 1);
  my $oid = '1.3.6.1.2.1.25.4.2.1.5.28707';
  ok(NSNMP->decode_oid($varbinds[0][0]), $oid);
  ok($varbinds[0][0], NSNMP->encode_oid($oid));
  ok($varbinds[0][1], NSNMP::OCTET_STRING);
  # this actually comes from a process table
  ok($varbinds[0][2], '-w -Mstrict -MSNMP::Simple -MData::Dumper -e' .
     ' print Data::Dumper::Dumper(SNMP::Simple->get_table("127.0.0.' .
     '1", ".1.3"), $SNMP::Simple::error, $SNMP::error)');
}

# encoding and decoding packets with many lengths
{
  for my $length (100..300, 4000, 4090..4100) {
    my $encoded = NSNMP->encode(
      type => NSNMP::GET_RESPONSE,
      request_id => 'jkl;',
      varbindlist => [
	[NSNMP->encode_oid('.1.2.3.4.5'), NSNMP::OCTET_STRING, 'x' x $length],
      ],
    );
    ok(length($encoded) > $length);
    my $decoded = NSNMP->decode($encoded);
    ok($decoded->type, NSNMP::GET_RESPONSE);
    ok(@{[$decoded->varbindlist]}, 1);
    ok(length(($decoded->varbindlist)[0]->[2]), $length);
 }
}
