#!/usr/bin/perl
package Net::DNS::Dig;

use strict;
#use diagnostics;

use vars qw(
	$VERSION
	@ISA
	@EXPORT_OK
);

use Net::DNS::Codes qw(:all);
use Net::DNS::ToolKit qw(
	get_ns
	newhead
	gethead
	get16
	put16
	getflags
	putflags
	gettimeofday
	strip
);
use Net::DNS::ToolKit::Utilities qw(
	id
	question
	revIP
);
use Net::DNS::ToolKit::RR;
use Net::NBsocket qw(
        connect_NB   
        open_udpNB   
	sockaddr_in
);
use NetAddr::IP::InetBase qw(
	inet_ntoa
	inet_aton
	ipv6_aton
	ipv6_ntoa
	AF_INET
	AF_INET6
);
use NetAddr::IP::Util qw(
	havegethostbyname2
);
use Sys::Hostname::FQDN qw(
	fqdn
);

use Net::DNS::ToolKit::Debug qw(
        print_buf
        print_head
);
use Data::Dumper;
#use AutoLoader qw(AUTOLOAD);

require Exporter;
@ISA = qw(Exporter);


$VERSION = do { my @r = (q$Revision: 0.12 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

@EXPORT_OK = qw(
	ndd_gethostbyaddr
	ndd_gethostbyname
	ndd_gethostbyname2
	AF_INET
	AF_INET6
);

# used a lot, create once per session
my @_NS	= get_ns() || die "this host has no usable name server\n";
my $ID	= time % 65536;			# seed unique
my $ME	= fqdn();			# get my name

# declare autoload prototypes
sub my_name2_gethostby;
sub my_addr_gethostby;
sub al_name_gethostby;
sub al_name2_gethostby;
sub al_addr_gethostby;
sub _check4addr;
sub _get_host;

*ndd_gethostbyaddr  = \&al_addr_gethostby;
*ndd_gethostbyname  = \&al_name_gethostby;
*ndd_gethostbyname2 = \&al_name2_gethostby;

sub DESTROY {};

my $_Sock6ok	 = 1;		# for testing gethostby emulations
				# true uses Socket6 if present

my $_gethostHelp = 1;		# for testing gethostby emulations
				# true uses core gethostby__ if present

# for autoloading
sub _get_NS {
  @_NS;
}

sub _hostHelp {
  $_gethostHelp;
}

# for testing
sub _set_NS {
  @_NS = @_;
}
sub _set_Help {
  $_gethostHelp = shift;
}

sub import {
  if (grep { $_ eq ':noSock6' } @_) {
        $_Sock6ok = 0;
        @_ = grep { $_ ne ':noSock6' } @_;
  }
  if (grep { $_ eq ':forceEmu' } @_) {
	$_gethostHelp = 0;
	@_ = grep { $_ ne ':forceEmu' } @_;
  }
  Net::DNS::Dig->export_to_level(1,@_);
}

=head1 NAME

Net::DNS::Dig - dig like methods

=head1 SYNOPSIS

IO methods and functions to return DNS information

These functions do not use C<SIG_ALRM> and are safe to use in CGI programs.

  use Net::DNS::Dig qw(
	:forceEmu
	ndd_gethostbyaddr
	ndd_gethostbyname
	ndd_gethostbyname2
	AF_INET
	AF_INET6
  );

  $dig = new Net::DNS::Dig();
  $dig = new Net::DNS::Dig( %hash );
  $dig = new Net::DNS::Dig( \%hash );

  $dobj = $dig->for(name, type);
  $tobj = $dig->to_text();

  $array_ptr =  $dig->data($section);
  $array_ptr = $tobj->data($section);

  $array_ptr =  $dig->records($type,$sect);
  $array_ptr = $tobj->records($type,$sect);

  $text  = $dig->sprintf;

  $rv    = $dig->rcode(true/false);
  $rdata =  $dig->rdata($type,$sect);
  $rdata = $tobj->rdata($type,$sect;

     or in array context
  @array = $dig->data($section);
  @array = $dig->records($type,$sect);
  @rdata = $dig->rdata($type,$sect);

  ($name,$aliases,$addrtype,$length,@addrs)
	= ndd_gethostbyaddr( naddr_naddr6 );

  ($name,$aliases,$addrtype,$length,@addrs)
	= ndd_gethostbyname( name_ipV4_ipV6 );

  ($name,$aliases,$addrtype,$length,@addrs)
	= ndd_gethostbyname2( name_ipV4_ipV6 AF_family);

    or in array context
  $name	   = ndd_gethostbyaddr(netaddr);
  $netaddr = ndd_gethostbyname(name_ipV4);
  $netaddr = ndd_gethostbyname2(name_ipV4_ipV6,AF_family);

=cut

my %Defaults = (
	Timeout		=>  15,
	Class		=> 'IN',
#	PeerAddr	=>  filled in by _get_nameservers
	PeerPort	=>  53,
	Proto		=> 'UDP',
	Recursion	=>  1
);

# for autoloading
sub _timeout {
  $Defaults{Timeout};
}

# method to calculate elapsed run time
#
# input:	two element start time from gettimeofday
# returns:	milliseconds of elapsed time
#
sub _elapsed {
  my($self,$startsec,$startusec) = @_;
  my($endsec,$endusec) = gettimeofday;

  if ($endusec < $startusec) {
    $endusec += 1000000;
    $endsec -= 1;
  }
  my $msec = ($endusec - $startusec)/1000;
  $msec += ($endsec - $startsec) * 1000;
  $self->{ELAPSED} = sprintf("%0.0f",$msec);
}

#use POSIX qw(EINTR EAGAIN);

# function to write to a non-blocking tcp socket
# input:	socket
#		buffer pointer
#		length of message
#		timeout
# returns:	number of bytes written
#
sub _tcp_write {
  my($sock,$bp,$len,$timeout) = @_;
  my($dummyin,$dummyout,$win,$wout,$ein,$eout,$delta,$wrote);
  my $fileno = fileno($sock);
  my $written = 0;
  my $then = time;
  my $buffer = $$bp;

  local $SIG{PIPE} = 'IGNORE';

  while ($len > 0) {
    $dummyin = $win = '';
    vec($win,fileno($sock),1) = 1;
    $ein = $win;
    my $nbfound = select($dummyout=$dummyin,$wout=$win,undef,0.1);
    if ($nbfound > 0) {
      if ($wout) {	# ready to write
	$wrote = syswrite($sock,$buffer,$len,$written);
	return undef unless defined $wrote;	# some error
	$written += $wrote;
	$len -= $wrote;
      }
# hint
#             if ( ! defined $wrote ) {
#               next if $! == EAGAIN;           # would block
#             }
    }
    elsif ($delta = ($_ = time) - $then) {
      $then = $_;
      $timeout -= $delta;
      last if $timeout < 0;
    }
  }
  if ($timeout < 0) {
    $! = 110;
    return undef;
  }
  return $written;	# return number of bytes written
}

# function to read a non-blocking tcp socket
#
# input:	socket
#		buffer pointer
#		length of message
#		timeout
# returns:	number of bytes read
#	appends to $$bp
#
sub _tcp_read {
  my($sock,$bp,$len,$timeout) = @_;
  my($dummyin,$dummyout,$rin,$rout,$ein,$eout,$delta,$rcv);
  my $off = 0;
  my $nleft = $len;
  my $fileno = fileno($sock);
  my $then = time; 
  my $buffer = '';

  local $SIG{PIPE} = 'IGNORE';

  while (1) {
    $dummyin = $rin = '';
    vec($rin,$fileno,1) = 1;
    $ein = $rin;
    my $nbfound = select($rout=$rin,$dummyout=$dummyin,undef,0.1);
    if ($nbfound > 0) {
      if ($rout) {	# ready to read
	$rcv = sysread($sock,$buffer,$nleft,$off);
       	if ($rcv) {
	  $off += $rcv;
	  $nleft -= $rcv;
	  unless ($off < $len) {
	    $$bp .= $buffer;
	    return $off;
	  }
	}
	elsif (defined $rcv ) {			# must be zero
	  $$bp .= $buffer;
	  return $off;
	} else {
	  return undef;				# failed on some error
	}
      }
# hint
#             if ( ! defined $wrote ) {
#               next if $! == EAGAIN;           # would block
#             }
    }
    elsif ($delta = ($_ = time) - $then) {
      $then = $_;
       $timeout -= $delta;
      last if $timeout < 0;
    }
  }
  if ($timeout < 0) {
    $! = 110;
    return undef;
  }
  return $rcv;	# return number of bytes read
}

# method to do standard tcp DNS queries
#
#  input:	pointer to query buffer
#		netaddr for name server
#  returns:	pointer to query response or undef,
#		sock if wantarray
#  else closes sock (also closes on error)
#
#  errno:       set on error
#
# see wrapper sub '_tquery' below

sub _tcp_send {
  my($self,$bp,$srv) = @_;
  my $sock;
  $sock = connect_NB($self->{PeerPort},$srv);
  return () unless $sock;            # server error
  
  my $timeout = $self->{Timeout};

##### send TCP query

  my $msglen = length($$bp);
  my $wbuf = '';
  put16(\$wbuf,0,$msglen);              # contains the length of message
  unless (_tcp_write($sock,\$wbuf,2,$timeout)) {
    close $sock;
    return ();
  }
  unless (_tcp_write($sock,$bp,$msglen,$timeout)) {
    close $sock;
    return ();
  }
  return ($sock,$timeout);
}

##### read TCP answer

sub _tcp_ans {
  my($sock,$timeout) = @_;
  return () unless $sock;
  my $rcvd;
  my $buf = '';
  if (_tcp_read($sock,\$buf,2,$timeout)) {
    my $msglen = get16(\$buf,0);
    $buf = '';
    $rcvd = _tcp_read($sock,\$buf,$msglen);
  }
  if (defined $rcvd) {
    return (\$buf,$sock);
  } else {
    close $sock;
    return ();
  }
}

sub _tquery {
  local $SIG{PIPE} = 'IGNORE';
  my($bp,$sock) = _tcp_ans(_tcp_send(@_));
  return wantarray ? ($bp,$sock) : $bp;
}

# method to do standard udp DNS queries
#
#  input:	pointer to query buffer
#		netaddr for name server
#  returns:	undef or pointer to response
#
#  errno:	set on error ENODATA, ETIMEDOUT, ECONNREFUSED
#
sub _query {
  my ($self,$bp,$srv) = @_;
  my $timeout = $self->{Timeout};
  my $sock = open_udpNB();		# open nonblocking UDP socket
  my $sin = sockaddr_in($self->{PeerPort}, $srv);	# port 53 or wherever of this hosts nameserver
  my $fileno = fileno($sock);

  local $SIG{PIPE} = 'IGNORE';

  my ($dummyin,$dummyout,$rout,$delta,$urcv,$response);
  my $rin = $dummyin= '';
  my $then = time;
  my $data = $$bp;
  my $len = send $sock, $data, 0, $sin;
  while (1) {
	vec($rin,$fileno,1) = 1;		# set read flags
	my $nbfound = select($rout=$rin,$dummyout=$dummyin,undef,0.1);	# tick every 100ms
	if ($nbfound > 0) {			# found something
	  if ($rout) {				# if it is real
	    $urcv = recv($sock,$response,NS_PACKETSZ,0);
	    last;
	  }
        } elsif ($delta = ($_ = time) - $then) {
	  $then = $_;
	  $timeout -= $delta;
	  last if $timeout < 0;
	}
  }
  close $sock;

  if ($timeout < 0) {
    $! = 110;			# connection timed out
    return undef;
  }
  elsif (! defined $urcv) {	# undef is an error
    $! = 111;			# connection refused
    return undef;
  }
  elsif ( $response) {	# if there is data
    return \$response;
  }
  $! = 61;			# no data available
  return undef;
}

# function to process query header
#
#
#  input:#	response buffer pointer
#		fill response object || false
#  returns:	offset
#		rcode
#		qdcount
#		ancount
#		nscount
#		arcount
#
# When a response object is returned, the HEADER section is complete
#
sub _proc_head($;$) {
  my($bp,$obj) = @_;
    my($newoff,$id,$qr,$opcode,$aa,$tc,$rd,$ra,$mbz,$ad,$cd,$rcode,
	$qdcount,$ancount,$nscount,$arcount)
	= gethead($bp);
  unless ($obj) {
    return (undef,$rcode,0,0,0,0)
	unless $ancount && defined $newoff;
  } else {
    @{$obj->{HEADER}}{qw(
		ID
		QR
		AA
		TC
		RD
		RA
		MBZ
		AD
		CD
		RCODE
		OPCODE
		QDCOUNT
		ANCOUNT
		NSCOUNT
		ARCOUNT
    )} = ($id,$qr,$aa,$tc,$rd,$ra,$mbz,$ad,$cd,$rcode,$opcode,$qdcount,$ancount,$nscount,$arcount);
  }
  return ($newoff,$rcode,$qdcount,$ancount,$nscount,$arcount);
}

# function to process question response question
#
#  input:	get pointer
#		offset
#		response buffer pointer
#		fill response object || false
#  returns:	offset
#
# When response object is returned, the
# HEADER and QUESTION sections are complete
#
sub _proc_ques($$$;$) {
  my($get,$off,$bp,$self) = @_;
  ($off,my($name,$type,$class)) = $get->Question($bp,$off);

  if ($self ) {
    my $record = {};
    @{$record}{qw( NAME TYPE CLASS )}
	= ($name, $type, $class);
    push @{$self->{QUESTION}}, $record;
  }
  return $off;
}

# function to process query response data records
#
#  input:	get pointer
#		offset
#		response buffer pointer
#		section, one of ANSWER AUTHORITY ADDITIONAL
#		counter for section
#		SOA count pointer
#		fill response object pointer or false
#  returns:	offset
#		@rdata
#
sub _proc_data($$$$$;$$) {
  my($get,$off,$bp,$sect,$count,$soap,$obj) = @_;
  my @retdata;
  foreach(0..$count -1) {		# slurp all records
    ($off,my($name,$type,$class,$ttl,$rdlen,@rdata)) = $get->next($bp,$off);    
    ++$$soap if $soap && $type == T_SOA;
    if ($obj) {
      my $record = {};
      @{$record}{qw( NAME TYPE CLASS TTL RDLEN RDATA )}
	= ($name,$type,$class,$ttl,$rdlen,\@rdata);
      push @{$obj->{$sect}}, $record;
    }
    push @retdata, @rdata;
  }
  return ($off,@retdata);
}

# method to process entire body of response (recursively) for TCP
#
# input:	self
#		response pointer
#		pointer to query buffer
#		get
#		put
#		SOA counter pointer and flag that this is an AXFR
# returns:	response pointer updated
#
sub _proc_body {
  my($self,$resptr,$bp,$get,$put,$soap) = @_;

  unless ($resptr) {		# if server fails
    my $flags = getflags($bp);
    $flags &= RCODE_MASK;
    $flags |= SERVFAIL;
    putflags($bp,$flags);
    $resptr = $bp;
  }

  my ($off,$rcode,$qdcount,$ancount,$nscount,$arcount)
	= _proc_head($resptr,$self);

  if ($rcode) {		# some failure code
    $ancount = $nscount = $arcount = 0;
  }

  $self->{NRECS} += $qdcount + $ancount + $nscount + $arcount;

  if ($soap && $$soap > 0) {		# this is an AXFR and question is processed
    $off = _proc_ques($get,$off,$resptr) if $qdcount;
  } else {
    $off = _proc_ques($get,$off,$resptr,$self) if $qdcount;
  }

  my @section = (qw( ANSWER AUTHORITY ADDITIONAL ));
  my @counts  = ($ancount,$nscount,$arcount);
  foreach (0..$#section) {
    ($off) = _proc_data($get,$off,$resptr,$section[$_],$counts[$_],$soap,$self);
  }

  $self->{BYTES} += $off;
  return $resptr;
}

my $native;			# sub pointer if native gethostbyname2 is present

# for autoloading
sub _no_emulation {
  return $native && $_Sock6ok && $_gethostHelp;
}

# run time configuration for this HOST

if (havegethostbyname2()) {
  $native = \&Socket6::gethostbyname2;
}
else {
  $native = undef;
}

=head1 DESCRIPTION

=over 1

=item * $dig = new Net::DNS::Dig(	# optional parameters

      Timeout   => 15,		# default
      Class     => 'IN',	# default
      PeerAddr  => host or [name1, name2, ...] default local NS
      PeerPort  => 53,		# default
      Proto     => 'UDP',	# default
      Recursion => 1,		# default
      QuesHead	=> 0,		# default, print question header
      QuesBody	=> 0,		# default, print question body
      RespHead	=> 0,		# default, print response header
      RespBody	=> 0,		# default, print response body
    );

=cut

# set up name servers for a query
#
# input:	none
# returns:	nothing
#
# sets value of _SS hash
#
sub _get_nameservers {
  my $obj = shift;		# this section is IPv6 compatible
  $obj->{_SS} = {};		# server names => netaddrs

  if ($obj->{PeerAddr}) {
    $obj->{PeerAddr} = [$obj->{PeerAddr}]
	unless ref $obj->{PeerAddr};

    foreach(@{$obj->{PeerAddr}}) {
      my $naddr = ndd_gethostbyname($_);
      $naddr = ndd_gethostbyname2($_,AF_INET6())
	unless $naddr;
      $obj->{_SS}->{$_} = $naddr if $naddr;
    }
  }
  else {
    $obj->{_SS} = {};
    $obj->{PeerAddr} = [];
    foreach(@_NS) {
      my $ns = (length($_) == 4)
	? inet_ntoa($_)
	: ipv6_ntoa($_);
      push @{$obj->{PeerAddr}}, $ns;
      $obj->{_SS}->{$ns} = $_;
    }
  }
}

sub new {
  my $proto     = shift;
  my $class = ref $proto || $proto || __PACKAGE__;

# gather input hash if any
  my $self = ref $_[0] ? $_[0] : {@_} || {};

# special server name processing if user supplied NS
  _get_nameservers($self);

  foreach(keys %Defaults) {
    $self->{$_} = $Defaults{$_} unless exists $self->{$_};
  }

  $self->{Recursion} = &RD
	if $self->{Recursion};

# correct case of Class and Proto
  $self->{Class}	= uc $self->{Class};
  $self->{Proto}	= uc $self->{Proto};

  die "unsupported Class '$self->{Class}'"
	unless	$self->{Class} eq 'IN';
  die "unsupported Proto '$self->{Proto}'"
	unless	$self->{Proto} eq 'UDP'
	||	$self->{Proto} eq 'TCP';

  return bless $self, $class;
}

=item * $dobj = $dig->for(name, type);

This method returns a blessed object containing the binary query response object

  $dobj is $dig filled with the following data

  input:	query name	i.e. host name, ip address, etc...
		type		[optional type] A, MX, etc...
  returns:	blessed object of the form...

  $dobj = {
	Timeout	  => input value,
	Class	  => input value,
	PeerAddr  => [input value],
	PeerPort  => input value,
	Proto	  => input value,
	Recursion => input value,

	Errno	  => posix error number or set to zero

	ELAPSED	  => milliseconds,	# query time
	NRECS	  => number of records,
	BYTES	  => number of bytes
	TEXT	  => '',		# this field is empty
	SERVER	  => name,		# of query server

	HEADER	  => {
		ID	=> return value,
		QR	=> return value,
		AA	=> return value,
		TC	=> return value,
		RD	=> return value,
		RA	=> return value,
		MBZ	=> return value,
		AD	=> return value,
		CD	=> return value,
		RCODE	=> return value,
		OPCODE	=> return value,
		QDCOUNT	=> return value, # question
		ANCOUNT	=> return value, # answer
		NSCOUNT	=> return value, # authority
		ARCOUNT => return value, # additional
	},
	QUESTION  => [
		{
		NAME	=> return name,
		TYPE	=> return type,
		CLASS	=> return class,
		},
	],
	ANSWER	  => [	# for each answer record
		{
		NAME	=> return name,
		TYPE	=> return type,
		CLASS	=> return class,
		TTL	=> return ttl,
		RDLEN	=> $n,		# octets
		RDATA	=> @rdata,	# data fields
		},
	],
	AUTHORITY  => [	# for each authority record
		{
		NAME	=> return name,
		TYPE	=> return type,
		CLASS	=> return class,
		TTL	=> return ttl,
		RDLEN	=> $n,		# octets
 		RDATA	=> @rdata,	# data fields
		},
	],
	ADDITIONAL  => [	# for each glue record
		{
		NAME	=> return name,
		TYPE	=> return type,
		CLASS	=> return class,
		TTL	=> return ttl,
		RDLEN	=> $n,		# octets
		RDATA	=> @rdata,	# data fields
		},
	],
  };

=cut

# deprecated
my %allowed = (
        A       =>      T_A,
        AAAA    =>      T_AAAA,
        MX      =>      T_MX,
        NS      =>      T_NS,
        CNAME   =>      T_CNAME,
        SOA     =>      T_SOA,
        AXFR    =>      T_AXFR,
        ANY     =>      T_ANY,
        TXT     =>      T_TXT,
        PTR     =>      T_PTR,
);

my %not_allowed = (
	IXFR	=>	T_IXFR,
);

sub for($$$) {									# NOT LOADABLE
  my($self,$name,$Type) = @_;
  $Type = 'A' unless $Type;

# check arguments
  die "you must provide name to look up\n" unless $name;

  $Type = uc $Type;
  my $ttype = 'T_'. $Type;

  if ( $not_allowed{$Type} || ! exists $Net::DNS::Codes::{$ttype}) {
    die "unsupported type '$Type'\n";
    $ttype = do { no strict; &$ttype; };
  } else {
    $ttype = do { no strict; &$ttype; };
  }

# deprecated by above in v0.04
#  my $ttype = $allowed{$Type};

  die "unsupported class '$self->{Class}'\n"
	unless $self->{Class} eq 'IN';

  my @time = gettimeofday;

  my ($get,$put,$parse) = new Net::DNS::ToolKit::RR;

  my $buffer = '';
  my $resptr;
  
  my $off = newhead(\$buffer,
	$ID,					# pid is always unique
	BITS_QUERY | $self->{Recursion},	# query, recursion desired
	1,0,0,0,				# one question
  );

  $off = $put->Question(\$buffer,$off,$name,$ttype,C_IN);

  my $isAXFR = $Type eq 'AXFR'
	? 1 : 0;
  my $isTCP = ($isAXFR || $self->{Proto} eq 'TCP')
	? 1 : 0;
 NameServer:
  foreach my $h (@{$self->{PeerAddr}}) {	# preserve order of name servers
    $self->{SERVER} = $h;
    next unless exists $self->{_SS}->{$h};	# punt if _get_nameservers could not find host
    my $ns = $self->{_SS}->{$h};
    if ($isTCP) {
	my $soaCount = 0;
	my $soap = $isAXFR ? \$soaCount : 0;	# set flag for AXFR
	my $sock;
	if ($soap) {
	  ($resptr,$sock) = $self->_tquery(\$buffer,$ns);
	} else {
	  $resptr = $self->_tquery(\$buffer,$ns);
	}
	unless ($resptr) {
	  close $sock if $sock;
	  next NameServer;
	}
	while ($soaCount < 2) {
		$soaCount = 2 unless $isAXFR;
		$resptr = $self->_proc_body($resptr,\$buffer,$get,$put,$soap);
		unless ($resptr) {
		  close $sock if $sock;
		  next NameServer;
		}
	} continue {
		if ($soaCount < 2) {
		  ($resptr,$sock) = _tcp_ans($sock,$self->{Timeout});
		  unless ($resptr) {
		    close $sock if $sock;
		    next NameServer;
		  }
		}
	}
	close $sock if $sock;
    } else {	# is UDP
	$resptr = $self->_query(\$buffer,$ns);
	next NameServer unless $resptr;
	$resptr = $self->_proc_body($resptr,\$buffer,$get,$put);
    }
    last if $resptr;
  }
  if ($resptr) {
    $! = 0;		# errno unconditionally set to zero
  } else {		# server failed
    $self->_proc_body($resptr,\$buffer,$get,$put);
  }
  $self->{Errno} = $!;
  print_head(\$buffer)	if $self->{QuesHead};
  print_buf(\$buffer)	if $self->{QuesBody};
  print_head($resptr)	if $self->{RespHead};
  print_buf($resptr)	if $self->{RespBody};
  $self->_elapsed(@time);
  return $self;
}

1;
#__END__

=item * $tobj = $dig->to_text();

This method returns a blessed object of the same form as B<dig> above with the
following fields converted to text:

	RCODE
	OPCODE
	QUESTION
	ANSWER
	AUTHORITY
	ADDITIONAL

The TEXT value scalar is filled with a formatted text string like that returned from *NIX C<dig>

=cut

sub to_text {
  my $self = shift;
  my $d = Data::Dumper->new([$self],['tobj']);
  $d->Purity(1)->Deepcopy(1)->Indent(1);
  my $tobj;
  eval $d->Dump;

  my $isAXFR = (exists $self->{QUESTION}->[0]->{TYPE} &&
		$self->{QUESTION}->[0]->{TYPE} == &T_AXFR)
	? 1 : 0;

  my $tcp = $self->{Proto} eq 'TCP'
	? '+tcp ' : '';

# HEADER
  my $head = $tobj->{HEADER};
  $head->{OPCODE}	= OpcodeTxt->{$head->{OPCODE}}
				|| $head->{OPCODE};		# numeric if unknown

  my $Rcode = $head->{RCODE};					# true if not NOERROR
  $head->{RCODE}	= RcodeTxt->{$Rcode} || $Rcode;		# numeric if unknown

  my $flags  = ' ';
  $flags .= 'qr ' if $head->{QR};
  $flags .= 'aa ' if $head->{AA};
  $flags .= 'tc ' if $head->{TC};
  $flags .= 'rd ' if $head->{RD};
  $flags .= 'ra ' if $head->{RA};
  $flags .= 'z '  if $head->{MBZ};
  $flags .= 'ad ' if $head->{AD};
  $flags .= 'cd ' if $head->{CD};
  chop $flags;

# convert each section as appropriate

  my $text = '';
  my($get,$put,$parse) = new Net::DNS::ToolKit::RR;

  foreach my $sect (qw( QUESTION ANSWER AUTHORITY ADDITIONAL )) {

    next unless exists $tobj->{$sect};
# append Section Text
    $text .= qq|
;; $sect SECTION:
| unless $isAXFR || $Rcode;

    my($name,$type,$class,$ttl,$rdlen,@rdata);

    my @data = @{$tobj->{$sect}};
    foreach my $resp (@data) {
      if ($sect eq 'QUESTION') {
	@{$resp}{qw( NAME TYPE CLASS )} = $parse->Question(@{$resp}{qw( NAME TYPE CLASS )});
	$resp->{TYPE} = strip($resp->{TYPE});
	$resp->{CLASS} = strip($resp->{CLASS});
	($name,$type,$class,) = @{$resp}{qw( NAME TYPE CLASS )};
	$text .= qq|;$name\t\t$class\t$type\n|
		unless $isAXFR;
      } elsif (! $Rcode) {				# no error
	($name,$type,$class,$ttl,$rdlen,@rdata) = $parse->RR(@{$resp}{qw( NAME TYPE CLASS TTL RDLEN )}, @{$resp->{RDATA}});
	$type = strip($type);
	$class = strip($class);
	@{$resp}{qw( NAME TYPE CLASS TTL RDLEN RDATA )} = ($name,$type,$class,$ttl,$rdlen,[@rdata]);
	$text .= qq|$name\t$ttl\t$class\t$type\t|;
	foreach (@rdata) {
	  $text .= ' '. $_;
	}
	$text .= "\n";
      }
    }
  }

  my $sname = $self->{SERVER};
  my $server = '';

  if (exists $self->{_SS}->{$sname} && ! $Rcode) {	# if there really was a lookup
    $server = $self->{_SS}->{$sname};			# address of server
    $server = (length($server) == 4)
	? inet_ntoa($server)
	: ipv6_ntoa($server);
  }

  $text .= "\n" unless $isAXFR || $Rcode;	# extra carrige return except for Rcode failure and AXFR
  $text .= q
|;; Query time: |. $self->{ELAPSED} .qq| ms
;; SERVER: ${server}# |. $self->{PeerPort} .qq|($sname)
;; WHEN: | . scalar localtime() . q|
;; MSG SIZE rcvd: |. $self->{BYTES} .q| -- XFR size: |. $self->{NRECS} .q| records
| unless $Rcode;

# build header
  $head =  q|
; <<>> |. __PACKAGE__ .' '. sprintf("%0.2f", $VERSION) .qq| <<>> ${tcp}-t |. 
(lc $tobj->{QUESTION}->[0]->{TYPE}) .' '.
$tobj->{QUESTION}->[0]->{NAME} .q|
;;
|;

  my($opcode,$rcode,$id,$qdcount,$ancount,$nscount,$arcount)
	= @{$tobj->{HEADER}}{qw( OPCODE RCODE ID QDCOUNT ANCOUNT NSCOUNT ARCOUNT )};

  $head .= "; Transfer failed.\n"
	if $Rcode;

  $head .= qq
|;; Got answer.
;; ->>HEADER<<- opcode: $opcode, status: $rcode, id: $id
;; flags:$flags; QUERY: $qdcount, ANSWER: $ancount, AUTHORITY: $nscount, ADDITIONAL: $arcount
| unless $isAXFR;


  $tobj->{TEXT} = $head . $text;

  return $tobj;
}

=item * $array_ptr =  $dig->data($section);

=item * $array_ptr = $tobj->data($section);

  or

=item * @array = $dig->data($section);

This method returns a pointer or array in binary or text form from 
from a $dig or $tobj object pointer, respectively.

In scalar context returns a pointer to an array of query response hash's
representing each record returned.

In array context returns an array of hash's for each query response record.

  input:    section name [optional, default ANSWER]

  returns:  array pr pointer to array of one or more hash's
	    ->[ {}, {}, {}, ...];

  where $section if one of:
   QUESTION, ANSWER, AUTHORITY, ADDITIONAL

Each answer hash is of the form described above for:

	$dig->for();

=cut

sub data {
  my($self,$sect) = @_;
  $sect = 'ANSWER' unless $sect;
  unless (	$sect eq 'ANSWER' ||
		$sect eq 'AUTHORITY' ||
		$sect eq 'ADDITIONAL' ||
		$sect eq 'QUESTION' ) {
    return wantarray
	? () : [];
  }
  return wantarray
	? @{$self->{$sect}}
	: $self->{$sect};
}

=item * $array_ptr =  $dig->records($type,$sect);

=item * $array_ptr = $tobj->records($type,$sect);

  or

=item * @array = $dig->records($type,$sect);

This method returns a pointer to or an array of RDATA arrays for each query response
record.

  input:    $type  [optional record type, A, NS, etc...]
    not case sensitive, defaults to TYPE of original query
	    $sect  [optional section, defaults to ANSWER]

  returns:  array or pointer to array of one or more rdata arrays
		->[ [], [], [], ...] ];

  where $sect is one of ANSWER, AUTHORITY, ADDITIONAL

Each answer array is of the form described above for RDATA in:

	$dig->for();

=cut

sub records {
  my($self,$type,$sect) = @_;
  $sect = 'ANSWER' unless $sect;
  unless (	$sect eq 'ANSWER' ||
		$sect eq 'AUTHORITY' ||
		$sect eq 'ADDITIONAL' ) {
    return wantarray
	? () : [];
  }
  my $mode = $self->{QUESTION}->[0]->{CLASS} =~ /\d+/
	? 0	# binary
	: 1;	# text

  unless ($type) {
    $type = $self->{QUESTION}->[0]->{TYPE};
    $type = TypeTxt->{$type} unless $mode;	# convert to text if binary
    $type =~ s/T_//;
  }

  $type = eval {
	no strict;
	&{'T_'. uc $type};			# convert type to binary
  } || 0;

  unless ($type) {
    return wantarray
	? () : [];
  }

  if ($mode) {
    ($type = TypeTxt->{$type}) =~ s/T_//;
  }

  my @records;
  foreach (@{$self->{$sect}}) {
    if (
	($mode && $_->{TYPE} eq $type) ||
	(!$mode && $_->{TYPE} == $type) ) {
      push @records, $_->{RDATA};
    }
  }
  return wantarray
	? @records
	: \@records;
}

=item * $rdata =  $dig->rdata($type,$sect);

=item * $rdata = $tobj->rdata($type,$sect;

  or

=item * @rdata = $dig->rdata($type,$sect);

This method returns the first element or a list of rdata items. See the
appropriate RFC's for types such as MX which have two elements per record.

  i.e.	MX rdata => (priority, name)

  multiple records would be returned as a list of 
	pri, name, pri, name, etc...

  input:    $type  [optional record type, A, NS, etc...]
    not case sensitive, defaults to TYPE of original query
	    $sect  [optional section, defaults to ANSWER]

  returns: a list or its first element

=cut

sub rdata {
  my $records = &records;
  return $records->[0]->[0] unless wantarray;
  my @list;
  foreach my $rdata (@{$records}) {
    push @list, @{$rdata};
  }
  return @list;
}

=item * $rv = $dig->rcode(true/false);

This method returns the query response code in numeric form if argument is false and the text response code if the argument is true.

  NOERROR   => 0,
  FORMERR   => 1,
  SERVFAIL  => 2,
  NXDOMAIN  => 3,
  NOTIMP    => 4,
  REFUSED   => 5,
  YXDOMAIN  => 6,
  YXRRSET   => 7,
  NXRRSET   => 8,
  NOTAUTH   => 9,
  NOTZONE   => 10,

=cut

sub rcode {
  return $_[1]
	? RcodeTxt->{$_[0]->{HEADER}->{RCODE}}
	: $_[0]->{HEADER}->{RCODE};
}

=item * $text = $dig->sprintf;

This method return the B<dig> query response text from either the dig
object pointer or a dig text object pointer. C<to_text> is called automatically
if required.

=cut

sub sprintf : method {
  my $self = shift;

  my $tobj = ($self->{QUESTION}->[0]->{CLASS} =~ /\D/)	# are we text mode?
	? $self
	: $self->to_text;

  return $tobj->{TEXT};
}

=item * $netaddr = ndd_gethostbyname($name);

or

=item * @array = ndd_gethostbyname($name);

  ($name,$aliases,$aftype,$len,@addrs)
	= ndd_gethostbyname($name);

=item * $netaddr = ndd_gethostbyname2($name,$AF_family);

or

=item * @array = ndd_gethostbyname2

  ($name,$aliases,$aftype,$len,@addrs)
	= ndd_gethostbyname2($name,$AF_family);

=item * $name = ndd_gethostbyaddr($iaddr,$AF_family);

or

=item * @array = ndd_gethostbyaddr

  ($name,$aliases,$aftype,$len,@addrs)
	= ndd_gethostbyaddr($iaddr,$AF_family);

=back

These functions use or emulate the underlying system calls of the same name,
enhancing the capability of Perl to support IPv6 where needed. If the function
is present in Perl and/or Socket6, the Perl function is called directly.

If  C<use Net::DNS::Dig qw( :forceEmu )> is loaded with the force emulation
tag, the Net::DNS;Dig's version of the function is always used. This is
useful when the underlying system C<gethostbyname2> and/or C<gethostbyaddr>
functions are present but broken.

NOTE: the emulations do not check NIS or system C<hosts> file.

  Function Net::DNS::Dig (ndd_) gethostbyname

  input:	$name		text string or ip address
    [optional]	$timeout 	seconds

B<ndd_gethostbyname> emulates or uses Perl's gethostbyname system call.

  Function Net::DNS::Dig (ndd_) gethostbyname2

  input:	$name		text string or ip address
    [optional]	$AF_family	address family type
    [optional]	$timeout	seconds for the emulation

B<ndd_gethostbyname2> provides a fully functional gethostbyname2
implementation that will work on systems that do not support IPv6 or have
broken IPv6 socket libraries. 

If $AF_family is false, B<ndd_gethostbyname2> will examine the supplied 
$name to try and determine the appropriate AF_family if the name is an 
IPv4 address of the form d+.d+.d+.d+ or and IPv6 address in one of the
RFC1884 formats it will do the right thing and return a text version of 
the address. Otherwise, AF_INET is assumed by default 
and a DNS lookup will be performed.

  Function Net::DNS::Dig (ndd_) gethostbyaddr

  input:	$naddr		network address
    [optional]	$AF_family	address family type
    [optional]	$timeout 	seconds for the emulation

If $AF_family is false, B<ndd_gethostbyaddr> will examine the
supplied $naddr and determine the appropriate AF_family.

Common return, all functions

  $name		text name
  $aliases	space separated list of text names
  $atype	address type - AF_family constant
  $len		length of the address 4 or 16
  @addrs	array of naddrs in network form

=over 1

=item * $constant = AF_INET;

=item * $constant = AF_INET6;

=back

These two functions return the constant value for the AF_families, respectively,
of the underlying operating system.

=cut

sub my_name2_gethostby {								# LOADABLE
  my($self,$name,$af) = @_; 

  return $native->($name,$af) 
	if &_no_emulation;							# sub LOADABLE

# else use the emulator

  $self->{AddrType} = $af;

  my $type = ($af == &AF_INET)
	? &T_A
	: &T_AAAA;
  return $self->_get_host($name,$type);
}

sub my_addr_gethostby {								# LOADABLE
  my($self,$name,$af) = @_;

  $self->{NetAddr}  = $name;
  $self->{AddrType} = $af;

  if ($af == &AF_INET) {
    return gethostbyaddr($name,$af) if &_hostHelp;				# sub LOADABLE
    $name = revIP(inet_ntoa($name)) .'.in-addr.arpa';	# else use the emulation
  } else {
    $name = join('.',
	reverse split(//,
	sprintf ("%04x%04x%04x%04x%04x%04x%04x%04x",unpack("n8",$name))
			 )
		     ) .'.ip6.arpa';
  }
  return $self->_get_host($name,&T_PTR);
}

# sub ndd_gethostbyname {								# LOADABLE
sub al_name_gethostby {
  my($name,$timeout) = @_;
  $timeout = &_timeout unless $timeout;						# sub LOADABLE

  my @rv;

  my($addrtype,$length,@addrs) = _check4addr($name);

  if ($addrtype) {
    @rv = ($name,'',$addrtype,$length,@addrs);
  }
  elsif (&_hostHelp) {	# using core routines					# sub LOADABLE
    @rv = gethostbyname($name);
  }
  else {			# use emulation
    my $self = bless { Timeout => $timeout };
    @rv = my_name2_gethostby($self,$name,&AF_INET);
  }
  return wantarray
	? @rv
	: $rv[4];	# first address slot
}

# sub ndd_gethostbyname2 {							# LOADABLE
sub al_name2_gethostby {
  my($name,$af,$timeout) = @_;

  $af = 0 unless $af;
  $timeout = &_timeout unless $timeout;						# sub LOADABLE

  my @rv;
  my($addrtype,$length,@addrs) = _check4addr($name,$af);

#
# if $addrtype is FALSE, one of the following apply
#
# combinations						action
#
# 1	gethostHelp	af = AF_INET			native gethostbyname
# 2	gethostHelp	af = AF_INET6			available gethostbyname2
# 3	gethostHelp	af = default	AF_INET		native gethostbyname
# 4	! gethostHelp	af = AF_INET			emulator
# 5	! gethostHelp	af = AF_INET6			emulator
# 6	! gethostHelp	af = default	AF_INET6	emulator
#
#	1 and 3 must be tested, 2 tests itself and will do the righ thing
#
  if ($addrtype) {						# have the answer
    @rv = ($name,'',$addrtype,$length,@addrs);			# was an IP address
  }
#	either ! $af or $af = AF_INET
  elsif ( &_hostHelp && $af != &AF_INET6) {		# user said AF_INET or is default AF_INET	# sub LOADABLE
    @rv = gethostbyname($name);				# default to IPv4 & core functions
  }
  else {
    my $self = bless { Timeout => $timeout };
    @rv = my_name2_gethostby($self,$name,$af);		# this function checks $_gethostHELP
  }
  return wantarray
	? @rv
	: $rv[4];
}

# sub ndd_gethostbyaddr {							# LOADABLE
sub al_addr_gethostby {
  my($name,$af,$timeout) = @_;

  $timeout = &_timeout unless $timeout;						# sub LOADABLE
  my @rv;

  unless ($af) {
    if ( length($name) == 4 ) {		# looks like IPv4
      $af = &AF_INET;
    }
    elsif ( length($name) == 16) {	# it is possible to screw this up
      $af = &AF_INET6;
    }
    else {				# unknown naddr length, probably a real name
      goto &ndd_gethostbyname;		# emulate behavior of perl gethostbyaddr, assume IPv4
    }
  }

  if ($af) {
    $af = 0 unless $af == &AF_INET || $af == &AF_INET6;
  }

  if ((length($name) == 4 && $af == &AF_INET) ||
      (length($name) == 16 && $af == &AF_INET6)	) {
    my $self = { Timeout => $timeout };
    bless $self;
    @rv = my_addr_gethostby($self,$name,$af);
  }
  elsif ($af == &AF_INET || $af == &AF_INET6) {	# valid address family, funny naddr length
    my $self = { Timeout => $timeout };
    bless $self;
    @rv = my_name2_gethostby($self,$name,$af);	# probably a real name, emulate behavior of gethostbyaddr
  }
# else		unknown, return empty
  return wantarray
	? @rv
	: $rv[4];
}

# function to checkfor an IPv4 or IPv6 address and return value + family	# LOADABLE	used only by gethostby
#
# input:	hostname or IP address
#		address family [optional]
#
# returns:	array with addressfamily = 0	if not an address or bad family address match	
#	else	($addressfamily, $length, $netaddr)
#

sub _check4addr {
  my($name,$af) = @_;

  my($len,$netaddr);

  if ($af) {					# address family specified
    if ( $af == &AF_INET && $name !~/[^0-9\.]/ &&
	 ($netaddr = inet_aton($name)) ) {
      $len = 4;
    }
    elsif ( $af == &AF_INET6 && $name !~ /[^0-9a-fA-F\:]/ &&
	    ($netaddr = ipv6_aton($name)) ) {
      $len = 16;
    }
    else {
      return (0);	# not an address or family does not match address
    }
  }
  else {					# family is unknown
    if ( $name !~/[^0-9\.]/ && ($netaddr = inet_aton($name)) ) {
      $af = &AF_INET;
      $len = 4;
    }
    elsif ( $name !~ /[^0-9a-fA-F\:]/ && ($netaddr = ipv6_aton($name)) ) {
      $af = &AF_INET6;
      $len = 16;
    }
    else {
      return (0);	# not an address
    }
  }
  return ($af, $len, $netaddr);

  $netaddr = inet_aton($name);

  if ( $netaddr ) {				# is IPv4
    return (&AF_INET, 4, $netaddr);
  }
  elsif ( $netaddr = ipv6_aton($name) ) {	# is IPv4
    return (&AF_INET6, 16, $netaddr);
  }
  return ();
}

#
# function to execute gethostby
#
# input:	name, type
#	where allowed types are T_PTR, T_A, T_AAAA
#	and PTR names are in appropriate ascii form
#
# returns:	($name,$aliases,$addrtype,$length,@addrs)
#
sub _get_host {									# LOADABLE
  my($self,$n,$t) = @_;
#
#	HOST_NOT_FOUND  1       /* Authoritative Answer Host not found.  */
#	TRY_AGAIN       2       /* Non-Authoritative Host not found,
#                                   or SERVERFAIL.  */
#	NO_RECOVERY     3       /* Non recoverable errors, FORMERR, REFUSED,
#                                   NOTIMP.  */
#	NO_DATA         4       /* Valid name, no data record of requested
#                                   type.  */

# find a name server
  my($buffer,$rp);
  foreach (&_get_NS) {								# sub  LOADABLE
    $buffer = question($n,$t);
    last if $rp = $self->_query(\$buffer,$_);
    $! = 3;		# NO_RECOVERY - Non recoverable errors
  }
  return () unless $rp;
  my($off,$rcode,$qdcount,$ancount,$nscount,$arcount) = _proc_head($rp,$self);
  unless ($ancount) {
    unless ($self->{HEADER}->{RCODE} ) {	# no answers, no data
      $! = $self->{HEADER}->{AA}
	? 1 : 4;	# HOST_NOT_FOUND - Authoritative Answer Host not found (wouldn't this be NXDOMAIN?)
			# NO_DATA - Valid name, no data record of requested
    }
    elsif ( $self->{HEADER}->{RCODE} == &NXDOMAIN) {
      $! = $self->{HEADER}->{AA}
	? 1 : 2;	# HOST_NOT_FOUND - Authoritative Answer Host not found
			# TRY_AGAIN - Non-Authoritative Host not found
    }
    elsif ($self->{HEADER}->{RCODE} == &SERVFAIL) {
      $! = 2;		# TRY_AGAIN - Non-Authoritative Host not found or SERVER FAIL
    }
    else {
      $! = 3;		# NO_RECOVERY - Non recoverable errors
    }
    return ();
  }
  $! = 0;			# no error
  my ($get,$put,$parse) = new Net::DNS::ToolKit::RR;
  $off = _proc_ques($get,$off,$rp);     # skip over question

  my @retdata;

  ($off,@retdata) = _proc_data($get,$off,$rp,'ANSWER',$ancount,undef,$self);

  my($name,$aliases,$addrtype,$length,@addrs);
  $aliases = '';
  $addrtype = $self->{AddrType};

  my @data = @{$self->{ANSWER}};

  foreach my $resp (@data) {
    my ($nam,$typ) = @{$resp}{qw( NAME TYPE )};
    my @rdata = @{$resp->{RDATA}};
    if ($typ == $t) {			# if this is the requested type
      if ($name) {			# and name present
	next;				# skip
      }
      elsif ( $typ == &T_PTR ) {
	$name = $rdata[0];
	$length = ($self->{AddrType} == &AF_INET)
		? 4 : 16;
	push @addrs, $self->{NetAddr};	# recover calling network address
      }
      elsif ( $typ == &T_A || $typ == &T_AAAA) {
	$name = $nam;
	$length = length($rdata[0]);
	push @addrs, @rdata;
      }
#     else	type is unknown and we don't need it
    }
    elsif ( $typ == &T_CNAME ) {
      $aliases .= $nam .' ';
    }
    elsif ( $typ == &T_A || $typ == &T_AAAA) {
      push @addrs, @rdata;
    }
#   else	type is unknown and we don't need it
  }
  chop $aliases if $aliases;		# remove trailing space
  return ($name,$aliases,$addrtype,$length,@addrs);
}

=head1 EXAMPLES

Example usage of Net::DNS::Dig

  ########### example 1	retrieving netaddrs

  use NetAddr::IP::Util qw(inet_ntoa);
  use Net::DNS::Dig;

  $name = 'gmail.com';

  # return one of the gmail 'A' records

  $netaddr = Net::DNS::Dig->new()->for($name)->rdata();

  print inet_ntoa($netaddr),"\n";

  ########### example 2 retrieve many netaddrs

  use NetAddr::IP::Util qw(inet_ntoa);
  use Net::DNS::Dig;

  $name = 'gmail.com';

  # return all of the gmail 'A' records

  @netaddrs = Net::DNS::Dig->new()->for( $name )->rdata();

  foreach ( @netaddrs ) {
    print inet_ntoa( $_ ),"\n";
  }

  ########### example 3	retrieve MX host for email

  use Net::DNS::Dig;

  $email = 'john.doe@gmail.com';

  ( $name = $email ) =~ s/.+\@(.+)/$1/;

  # return all of the gmail 'MX' records
  # records return PRIORITY, HOST, ...   
  # hostnames are unique

  my %mx_info = reverse Net::DNS::Dig->new()->for( $name,'MX' )->rdata();

  my @host_by_priority;

  foreach ( sort {
        $mx_info{$a} <=> $mx_info{$b}
                 } keys %mx_info ) {
    push @host_by_priority, $_;
  }

  foreach ( @host_by_priority ) {  
    print "$_\t    $mx_info{$_}\n";
   
  }

  ########### example 4 a simple 'dig' script

  #!/usr/bin/perl
  #
  # example simple 'dig.pl' script
  #
  use Net::DNS::Dig;

  my ($name,$type);

  while ( $_ = shift @ARGV ) {
    if ( $_ eq '-t' ) {
      $type = shift;
    } else {
      $name = $_;
    }
  }

  print Net::DNS::Dig->new()->for( $name, $type )->sprintf;

# end of script simple dig.pl

  command prompt > dig.pl -t aaaa arpa.com

  [response]

  
  ; <<>> Net::DNS::Dig 0.01 <<>> -t aaaa arpa.com.
  ;;
  ;; Got answer.
  ;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 35979
  ;; flags: qr ra; QUERY: 1, ANSWER: 0, AUTHORITY: 8, ADDITIONAL: 8

  ;; QUESTION SECTION:
  ;arpa.com.              IN      AAAA

  ;; AUTHORITY SECTION:
  arpa.com.       79436   IN      NS       pdns2.ultradns.net.
  arpa.com.       79436   IN      NS       pdns1.ultradns.net.
  arpa.com.       79436   IN      NS       pdns5.ultradns.info.
  arpa.com.       79436   IN      NS       pdns3.ultradns.org.
  arpa.com.       79436   IN      NS       udns2.ultradns.net.
  arpa.com.       79436   IN      NS       pdns4.ultradns.org.
  arpa.com.       79436   IN      NS       udns1.ultradns.net.
  arpa.com.       79436   IN      NS       pdns6.ultradns.co.uk.

  ;; ADDITIONAL SECTION:
  pdns1.ultradns.net.     54013   IN      A        204.74.108.1
  pdns2.ultradns.net.     54013   IN      A        204.74.109.1
  pdns3.ultradns.org.     67699   IN      A        199.7.68.1
  pdns4.ultradns.org.     67699   IN      A        199.7.69.1
  pdns5.ultradns.info.    67699   IN      A        204.74.114.1
  pdns6.ultradns.co.uk.   67699   IN      A        204.74.115.1
  udns1.ultradns.net.     67698   IN      A        204.69.234.1
  udns2.ultradns.net.     67698   IN      A        204.74.101.1

  ;; Query time: 27 ms
  ;; SERVER: 192.168.1.171# 53(192.168.1.171)
  ;; WHEN: Mon Oct 10 17:23:39 2011
  ;; MSG SIZE rcvd: 365 -- XFR size: 17 records


  ########### example 5 a complex 'dig' script

  #!/usr/bin/perl
  #
  # example complex 'dig.pl' script
  #
  use Net::DNS::Dig qw(
	ndd_gethostbyname
  );

  my($name, $type, $port, $server, $tcp, $time, $recurse);

  unless (@ARGV) {
    print qq|\nusage: $0 [options] name

	-t [type]		a, mx, etc...
	-p [port number]
	+tcp			use TCP
	+norecursive
	+time=[seconds]		timeout

  |;
    exit;
  }

  while ( $_ = shift @ARGV ) {
    if ( $_ eq '-t' ) {
      $type = shift;
    }
    elsif ( $_ eq '-p' ) {
      $port = shift;
    }
    elsif ( $_ =~ /^\@(.+)/ ) {
      $server = $1;
    }
    elsif ( lc $_ eq '\+tcp' ) {
      $tcp = 'tcp';
    }
    elsif ( $_ =~ /^\+time=(\d+)/ ) {
      $time = $1;
    }
    elsif ( $_ =~ /^\+norecursive/ ) {
      $recurse = 1;
    }
    else {
      $name = $_;
    }
  }

  my $config = {
	Timeout	  => $time,
	PeerAddr  => $server,
	PeerPort  => $port,
	Proto	  => $tcp,
	Recursion => $recurse,
  };
	
  print Net::DNS::Dig->new($config)->for($name,$type)->to_text->sprintf;

  # end of script complex dig.pl

=head1 EXPORTS_OK

	:forceEmu
	ndd_gethostbyaddr
	ndd_gethostbyname
	ndd_gethostbyname2
	AF_INET
	AF_INET6

=head1 AUTHOR

Michael Robinton <michael@bizsystems.com>

=head1 COPYRIGHT 2011-2014

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

=head1 See also:

Net::DNS::Codes(3), 
Net::DNS::ToolKit(3), 
Net::DNS::ToolKit::Utilities(3),
NetAddr::IP::Util(3)

=cut

1;
