#!/usr/bin/perl
#
# dig.pl
my $version = sprintf("%0.2f",1.11);	# 10-4-11 Michael Robinton <michael@bizsystems.com>

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

my $DEBUG2FILE = 0;		# save response records to file

sub usage {
  print STDERR "\n",@_ if @_;
  print STDERR q|
Syntax:
dig.pl [@server] [+tcp] [-d] [-h] [-p port#] [-t type] name

server	is the name or IP address of the name server to query.  An IPv4
	address can be provided in dotted-decimal notation.  When the
	supplied server argument is a hostname, dig resolves that name
	before querying that name server.

  +tcp	only use TCP protocol

  -d	print the query to the console

  -h	print the header to the console

  -p	port# is the port number that dig.pl will send its queries 
	instead of the standard DNS port number 53.

  -t	indicates what type of query is required. This script supports
	only A, AAAA, MX, NS, CNAME, SOA, TXT, and ANY queries as well as
	AXFR record transfers. If no type argument is supplied, dig.pl
	will perform a lookup for an A record

name    is the name of the resource record that is to be looked up.

|;
  exit 1;
}

my $tcp		= 0;		# default
my $debug	= 0;		# default
my $headbug	= 0;		# default
my $Type	= T_A;		# default
my $port	= 53;		# default
my $server	= get_ns();	# default to first ns on list
my $name	= '';
$server	= ($server)
	? inet_ntoa($server)
	: '127.0.0.1';
my $sname = $server;

my %allowed = (
	A	=>	T_A,
	AAAA	=>	T_AAAA,
	MX	=>	T_MX,
	NS	=>	T_NS,
	CNAME	=>	T_CNAME,
	SOA	=>	T_SOA,
	AXFR	=>	T_AXFR,
	ANY	=>	T_ANY,
	TXT	=>	T_TXT,
	PTR	=>	T_PTR,
);

my($class);

&usage unless (@_ = @ARGV);		# exit with message if no args

my $cmdline = join(' ',@ARGV);

# parse args
while ($_ = shift) {
  if ($_ =~ /^@(.+)/) {			# new server
    $sname = $1;
    $server = (gethostbyname($sname))[4]; # use first address
    &usage("could not find server $sname")
	unless $server;
    $server = inet_ntoa($server);
  }
  elsif ($_ =~ /^\-d/) {	# debug?
    $debug = 1;
  }
  elsif ($_ =~ /^\-h/) {	# header?
    $headbug = 1;
  }
  elsif ($_ =~ /^\-t/) {	# type?
    $Type = uc shift;		# must be next item 
    &usage("bad type $Type") unless exists $allowed{$Type};
    $Type = $allowed{$Type};
  }
  elsif ($_ =~ /^\-p/) {	# port?
    &usage("invalid port number $port")
	if ($port = shift) =~ /\D/;
  }
  elsif ($_ =~ /^\+tcp/) {
    $tcp = 1;
  }
  elsif ($_ =~ /^\-/) {
    &usage("unknown option $_");
  }
  else {			# must be a name
    chop if $_ =~ /\.$/;
    $name = $_;
  }
}

# get start timer
my @time = gettimeofday;

# construct query
my $buffer;
my $offset = newhead(\$buffer,
	$$,				# pid is always unique
	BITS_QUERY | RD,		# query, recursion desired
	1,0,0,0,			# one question
);

&usage('you must supply a name')
	unless $name;

my ($get,$put,$parse) = new Net::DNS::ToolKit::RR;
$offset = $put->Question(\$buffer,$offset, $name,$Type,C_IN);

print_head(\$buffer) if $headbug;	# show header if header debug
print_buf(\$buffer) if $debug;		# show query if debug

my $response;
my $head = qq|
; <<>> dig.pl $version <<>> $cmdline
;;
|;

my $timeout = 15;	# seconds

eval {
  local $SIG{ALRM} = sub {die "connection time out, no servers could be reached"};
  alarm $timeout;
  if (! $tcp && $Type != T_AXFR) {			# UDP for all except AXFR
##### open socket
    my $socket = IO::Socket::INET->new(
	PeerAddr	=> $server,
	PeerPort	=> $port,
	Proto		=> 'udp',
	Type		=> SOCK_DGRAM,
    ) or die "connection timed out, no servers could be reached";

##### send UDP query
    syswrite $socket, $buffer, $offset;	# offset contains length of packet

##### read UDP answer
    my $urcv;
    die "failed to get UDP message" unless 
	defined ($urcv = sysread($socket, $response, NS_PACKETSZ));	# get response, size limited
    close $socket;
    if($DEBUG2FILE) {
	open(T,'>./tmpu.tmp');
	syswrite T, $response, $urcv;
	close T;
	print "UDP RCV=$urcv\n";
    }
  } # UDP only

  if ($tcp || $Type == T_AXFR || ! response2text(\$response)) {
    my $socket = IO::Socket::INET->new(
	PeerAddr	=> $server,
	PeerPort	=> $port,
	Proto		=> 'tcp',
	Type		=> SOCK_STREAM,
    ) or die "connection timed out, no servers could be reached";

##### send TCP query
    my $msglen;
    put16(\$msglen,0,$offset);		# offset contains the length of message
    syswrite $socket, $msglen, 2;
    syswrite $socket, $buffer, $offset;	# offset contains length of message

##### read TCP answer

    open(T,'>./tmpt.tmp') if $DEBUG2FILE;

    my $continue = 1;
    my $soaCount = 0;
    while ($soaCount < 2) {
      $soaCount = 2 unless $Type == T_AXFR;
      alarm $timeout;
      if ($continue && sysread $socket, $response, 2) {
	my $rcvdtot = 0;
	my($rcvd,$buf);
        $msglen = get16(\$response,0);
	$response = '';
	my $nleft = $msglen;
	while($rcvd = sysread($socket, $buf, $nleft)) {
	  $response .= $buf;
	  $nleft -= $rcvd;
	  alarm $timeout;
	}
	die "failed to read TCP message $msglen" unless
	  defined $rcvd;
	alarm 0;

	syswrite(T,$response,$msglen) if $DEBUG2FILE;
        $continue = response2text(\$response,\$soaCount);
      } else {
        print "; Transfer failed.\n";
	alarm 0;
	close $socket;
	exit 1;
	last;
      }
    close T if $DEBUG2FILE;
    }    
    close $socket;
  } # using TCP
  alarm 0;
}; # end eval

if ($@) {
  print STDERR $head,';; ',$@,"\n";
  exit 1;
}

sub response2text {
  my($bp,$soap) = @_;
  my $type;
  if ($headbug) {
    print "\n\n";
    print_head($bp);		# show header if header debug
  }
  if ($debug) {
    print "\n\n";
    print_buf($bp);		# show answer if debug
  }

## decipher the answer
  my ($newoff,$id,$qr,$opcode,$aa,$tc,$rd,$ra,$mbz,$ad,$cd,$rcode,
	$qdcount,$ancount,$nscount,$arcount)
	= gethead($bp);

## adjust format for print
  my $flags .= 'qr ' if $qr;
  $flags .= 'aa ' if $aa;
  $flags .= 'tc ' if $tc;
  $flags .= 'rd ' if $rd;
  $flags .= 'ra ' if $ra;
  $flags .= 'z ' if $mbz;
  $flags .= 'ad ' if $ad;
  $flags .= 'cd ' if $cd;
  chop $flags;

  print $head;
  return 0 unless $rcode == &NOERROR;	# flag failures for AXFR

  $opcode = OpcodeTxt->{$opcode};
  $rcode = RcodeTxt->{$rcode};

  print qq
|;; Got answer.
;; ->>HEADER<<- opcode: $opcode, status: $rcode, id: $id
;; flags: $flags; QUERY: $qdcount, ANSWER: $ancount, AUTHORITY: $nscount, ADDITIONAL: $arcount
| unless $Type == T_AXFR;

  print q|
;; QUESTION SECTION:
| unless $Type == T_AXFR;

  foreach(0..$qdcount -1) {
    ($newoff,$name,$type,$class) = $get->Question($bp,$newoff);
    ($name,$type,$class) = $parse->Question($name,$type,$class);
    $type = strip($type);
    $class = strip($class);
    print ";$name\t\t$class\t$type\n" unless $Type == T_AXFR;
  }

  print q|
;; ANSWER SECTION:
| unless $Type == T_AXFR;
  $newoff = nextsect($bp,$newoff,$ancount,$soap);

  print q|
;; AUTHORITY SECTION:
| unless $Type == T_AXFR;
  $newoff = nextsect($bp,$newoff,$nscount,$soap);
  
  print q|
;; ADDITIONAL SECTION:
| unless $Type == T_AXFR;
  $newoff = nextsect($bp,$newoff,$arcount,$soap);

# end timer
  @time[2,3] = gettimeofday;
  my $msec = sprintf("%0.0f",elapsed(@time));
  $_ = $qdcount + $ancount + $nscount + $arcount;
  print qq|
;; Query time: $msec ms
;; SERVER: $server#$port($sname)
;; WHEN: | . scalar localtime() . qq|
;; MSG SIZE rcvd: $newoff -- XFR size: $_ records
|;
1;	# true if no errors
}

sub nextsect {
  my($bp,$off,$count,$soap) = @_;
  foreach(0..$count -1) {
    ($off, my($name,$type,$class,$ttl,$rdlength,@rdata)) = $get->next($bp,$off);
    ++$$soap if $soap && $type == T_SOA;	# bump soa counter if it exists
    ($name,$type,$class,$ttl,$rdlength,@rdata) = $parse->RR($name,$type,$class,$ttl,$rdlength,@rdata);
    $type =~ s/T_//;
    $class =~ s/C_//;
    print "$name\t$ttl\t$class\t$type\t";
    foreach(@rdata) {
      print $_,' ';
    }
    print "\n";
  }
  return $off;
}

sub elapsed {
  my ($startsec,$startusec,$endsec,$endusec) = @_;
  if ($endusec < $startusec) {
    $endusec += 1000000;
    $endsec -= 1;
  }
  my $msec = ($endusec - $startusec)/1000;
  $msec += ($endsec - $startsec) * 1000;
}
