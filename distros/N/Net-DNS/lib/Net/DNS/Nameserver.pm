package Net::DNS::Nameserver;

use strict;
use warnings;

our $VERSION = (qw$Id: Nameserver.pm 1963 2024-01-26 14:47:47Z willem $)[2];


=head1 NAME

Net::DNS::Nameserver - DNS server class

=head1 SYNOPSIS

    use Net::DNS::Nameserver;

    my $nameserver = Net::DNS::Nameserver->new(
	LocalAddr	=> ['::1', '127.0.0.1'],
	LocalPort	=> 15353,
	ZoneFile	=> 'filename'
	);

    my $nameserver = Net::DNS::Nameserver->new(
	LocalAddr	=> '10.1.2.3',
	LocalPort	=> 15353,
	ReplyHandler	=> \&reply_handler
    );

    $nameserver->start_server($timeout);
    $nameserver->stop_server;


=head1 DESCRIPTION

Net::DNS::Nameserver offers a simple mechanism for instantiation of
customised DNS server objects intended to provide test responses to
queries emanating from a client resolver.

It is not, nor will it ever be, a general-purpose DNS nameserver
implementation.

See L</EXAMPLES> below for further details.

=cut

use integer;
use Carp;
use Net::DNS;
use Net::DNS::ZoneFile;

use IO::Select;
use IO::Socket::IP 0.38;
use IO::Socket;
use Socket;

use constant SOCKOPT => eval {
	my @sockopt;
	push @sockopt, eval '[SOL_SOCKET, SO_REUSEADDR]';	## no critic
	push @sockopt, eval '[SOL_SOCKET, SO_REUSEPORT]';	## no critic

	my $filter = sub {					# check that options safe to use
		return eval { IO::Socket::IP->new( Proto => "udp", Sockopts => [shift], Type => SOCK_DGRAM ) }
	};
	return grep { &$filter($_) } @sockopt;			# without any guarantee that they work!
};

use constant DEFAULT_ADDR => qw(::1 127.0.0.1);
use constant DEFAULT_PORT => 15353;

use constant POSIX => defined eval 'use POSIX ":sys_wait_h"; 1';	## no critic
use constant MSWin => scalar( $^O =~ /MSWin/i );


#------------------------------------------------------------------------------
# Constructor.
#------------------------------------------------------------------------------

sub new {
	my ( $class, %self ) = @_;
	my $self = bless \%self, $class;

	$self->ReadZoneFile( $self{ZoneFile} ) if exists $self{ZoneFile};

	croak 'No reply handler!' unless ref( $self{ReplyHandler} ) eq "CODE";

	# local server addresses need to be accepted by a resolver
	my $LocalAddr = $self{LocalAddr} || [DEFAULT_ADDR];
	my $resolver  = Net::DNS::Resolver->new( nameservers => $LocalAddr );
	$resolver->force_v4(1) if $self{Force_IPv4};
	$resolver->force_v6(1) if $self{Force_IPv6};
	$self{LocalAddr} = [$resolver->nameservers];
	$self{LocalPort} ||= DEFAULT_PORT;
	$self{Truncate} = 1 unless defined( $self{Truncate} );
	return $self;
}


#------------------------------------------------------------------------------
# ReadZoneFile - Read zone file used by default reply handler
#------------------------------------------------------------------------------

sub ReadZoneFile {
	my ( $self, $file ) = @_;
	my $zonefile = Net::DNS::ZoneFile->new($file);

	my $RRhash = $self->{index} = {};
	my $RRlist = [];
	my @zonelist;
	while ( my $rr = $zonefile->read ) {
		push @{$RRhash->{lc $rr->owner}}, $rr;

		# Warning: Nasty trick abusing SOA to reference zone RR list
		if ( $rr->type eq 'SOA' ) {
			$RRlist = $rr->{RRlist} = [];
			push @zonelist, lc $rr->owner;
		} else {
			push @$RRlist, $rr;
		}
	}

	$self->{namelist}     = [sort { length($b) <=> length($a) } keys %$RRhash];
	$self->{zonelist}     = [sort { length($b) <=> length($a) } @zonelist];
	$self->{ReplyHandler} = sub { $self->ReplyHandler(@_) };
	return;
}


