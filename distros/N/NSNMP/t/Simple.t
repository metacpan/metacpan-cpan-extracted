#!/usr/bin/perl -w
use strict;
use Test;
BEGIN { plan tests => 109 }
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
use NSNMP;
use Time::HiRes ();
use NSNMP::Agent;
use NSNMP::Simple;
use Carp qw(confess);
$SIG{__WARN__} = sub { confess @_ };
END { NSNMP::Agent->kill_temp_agents() }

my $sysname = '.1.3.6.1.2.1.1.5';
my $sysname0 = "$sysname.0";
my $thor = 'thor.cs.cmu.edu';

my %only_sysname0 = (
  types => { $sysname => NSNMP::OCTET_STRING },
  values => { $sysname0 => $thor },
);

my $agent = NSNMP::Agent->new(%only_sysname0);
my $port = 16161;
my $pid = $agent->spawn($port);
END { exit(0) } # otherwise we get exit(9) for some reason
END { if ($pid) { kill 9, $pid; wait() } }
my $addr = "127.0.0.1:$port";

# get
{
  # nonsense hostname
  ok(not NSNMP::Simple->get("bad.hostname.example.com:$port", $sysname0));
  ok($NSNMP::Simple::error,
     "Unable to resolve destination address 'bad.hostname.example.com'");

  # successful get
  my $sysName = NSNMP::Simple->get($addr, $sysname0);
  ok($sysName, $thor);
  ok($NSNMP::Simple::error, undef);

  # error handling
  my $garbage = NSNMP::Simple->get($addr, '.1.3.6.1.2.3.4.5.6.7.8');
  ok($garbage, undef);
  ok($NSNMP::Simple::error, 'Received noSuchName(2) error-status at error-index 1');

  # success clears error
  $sysName = NSNMP::Simple->get($addr, $sysname0);
  ok($sysName, $thor);
  ok($NSNMP::Simple::error, undef);

  # hostnames are accepted, not just IPs
  ok(NSNMP::Simple->get("localhost:$port", $sysname0), $thor);
  ok($NSNMP::Simple::error, undef);

  # different community string etc.
  ok(NSNMP::Simple->get($addr, $sysname0, community => 'public', 
		       timeout => 0.3),
     $thor);
  ok($NSNMP::Simple::error, undef);
  ok(NSNMP::Simple->get($addr, $sysname0, community => 'smallville',
		       timeout => 0.3),
     undef);
  ok($NSNMP::Simple::error, "No response from remote host '127.0.0.1'");
}

# set
{
  my $oldname = NSNMP::Simple->get($addr, $sysname0);
  my $newname = 'some unusual name';
  ok(NSNMP::Simple->set($addr, $sysname0, NSNMP::OCTET_STRING, $newname));
  ok($NSNMP::Simple::error, undef);
  ok(NSNMP::Simple->get($addr, $sysname0), $newname);
  ok($NSNMP::Simple::error, undef);
  # cleanup:
  NSNMP::Simple->set($addr, $sysname0, NSNMP::OCTET_STRING, $oldname);
}

sub ok_elapsed {
  my ($start, $intv) = @_;
  local $Test::TestLevel = $Test::TestLevel + 1;
  my $diff = Time::HiRes::time - $start;
  ok(abs($diff - $intv) < 0.2) or print "# $diff far from $intv\n";
}

# ensure correct handling of long strings
{
  my $long_string = 'These are a lot of bytes: ' . 'A' x 300;
  my $longer_string = 'Even more bytes: ' . 'A' x 2000;
  my $addr = NSNMP::Agent->new(
    types => { $sysname => NSNMP::OCTET_STRING },
    values => {
      $sysname0 => 'Look out!',
      "$sysname.1" => $long_string,
      "$sysname.2" => $longer_string,
    },
  )->temp_agent();
  ok(NSNMP::Simple->get($addr, $sysname0), 'Look out!');
  ok(NSNMP::Simple->get($addr, "$sysname.1"), $long_string);
  ok(NSNMP::Simple->get($addr, "$sysname.2"), $longer_string);
}

