#!/usr/bin/perl -w
use strict;
use Test;
BEGIN { plan tests => 86 }
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
use lib '..';
use Carp qw(confess);  
use NSNMP;
use POSIX;
use IO::Socket;
use NSNMP::Agent;

$SIG{__DIE__} = sub { confess @_ };

my $encoded_oid = NSNMP->encode_oid('.1.2.3.4.5');
ok($encoded_oid);

my $request_id = 'fwsa';
sub getreq {
  my ($oid) = @_;
  return NSNMP->encode(
    type => NSNMP::GET_REQUEST,
    varbindlist => [[NSNMP->encode_oid($oid), NSNMP::NULL, '']],
    request_id => $request_id,
  );
}

my $initial_request = getreq('.1.2.3.4.5');
ok($initial_request);
ok(NSNMP->decode($initial_request));


my $sysname = '.1.3.6.1.2.1.1.5';
my $sysname0 = "$sysname.0";

# noSuchName
{
  my $agent = NSNMP::Agent->new(types => { }, values => { });
  ok($agent);
  my $response = $agent->handle_request($initial_request);
  ok($response);
  my $dr = NSNMP->decode($response);
  ok($dr);
  ok($dr->error_status, NSNMP::noSuchName);
  ok($dr->error_index, 1);
  ok($dr->version, 1);
  ok($dr->type, NSNMP::GET_RESPONSE);
  ok($dr->request_id, $request_id);
  ok($dr->community, 'public');
  my @varbinds = $dr->varbindlist;
  ok(@varbinds, 1);
  ok($varbinds[0][0], $encoded_oid);
  ok($varbinds[0][1], NSNMP::NULL); # ???
  ok($varbinds[0][2], '');
}

# fetching an existing name
{
  my $agent = NSNMP::Agent->new(
    types => { '.1.3.6.1.2.1.1.5' => NSNMP::OCTET_STRING },
    values => { $sysname0 => 'thor.cs.cmu.edu' },
  );

  my $response = $agent->handle_request($initial_request);
  ok($response);
  ok(NSNMP->decode($response)->error_status, NSNMP::noSuchName);

  $response = $agent->handle_request(getreq($sysname0));

  ok($response);
  my $dr = NSNMP->decode($response);
  ok($dr);
  ok($dr->error_status, 0);
  ok($dr->error_index, 0);
  ok($dr->version, 1);
  ok($dr->type, NSNMP::GET_RESPONSE);
  ok($dr->request_id, $request_id);
  ok($dr->community, 'public');
  my @varbinds = $dr->varbindlist;
  ok(@varbinds, 1);
  ok($varbinds[0][0], NSNMP->encode_oid($sysname0));
  ok($varbinds[0][1], NSNMP::OCTET_STRING);
  ok($varbinds[0][2], 'thor.cs.cmu.edu');
}

# handling of wrong community string
{
  my $agent = NSNMP::Agent->new(types => {}, values => {});
  my %request_args = (
    type => NSNMP::GET_REQUEST,
    request_id => 'pets',
    varbindlist => [[NSNMP->encode_oid($sysname0), NSNMP::NULL, '']],
  );
  my $response = $agent->handle_request(NSNMP->encode(%request_args));
  ok($response);
  my $decoded = NSNMP->decode($response);
  ok($decoded->error_status, NSNMP::noSuchName);

  $response = $agent->handle_request(NSNMP->encode(%request_args,
    community => 'cilbup',
  ));
  ok($response, undef);

  # non-default community string
  $agent = NSNMP::Agent->new(types => {}, values => {}, community => 'cilbup');
  ok($agent->handle_request(NSNMP->encode(%request_args)), undef);
  ok($agent->handle_request(NSNMP->encode(
    %request_args, community => 'cilbup',
  )));
}