#------------------------------------------------------------------------------
# ReplyHandler - Default reply handler serving RRs from zone file
#------------------------------------------------------------------------------

sub ReplyHandler {
	my ( $self, $qname, $qclass, $qtype, $peerhost, $query, $conn ) = @_;
	my $RRhash = $self->{index};
	my $rcode;
	my %headermask;
	my @ans;
	my @auth;

	if ( $qtype eq 'AXFR' ) {
		my $RRlist = $RRhash->{lc $qname} || [];
		my ($soa) = grep { $_->type eq 'SOA' } @$RRlist;
		if ($soa) {
			$rcode = 'NOERROR';
			push @ans, $soa, @{$soa->{RRlist}}, $soa;
		} else {
			$rcode = 'NOTAUTH';
		}
		return ( $rcode, \@ans, [], [], {}, {} );
	}

	my @RRname = @{$self->{namelist}};			# pre-sorted, longest first
	{
		my $RRlist = $RRhash->{lc $qname} || [];	# hash, then linear search
		my @match  = @$RRlist;				# assume $qclass always 'IN'
		if ( scalar(@match) ) {				# exact match
			$rcode = 'NOERROR';
		} elsif ( grep {/\.$qname$/i} @RRname ) {	# empty non-terminal
			$rcode = 'NOERROR';			# [NODATA]
		} else {
			$rcode = 'NXDOMAIN';
			foreach ( grep {/^[*][.]/} @RRname ) {
				my $wildcard = $_;		# match wildcard per RFC4592
				s/^\*//;			# delete leading asterisk
				s/([.?*+])/\\$1/g;		# escape dots and regex quantifiers
				next unless $qname =~ /[.]?([^.]+$_)$/i;
				my $encloser = $1;		# check no ENT encloses qname
				$rcode = 'NOERROR';
				last if grep {/(^|\.)$encloser$/i} @RRname;    # [NODATA]

				my ($q) = $query->question;	# synthesise RR at qname
				foreach my $rr ( @{$RRhash->{$wildcard}} ) {
					my $clone = bless( {%$rr}, ref($rr) );
					$clone->{owner} = $q->{qname};
					push @match, $clone;
				}
				last;
			}
		}
		push @ans, my @cname = grep { $_->type eq 'CNAME' } @match;
		$qname = $_->cname for @cname;
		redo if @cname;
		push @ans, @match if $qtype eq 'ANY';		# traditional, now out of favour
		push @ans, grep { $_->type eq $qtype } @match;
		unless (@ans) {
			foreach ( @{$self->{zonelist}} ) {
				s/([.?*+])/\\$1/g;		# escape dots and regex quantifiers
				next unless $qname =~ /[^.]+[.]$_[.]?$/i;
				push @auth, grep { $_->type eq 'SOA' } @{$RRhash->{$_}};
				last;
			}
		}
		$headermask{aa} = 1;
	}
	return ( $rcode, \@ans, \@auth, [], \%headermask, {} );
}


#------------------------------------------------------------------------------
# make_reply - Make a reply packet.
#------------------------------------------------------------------------------