# ignore responses with incorrect request-IDs
{
  {
    package CorruptedAgent;
    use base qw(NSNMP::Agent);
    sub weird_request_id { 'gums' }
    sub handle_request {
      my ($self, $request) = @_;
      Time::HiRes::sleep(0.4);
      my $dr = NSNMP->decode($request);
      return $self->SUPER::handle_request(NSNMP->encode(
        request_id => $self->weird_request_id($dr->request_id),
        type => $dr->type,
        varbindlist => [$dr->varbindlist],
        community => $dr->community,
        version => $dr->version,
     ));
    }
  }
  my $addr = CorruptedAgent->new(%only_sysname0)->temp_agent();
  my $start = Time::HiRes::time;
  ok(NSNMP::Simple->get($addr, $sysname0, timeout => my $timeout = 0.8,
		       retries => 0), undef);
  ok_elapsed($start, $timeout);  # ensure extra packet didn't screw up timeout
  ok($NSNMP::Simple::error, "No response from remote host '127.0.0.1'");

  {
    package PaddingAgent;
    use base qw(CorruptedAgent);
    sub weird_request_id {
      my ($self, $request_id) = @_;
      return "\0\0$request_id";  # numerically equal but not string equal
    }
  }
  $addr = PaddingAgent->new(%only_sysname0)->temp_agent();
  ok(NSNMP::Simple->get($addr, $sysname0), $thor);
}

# timeout
{
  {
    package SlowAgent;
    use base qw(NSNMP::Agent);
    sub handle_request {
      my ($self, $request) = @_;
      Time::HiRes::sleep($self->{delay});
      $self->SUPER::handle_request($request);
    }
  }
  # get
  my $delay = .5;
  my $addr = SlowAgent->new(%only_sysname0, 
			    delay => $delay)->temp_agent();
  my $start = Time::HiRes::time;
  ok(NSNMP::Simple->get($addr, $sysname0, retries => 0, timeout => .8),
     $thor);
  ok_elapsed($start, $delay);
  ok(NSNMP::Simple->get($addr, $sysname0, retries => 0, timeout => .3),
     undef);
  ok($NSNMP::Simple::error, "No response from remote host '127.0.0.1'");
  # ensure that the stray response isn't erroneously accepted
  ok(NSNMP::Simple->get($addr, '.1.2.3'), undef);
  ok($NSNMP::Simple::error, 'Received noSuchName(2) error-status at error-index 1');

  # set
  ok(NSNMP::Simple->set($addr, $sysname0, NSNMP::OCTET_STRING, 'mufflewoof',
		       retries => 0, timeout => .8));
  ok(not NSNMP::Simple->set($addr, $sysname0, NSNMP::OCTET_STRING, 'bligglemart',
			   retries => 0, timeout => .3));
  ok($NSNMP::Simple::error, "No response from remote host '127.0.0.1'");
  Time::HiRes::sleep($delay);
  ok(NSNMP::Simple->get($addr, $sysname0), 'bligglemart');


  # default get timeout: 5 (XXX: this test sucks!)
  $addr = SlowAgent->new(%only_sysname0, 
			 delay => 100)->temp_agent();
  $start = Time::HiRes::time;
  print "# About to time out in 5 seconds\n";
  ok(NSNMP::Simple->get($addr, $sysname0, retries => 0), undef);
  ok_elapsed($start, 5);
}

# handling garbage packets (and retries)
{
  {
    package GarbageMan;
    # returns a garbage packet the first few times, then normal responses
    use base qw(NSNMP::Agent);
    sub handle_request {
      my ($self, $request) = @_;
      return $self->SUPER::handle_request($request) unless $self->{garbage};
      $self->{garbage}--;
      return 'This is just some garbage --- not much like an SNMP packet';
    }
  }
  my $addr = GarbageMan->new(%only_sysname0, 
			     garbage => 1)->temp_agent();
  my $start = Time::HiRes::time;
  ok(NSNMP::Simple->get($addr, $sysname0, timeout => 0.5, retries => 1), $thor);
  ok_elapsed($start, 0.5);

  # retries default to 1
  $addr = GarbageMan->new(%only_sysname0, 
			  garbage => 2)->temp_agent();
  ok(NSNMP::Simple->get($addr, $sysname0, timeout => 0.5), undef);

  # but can be overridden
  $addr = GarbageMan->new(%only_sysname0, 
			  garbage => 2)->temp_agent();
  ok(NSNMP::Simple->get($addr, $sysname0, timeout => 0.5, retries => 2), $thor);
}

