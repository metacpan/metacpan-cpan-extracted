package Net::DNS::Resolver::Base;

#
# $Id: Base.pm 1608 2017-12-07 10:10:38Z willem $
#
our $VERSION = (qw$LastChangedRevision: 1608 $)[1];


#
#  Implementation notes wrt IPv6 support when using perl before 5.20.0.
#
#  In general we try to be gracious to those stacks that do not have IPv6 support.
#  The socket code is conditionally compiled depending upon the availability of
#  IO::Socket::IP or the deprecated IO::Socket::INET6 package.
#
#  We have chosen not to use mapped IPv4 addresses, there seem to be issues
#  with this; as a result we use separate sockets for each family type.
#
#  inet_pton is not available on WIN32, so we only use the getaddrinfo
#  call to translate IP addresses to socketaddress.
#
#  The configuration options force_v4, force_v6, prefer_v4 and prefer_v6
#  are provided to control IPv6 behaviour for test purposes.
#
# Olaf Kolkman, RIPE NCC, December 2003.
# [Revised March 2016]


use constant USE_SOCKET_IP => defined eval 'use IO::Socket::IP 0.32; 1;';

use constant USE_SOCKET_INET => defined eval 'require IO::Socket::INET';

use constant USE_SOCKET_INET6 => defined eval 'require IO::Socket::INET6';

use constant IPv4 => USE_SOCKET_IP || USE_SOCKET_INET;
use constant IPv6 => USE_SOCKET_IP || USE_SOCKET_INET6;


# If SOCKSified Perl, use TCP instead of UDP and keep the socket open.
use constant SOCKS => scalar eval 'require Config; $Config::Config{usesocks}';


# Allow taint tests to be optimised away when appropriate.
use constant UNCND => $] < 5.008;	## eval '${^TAINT}' breaks old compilers
use constant TAINT => UNCND || eval '${^TAINT}';
use constant TESTS => TAINT && defined eval 'require Scalar::Util';


use strict;
use warnings;
use integer;
use Carp;
use IO::Select;
use IO::Socket;

use Net::DNS::RR;
use Net::DNS::Packet;

use constant PACKETSZ => 512;


#
# Set up a closure to be our class data.
#
{
	my $defaults = bless {
		nameservers	=> [qw(::1 127.0.0.1)],
		nameserver4	=> ['127.0.0.1'],
		nameserver6	=> ['::1'],
		port		=> 53,
		srcaddr4	=> '0.0.0.0',
		srcaddr6	=> '::',
		srcport		=> 0,
		searchlist	=> [],
		retrans		=> 5,
		retry		=> 4,
		usevc		=> ( SOCKS ? 1 : 0 ),
		igntc		=> 0,
		recurse		=> 1,
		defnames	=> 1,
		dnsrch		=> 1,
		ndots		=> 1,
		debug		=> 0,
		tcp_timeout	=> 120,
		udp_timeout	=> 30,
		persistent_tcp	=> ( SOCKS ? 1 : 0 ),
		persistent_udp	=> 0,
		dnssec		=> 0,
		adflag		=> 0,	# see RFC6840, 5.7
		cdflag		=> 0,	# see RFC6840, 5.9
		udppacketsize	=> 0,	# value bounded below by PACKETSZ
		force_v4	=> ( IPv6 ? 0 : 1 ),
		force_v6	=> 0,	# only relevant if IPv6 is supported
		prefer_v4	=> 0,
		prefer_v6	=> 0,
		},
			__PACKAGE__;


	sub _defaults { return $defaults; }
}


# These are the attributes that the user may specify in the new() constructor.
my %public_attr = (
	map( ( $_ => $_ ), keys %{&_defaults}, qw(domain nameserver srcaddr) ),
	map( ( $_ => 0 ), qw(nameserver4 nameserver6 srcaddr4 srcaddr6) ),
	);


my $initial;

sub new {
	my ( $class, %args ) = @_;

	my $self;
	my $base = $class->_defaults;
	my $init = $initial;
	$initial ||= [%$base];
	if ( my $file = $args{config_file} ) {
		my $conf = bless {@$initial}, $class;
		$conf->_read_config_file($file);		# user specified config
		$self = bless {_untaint(%$conf)}, $class;
		%$base = %$self unless $init;			# define default configuration

	} elsif ($init) {
		$self = bless {%$base}, $class;

	} else {
		$class->_init();				# define default configuration
		$self = bless {%$base}, $class;
	}

	while ( my ( $attr, $value ) = each %args ) {
		next unless $public_attr{$attr};
		my $ref = ref($value);
		croak "usage: $class->new( $attr => [...] )"
				if $ref && ( $ref ne 'ARRAY' );
		$self->$attr( $ref ? @$value : $value );
	}

	return $self;
}