sub make_reply {
	my ( $self, $query, $sock ) = @_;
	my $verbose = $self->{Verbose};

	unless ($query) {
		my $empty = Net::DNS::Packet->new();		# create empty reply packet
		my $reply = $empty->reply();
		$reply->header->rcode("FORMERR");
		return $reply;
	}

	if ( $query->header->qr() ) {
		print "ERROR: invalid packet (qr set), dropping\n" if $verbose;
		return;
	}

	my $reply  = $query->reply();
	my $header = $reply->header;
	my $headermask;
	my $optionmask;

	my $opcode  = $query->header->opcode;
	my $qdcount = $query->header->qdcount;

	unless ($qdcount) {
		$header->rcode("NOERROR");

	} elsif ( $qdcount > 1 ) {
		$header->rcode("FORMERR");

	} else {
		my ($qr)   = $query->question;
		my $qname  = $qr->qname;
		my $qtype  = $qr->qtype;
		my $qclass = $qr->qclass;

		print $qr->string, "\n" if $verbose;

		my $conn = {
			peerhost => my $peer = $sock->peerhost,
			peerport => $sock->peerport,
			protocol => $sock->protocol,
			sockhost => $sock->sockhost,
			sockport => $sock->sockport
			};

		my ( $rcode, $ans, $auth, $add );
		my @arglist = ( $qname, $qclass, $qtype, $peer, $query, $conn );

		if ( $opcode eq "QUERY" ) {
			( $rcode, $ans, $auth, $add, $headermask, $optionmask ) =
					&{$self->{ReplyHandler}}(@arglist);

		} elsif ( $opcode eq "NOTIFY" ) {		#RFC1996
			if ( ref $self->{NotifyHandler} eq "CODE" ) {
				( $rcode, $ans, $auth, $add, $headermask, $optionmask ) =
						&{$self->{NotifyHandler}}(@arglist);
			} else {
				$rcode = "NOTIMP";
			}

		} elsif ( $opcode eq "UPDATE" ) {		#RFC2136
			if ( ref $self->{UpdateHandler} eq "CODE" ) {
				( $rcode, $ans, $auth, $add, $headermask, $optionmask ) =
						&{$self->{UpdateHandler}}(@arglist);
			} else {
				$rcode = "NOTIMP";
			}

		} else {
			print "ERROR: opcode $opcode unsupported\n" if $verbose;
			$rcode = "FORMERR";
		}

		if ( !defined($rcode) ) {
			print "remaining silent\n" if $verbose;
			return;
		}

		$header->rcode($rcode);

		push @{$reply->{answer}},     @$ans  if $ans;
		push @{$reply->{authority}},  @$auth if $auth;
		push @{$reply->{additional}}, @$add  if $add;
	}

	while ( my ( $key, $value ) = each %{$headermask || {}} ) {
		$header->$key($value);
	}

	while ( my ( $option, $value ) = each %{$optionmask || {}} ) {
		$reply->edns->option( $option, $value );
	}

	$header->print if $verbose && ( $headermask || $optionmask );

	return $reply;
}


#------------------------------------------------------------------------------
# TCP_connection - Handle a TCP connection.
#------------------------------------------------------------------------------

sub TCP_connection {
	my ( $self, $socket, $buffer ) = @_;
	my $verbose = $self->{Verbose};

	my $query = Net::DNS::Packet->new( \$buffer );
	if ($@) {
		print "Error decoding query packet: $@\n" if $verbose;
		undef $query;		## force FORMERR reply
	}

	my $reply = $self->make_reply( $query, $socket );
	die 'Failed to create reply' unless defined $reply;

	my $segment = $reply->data;
	my $length  = length $segment;
	if ($verbose) {
		print "TCP response (2 + $length octets) - ";
		print $socket->send( pack 'na*', $length, $segment ) ? "sent" : "failed: $!", "\n";
	} else {
		$socket->send( pack 'na*', $length, $segment );
	}
	return;
}