# walk
{
  my $ifname = ".1.3.6.1.2.1.2.2.1.2";
  my %types = (types => {
    $sysname => NSNMP::OCTET_STRING,
    $ifname => NSNMP::OCTET_STRING,
  });

  my $addr = NSNMP::Agent->new(
    %types,
    values => {
      $sysname0 => $thor,
      "$ifname.0" => 'lo',
      "$ifname.1" => 'eth0',
    },
  )->temp_agent();

  # terminated by a non-matching OID
  my %table = NSNMP::Simple->get_table($addr, $sysname);
  ok(keys %table, 1);
  ok((keys %table)[0], "$sysname.0");
  ok((values %table)[0], $thor);
  ok($NSNMP::Simple::error, undef);

  # terminated by noSuchName
  my @table = NSNMP::Simple->get_table($addr, $ifname);
  ok(@table, 4);
  ok($table[0], "$ifname.0");
  ok($table[1], 'lo');
  ok($table[2], "$ifname.1");
  ok($table[3], 'eth0');

  # don't propagate noSuchName:
  ok($NSNMP::Simple::error, undef); 
  ok($NSNMP::Simple::error_status, undef);


  # ordering
  $addr = NSNMP::Agent->new(
    %types,
    values => {
      $ifname => "you can't fetch this",
      "$ifname.0" => 'lo',  # slightly traif, but we better handle it
      "$ifname.10" => 'bo',
      "$ifname.2" => 'no',
      "$ifname.129" => 'go',
    },
  )->temp_agent();
  @table = NSNMP::Simple->get_table($addr, $ifname, timeout => 0.2);
  ok(@table, 8);
  ok("$table[1] $table[3] $table[5] $table[7]", "lo no bo go");

  # test use of %args and error propagation
  @table = NSNMP::Simple->get_table($addr, $ifname,
				   community => 'Brigadoon', timeout => 0.2);
  ok(@table, 0);
  ok($NSNMP::Simple::error, "No response from remote host '127.0.0.1'");
  ok($NSNMP::Simple::error_status, NSNMP::Simple::noResponse);
  
  @table = NSNMP::Simple->get_table('12345.6789.1011', $sysname);
  ok(@table, 0);
  ok($NSNMP::Simple::error, 
     "Unable to resolve destination address '12345.6789.1011'");
  ok($NSNMP::Simple::error_status, NSNMP::Simple::badHostName);

  # missing leading dots reflected in output:
  @table = NSNMP::Simple->get_table($addr, "1.3.6.1.2.1.2.2.1.2");
  ok(@table, 8);
  ok($table[0], '1.3.6.1.2.1.2.2.1.2.0');
}

# speed
{
  my $tablesize = 100;
  my $iters = 6;
  my $slowdown_tablesize = 2000;
  my $values = { 
    (map { ("$sysname.$_" => "sysname $_") } (1..$tablesize)),
		# slow things down a bit:
    (map { (".1.3.0.$_" => "some $_") } (1..$slowdown_tablesize)),
  };
  my $addr = NSNMP::Agent->new(
    types => { $sysname => NSNMP::OCTET_STRING, '.1.3.0' => NSNMP::OCTET_STRING },
    values => $values,
  )->temp_agent();
  my %sysnames;
  my $end;
  my ($end_cpu_user, $end_cpu_sys);

  my $start = Time::HiRes::time;
  my ($start_cpu_user, $start_cpu_sys) = times;
  %sysnames = NSNMP::Simple->get_table($addr, $sysname) for 1..$iters;
  $end = Time::HiRes::time;
  ($end_cpu_user, $end_cpu_sys) = times;

  my $duration = $end - $start;
  ok($sysnames{"$sysname.45"}, "sysname 45");
  ok(keys %sysnames, 100);
  my $gets = ($tablesize + 1) * $iters;
  # without the lastoid optimization, this test gets 155 requests per
  # second; with it, it gets 580.  That's wall-clock time, including
  # time used by NSNMP::Simple.
  printf "# %d getNextRequests in %.2f seconds: %d/sec\n", 
    $gets, $duration, $gets/$duration;
  my $client_cpu = 
    $end_cpu_user + $end_cpu_sys - $start_cpu_user - $start_cpu_sys;
  printf "# and in %.2f client CPU seconds: %d/sec\n",
    $client_cpu, $gets/$client_cpu;

  # These thresholds are for my 500MHz laptop.  The usual numbers are
  # higher by about 200, but they vary quite a lot, and these
  # thresholds are low enough to very rarely fail.
  ok($gets/$duration > 360);
  ok($gets/$client_cpu > 900);
}

