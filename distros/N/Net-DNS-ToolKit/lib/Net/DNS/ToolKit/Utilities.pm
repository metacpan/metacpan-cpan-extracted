#!/usr/bin/perl
package Net::DNS::ToolKit::Utilities;

use strict;
#use diagnostics;

use vars qw($VERSION @ISA @EXPORT_OK $ID);

$VERSION = do { my @r = (q$Revision: 0.05 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

use AutoLoader 'AUTOLOAD';

use Config;
use IO::Socket;
use Net::DNS::Codes qw(
	T_ANY
	T_A
	T_TXT
	T_MX
	T_NS
	T_SOA
	T_PTR
	T_CNAME
	C_IN
	NS_PACKETSZ
	QUERY
	NOERROR
	BITS_QUERY
	RD
);
use Net::DNS::ToolKit qw(
	put16
	get16
	gethead
	newhead
	get_ns
);
use Net::DNS::ToolKit::RR;
	
$ID = time % 65536;	# unique for now

require Exporter;
@ISA = qw(Exporter);

@EXPORT_OK = qw(
	id
	question  
	revIP   
	query  
	dns_udpsend
	dns_udpresp
	dns_ans
	dns_ns
	dns_ptr
	rlook_send
	rlook_rcv
);

# autoload declarations

sub DESTROY{};

1;
__END__

=head1 NAME

Net::DNS::ToolKit::Utilities - a collection of helper utilities

=head1 SYNOPSIS

  use Net::DNS::ToolKit::Utilities qw(
	id
	question  
	revIP   
	query  
	dns_udpsend
	dns_udpresp
	dns_ans
	dns_ns
	dns_ptr
	rlook_send
	rlook_rcv
  );

  $unique = id($seed);
  $querybuf = question($name,$type);
  $rev = revIP($ip);
  $response = query(\$buffer,$timeout);
  $socket = dns_udpsend(\$buffer,$timeout);
  $response = dns_udpresp($socket,$timeout);
  ($aptr,$tptr,$auth_zone) = dns_ans(\$buffer);
  $nsptr = dns_ns(\$buffer);
  $hostname = dns_ptr(\$buffer);
  @hosts = dns_ptr(\$buffer);
  $socket = rlook_send($IP,$timeout);
  $hostname = rlook_rcv($socket,$timeout);

=head1 DESCRIPTION

B<Net::DNS::ToolKit::Utilities> provides a collection of DNS utilities
built from the ToolKit building blocks

=over 4

=item * $unique = id($seed);

Return a unique, non-zero, 16 bit ID for this session. Seeded with time, this number is
autoincremented each time it is retrieved and will be unique each call from
a single session. The number wraps around at 65535.

  input:	[optional] seed
  returns:	the last 16 bit number +1

Optionally, the user may supply a seed for the first call. Subsquent calls
will return the previous number + 1 (mod 65536). The seed is set when the module is
instantiated if no seed is supplied.

=cut

sub id {
  my $seed = shift;
  $ID = ($seed % 65536) if $seed;
  $ID = 1 if ++$ID > 65535;
  return $ID;
}

=item * $querybuf = question($name,$type);

Create a C_IN DNS query of $type about $name.

  input:	host or domain name,
		query type
  returns:	query buffer

Supports types T_A, T_TXT, T_ANY, T_MX, T_NS, T_PTR  

=cut

sub question {
  my ($name,$type) = @_;
  return undef unless
	$type == T_NS ||
	$type == T_MX ||
	$type == T_ANY ||
	$type == T_TXT ||
	$type == T_PTR ||
	$type == T_A;

  my $buffer;
  my $offset = newhead(\$buffer,
	&id(),
	BITS_QUERY | RD,		# query, recursion desired
	1,0,0,0,			# one question
  );
  my ($get,$put,$parse) = new Net::DNS::ToolKit::RR;
  $offset = $put->Question(\$buffer,$offset,$name,$type,C_IN);
  return $buffer;
}

=item * $rev = revIP($ip);

Reverse an IP address. i.e

  78.56.34.12 = revIP(12.34.56.78);

  input:	a dot quad IP address
  returns:	reversed dot quad address

NOTE: this is an operation on ASCII characters, not packed network
addresses.

=cut

sub revIP {
  my @ip = split(/\./, shift);
  @_ = reverse @ip;
  return join('.',@_);
}
  
=item * $response = query(\$buffer,$timeout);

Sends a DNS query contained in $buffer. Return a DNS
response buffer or undef on error. If the error is catastophic (like a
timeout), $@ will be set.

  input:	pointer to query buffer,
		optional timeout (secs, def 30)
  returns:	DNS answer or undef

=cut

sub query {
  my($bp,$timeout) = @_;
  $timeout = 30 unless $timeout && $timeout > 0;
  my @servers = get_ns();
  my $port = 53;
  my ($msglen,$response);
  my $len = length($$bp);
  foreach my $server (@servers) {
    $server = inet_ntoa($server);
    eval {
      local $SIG{ALRM} = sub {die "connection timed out, no servers could be reached"};
      alarm $timeout;
##### open socket
      my $socket = IO::Socket::INET->new(
	PeerAddr	=> $server,
	PeerPort	=> $port,
	Proto		=> 'udp',
	Type		=> SOCK_DGRAM,
      ) or die "connection timed out, no servers could be reached";

##### send UDP query
      syswrite $socket, $$bp, length($$bp);
##### read UDP answer
      unless ($msglen = sysread($socket,$response,NS_PACKETSZ)) {	# get response, size limited
	close $socket;

	$socket = IO::Socket::INET->new(
	  PeerAddr	=> $server,
	  PeerPort	=> $port,
	  Proto		=> 'tcp',
	  Type		=> SOCK_STREAM,
	) or die "connection timed out, no servers could be reached";

##### send TCP query
	put16(\$msglen,0,$len);
	syswrite $socket, $msglen, 2;
	syswrite $socket, $$bp, $len;

##### read TCP answer
	sysread $socket, $response, 2;

	$msglen = get16(\$response,0);
	$msglen = sysread $socket, $response, $msglen;
      } # using TCP
      close $socket;
      alarm 0;
    }; # end eval
    next if $@;
    next unless $msglen;
    return $response;
  } # end if foreach, no server found
  return undef;
}

=item * $socket = dns_udpsend(\$buffer,$timeout);

Sends a DNS query contained in $buffer. Returns a UDP socket or undef;
If the error is catastophic (like a timeout), $@ will be set.

  input:	pointer to query buffer,
		optional timeout (secs, def 30)
  returns:	socket or undef

=cut

sub dns_udpsend {
  my($bp,$timeout) = @_;
  $timeout = 30 unless $timeout && $timeout > 0;
  my @servers = get_ns();
  my $port = 53;
  my $len = length($$bp);
  my $server = inet_ntoa($servers[0]);
  my $socket;
  eval {
      local $SIG{ALRM} = sub {die "connection timed out, no servers could be reached"};
      alarm $timeout;
##### open socket
      $socket = IO::Socket::INET->new(
	PeerAddr	=> $server,
	PeerPort	=> $port,
	Proto		=> 'udp',
	Type		=> SOCK_DGRAM,
      ) or die "connection timed out, no servers could be reached";

##### send UDP query, should not block
      syswrite $socket, $$bp, length($$bp);
      alarm 0;
  };
  return $socket;
}

=item * $buffer = dns_udpresp($socket,$timeout);

Returns a DNS answer from $socket and closes socket. Returns undef on
failure. If the error is catastophic (like a timeout), $@ will be set.

  input:	socket,
		optional timeout (secs, def 30)
  returns:	response buffer

  closes:	socket

=cut

sub dns_udpresp {
  my($socket,$timeout) = @_;
  return undef unless $socket;
  $timeout = 30 unless $timeout && $timeout > 0;
  my $response = undef;
  eval {
      local $SIG{ALRM} = sub {die "connection timed out, no servers could be reached"};
      alarm $timeout;
      sysread($socket,$response,NS_PACKETSZ) or die "no message received";
  };
  alarm 0;
  close $socket;
  return $response;
}

=item * ($aptr,$tptr,$auth_zone)=dns_ans(\$buffer);

Parse a DNS answer and return pointer to an array of B<A> response records
and B<TXT> records blessed into the callers namespace.

  input:	DNS answer
  returns:	pointers to two arrays,
		auth_zone name or ''

Returns an empty array unless there is at least ONE B<A> record found.

The first array contains packed IPv4 addresses of the form
returned by inet_aton (text). The second array contains text strings.

auth_zone will contain the zone name if an SOA record is found, otherwise
it will contain ''.

=cut

sub dns_ans {
  my $bp = shift;
  my $aptr = [];
  my $tptr = [];
  my $zone = '';
  my ($caller) = caller;
  my ($off,$id,$qr,$opcode,$aa,$tc,$rd,$ra,$mbz,$ad,$cd,$rcode,
	$qdcount,$ancount,$nscount,$arcount)
	= gethead($bp);

  DECODE:
  while(1) {
    last if
	$tc ||
	$opcode != QUERY ||
	$rcode != NOERROR ||
	$qdcount != 1 ||
	$ancount < 1;

    my ($get,$put,$parse) = new Net::DNS::ToolKit::RR;
    my ($off,$name,$type,$class) = $get->Question($bp,$off);
    last unless $class == C_IN;

    foreach(0..$ancount -1) {
      ($off,$name,$type,$class,my($ttl,$rdlength,@rdata)) =
	$get->next($bp,$off);
      if ($type == T_A) {
	push @$aptr, @rdata;
      } elsif ($type == T_TXT) {
	if (@rdata > 1) {
	  push @$tptr, join(' ',@rdata);
	} else {
	  push @$tptr, @rdata;
	}
      }
    }
    last if $ancount && @$aptr;	# end, if there is an answer
    last unless $arcount;	# end if there is no authority
    foreach(0..$nscount -1) {
      ($off,@_) = $get->next($bp,$off);	# toss these
    }
    foreach(0..$arcount -1) {
      ($off,$name,$type,@_) =
	$get->next($bp,$off);
      if($type == T_SOA) {
	$zone = $name;
	last DECODE;
      }
    }
    last;
  }
  return () unless @$aptr;
  bless $aptr, $caller;
  bless $tptr, $caller;
  return($aptr,$tptr,$zone);
}

=item * $nsptr = dns_ns(\$buffer);

Parse a DNS NS request answer and return pointer to a hash of name servers
and TTL's.

  $ptr->{hostname}--->{addr} = netaddr
		   |
		   *->{ttl}  = seconds

If no records are found, undef is returned

  input:	pointer to response buffer
  returns:	pointer to hash or undef

=cut

sub dns_ns {
  my $bp = shift;
  my $nsptr = {};
  my @ns;
  my ($caller) = caller;
  my ($off,$id,$qr,$opcode,$aa,$tc,$rd,$ra,$mbz,$ad,$cd,$rcode,
	$qdcount,$ancount,$nscount,$arcount)
	= gethead($bp);

  DECODE:
  while(1) {
    last if
	$tc ||
	$opcode != QUERY ||
	$rcode != NOERROR ||
	$qdcount != 1 ||
	$ancount < 1 ||
	$arcount < 1;

    my ($get,$put,$parse) = new Net::DNS::ToolKit::RR;
    my ($off,$name,$type,$class) = $get->Question($bp,$off);
    last unless $class == C_IN;

    foreach(0..$ancount -1) {
      ($off,$name,$type,$class,my($ttl,$rdlength,@rdata)) =
	$get->next($bp,$off);
      if ($type == T_NS) {
	push @ns, @rdata;
      }
    }
    last unless @ns;		# end if there is no answer
    foreach(0..$nscount -1) {
      ($off,@_) = $get->next($bp,$off); # toss these
    }
    foreach(0..$arcount -1) {
      ($off,$name,$type,$class,my($ttl,$rdlength,@rdata)) =
	$get->next($bp,$off);
      if ($type == T_A && grep($name eq $_,@ns)) {
	$nsptr->{"$name"}->{addr} = $rdata[0];	# return first available ns address
	$nsptr->{"$name"}->{ttl} = $ttl;
      }
    }
    last;
  }
  return undef unless keys %$nsptr;
  bless $nsptr, $caller;
  return $nsptr;
}

=item * $host = dns_ptr(\$buffer);

Parse a DNS PTR request answer and return the hostname

If no records are found, undef or an empty array is returned

  input:	pointer to response buffer
  returns:	host name or array of hosts

=cut

sub dns_ptr {
  my $bp = shift;
  unless ($$bp) {
    return wantarray ? () : undef;
  }
  my ($off,$id,$qr,$opcode,$aa,$tc,$rd,$ra,$mbz,$ad,$cd,$rcode,
	$qdcount,$ancount,$nscount,$arcount)
	= gethead($bp);

  if (	$tc ||
	$opcode != QUERY ||
	$rcode != NOERROR ||
	$qdcount != 1 ||
	$ancount < 1 ) {
    return wantarray ? () : undef;
  }

  my ($get,$put,$parse) = new Net::DNS::ToolKit::RR;
  ($off,my($name,$type,$class)) = $get->Question($bp,$off);
  unless ($class == C_IN) {
    return wantarray ? () : undef;
  }

  my($ttl,$rdlength,$host,@hosts);
  foreach(0..$ancount -1) {
    ($off,$name,$type,$class,$ttl,$rdlength,$host) =
	$get->next($bp,$off);
    push @hosts, $host;
  }
#  ($name,$type,$class,@hosts) = $parse->PTR($name,$type,$class,@hosts);
  return wantarray ? @hosts : $hosts[0];
}

=item * $socket = rlook_send($IP,$timeout);

Send a query for reverse lookup of $IP 
and return the receive socket handle.

  input:	dotquad IP address,
		optional timeout (sec, def 30)
  return:	socket or undef

=cut

sub rlook_send {
  my($IP,$timeout) = @_;
  my $buffer = undef;
  my $offset = newhead(\$buffer,
	&id(),
	BITS_QUERY | RD,	# query, recursion desired
	1,0,0,0,		# one question
  );
  my $dnsblIP = revIP($IP);
  my ($get,$put,$parse) = new Net::DNS::ToolKit::RR;
  $offset = $put->Question(\$buffer,$offset,$dnsblIP.'.in-addr.arpa',T_PTR,C_IN);
 return dns_udpsend(\$buffer,$timeout);
}

=item * $hostname = rlook_rcv($socket,$timeout);

Receive DNS response, parse for hostname, close socket;

  input:	receive socket,
		optional timeout (sec, def 30)
  return:	hostname text or undef

=back

=cut

sub rlook_rcv {
  my $buffer = dns_udpresp(@_);
  return dns_ptr(\$buffer);
}

=head1 DEPENDENCIES

	IO::Socket
        Net::DNS::Codes
        Net::DNS::ToolKit
        Net::DNS::ToolKit::RR

=head1 EXPORT

        none by default

=head1 EXPORT_OK

        id   
        question
        revIP
        query
        dns_udpsend
        dns_udpresp
        dns_ans
        dns_ns
        dns_ptr
        rlook_send
        rlook_rcv 

=head1 COPYRIGHT

=head1 COPYRIGHT

    Copyright 2003 - 2011, Michael Robinton <michael@bizsystems.com>
   
Michael Robinton <michael@bizsystems.com>

All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of either:

  a) the GNU General Public License as published by the Free
  Software Foundation; either version 2, or (at your option) any
  later version, or

  b) the "Artistic License" which comes with this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of 
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either    
the GNU General Public License or the Artistic License for more details.

You should have received a copy of the Artistic License with this
distribution, in the file named "Artistic".  If not, I'll be glad to provide
one.

You should also have received a copy of the GNU General Public License
along with this program in the file named "Copying". If not, write to the

        Free Software Foundation, Inc.                        
        59 Temple Place, Suite 330
        Boston, MA  02111-1307, USA                                     

or visit their web page on the internet at:                      

        http://www.gnu.org/copyleft/gpl.html.

=head1 AUTHOR

Michael Robinton <michael@bizsystems.com>

=head1 SEE ALSO

L<Net::DNS::Codes>, L<Net::DNS::ToolKit>, L<Net::DNS::ToolKit::RR>,

=cut

1;