sub read_tcp {
	my ( $socket, $verbose ) = @_;

	my $l = '';
	local $! = 0;
	my $n = sysread( $socket, $l, 2 );
	unless ( defined $n ) {
		redo if $!{EINTR};	## retry if aborted by signal
		die "sysread: $!";
	}
	return if $n == 0;
	my $msglen = unpack 'n', $l;

	my $buffer = '';
	while ( $msglen > ( my $l = length $buffer ) ) {
		local $! = 0;
		my $n = sysread( $socket, $buffer, ( $msglen - $l ), $l );
		unless ( defined $n ) {
			redo if $!{EINTR};	## retry if aborted by signal
			die "sysread: $!";
		}
		last if $n == 0;	## client closed (or lied)	per RT#151240
	}

	if ($verbose) {
		my $peer = $socket->peerhost;
		my $port = $socket->peerport;
		my $size = length $buffer;
		print "Received $size octets from [$peer] port $port\n";
	}
	return $buffer;
}


#------------------------------------------------------------------------------
# UDP_connection - Handle a UDP connection.
#------------------------------------------------------------------------------

sub UDP_connection {
	my ( $self, $socket, $buffer ) = @_;
	my $verbose = $self->{Verbose};

	my $query = Net::DNS::Packet->new( \$buffer );
	if ($@) {
		print "Error decoding query packet: $@\n" if $verbose;
		undef $query;		## force FORMERR reply
	}

	my $reply = $self->make_reply( $query, $socket );
	die 'Failed to create reply' unless defined $reply;

	my @UDPsize = ( $query && $self->{Truncate} ) ? $query->edns->UDPsize || 512 : ();
	if ($verbose) {
		my $response = $reply->data(@UDPsize);
		print 'UDP response (', length($response), ' octets) - ';
		print $socket->send($response) ? "sent" : "failed: $!", "\n";
	} else {
		$socket->send( $reply->data(@UDPsize) );
	}
	return;
}

sub read_udp {
	my ( $socket, $verbose ) = @_;
	my $buffer = '';
	$socket->recv( $buffer, 9000 );	## payload limit for Ethernet "Jumbo" packet
	if ($verbose) {
		my $peer = $socket->peerhost;
		my $port = $socket->peerport;
		my $size = length $buffer;
		print "Received $size octets from [$peer] port $port\n";
	}
	return $buffer;
}


#------------------------------------------------------------------------------
# Socket mechanics.
#------------------------------------------------------------------------------

use constant DEBUG => 0;

sub logmsg { return warn join '', "$0 $$: @_ at ", scalar localtime(), "\n" }

sub TCP_socket {
	my ( $ip, $port ) = @_;
	my $socket = IO::Socket::IP->new(
		LocalAddr => $ip,
		LocalPort => $port,
		Sockopt	  => [SOCKOPT],
		Proto	  => "tcp",
		Listen	  => SOMAXCONN,
		Type	  => SOCK_STREAM
		)
			or die "can't setup TCP socket: $!";

	logmsg "TCP server [$ip] port $port" if DEBUG;
	return $socket;
}

sub TCP_server {
	my ( $self, $ip, $port, $timeout ) = @_;
	my $listen = TCP_socket( $ip, $port );
	my $select = IO::Select->new($listen);

	my $expired;
	local $SIG{ALRM} = sub { $expired++ };
	local $SIG{TERM} = sub { $expired++ };
	alarm $timeout;
	until ($expired) {
		local $! = 0;
		scalar( my @ready = $select->can_read(2) ) or do {
			redo if $!{EINTR};	## retry if aborted by signal
			last if $!;
		};

		foreach my $socket (@ready) {
			if ( $socket == $listen ) {
				$select->add( $listen->accept );
				next;
			}
			if ( my $buffer = read_tcp( $socket, $self->{Verbose} ) ) {
				spawn( sub { $self->TCP_connection( $socket, $buffer ) } );
			} else {
				close($socket);
				$select->remove($socket);
			}
		}
		sleep(0) if MSWin;
	}
	return;
}


sub UDP_socket {
	my ( $ip, $port ) = @_;
	my $socket = IO::Socket::IP->new(
		LocalAddr => $ip,
		LocalPort => $port,
		Sockopt	  => [SOCKOPT],
		Proto	  => "udp",
		Type	  => SOCK_DGRAM
		)
			or die "can't setup UDP socket: $!";

	logmsg "UDP server [$ip] port $port" if DEBUG;
	return $socket;
}