# getting data types other than OCTET STRING.  Like INTEGER.
{
  my $intoid = '.1.3.6.1.2.1.2.2.1.4';  # interface MTU
  my $addr = NSNMP::Agent->new(
    types => { $intoid => NSNMP::INTEGER },
    values => {
      "$intoid.1" => (pack "N", 1),  # 4 bytes
      "$intoid.2" => (pack "C", 1),  # 1 byte
      "$intoid.3" => (pack "n", 1),  # 2 bytes
      "$intoid.4" => (pack "N", 37), # another value
      "$intoid.5" => (pack "C", 37),
      "$intoid.6" => (pack "n", 37),
      "$intoid.7" => (pack "N", -3), # 4-byte -3
      "$intoid.8" => (pack "c", -3), # 1-byte -3
      "$intoid.9" => (pack "n", -3), # 2-byte -3
      "$intoid.10" => (pack "n", 255),
      "$intoid.11" => (pack "cn", 0, 65535),
      "$intoid.12" => (pack "cN", 0, 4294967295),
      "$intoid.13" => (pack "NN", 0, 4294967295),  # 8 bytes
    },
  )->temp_agent();
  ok(NSNMP::Simple->get($addr, "$intoid.1"), 1);
  ok(NSNMP::Simple->get($addr, "$intoid.2"), 1);
  ok(NSNMP::Simple->get($addr, "$intoid.3"), 1);
  ok(NSNMP::Simple->get($addr, "$intoid.4"), 37);
  ok(NSNMP::Simple->get($addr, "$intoid.5"), 37);
  ok(NSNMP::Simple->get($addr, "$intoid.6"), 37);
  ok(NSNMP::Simple->get($addr, "$intoid.7"), -3);
  ok(NSNMP::Simple->get($addr, "$intoid.8"), -3);
  ok(NSNMP::Simple->get($addr, "$intoid.9"), -3);
  ok(NSNMP::Simple->get($addr, "$intoid.10"), 255);
  ok(NSNMP::Simple->get($addr, "$intoid.11"), 65535);
  ok(NSNMP::Simple->get($addr, "$intoid.12"), 4294967295);
  ok(NSNMP::Simple->get($addr, "$intoid.13"), 4294967295);

  my %table = NSNMP::Simple->get_table($addr, $intoid);
  ok($table{"$intoid.1"}, 1);
}