my %resolv_conf = (			## map traditional resolv.conf option names
	attempts => 'retry',
	inet6	 => 'prefer_v6',
	timeout	 => 'retrans',
	);

my %res_option = (			## any resolver attribute plus those listed above
	%public_attr,
	%resolv_conf,
	);

sub _option {
	my ( $self, $name, @value ) = @_;
	my $attribute = $res_option{lc $name} || return;
	push @value, 1 unless scalar @value;
	$self->$attribute(@value);
}


sub _untaint {
	return TAINT ? map ref($_) ? [_untaint(@$_)] : do { /^(.*)$/; $1 }, @_ : @_;
}


sub _read_env {				## read resolver config environment variables
	my $self = shift;

	$self->nameservers( map split, $ENV{RES_NAMESERVERS} ) if defined $ENV{RES_NAMESERVERS};

	$self->domain( $ENV{LOCALDOMAIN} ) if defined $ENV{LOCALDOMAIN};

	$self->searchlist( map split, $ENV{RES_SEARCHLIST} ) if defined $ENV{RES_SEARCHLIST};

	foreach ( map split, $ENV{RES_OPTIONS} || '' ) {
		$self->_option( split m/:/ );
	}
}


sub _read_config_file {			## read resolver config file
	my $self = shift;
	my $file = shift;

	local *FILE;
	open( FILE, $file ) or croak "$file: $!";

	my @nameserver;
	my @searchlist;

	local $_;
	while (<FILE>) {
		s/[;#].*$//;					# strip comments

		/^nameserver/ && do {
			my ( $keyword, @ip ) = grep defined, split;
			push @nameserver, @ip;
			next;
		};

		/^domain/ && do {
			my ( $keyword, $domain ) = grep defined, split;
			$self->domain($domain);
			next;
		};

		/^search/ && do {
			my ( $keyword, @domain ) = grep defined, split;
			push @searchlist, @domain;
			next;
		};

		/^option/ && do {
			my ( $keyword, @option ) = grep defined, split;
			foreach (@option) {
				$self->_option( split m/:/ );
			}
		};
	}

	close(FILE);

	$self->nameservers(@nameserver) if @nameserver;
	$self->searchlist(@searchlist)	if @searchlist;
}


sub string {
	my $self = shift;
	$self = $self->_defaults unless ref($self);

	my @nslist = $self->nameservers();
	my ($force)  = ( grep( $self->{$_}, qw(force_v6 force_v4) ),   'force_v4' );
	my ($prefer) = ( grep( $self->{$_}, qw(prefer_v6 prefer_v4) ), 'prefer_v4' );
	return <<END;
;; RESOLVER state:
;; nameservers	= @nslist
;; searchlist	= @{$self->{searchlist}}
;; defnames	= $self->{defnames}	dnsrch		= $self->{dnsrch}
;; igntc	= $self->{igntc}	usevc		= $self->{usevc}
;; recurse	= $self->{recurse}	port		= $self->{port}
;; retrans	= $self->{retrans}	retry		= $self->{retry}
;; tcp_timeout	= $self->{tcp_timeout}	persistent_tcp	= $self->{persistent_tcp}
;; udp_timeout	= $self->{udp_timeout}	persistent_udp	= $self->{persistent_udp}
;; ${prefer}	= $self->{$prefer}	${force}	= $self->{$force}
;; debug	= $self->{debug}	ndots		= $self->{ndots}
END
}


sub print { print &string; }


sub domain {
	my $self   = shift;
	my ($head) = $self->searchlist(@_);
	my @list   = grep defined, $head;
	wantarray ? @list : "@list";
}

sub searchlist {
	my $self = shift;
	$self = $self->_defaults unless ref($self);

	return $self->{searchlist} = [@_] unless defined wantarray;
	$self->{searchlist} = [@_] if scalar @_;
	my @searchlist = @{$self->{searchlist}};
}


sub nameservers {
	my $self = shift;
	$self = $self->_defaults unless ref($self);

	my @ip;
	foreach my $ns ( grep defined, @_ ) {
		if ( _ipv4($ns) || _ipv6($ns) ) {
			push @ip, $ns;

		} else {
			my $defres = ref($self)->new( debug => $self->{debug} );
			$defres->{persistent} = $self->{persistent};

			my $names  = {};
			my $packet = $defres->search( $ns, 'A' );
			my @iplist = _cname_addr( $packet, $names );

			if (IPv6) {
				$packet = $defres->search( $ns, 'AAAA' );
				push @iplist, _cname_addr( $packet, $names );
			}

			my %unique = map( ( $_ => $_ ), @iplist );

			my @address = values(%unique);		# tainted
			carp "unresolvable name: $ns" unless scalar @address;

			push @ip, @address;
		}
	}

	if ( scalar(@_) || !defined(wantarray) ) {
		my @ipv4 = grep _ipv4($_), @ip;
		my @ipv6 = grep _ipv6($_), @ip;
		$self->{nameservers} = \@ip;
		$self->{nameserver4} = \@ipv4;
		$self->{nameserver6} = \@ipv6;
	}

	my @ns4 = $self->{force_v6} ? () : @{$self->{nameserver4}};
	my @ns6 = $self->{force_v4} ? () : @{$self->{nameserver6}};
	my @nameservers = @{$self->{nameservers}};
	@nameservers = ( @ns4, @ns6 ) if $self->{prefer_v4} || !scalar(@ns6);
	@nameservers = ( @ns6, @ns4 ) if $self->{prefer_v6} || !scalar(@ns4);

	return @nameservers if scalar @nameservers;

	my $error = 'no nameservers';
	$error = 'IPv4 transport disabled' if scalar(@ns4) < scalar @{$self->{nameserver4}};
	$error = 'IPv6 transport disabled' if scalar(@ns6) < scalar @{$self->{nameserver6}};
	$self->errorstring($error);
	return @nameservers;
}

sub nameserver { &nameservers; }				# uncoverable pod

sub _cname_addr {

	# TODO 20081217
	# This code does not follow CNAME chains, it only looks inside the packet.
	# Out of bailiwick will fail.
	my @null;
	my $packet = shift || return @null;
	my $names = shift;

	map $names->{lc( $_->qname )}++, $packet->question;
	map $names->{lc( $_->cname )}++, grep $_->can('cname'), $packet->answer;

	my @addr = grep $_->can('address'), $packet->answer;
	map $_->address, grep $names->{lc( $_->name )}, @addr;
}


sub answerfrom {
	my $self = shift;
	$self->{answerfrom} = shift if scalar @_;
	return $self->{answerfrom};
}

sub _reset_errorstring {
	shift->{errorstring} = '';
}

sub errorstring {
	my $self = shift;
	my $text = shift || return $self->{errorstring};
	$self->_diag( 'errorstring:', $text );
	return $self->{errorstring} = $text;
}


sub query {
	my $self = shift;
	my $name = shift || '.';

	my @sfix;

	if ( $self->{defnames} && ( ( $name =~ tr/././ ) < $self->{ndots} ) ) {
		@sfix = $self->domain unless $name =~ m/:|\.\d*$/;
	}

	my $fqdn = join '.', $name, @sfix;
	$self->_diag( 'query(', $fqdn, @_, ')' );
	my $packet = $self->send( $fqdn, @_ ) || return;
	return $packet->header->ancount ? $packet : undef;
}


sub search {
	my $self = shift;

	return $self->query(@_) unless $self->{dnsrch};

	my $name = shift || '.';

	my @sfix = ( $name =~ m/:|\.\d*$/ ) ? () : @{$self->{searchlist}};
	my ( $domain, @etc ) = ( $name =~ tr/././ ) < $self->{ndots} ? (@sfix) : ( undef, @sfix );

	foreach my $suffix ( $domain, @etc ) {
		my $fqname = $suffix ? join( '.', $name, $suffix ) : $name;
		$self->_diag( 'search(', $fqname, @_, ')' );
		my $packet = $self->send( $fqname, @_ ) || next;
		return $packet->header->ancount ? $packet : next;
	}

	return undef;
}


sub send {
	my $self	= shift;
	my $packet	= $self->_make_query_packet(@_);
	my $packet_data = $packet->data;

	return $self->_send_tcp( $packet, $packet_data )
			if $self->{usevc} || length $packet_data > $self->_packetsz;

	my $ans = $self->_send_udp( $packet, $packet_data ) || return;

	return $ans if $self->{igntc};
	return $ans unless $ans->header->tc;

	$self->_diag('packet truncated: retrying using TCP');
	$self->_send_tcp( $packet, $packet_data );
}


sub _send_tcp {
	my ( $self, $query, $query_data ) = @_;

	$self->_reset_errorstring;

	my $tcp_packet = pack 'n a*', length($query_data), $query_data;
	my @ns = $self->nameservers();
	my $lastanswer;
	my $timeout = $self->{tcp_timeout};

	foreach my $ip (@ns) {
		my $socket = $self->_create_tcp_socket($ip) || next;
		my $select = IO::Select->new($socket);

		$self->_diag( 'tcp send', "[$ip]" );

		$socket->send($tcp_packet);
		$self->errorstring($!);

		next unless $select->can_read($timeout);	# uncoverable branch

		my $buffer = _read_tcp($socket);
		$self->answerfrom($ip);
		$self->_diag( 'answer from', "[$ip]", length($buffer), 'bytes' );

		my $reply = Net::DNS::Packet->decode( \$buffer, $self->{debug} );
		$self->errorstring($@);
		next unless $self->_accept_reply( $reply, $query );
		$reply->answerfrom($ip);

		if ( $self->{tsig_rr} && !$reply->verify($query) ) {
			$self->errorstring( $reply->verifyerr );
			next;
		}

		$lastanswer = $reply;

		my $rcode = $reply->header->rcode;
		$self->errorstring($rcode);			# historical quirk
		return $reply if $rcode eq 'NOERROR';
		return $reply if $rcode eq 'NXDOMAIN';
	}

	$self->{errorstring} = $lastanswer->header->rcode if $lastanswer;
	$self->errorstring('query timed out') unless $self->{errorstring};
	return $lastanswer;
}


sub _send_udp {
	my ( $self, $query, $query_data ) = @_;

	$self->_reset_errorstring;

	my @ns	    = $self->nameservers;
	my $port    = $self->{port};
	my $retrans = $self->{retrans} || 1;
	my $retry   = $self->{retry} || 1;
	my $servers = scalar(@ns);
	my $timeout = $servers ? do { no integer; $retrans / $servers } : 0;
	my $lastanswer;

	# Perform each round of retries.
RETRY: for ( 1 .. $retry ) {					# assumed to be a small number

		# Try each nameserver.
		my $select = IO::Select->new();

NAMESERVER: foreach my $ns (@ns) {

			# state vector replaces corresponding element of @ns array
			unless ( ref $ns ) {
				my $socket = $self->_create_udp_socket($ns) || next;
				my $dst_sockaddr = $self->_create_dst_sockaddr( $ns, $port );
				$ns = [$socket, $ns, $dst_sockaddr];
			}

			my ( $socket, $ip, $dst_sockaddr, $failed ) = @$ns;
			next if $failed;

			$self->_diag( 'udp send', "[$ip]:$port" );

			$select->add($socket);
			$socket->send( $query_data, 0, $dst_sockaddr );
			$self->errorstring( $$ns[3] = $! );

			# handle failure to detect taint inside socket->send()
			die 'Insecure dependency while running with -T switch'
					if TESTS && Scalar::Util::tainted($dst_sockaddr);

			my $reply;
			while ( my ($socket) = $select->can_read($timeout) ) {
				my $peer = $socket->peerhost;
				$self->answerfrom($peer);

				my $buffer = _read_udp( $socket, $self->_packetsz );
				$self->_diag( "answer from [$peer]", length($buffer), 'bytes' );

				my $packet = Net::DNS::Packet->decode( \$buffer, $self->{debug} );
				$self->errorstring($@);
				next unless $self->_accept_reply( $packet, $query );
				$reply = $packet;
				$reply->answerfrom($peer);
				last;
			}					#SELECT LOOP

			next unless $reply;

			if ( $self->{tsig_rr} && !$reply->verify($query) ) {
				$self->errorstring( $$ns[3] = $reply->verifyerr );
				next;
			}

			$lastanswer = $reply;

			my $rcode = $reply->header->rcode;
			$self->errorstring($rcode);		# historical quirk
			return $reply if $rcode eq 'NOERROR';
			return $reply if $rcode eq 'NXDOMAIN';
			$$ns[3] = $rcode;
		}						#NAMESERVER LOOP

		no integer;
		$timeout += $timeout;
	}							#RETRY LOOP

	$self->{errorstring} = $lastanswer->header->rcode if $lastanswer;
	$self->errorstring('query timed out') unless $self->{errorstring};
	return $lastanswer;
}


sub bgsend {
	my $self	= shift;
	my $packet	= $self->_make_query_packet(@_);
	my $packet_data = $packet->data;

	return $self->_bgsend_tcp( $packet, $packet_data )
			if $self->{usevc} || length $packet_data > $self->_packetsz;

	return $self->_bgsend_udp( $packet, $packet_data );
}


sub _bgsend_tcp {
	my ( $self, $packet, $packet_data ) = @_;

	$self->_reset_errorstring;

	my $tcp_packet = pack 'n a*', length($packet_data), $packet_data;

	foreach my $ip ( $self->nameservers ) {
		my $socket = $self->_create_tcp_socket($ip) || next;

		$self->_diag( 'bgsend', "[$ip]" );

		$socket->blocking(0);
		$socket->send($tcp_packet);
		$self->errorstring($!);

		my $expire = time() + $self->{tcp_timeout};
		${*$socket}{net_dns_bg} = [$expire, $packet];
		return $socket;
	}

	return undef;
}


sub _bgsend_udp {
	my ( $self, $packet, $packet_data ) = @_;

	$self->_reset_errorstring;

	my $port = $self->{port};

	foreach my $ip ( $self->nameservers ) {
		my $socket = $self->_create_udp_socket($ip) || next;
		my $dst_sockaddr = $self->_create_dst_sockaddr( $ip, $port );

		$self->_diag( 'bgsend', "[$ip]:$port" );

		$socket->send( $packet_data, 0, $dst_sockaddr );
		$self->errorstring($!);

		# handle failure to detect taint inside $socket->send()
		die 'Insecure dependency while running with -T switch'
				if TESTS && Scalar::Util::tainted($dst_sockaddr);

		my $expire = time() + $self->{udp_timeout};
		${*$socket}{net_dns_bg} = [$expire, $packet];
		return $socket;
	}

	return undef;
}


sub bgbusy {
	my ( $self, $handle ) = @_;
	return unless $handle;

	my $appendix = ${*$handle}{net_dns_bg} ||= [time() + $self->{udp_timeout}];
	my ( $expire, $query, $read ) = @$appendix;
	return if ref($read);

	return time() <= $expire unless IO::Select->new($handle)->can_read(0);

	return if $self->{igntc};
	return unless $handle->socktype() == SOCK_DGRAM;
	return unless $query;					# SpamAssassin 3.4.1 workaround

	my $ans = $self->_bgread($handle);
	$$appendix[2] = [$ans];
	return unless $ans;
	return unless $ans->header->tc;

	$self->_diag('packet truncated: retrying using TCP');
	my $tcp = $self->_bgsend_tcp( $query, $query->data ) || return;
	return defined( $_[1] = $tcp );
}


sub bgisready {				## historical
	!&bgbusy;						# uncoverable pod
}


sub bgread {
	while (&bgbusy) {					# side effect: TCP retry
		IO::Select->new( $_[1] )->can_read(0.02);	# use 3 orders of magnitude less CPU
	}
	&_bgread;
}


sub _bgread {
	my ( $self, $handle ) = @_;
	return unless $handle;

	my $appendix = ${*$handle}{net_dns_bg};
	my ( $expire, $query, $read ) = @$appendix;
	return shift(@$read) if ref($read);

	unless ( IO::Select->new($handle)->can_read(0) ) {
		$self->errorstring('timed out');
		return;
	}

	my $peer = $handle->peerhost;
	$self->answerfrom($peer);

	my $dgram = $handle->socktype() == SOCK_DGRAM;
	my $buffer = $dgram ? _read_udp( $handle, $self->_packetsz ) : _read_tcp($handle);
	$self->_diag( "answer from [$peer]", length($buffer), 'bytes' );

	my $reply = Net::DNS::Packet->decode( \$buffer, $self->{debug} );
	$self->errorstring($@);
	return unless $self->_accept_reply( $reply, $query );
	$reply->answerfrom($peer);

	return $reply unless $self->{tsig_rr} && !$reply->verify($query);
	$self->errorstring( $reply->verifyerr );
	return;
}


sub _accept_reply {
	my ( $self, $reply, $query ) = @_;

	return unless $reply;

	my $header = $reply->header;
	return unless $header->qr;

	return 1 unless $query;					# SpamAssassin 3.4.1 workaround
	return $header->id == $query->header->id;
}


sub axfr {				## zone transfer
	eval {
		my $self = shift;

		# initialise iterator state vector
		my ( $select, $verify, @rr, $soa ) = $self->_axfr_start(@_);

		my $iterator = sub {	## iterate over RRs
			my $rr = shift(@rr);

			if ( ref($rr) eq 'Net::DNS::RR::SOA' ) {
				return $soa = $rr unless $soa;
				$select = undef;
				return if $rr->encode eq $soa->encode;
				croak $self->errorstring('mismatched final SOA');
			}

			return $rr if scalar @rr;

			my $reply;
			( $reply, $verify ) = $self->_axfr_next( $select, $verify );
			@rr = $reply->answer;
			return $rr;
		};

		return $iterator unless wantarray;

		my @zone;		## subvert iterator to assemble entire zone
		while ( my $rr = $iterator->() ) {
			push @zone, $rr, @rr;			# copy RRs en bloc
			@rr = pop(@zone);			# leave last one in @rr
		}
		return @zone;
	};
}


sub axfr_start {			## historical
	my $self = shift;					# uncoverable pod
	defined( $self->{axfr_iter} = $self->axfr(@_) );
}


sub axfr_next {				## historical
	shift->{axfr_iter}->();					# uncoverable pod
}


sub _axfr_start {
	my $self  = shift;
	my $dname = scalar(@_) ? shift : $self->domain;
	my @class = @_;

	my $request = $self->_make_query_packet( $dname, 'AXFR', @class );
	my $content = $request->data;
	my $TCP_msg = pack 'n a*', length($content), $content;

	$self->_diag("axfr_start( $dname @class )");

	my ( $select, $reply, $rcode );
	foreach my $ns ( $self->nameservers ) {
		my $socket = $self->_create_tcp_socket($ns) || next;

		$self->_diag("axfr_start nameserver [$ns]");

		$select = IO::Select->new($socket);
		$socket->send($TCP_msg);
		$self->errorstring($!);

		($reply) = $self->_axfr_next($select);
		last if ( $rcode = $reply->header->rcode ) eq 'NOERROR';
	}

	croak $self->errorstring unless $reply;

	$self->errorstring($rcode);				# historical quirk

	my $verify = $request->sigrr ? $request : undef;
	unless ($verify) {
		croak $self->errorstring unless $rcode eq 'NOERROR';
		return ( $select, $verify, $reply->answer );
	}

	my $verifyok = $reply->verify($verify);
	croak $self->errorstring( $reply->verifyerr ) unless $verifyok;
	croak $self->errorstring unless $rcode eq 'NOERROR';
	return ( $select, $verifyok, $reply->answer );
}


sub _axfr_next {
	my $self   = shift;
	my $select = shift || return;
	my $verify = shift;

	my ($socket) = $select->can_read( $self->{tcp_timeout} );
	croak $self->errorstring('timed out') unless $socket;

	$self->answerfrom( $socket->peerhost );

	my $buffer = _read_tcp($socket);
	$self->_diag( 'received', length($buffer), 'bytes' );

	my $packet = Net::DNS::Packet->new( \$buffer );
	croak $@, $self->errorstring('corrupt packet') if $@;

	return ( $packet, $verify ) unless $verify;

	my $verifyok = $packet->verify($verify);
	croak $self->errorstring( $packet->verifyerr ) unless $verifyok;
	return ( $packet, $verifyok );
}


#
# Usage:  $data = _read_tcp($socket);
#
sub _read_tcp {
	my $socket = shift;

	my ( $s1, $s2 );
	$socket->recv( $s1, 2 );				# one lump
	$socket->recv( $s2, 2 - length $s1 );			# or two?
	my $size = unpack 'n', pack( 'a*a*@2', $s1, $s2 );

	my $buffer = '';
	while ( ( my $read = length $buffer ) < $size ) {

		# During some of my tests recv() returned undef even
		# though there was no error.  Checking the amount
		# of data read appears to work around that problem.

		my $recv_buf;
		$socket->recv( $recv_buf, $size - $read );

		$buffer .= $recv_buf || last;
	}
	return $buffer;
}


#
# Usage:  $data = _read_udp($socket, $length);
#
sub _read_udp {
	my $socket = shift;
	my $buffer = '';
	$socket->recv( $buffer, shift );
	return $buffer;
}


sub _create_tcp_socket {
	my $self = shift;
	my $ip	 = shift;

	my $sock_key = "TCP[$ip]";
	my $socket;

	if ( $socket = $self->{persistent}{$sock_key} ) {
		$self->_diag( 'using persistent socket', $sock_key );
		return $socket if $socket->connected;
		$self->_diag('socket disconnected (trying to connect)');
	}

	my $ip6_addr = IPv6 && _ipv6($ip);

	$socket = IO::Socket::IP->new(
		LocalAddr => $ip6_addr ? $self->{srcaddr6} : $self->{srcaddr4},
		LocalPort => $self->{srcport},
		PeerAddr  => $ip,
		PeerPort  => $self->{port},
		Proto	  => 'tcp',
		Timeout	  => $self->{tcp_timeout},
		)
			if USE_SOCKET_IP;

	unless (USE_SOCKET_IP) {
		$socket = IO::Socket::INET6->new(
			LocalAddr => $self->{srcaddr6},
			LocalPort => $self->{srcport},
			PeerAddr  => $ip,
			PeerPort  => $self->{port},
			Proto	  => 'tcp',
			Timeout	  => $self->{tcp_timeout},
			)
				if USE_SOCKET_INET6 && $ip6_addr;

		$socket = IO::Socket::INET->new(
			LocalAddr => $self->{srcaddr4},
			LocalPort => $self->{srcport} || undef,
			PeerAddr  => $ip,
			PeerPort  => $self->{port},
			Proto	  => 'tcp',
			Timeout	  => $self->{tcp_timeout},
			)
				unless $ip6_addr;
	}

	$self->errorstring("no socket $sock_key $!") unless $socket;
	$self->{persistent}{$sock_key} = $self->{persistent_tcp} ? $socket : undef;
	return $socket;
}


sub _create_udp_socket {
	my $self = shift;
	my $ip	 = shift;

	my $ip6_addr = IPv6 && _ipv6($ip);
	my $sock_key = IPv6 && $ip6_addr ? 'UDP/IPv6' : 'UDP/IPv4';
	my $socket;
	return $socket if $socket = $self->{persistent}{$sock_key};

	$socket = IO::Socket::IP->new(
		LocalAddr => $ip6_addr ? $self->{srcaddr6} : $self->{srcaddr4},
		LocalPort => $self->{srcport},
		Proto	  => 'udp',
		Type	  => SOCK_DGRAM
		)
			if USE_SOCKET_IP;

	unless (USE_SOCKET_IP) {
		$socket = IO::Socket::INET6->new(
			LocalAddr => $self->{srcaddr6},
			LocalPort => $self->{srcport},
			Proto	  => 'udp',
			Type	  => SOCK_DGRAM
			)
				if USE_SOCKET_INET6 && $ip6_addr;

		$socket = IO::Socket::INET->new(
			LocalAddr => $self->{srcaddr4},
			LocalPort => $self->{srcport} || undef,
			Proto	  => 'udp',
			Type	  => SOCK_DGRAM
			)
				unless $ip6_addr;
	}

	$self->errorstring("no socket $sock_key $!") unless $socket;
	$self->{persistent}{$sock_key} = $self->{persistent_udp} ? $socket : undef;
	return $socket;
}


{
	no strict qw(subs);
	my @udp = (
		flags	 => Socket::AI_NUMERICHOST,
		protocol => Socket::IPPROTO_UDP,
		socktype => SOCK_DGRAM
		);

	my $ip4 = USE_SOCKET_IP ? {family => AF_INET,  @udp} : {};
	my $ip6 = USE_SOCKET_IP ? {family => AF_INET6, @udp} : {};

	my $inet6 = USE_SOCKET_INET6 ? [AF_INET6, SOCK_DGRAM, 0, Socket6::AI_NUMERICHOST()] : [];

	sub _create_dst_sockaddr {	## create UDP destination sockaddr structure
		my ( $self, $ip, $port ) = @_;

		unless (USE_SOCKET_IP) {
			return sockaddr_in( $port, inet_aton($ip) ) unless _ipv6($ip);
			return ( Socket6::getaddrinfo( $ip, $port, @$inet6 ) )[3]
					if USE_SOCKET_INET6;
		}

		( grep ref, Socket::getaddrinfo( $ip, $port, _ipv6($ip) ? $ip6 : $ip4 ), {} )[0]->{addr}
				if USE_SOCKET_IP;		# NB: errors raised in socket->send
	}
}


# Lightweight versions of subroutines from Net::IP module, recoded to fix RT#96812

sub _ipv4 {
	for (shift) {
		return if m/[^.0-9]/;				# dots and digits only
		return m/\.\d+\./;				# dots separated by digits
	}
}

sub _ipv6 {
	for (shift) {
		return	 unless m/:.*:/;			# must contain two colons
		return 1 unless m/[^:0-9A-Fa-f]/;		# colons and hexdigits only
		return 1 if m/^[:.0-9A-Fa-f]+\%.+$/;		# RFC4007 scoped address
		return m/^[:0-9A-Fa-f]+:[.0-9]+$/;		# prefix : dotted digits
	}
}


sub _make_query_packet {
	my $self = shift;

	my ($packet) = @_;
	if ( ref($packet) ) {
		my $header = $packet->header;
		$header->rd( $self->{recurse} ) if $header->opcode eq 'QUERY';

	} else {
		$packet = Net::DNS::Packet->new(@_);

		my $header = $packet->header;
		$header->ad( $self->{adflag} );			# RFC6840, 5.7
		$header->cd( $self->{cdflag} );			# RFC6840, 5.9
		$header->do(1) if $self->{dnssec};
		$header->rd( $self->{recurse} );
	}

	$packet->edns->size( $self->{udppacketsize} );		# advertise UDPsize for local stack

	if ( $self->{tsig_rr} ) {
		$packet->sign_tsig( $self->{tsig_rr} ) unless $packet->sigrr;
	}

	return $packet;
}


sub dnssec {
	my $self = shift;

	return $self->{dnssec} unless scalar @_;

	# increase default udppacket size if flag set
	$self->udppacketsize(2048) if $self->{dnssec} = shift;

	return $self->{dnssec};
}


sub force_v6 {
	my $self = shift;
	my $value = scalar(@_) ? shift() : $self->{force_v6};
	$self->{force_v6} = $value ? do { $self->{force_v4} = 0; 1 } : 0;
}

sub force_v4 {
	my $self = shift;
	my $value = scalar(@_) ? shift() : $self->{force_v4};
	$self->{force_v4} = $value ? do { $self->{force_v6} = 0; 1 } : 0;
}

sub prefer_v6 {
	my $self = shift;
	my $value = scalar(@_) ? shift() : $self->{prefer_v6};
	$self->{prefer_v6} = $value ? do { $self->{prefer_v4} = 0; 1 } : 0;
}

sub prefer_v4 {
	my $self = shift;
	my $value = scalar(@_) ? shift() : $self->{prefer_v4};
	$self->{prefer_v4} = $value ? do { $self->{prefer_v6} = 0; 1 } : 0;
}


sub srcaddr {
	my $self = shift;
	for (@_) {
		my $hashkey = _ipv6($_) ? 'srcaddr6' : 'srcaddr4';
		$self->{$hashkey} = $_;
	}
	return shift;
}


sub tsig {
	my $self = shift;
	$self->{tsig_rr} = eval {
		local $SIG{__DIE__};
		require Net::DNS::RR::TSIG;
		Net::DNS::RR::TSIG->create(@_);
	};
	croak "${@}unable to create TSIG record" if $@;
}


# if ($self->{udppacketsize} > PACKETSZ
# then we use EDNS and $self->{udppacketsize}
# should be taken as the maximum packet_data length
sub _packetsz {
	my $udpsize = shift->{udppacketsize} || 0;
	return $udpsize > PACKETSZ ? $udpsize : PACKETSZ;
}

sub udppacketsize {
	my $self = shift;
	$self->{udppacketsize} = shift if scalar @_;
	return $self->_packetsz;
}


#
# Keep this method around. Folk depend on it although it is neither documented nor exported.
#
my $warned;

sub make_query_packet {			## historical
	unless ( $warned++ ) {					# uncoverable pod
		local $SIG{__WARN__};
		carp 'deprecated method; see RT#37104';
	}
	&_make_query_packet;
}


sub _diag {				## debug output
	my $self = shift;
	print "\n;; @_\n" if $self->{debug};
}


our $AUTOLOAD;

sub DESTROY { }				## Avoid tickling AUTOLOAD (in cleanup)

sub AUTOLOAD {				## Default method
	my ($self) = @_;

	my $name = $AUTOLOAD;
	$name =~ s/.*://;
	croak "$name: no such method" unless $public_attr{$name};

	no strict q/refs/;
	*{$AUTOLOAD} = sub {
		my $self = shift;
		$self = $self->_defaults unless ref($self);
		$self->{$name} = shift || 0 if scalar @_;
		return $self->{$name};
	};

	goto &{$AUTOLOAD};
}


1;

__END__


=head1 NAME

Net::DNS::Resolver::Base - DNS resolver base class

=head1 SYNOPSIS

    use base qw(Net::DNS::Resolver::Base);

=head1 DESCRIPTION

This class is the common base class for the different platform
sub-classes of L<Net::DNS::Resolver>.

No user serviceable parts inside, see L<Net::DNS::Resolver>
for all your resolving needs.


=head1 METHODS

=head2 new, domain, searchlist, nameservers, print, string, errorstring,

=head2 search, query, send, bgsend, bgbusy, bgread, axfr, answerfrom,

=head2 force_v4, force_v6, prefer_v4, prefer_v6,

=head2 dnssec, srcaddr, tsig, udppacketsize

See L<Net::DNS::Resolver>.


=head1 COPYRIGHT

Copyright (c)2003,2004 Chris Reinhardt.

Portions Copyright (c)2005 Olaf Kolkman.

Portions Copyright (c)2014-2017 Dick Franks.

All rights reserved.


=head1 LICENSE

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose and without fee is hereby granted, provided
that the above copyright notice appear in all copies and that both that
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

L<perl>, L<Net::DNS>, L<Net::DNS::Resolver>

=cut