sub UDP_server {
	my ( $self, $ip, $port, $timeout ) = @_;
	my $socket = UDP_socket( $ip, $port );
	my $select = IO::Select->new($socket);

	my $expired;
	local $SIG{ALRM} = sub { $expired++ };
	local $SIG{TERM} = sub { $expired++ };
	alarm $timeout;
	until ($expired) {
		local $! = 0;
		scalar( my @ready = $select->can_read(2) ) or do {
			redo if $!{EINTR};	## retry if aborted by signal
			last if $!;
		};

		foreach my $client (@ready) {
			my $buffer = read_udp( $client, $self->{Verbose} );
			spawn( sub { $self->UDP_connection( $client, $buffer ) } );
		}
		sleep(0) if MSWin;
	}
	return;
}


#------------------------------------------------------------------------------
# Process mechanics.
#------------------------------------------------------------------------------

sub spawn {
	my $coderef = shift;
	unless ( defined( my $pid = fork() ) ) {
		die "cannot fork: $!";
	} elsif ($pid) {
		logmsg "begat $pid" if DEBUG;
		return $pid;		## parent
	}

	# else ...
	local $SIG{TERM} = sub { };
	local $SIG{CHLD} = \&reaper;
	$coderef->();			## child
	exit;
}

sub reaper {
	local ( $!, $? );		## protect error and exit status
	$SIG{CHLD} = \&reaper;		## no critic	sysV semantics
	while ( abs( my $pid = waitpid( -1, POSIX ? WNOHANG : 0 ) ) > 1 ) {
		logmsg "reaped $pid" if DEBUG;
	}
	return;
}


our @pid;
my $pid = $$;

sub start_server {
	my ( $self, $timeout ) = @_;
	$timeout ||= 600;
	croak 'Attempt to start ', ref($self), ' in a subprocess' unless $$ == $pid;

	foreach my $ip ( @{$self->{LocalAddr}} ) {
		my $port = $self->{LocalPort};
		push @pid, spawn sub { $self->TCP_server( $ip, $port, $timeout ) };
		push @pid, spawn sub { $self->UDP_server( $ip, $port, $timeout ) };
	}
	return;
}

sub stop_server {
	logmsg "killing @pid" if DEBUG;
	kill 'TERM', @pid;
	return;
}

END {
	local ( $!, $? );		## protect error and exit status
	while ( abs( my $pid = waitpid( -1, 0 ) ) > 1 ) {
		logmsg "reaped $pid" if DEBUG;
	}
	logmsg "terminated" if DEBUG;
}


#------------------------------------------------------------------------------
# main_loop - Start nameserver loop.
#------------------------------------------------------------------------------

sub main_loop {				## historical
	carp 'deprecated method; prefer start_server()';
	&start_server;
	exit;
}


#------------------------------------------------------------------------------
# loop_once - Single-transaction nameserver
#------------------------------------------------------------------------------

my ( @TCP, @UDP );

sub loop_once {				## historical
	my ( $self, @timeout ) = @_;
	unless (@UDP) {
		foreach my $ip ( @{$self->{LocalAddr}} ) {
			push @TCP, TCP_socket( $ip, $self->{LocalPort} );
			push @UDP, UDP_socket( $ip, $self->{LocalPort} );
		}
	}
	my $select = IO::Select->new( @TCP, @UDP );
	my %listen = map { ( $_, 1 ) } @TCP;
	while ( scalar( my @ready = $select->can_read(@timeout) ) ) {
		my ($socket) = @ready;
		if ( $socket->socktype() == SOCK_DGRAM ) {
			my $buffer = read_udp( $socket, $self->{Verbose} );
			$self->UDP_connection( $socket, $buffer );
			last;
		} else {
			if ( $listen{$socket} ) {
				$select->add( $socket->accept );
				next;
			}
			my $buffer = read_tcp( $socket, $self->{Verbose} );
			$self->TCP_connection( $socket, $buffer ) if $buffer;
			close($socket);
			last;
		}
	}
}