# handling network packets
{
  # We'd like to use NSNMP::Simple here, but the problem is that we use
  # NSNMP::Agent in NSNMP::Simple's tests, so if NSNMP::Simple's tests
  # start failing, we want to be able to use these tests to see if the
  # problem is with NSNMP::Simple or NSNMP::Agent.

  # receive if a packet happens soon, returning a timedout boolean and the packet
  sub recv_timeout {
    my ($socket) = @_;
    my $rin = '';
    vec($rin, fileno($socket), 1) = 1;
    select($rin, undef, undef, .25);  # PLENTY of time to get a response
    if (vec($rin, fileno($socket), 1)) {
      my $recv;
      if (recv $socket, $recv, 65536, 0) {
	return (0, $recv);
      } # else there was an error, e.g. ECONNREFUSED, so fall through
    }
    return 1, undef;
  }

  my $agent = NSNMP::Agent->new(
    types => { '.1.3.6.1.2.1.1.5' => NSNMP::OCTET_STRING },
    values => { $sysname0 => 'thor.cs.cmu.edu' },
  );

  my $port = 16161;
  my $pid = $agent->spawn($port);
  END { exit(0) } # for some reason, the other END block results in exiting with status 9
  END { if ($pid) { kill(9, $pid); wait(); } }  # clean up

  my $talksocket = IO::Socket::INET->new(
    PeerAddr => "127.0.0.1:$port",
    Proto => 'udp',
  );
  $talksocket->send($initial_request);
  my ($timedout, $message) = recv_timeout($talksocket);
  ok(not $timedout);
  ok($message);

  my $dm = NSNMP->decode($message);
  ok($dm->error_status, NSNMP::noSuchName);
  ok($dm->error_index, 1);

  $talksocket->send(NSNMP->encode(
    type => NSNMP::GET_REQUEST,
    request_id => 'BeaM',
    varbindlist => [[NSNMP->encode_oid($sysname0), NSNMP::NULL, '']],
  ));
  ($timedout, $message) = recv_timeout($talksocket);
  ok(not $timedout);
  ok($message);
  $dm = NSNMP->decode($message);
  my @varbinds = $dm->varbindlist;
  ok(@varbinds, 1);
  ok(NSNMP->decode_oid($varbinds[0][0]), '1.3.6.1.2.1.1.5.0');
  ok($varbinds[0][1], NSNMP::OCTET_STRING);
  ok($varbinds[0][2], 'thor.cs.cmu.edu');

  # wrong community string
  $talksocket->send(NSNMP->encode(
    type => NSNMP::GET_REQUEST,
    request_id => 'BeaM',
    varbindlist => [[NSNMP->encode_oid($sysname0), NSNMP::NULL, '']],
    community => 'cilbup',
  ));
  ($timedout, $message) = recv_timeout($talksocket);
  ok($timedout);
  ok($message, undef);

  # garbage packet
  $talksocket->send('This does not look much like an SNMP packet');
  $talksocket->send($initial_request);
  ($timedout, $message) = recv_timeout($talksocket);
  ok(not $timedout);  # garbage message didn't kill it
  ok($message);
  # ensure the reply was for the real SNMP message:
  ok(NSNMP->decode($message)->request_id, $request_id);
}

# handling of set requests
{
  my $agent = NSNMP::Agent->new(
    types => { '.1.3.6.1.2.1.1.5' => NSNMP::OCTET_STRING },
    values => { $sysname0 => 'thor.cs.cmu.edu' },
  );
  my $get_request = NSNMP->encode(
    type => NSNMP::GET_REQUEST,
    request_id => 'love',
    varbindlist => [[NSNMP->encode_oid($sysname0), NSNMP::NULL, '']],
  );

  # first get the value
  my $response = $agent->handle_request($get_request);
  ok($response);
  my $dr = NSNMP->decode($response);
  ok($dr);
  ok(($dr->varbindlist)[0]->[2], 'thor.cs.cmu.edu');

  # then set it to something else
  $response = $agent->handle_request(NSNMP->encode(
    type => NSNMP::SET_REQUEST,
    request_id => 'kiss',
    varbindlist => [[NSNMP->encode_oid($sysname0), NSNMP::OCTET_STRING,
      'steadfast.canonical.org']],
  ));
  ok($response);
  $dr = NSNMP->decode($response);
  ok($dr);
  ok($dr->error_status, 0);
  ok($dr->error_index, 0);
  ok($dr->request_id, 'kiss');
  ok(($dr->varbindlist)[0]->[2], 'steadfast.canonical.org');

  # then get it again and verify that it's changed
  $response = $agent->handle_request($get_request);
  ok($response);
  $dr = NSNMP->decode($response);
  ok($dr);
  ok(($dr->varbindlist)[0]->[2], 'steadfast.canonical.org');
}