# other types
{
  my $counter_oid = '.1.3.6.1.2.1.4.3';
  my $gauge_oid = '.1.3.6.1.2.1.25.1.5';
  my $ip_oid = '.1.3.6.1.2.1.4.20.1.1';
  my $oid_oid = '.1.3.6.1.2.1.1.2';
  my $timeticks_oid = '.1.3.6.1.2.1.1.8';
  my $intoid = '.1.3.6.1.2.1.2.2.1.4';  # interface MTU
  my $addr = NSNMP::Agent->new(
    types => {
      $counter_oid => NSNMP::Counter32,
      $gauge_oid => NSNMP::Gauge32,
      $ip_oid => NSNMP::IpAddress,
      $oid_oid => NSNMP::OBJECT_IDENTIFIER,
      $timeticks_oid => NSNMP::TimeTicks,
      $intoid => NSNMP::INTEGER,
    },
    values => {
      "$counter_oid.0" => (pack "N", 12345),
      "$gauge_oid.0" => (pack "C", 8),
      "$ip_oid.127.0.0.1" => (pack "C*", 127,0,0,1),
      "$oid_oid.0" => (NSNMP->encode_oid(".1.3.6.1.4.1.8072.3.2.10")),
      "$timeticks_oid.0" => (pack "N", 400),
      "$intoid.0" => (pack "N", 1536),
    },
  )->temp_agent();

  # getting
  ok(NSNMP::Simple->get($addr, "$counter_oid.0"), 12345);
  ok(NSNMP::Simple->get($addr, "$gauge_oid.0"), 8);
  ok(NSNMP::Simple->get($addr, "$ip_oid.127.0.0.1"), '127.0.0.1');
  # note no leading dot:
  ok(NSNMP::Simple->get($addr, "$oid_oid.0"), "1.3.6.1.4.1.8072.3.2.10");
  ok(NSNMP::Simple->get($addr, "$timeticks_oid.0"), 400);
  # XXX opaque, NsapAddress

  # setting
  ok(NSNMP::Simple->set($addr, "$gauge_oid.0", NSNMP::Gauge32, 17));
  ok(NSNMP::Simple->get($addr, "$gauge_oid.0"), 17);
  ok(not NSNMP::Simple->set($addr, "$gauge_oid.0", NSNMP::INTEGER, 18));
  ok(NSNMP::Simple->get($addr, "$gauge_oid.0"), 17);

  ok(NSNMP::Simple->set($addr, "$ip_oid.127.0.0.1", NSNMP::IpAddress,
		       '10.6.7.1'));
  ok(NSNMP::Simple->get($addr, "$ip_oid.127.0.0.1"), '10.6.7.1');

  # different sizes of integer.  Note that SNMP doesn't require
  # minimal encoding.
  ok(NSNMP::Simple->set($addr, "$gauge_oid.0", NSNMP::Gauge32, 255));
  ok(NSNMP::Simple->get($addr, "$gauge_oid.0"), 255);
  ok(NSNMP::Simple->set($addr, "$gauge_oid.0", NSNMP::Gauge32, 300));
  ok(NSNMP::Simple->get($addr, "$gauge_oid.0"), 300);
  ok(NSNMP::Simple->set($addr, "$gauge_oid.0", NSNMP::Gauge32, 5000));
  ok(NSNMP::Simple->get($addr, "$gauge_oid.0"), 5000);
  ok(NSNMP::Simple->set($addr, "$gauge_oid.0", NSNMP::Gauge32, 50000));
  ok(NSNMP::Simple->get($addr, "$gauge_oid.0"), 50000);
  ok(NSNMP::Simple->set($addr, "$gauge_oid.0", NSNMP::Gauge32, 65535));
  ok(NSNMP::Simple->get($addr, "$gauge_oid.0"), 65535);
  ok(NSNMP::Simple->set($addr, "$gauge_oid.0", NSNMP::Gauge32, 65536));
  ok(NSNMP::Simple->get($addr, "$gauge_oid.0"), 65536);
  ok(NSNMP::Simple->set($addr, "$gauge_oid.0", NSNMP::Gauge32, 1_000_000));
  ok(NSNMP::Simple->get($addr, "$gauge_oid.0"), 1_000_000);
  # gauge32 is supposed to be *unsigned* 32-bit, so it should handle this
  ok(NSNMP::Simple->set($addr, "$gauge_oid.0", NSNMP::Gauge32, 4_294_967_295));
  ok(NSNMP::Simple->get($addr, "$gauge_oid.0"), 4_294_967_295);

  # but integer is signed, so it should handle this
  ok(NSNMP::Simple->set($addr, "$intoid.0", NSNMP::INTEGER, -2_147_483_648));
  ok(NSNMP::Simple->get($addr, "$intoid.0"), -2_147_483_648);
}

# this is to make sure our exit status is 0.
# for some reason, doing this in the END block makes our exit status
# be 9 instead!
NSNMP::Agent->kill_temp_agents();

# TODO ensure port defaults to 161
# TODO tie
# TODO negative timeticks