1;
__END__


=head1 METHODS

=head2 new

    $nameserver = Net::DNS::Nameserver->new(
	LocalAddr	=> ['::1', '127.0.0.1'],
	LocalPort	=> 15353,
	ZoneFile	=> "filename"
	);

    $nameserver = Net::DNS::Nameserver->new(
	LocalAddr	=> '10.1.2.3',
	LocalPort	=> 15353,
	ReplyHandler	=> \&reply_handler,
	Verbose		=> 1,
	Truncate	=> 0
    );

Instantiates a Net::DNS::Nameserver object.
An exception is raised if the object could not be created.

Each instance is configured using the following optional arguments:

    LocalAddr		IP address on which to listen	Defaults to loopback address
    LocalPort		Port on which to listen
    ZoneFile		Name of file containing RRs
			accessed using the internal
			reply-handling subroutine
    ReplyHandler	Reference to customised
			reply-handling subroutine
    NotifyHandler	Reference to reply-handling
			subroutine for queries with
			opcode NOTIFY (RFC1996)
    UpdateHandler	Reference to reply-handling
			subroutine for queries with
			opcode UPDATE (RFC2136)
    Verbose		Report internal activity	Defaults to 0 (off)
    Truncate		Truncates UDP packets that
			are too big for the reply	Defaults to 1 (on)

The LocalAddr attribute may alternatively be specified as an array
of IP addresses to listen to.