# The Powerful Get-Next Operator
{
  my $ifname = '.1.3.6.1.2.1.2.2.1.2';
  my %ifnames = (
      "$ifname.0" => 'lo',
      "$ifname.10" => 'eth0',
      "$ifname.2" => 'br0',
      "$ifname.129" => 'big0',
  );
  my $agent = NSNMP::Agent->new(
    types => { $ifname => NSNMP::OCTET_STRING },
    values => \%ifnames,
  );
  sub getnextreq {
    my ($oid) = @_;
    return NSNMP->encode(type => NSNMP::GET_NEXT_REQUEST,
      request_id => 'fjew', 
      varbindlist => [[NSNMP->encode_oid($oid), NSNMP::NULL, '']],
    );
  }

  # child
  my $response = NSNMP->decode($agent->handle_request(getnextreq($ifname)));
  ok($response->request_id, 'fjew');
  ok($response->type, NSNMP::GET_RESPONSE);
  ok($response->error_status, 0);
  ok($response->error_index, 0);
  my @varbinds = $response->varbindlist;
  ok(@varbinds, 1);
  ok($varbinds[0][0], NSNMP->encode_oid("$ifname.0"));
  ok($varbinds[0][2], 'lo');

  # sibling
  $response = NSNMP->decode($agent->handle_request(getnextreq("$ifname.0")));
  ok($response->error_status, 0);
  @varbinds = $response->varbindlist;
  ok($varbinds[0][0], NSNMP->encode_oid("$ifname.2"));
  ok($varbinds[0][2], 'br0');

  # correct order
  $response = NSNMP->decode($agent->handle_request(getnextreq("$ifname.2")));
  ok($response->error_status, 0);
  ok(($response->varbindlist)[0]->[0], NSNMP->encode_oid("$ifname.10"));

  # even for numbers over 128
  $response = NSNMP->decode($agent->handle_request(getnextreq("$ifname.10")));
  ok($response->error_status, 0);
  ok(($response->varbindlist)[0]->[0], NSNMP->encode_oid("$ifname.129"));

  # and last OID
  $response = NSNMP->decode($agent->handle_request(getnextreq("$ifname.129")));
  ok($response->error_status, NSNMP::noSuchName);
}

sub setreq {
  my ($oid, $type, $value) = @_;
  return NSNMP->encode(
    type => NSNMP::SET_REQUEST,
    varbindlist => [[NSNMP->encode_oid($oid), $type, $value]],
    request_id => $request_id,
  );
}

# handling of different types
{
  my $counter_oid = '.1.3.6.1.2.1.4.3';
  my $agent = NSNMP::Agent->new(
    types => {
      $sysname => NSNMP::OCTET_STRING,
      $counter_oid => NSNMP::INTEGER,
    },
    values => {
      $sysname0 => 'bob',
      "$counter_oid.0" => (pack "C", 21),
    },
  );
  my $response = NSNMP->decode($agent->handle_request(
    setreq($sysname0, NSNMP::OCTET_STRING, 'mary')));
  ok($response->error_status, 0);
  ok($response->error_index, 0);
  $response = NSNMP->decode($agent->handle_request(getreq($sysname0)));
  ok(($response->varbindlist)[0]->[2], 'mary');

  $response = NSNMP->decode($agent->handle_request(
    setreq($sysname0, NSNMP::INTEGER, (pack "C", 31))));
  ok($response->error_status, NSNMP::badValue);
  ok($response->error_index, 1);
  $response = NSNMP->decode($agent->handle_request(getreq($sysname0)));
  ok(($response->varbindlist)[0]->[2], 'mary');

  $response = NSNMP->decode($agent->handle_request(
    setreq("$counter_oid.0", NSNMP::INTEGER, (pack "C", 31))));
  ok($response->error_status, 0);
  ok($response->error_index, 0);
  $response = NSNMP->decode($agent->handle_request(getreq("$counter_oid.0")));
  ok(($response->varbindlist)[0]->[2], (pack "C", 31));
}

# TODO: handling of multiple types
# TODO: handling of multiple varbinds
# TODO: handling of different OID spellings
