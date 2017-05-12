#!/usr/bin/perl
#
# rdns_blk.pl
#
my $version = 0.03;	# 8-9-04 Michael Robinton <michael@bizsystems.com>

#
# Copyright 2003, Michael Robinton <michael@bizsystems.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#

use strict;
#use diagnostics;
use IO::Socket 1.18;
use Net::DNS::Codes qw(:all);
use Net::DNS::ToolKit qw(
	get16
	put16
	get_ns
	newhead
	gethead
	strip
	gettimeofday
);
use Net::DNS::ToolKit::Debug qw(
	print_buf
	print_head
);
use Net::DNS::ToolKit::RR;

my $timeout	= 5;		# default DNS timeout
my $debug	= 0;		# default
my $Type	= T_PTR;	# default
my $port	= 53;		# default
		# first server on list
my $server	= inet_ntoa(scalar get_ns());
my $seed = time % 65536;

sub ranid {
  $seed = 1 if (++$seed > 65535);
  return $seed;
}

sub usage {
  print STDERR "\n",@_ if @_;
  print STDERR qq|
Syntax:
  $0 nn.nn.nn[.nn]
    or
  $0 -d nn.nn.nn[.nn]

  at least the first three groups of 
  dot.quad.addr numbers

  returns PTR results for 1..255 of address range
  skips non-existent records, notes timeouts

  '-d'	use this flag to show the DNS response
	code when there is no rDNS record.

|;
  exit 1;
}

$| = 1;			# unbuffer IO

# construct query
my ($name,$offset,$buffer,$ip,$response,$revip,$match);

usage unless @ARGV;

while($_ = shift @ARGV) {
  if ($_ eq '-d') {
    $debug = 1;
    next;
  }
  elsif ($_ =~ /(\d+)\.(\d+)\.(\d+)/) {
    $revip = "${3}.${2}.${1}.in-addr.arpa";
    $match = "${&}.";
  }
}
usage unless $revip;

##### open socket
my $socket = IO::Socket::INET->new(
	PeerAddr	=> $server,
	PeerPort	=> $port,
	Proto		=> 'udp',
	Type		=> SOCK_DGRAM,
) or die "no servers could be reached";

# construct query
my ($get,$put,$parse) = new Net::DNS::ToolKit::RR;

foreach (1..255) {
  $name = join('.',$_,$revip);
  $ip = $match . $_;
  my $bp = \$buffer;
  $offset = newhead($bp,
	ranid(),
	BITS_QUERY | RD,		# query, recursion desired
	1,0,0,0,			# one question
  );

#  print_head($bp) if $debug;

  $offset = $put->Question(\$buffer,$offset, $name,$Type,C_IN);

#  print_buf($bp) if $debug;

eval {
  local $SIG{ALRM} = sub {die "timeout"};
  alarm $timeout;
  my $wrote = syswrite $socket, $buffer, $offset;	# offset contains length of packet

##### read UDP answer
  my $urcv;
  die "failed to get UDP message" unless 
	defined ($urcv = sysread($socket, $response, NS_PACKETSZ));	# get response, size limited
  alarm 0;
  };
  if ($@) {
    print "$ip\ttimeout ${timeout}s\n";
    next;
  }
  $bp = \$response;
## decipher the answer
  my ($newoff,$id,$qr,$opcode,$aa,$tc,$rd,$ra,$mbz,$ad,$cd,$rcode,
	$qdcount,$ancount,$nscount,$arcount)
	= gethead($bp);

  if ($rcode != NOERROR) {
    if ($debug) {
      $rcode = RcodeTxt->{$rcode};
      print "$ip\t$rcode\n";
    }
    next;
  }

  my($type,$class,$ttl,$rdlength,@rdata);
  foreach(0..$qdcount -1) {
    ($newoff,$name,$type,$class) = $get->Question($bp,$newoff);
  }
  print $ip;
  foreach(0..$ancount -1) {
    ($newoff, $name,$type,$class,$ttl,$rdlength,@rdata) = $get->next($bp,$newoff);
#  ($name,$type,$class,$ttl,$rdlength,@rdata) = $parse->RR($name,$type,$class,$ttl,$rdlength,@rdata);
    print "\t$rdata[0]";
  }
  print "\n";
}

close $socket;