The ReplyHandler subroutine is passed the query name, query class,
query type, peerhost, query record, and connection descriptor.
It must either return the response code and references to the answer,
authority, and additional sections of the response, or undef to leave
the query unanswered.  Common response codes are:

    NOERROR	No error
    FORMERR	Format error
    SERVFAIL	Server failure
    NXDOMAIN	Non-existent domain (name doesn't exist)
    NOTIMP	Not implemented
    REFUSED	Query refused

For advanced usage it may also contain a headermask containing an
hashref with the settings for the C<aa>, C<ra>, and C<ad>
header bits. The argument is of the form:
	{ad => 1, aa => 0, ra => 1}

EDNS options may be specified in a similar manner using the optionmask:
	{$optioncode => $value, $optionname => $value}

See RFC1035 and IANA DNS parameters file for more information:


The nameserver will listen for both UDP and TCP connections.  On linux
and other Unix-like systems, unprivileged users are denied access to
ports below 1024.

UDP reply truncation functionality was introduced in Net::DNS 0.66.
The size limit is determined by the EDNS0 size advertised in the query,
otherwise 512 is used.
If you want to do packet truncation yourself you should set Truncate=>0
and truncate the reply packet in the code of the ReplyHandler.


=head2 start_server

    $ns->start_server( <TIMEOUT_IN_SECONDS> );

Starts a server process for each of the specified UDP and TCP sockets
which continuously responds to user connections.

The timeout parameter specifies the time the server is to remain active.
If called with no parameter a default timeout of 10 minutes is applied.


=head2 stop_server

    $ns->stop_server();

Terminates all server processes in an orderly fashion.


=head1 EXAMPLES

=head2 Example 1: Test script with embedded nameserver

The following example is a self-contained test script which queries DNS
zonefile data served by an embedded Net::DNS::Nameserver instance.

    use strict;
    use warnings;
    use Test::More;

    plan skip_all => 'Net::DNS::Nameserver not available'
		unless eval { require Net::DNS::Nameserver }
		and Net::DNS::Nameserver->can('start_server');
    plan tests => 2;

    my $resolver = Net::DNS::Resolver->new(
	nameserver => ['::1', '127.0.0.1'],
	port	   => 15353
	);
 
    my $ns = Net::DNS::Nameserver->new(
	LocalAddr => [$resolver->nameserver],
	LocalPort => $resolver->port,
	Verbose	  => 0,
	ZoneFile  => \*DATA
	)
		|| die "couldn't create nameserver object";

    $ns->start_server(10);

    my $reply = $resolver->send(qw(example.com SOA));
    is( ref($reply), 'Net::DNS::Packet', 'received reply packet' );
    my ($rr) = $reply->answer;
    is( $rr->type, 'SOA', 'answer contains SOA record' );

    $ns->stop_server();

    exit;

    __DATA__
    $ORIGIN example.com.
    @	IN SOA	mname rname 2023 2h 1h 2w 1h
    www	IN A	93.184.216.34


=head2 Example 2: Free-standing customised DNS nameserver

The following example will listen on port 15353 and respond to all queries
for A records with the IP address 10.1.2.3.  All other queries will be
answered with NXDOMAIN.	 Authority and additional sections are left empty.
The $peerhost variable catches the IP address of the peer host, so that
additional filtering on a per-host basis may be applied.

    use strict;
    use warnings;
    use Net::DNS::Nameserver;

    sub reply_handler {
	my ( $qname, $qclass, $qtype, $peerhost, $query, $conn ) = @_;
	my ( $rcode, @ans, @auth, @add );

	print "Received query from $peerhost to " . $conn->{sockhost} . "\n";
	$query->print;

	if ( $qtype eq "A" && $qname eq "foo.example.com" ) {
		my ( $ttl, $rdata ) = ( 3600, "10.1.2.3" );
		my $rr = Net::DNS::RR->new("$qname $ttl $qclass $qtype $rdata");
		push @ans, $rr;
		$rcode = "NOERROR";
	} elsif ( $qname eq "foo.example.com" ) {
		$rcode = "NOERROR";

	} else {
		$rcode = "NXDOMAIN";
	}

	# mark the answer as authoritative (by setting the 'aa' flag)
	my $headermask = {aa => 1};

	# specify EDNS options	{ option => value }
	my $optionmask = {};

	return ( $rcode, \@ans, \@auth, \@add, $headermask, $optionmask );
    }

    my $ns = Net::DNS::Nameserver->new(
	LocalPort    => 15353,
	ReplyHandler => \&reply_handler,
	Verbose	     => 1
	) or die "couldn't create nameserver object";

    $ns->start_server(60);

    exit;	# leaving nameserver processes running


=head1 BUGS

Limitations in perl make it impossible to guarantee that replies to UDP
queries from Net::DNS::Nameserver are sent from the IP-address to which
the query was directed, the source address being chosen by the operating
system based upon its notion of "closest address". This limitation is
mitigated by creating a separate set of sockets and server subprocesses
bound to each IP address.


=head1 COPYRIGHT

Copyright (c)2000 Michael Fuhr.

Portions Copyright (c)2002-2004 Chris Reinhardt.

Portions Copyright (c)2005 Robert Martin-Legene.

Portions Copyright (c)2005-2009 O.M.Kolkman, RIPE NCC.

Portions Copyright (c)2017-2024 R.W.Franks.

All rights reserved.


=head1 LICENSE

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose and without fee is hereby granted, provided
that the original copyright notices appear in all copies and that both
copyright notice and this permission notice appear in supporting
documentation, and that the name of the author not be used in advertising
or publicity pertaining to distribution of the software without specific
prior written permission.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.


=head1 SEE ALSO

L<perl> L<Net::DNS> L<Net::DNS::Resolver> L<Net::DNS::Packet>
L<Net::DNS::Update> L<Net::DNS::Header> L<Net::DNS::Question>
L<Net::DNS::RR>

L<RFC1035|https://tools.ietf.org/html/rfc1035>

L<IANA DNS parameters|http://www.iana.org/assignments/dns-parameters>

=cut

__END__

