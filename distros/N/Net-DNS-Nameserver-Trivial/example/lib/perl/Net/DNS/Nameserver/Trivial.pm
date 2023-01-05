package Net::DNS::Nameserver::Trivial;

use vars qw($VERSION);

$VERSION = 0.302;
#---------------

use strict;
use warnings;
#-----------------------------------------------------------------------
use Net::IP::XS;
use Net::DNS;
use Net::DNS::Nameserver;

use Log::Tiny;
use List::MoreUtils qw(uniq);
use Cache::FastMmap;
use Regexp::IPv6 qw($IPv6_re);
#=======================================================================
use constant A		=> q/A/;
use constant A6		=> q/A6/;
use constant IN		=> q/IN/;
use constant NS		=> q/NS/;
use constant MX		=> q/MX/;
use constant TTL	=> 86400; 
use constant PTR	=> q/PTR/;
use constant SOA	=> q/SOA/;
use constant AAAA	=> q/AAAA/;
use constant CNAME	=> q/CNAME/;
use constant AXFR	=> q/AXFR/;
#=======================================================================
sub new {
	my ($class, $config, $params) = @_;
	
	my $self = bless { }, $class;
	
	# Server +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	$self->{ nameserver } = Net::DNS::Nameserver->new(
		LocalAddr		=> $params->{ SERVER }->{ address 	},
		LocalPort		=> $params->{ SERVER }->{ port 	 	},
		Verbose			=> $params->{ SERVER }->{ verbose 	},
		Truncate        => $params->{ SERVER }->{ truncate 	},
		IdleTimeout  	=> $params->{ SERVER }->{ timeout 	},
		ReplyHandler	=> sub { $self->_handler( @_ )   	},
	) || die "Couldn't create nameserver object\n";
	
	# Resolver +++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	$self->{ resolv } =	Net::DNS::Resolver->new(
							tcp_timeout		=> $params->{ RESOLVER }->{ tcp_timeout 	},
							udp_timeout		=> $params->{ RESOLVER }->{ udp_timeout 	},
						);
						
	# Cache ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	$self->{ cache }  =	Cache::FastMmap->new(
							cache_size      => $params->{ CACHE }->{ size 	},
							expire_time     => $params->{ CACHE }->{ expire },
							init_file		=> $params->{ CACHE }->{ init 	},
							unlink_on_exit  => $params->{ CACHE }->{ unlink },
							share_file      => $params->{ CACHE }->{ file 	},
							compress        => 1,
							catch_deadlocks	=> 1,
							raw_values      => 0,
						);					
						
	# Log ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	my @log_level = qw( FAKE DEBUG INFO WARN ERROR FATAL );
	shift @log_level while @log_level and $log_level[ 0 ] ne $params->{ LOG }->{ level };

	$self->{ log } = Log::Tiny->new( $params->{ LOG }->{ file } ) or die 'Could not log: ' . Log::Tiny->errstr . "\n";
	$self->{ log }->log_only( @log_level );

	#select((select(Log::Tiny::LOG), $| = 1)[0]); # turn off buffering of LOG
	#select((select(Log::Tiny::LOG), $| = 1)[0]); # turn off buffering of LOG
	
	# Flags ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	$self->{ _ra } = $params->{ FLAGS }->{ ra };
	
	# Serial +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	$self->{ serial } = $config->{ _ }->{ serial } || $self->_serial;
	
	# Slaves +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	$self->{ SL } = { map { $_ => 1 } split( /\s*,\s*/o, $config->{ _ }->{ slaves } ) };
	
	# Nameservers for domain +++++++++++++++++++++++++++++++++++++++++++
	foreach my $name ( keys %{ $config->{ NS } } ){
		$self->{ NS }->{ $name } = [ uniq split(/\s*,\s*/, $config->{ NS }->{ $name } ) ];
	}
	# $self->{ NS } = {
	#	'example.com'	=> [ qw( ns.example.com ) ],
	# };
	
	# A ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	foreach my $name ( keys %{ $config->{ A } } ){
		$self->{ A }->{ $name } = [ grep { /^\d+\.\d+\.\d+\.\d+$/o } uniq split( /\s*,\s*/, $config->{ A }->{ $name } ) ];
	}
	# $self->{ A } = {
	#	'ns1.example.com' => [ qw( 10.3.57.1 ) ],
	# };
	
	# AAAA +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	foreach my $name (keys %{ $config->{ AAAA } } ){
		$self->{ AAAA }->{ $name } = [ grep { /^$IPv6_re$/o } uniq split( /\s*,\s*/, $config->{ AAAA }->{ $name } ) ];
	}
	# $self->{ AAAA } = {
	#	'srv.example.com'	=> [qw( fe80::20c:29ff:fee2:ed62 )],
	#	'mail.example.com'	=> [qw( fe80::21d:7dff:fed5:b3d6 )],
	# };
	
	# CNAME ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	foreach my $name ( keys %{ $config->{ CNAME } } ){
		$self->{ CNAME }->{ $_ } = $name for uniq split( /\s*,\s*/, $config->{ CNAME }->{ $name } );
	}
	# $self->{ CNAME } = {
	#	'ns0.example.com'	=> 'srv.example.com',
	# };
	
	# MX +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	foreach my $name ( keys %{ $config->{ MX } } ){
		$self->{ MX }->{ $name } = [ uniq split(/\s*,\s*/, $config->{ MX }->{ $name } ) ];
	}
	# $self->{ MX } = {
	#	'example.com'	=> [ qw( mail.example.com ) ],
	# };
	
	# SOA ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	foreach my $name ( keys %{ $config->{ SOA } } ){
		$self->{ SOA }->{ $name } = $config->{ SOA }->{ $name };
	}
	# $self->{ SOA } = {
	#	'example.com'	=> [ qw( srv.example.com ) ],
	# };
	
	# PTR ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	foreach my $name ( keys %{ $self->{ A } } ){
		foreach my $ip ( @{ $self->{ A }->{ $name } } ){
			( my $key = Net::IP::XS->new( $ip )->reverse_ip() ) =~ s/\.$//o;
			$self->{ PTR }->{ $key } = $name;
		}
	}
	foreach my $name (keys %{ $self->{ AAAA } } ){
		foreach my $ip ( @{ $self->{ AAAA }->{ $name } } ){
			(my $key = Net::IP::XS->new( $ip )->reverse_ip()) =~ s/\.$//o;
			$self->{ PTR }->{ $key } = $name;
		}
	}
	#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	return $self;
}
#=======================================================================
# RFC1912 2.2
sub _serial {
    my ($self, $sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime( time );

    $year += 1900;
    $mon  += 1;

    $sec  = q[0] . $sec  if $sec  =~ /^\d$/o;
    $min  = q[0] . $min  if $min  =~ /^\d$/o;
    $hour = q[0] . $hour if $hour =~ /^\d$/o;
    $mday = q[0] . $mday if $mday =~ /^\d$/o;
    $mon  = q[0] . $mon  if $mon  =~ /^\d$/o;

    return $year . $mon . $mday . $hour;
}
#=======================================================================
sub _plain {
	my ($self, $str) = @_;
	
	$str =~ s/[\s\t]+(\d+)\s*(\)?)\s*;[^\n]+\n?/ $1/go;
	$str =~ s/\(\s*//o;
	
	return $str;
}
#=======================================================================
sub _log_response {
	my ($self, $peerhost, $qtype, $qname, $val) = @_;
	
	$self->{ log }->INFO( q[ ] . $peerhost . q[ ] . $qname . ' [' . $qtype . '] ' . ( scalar( @{ $val->[ 1 ] } ) ? q[OK] : q[FAIL] ) );

	$self->{ log }->DEBUG( "-" x 72 );
	$self->{ log }->DEBUG( 'Code: ' . $val->[0]  );
	$self->{ log }->DEBUG( " Ans: " . $self->_plain( $_->string ) ) for @{ $val->[ 1 ] };
	$self->{ log }->DEBUG( "Auth: " . $self->_plain( $_->string ) ) for @{ $val->[ 2 ] };
	$self->{ log }->DEBUG( " Add: " . $self->_plain( $_->string ) ) for @{ $val->[ 3 ] };
	$self->{ log }->DEBUG( "=" x 72 );
	
}
#=======================================================================
sub _handler {
	my ($self, $qname, $qclass, $qtype, $peerhost, $query, $conn) = @_;

	# sprawdzamy, czy odpowiedz jest w pamieci cache -------------------
	my $key = join( q/$/, $qname, $qclass, $qtype );
	my $val = $self->{ cache }->get( $key );
	
	if( $val ){
		$self->_log_response( $peerhost, $qtype, $qname, $val );
		return @$val;
	} 
	#-------------------------------------------------------------------

	my ($rcode, @ans, @auth, @add, $local);
	if($qtype eq A and ( exists $self->{ A }->{ $qname} or exists $self->{ CNAME }->{ $qname} )){
		
		if($self->{ CNAME }->{ $qname } ){
			push @ans, Net::DNS::RR->new(
					name    => $qname,
					ttl     => TTL,
					class   => $qclass,
					type    => CNAME,
					cname => $self->{ CNAME }->{ $qname },
				);
			$qname = $self->{ CNAME }->{ $qname };
		}

		foreach my $ip ( @{ $self->{ A }->{ $qname } } ){
			push @ans, Net::DNS::RR->new(
						name    => $qname,
						ttl     => TTL,
						class   => $qclass,
						type    => $qtype,
						address => $ip,
					);
		}
		
		$local = 1;
		$rcode = "NOERROR";
	}elsif( ( $qtype eq AAAA or $qtype eq A6 ) and ( exists $self->{ AAAA }->{ $qname } or exists $self->{ CNAME }->{ $qname } ) ){
		
		if($self->{ CNAME }->{ $qname } ){
			push @ans, Net::DNS::RR->new(
					name    => $qname,
					ttl     => TTL,
					class   => $qclass,
					type    => CNAME,
					cname => $self->{ CNAME }->{ $qname },
				);
			$qname = $self->{ CNAME }->{ $qname };
		}

		foreach my $ip ( @{ $self->{ AAAA }->{ $qname } } ){
			push @ans, Net::DNS::RR->new(
						name    => $qname,
						ttl     => TTL,
						class   => $qclass,
						type    => $qtype,
						address => $ip,
					);
		}
		
		$local = 1;
		$rcode = "NOERROR";
	}elsif( $qtype eq MX and ( exists $self->{ MX }->{ $qname } or exists $self->{ CNAME }->{ $qname } ) ){
MX:		
		if( $self->{ CNAME }->{ $qname } ){
			push @ans, Net::DNS::RR->new(
					name    => $qname,
					ttl     => TTL,
					class   => $qclass,
					type    => CNAME,
					cname 	=> $self->{ CNAME }->{ $qname },
				);
			$qname = $self->{ CNAME }->{ $qname };
		}
		
		foreach my $name ( @{$self->{ MX }->{ $qname } } ){
			push @ans, Net::DNS::RR->new(
						name    	=> $qname,
						ttl     	=> TTL,
						class   	=> $qclass,
						type    	=> MX,
						preference	=> 10,
						exchange 	=> $name,
					);
			
			my @ip;
			push @ip, @{ $self->{ A    }->{ $name } } if exists $self->{ A	  }->{ $name };
			push @ip, @{ $self->{ AAAA }->{ $name } } if exists $self->{ AAAA }->{ $name };
			
			for my $ip ( @ip ){
				push @add, Net::DNS::RR->new(
							name    => $name,
							ttl     => TTL,
							class   => IN,
							type    => $ip =~ /:/o ? AAAA : A,
							address => $ip,
						);
			}
		}
		
		$local = 1;
		$rcode = "NOERROR";
	}elsif( $qtype eq PTR and exists $self->{ PTR }->{ $qname } ){
		push @ans, Net::DNS::RR->new(
						name    => $qname . q/./,
						ttl     => TTL,
						class   => $qclass,
						type    => $qtype,
						ptrdname => $self->{ PTR }->{ $qname } . q/./,
					);
		
		$local = 1;
		$rcode = "NOERROR";
	}elsif( $qtype eq SOA and exists $self->{ SOA }->{ $qname } ){
		
		# SOA ----------------------------------------------------------
		push @ans, Net::DNS::RR->new(
							name	=> $qname . q/./,
							mname   => $self->{ SOA }->{ $qname },
							rname	=> q/root./ . $self->{ SOA }->{ $qname } . q/./,
							ttl     => TTL,
							class   => IN,
							type    => SOA,
							serial	=> $self->{ serial },
							refresh	=> 10800,		# 3  godziny
							retry	=> 3600,		# 1  godzina
							expire	=> 2592000,		# 30 dni
							minimum	=> TTL,
						);
						
		$local = 1;
		$rcode = "NOERROR";
	}elsif( $qtype eq NS and exists $self->{ NS }->{ $qname } ){
		# NS -----------------------------------------------------------
		for my $ns ( @{ $self->{ NS }->{ $qname } } ){
			push @ans, Net::DNS::RR->new(
							name	=> $qname,
							ttl		=> TTL,
							class	=> IN,
							type	=> NS,
							nsdname => $ns . q/./,
					);		
		}
						
		$local = 1;
		$rcode = "NOERROR";
	}elsif( $qtype eq AXFR and exists $self->{ SOA }->{ $qname } and exists $self->{ SL }->{ $peerhost } ){
		
		# SOA ----------------------------------------------------------
		push @ans, Net::DNS::RR->new(
							name	=> $qname . q/./,
							mname   => $self->{ SOA }->{ $qname },
							rname	=> q/root./ . $self->{ SOA }->{ $qname } . q/./,
							ttl     => TTL,
							class   => IN,
							type    => SOA,
							serial	=> $self->{ serial },
							refresh	=> 10800,		# 3  godziny
							retry	=> 3600,		# 1  godzina
							expire	=> 2592000,		# 30 dni
							minimum	=> TTL,
						);
		
		# A ------------------------------------------------------------
		for my $name ( keys %{ $self->{ A } } ){
			next if $name !~ /$qname/;
			foreach my $ip ( @{ $self->{ A }->{ $name } } ){
				push @ans, Net::DNS::RR->new(
							name    => $name,
							ttl     => TTL,
							class   => $qclass,
							type    => A,
							address => $ip,
						);
			}
		}

		# CNAME --------------------------------------------------------
		for my $name ( keys %{ $self->{ CNAME } } ){
			next if $name !~ /$qname/;			
			push @ans, Net::DNS::RR->new(
					name    => $name,
					ttl     => TTL,
					class   => $qclass,
					type    => CNAME,
					cname => $self->{ CNAME }->{ $name },
				);
		}

		# NS -----------------------------------------------------------
		for my $ns ( @{ $self->{ NS }->{ $qname } } ){
			push @ans, Net::DNS::RR->new(
							name	=> $qname,
							ttl		=> TTL,
							class	=> IN,
							type	=> NS,
							nsdname => $ns . q/./,
					);		
		}
		# MX -----------------------------------------------------------
		goto MX;
		#---------------------------------------------------------------

		$local = 1;
		$rcode = "NOERROR";
	}elsif( $self->{ _ra } ){
		# poszukujemy informacji o zadanym wezle -----------------------
		if( $qtype eq A or $qtype eq PTR or $qtype eq MX or $qtype eq SOA or $qtype eq NS ){
			
			my $q = $self->{ resolv }->send( $query );
			
			if( $q ){
				push @ans,  $q->answer;
				push @auth, $q->authority;
				# adres serwera poczty ---------------------------------
				if( $qtype eq MX ){
					my %seen;
					for my $ans ( @ans ){
						my $str = $ans->type eq CNAME ? $ans->cname : $ans->exchange;
						my $res = $self->{ resolv }->query( $str );
						next unless $res;
						for my $ans ( $res->answer ){
							next if $seen{ $ans->name };
							$seen{ $ans->name } = 1;
							push @add, $ans;
						}
					}
				}
				$rcode = scalar( @ans ) ? "NOERROR" : "NXDOMAIN";
			}else{
				$rcode = "NXDOMAIN";
			}	
		}else{
			$local = 1;
			$rcode = "NOTIMP";
		}
		#---------------------------------------------------------------
	}else{
		$rcode = "NXDOMAIN";
	}

	if( $rcode ne 'NOTIMP' ){
		# zapis w lokalnej konfiguracji --------------------------------
		if( $local ){
			(my $rdom = $qname) =~ s/^[\d\w]+\.//o;		# fix it!!!
			my   $dom = ( $qtype eq AXFR || $qtype eq SOA ) ? $qname : $rdom;
			
			if( exists $self->{ NS }->{ $dom } ){
				for my $ns ( @{ $self->{ NS }->{ $dom } } ){

					push @auth, Net::DNS::RR->new(
									name	=> $dom . q/./,
									ttl		=> TTL,
									class	=> IN,
									type	=> NS,
									nsdname => $ns . q/./,
					);		
				
					my $name = $self->{ CNAME }->{ $ns } ? $self->{ CNAME }->{ $ns } : $ns;
					foreach my $ip ( @{$self->{ A }->{ $name } }, @{ $self->{ AAAA }->{ $name } } ){
						push @add, Net::DNS::RR->new(
									name    => $ns,
									ttl     => TTL,
									class   => IN,
									type    => $ip =~ /:/o ? AAAA : A,
									address => $ip,
								);
					}
				}
			}
		}
		# zewnetrzna nazwa DNS ---------------------------------------------
		else {
			if( scalar( @ans ) ){
				unless( scalar( @auth ) ){
					my $str = 	$qtype eq PTR 							? $ans[0]->ptrdname :
								$qtype eq MX  && $ans[0]->type ne CNAME ? $ans[0]->exchange	: $qname;
					
					while( $str =~ /\./o ){	
						my $qry = $self->{ resolv }->query( $str, NS );
						if( $qry ){
							push @auth, $_ for grep { $_->type eq NS or $_->type eq SOA } $qry->answer;
							
							for my $q ( @auth ){
								my $res = $self->{ resolv }->query( $q->nsdname );
								push @add, $res->answer if $res;
							}
							last;
						}
						$str =~ s/^[^\.]+\.//o;
					}
				}
			}
		}
	}
	
	@ans = sort { ref( $b ) cmp ref( $a ) } @ans;
	
	my @res = 	$qtype eq AXFR 	? ( $rcode, [ @ans, $ans[0] ], 	[ ], [ ] ) :  ( $rcode, \@ans, \@auth, \@add );

	# ustawiamy dodatkowe flagi ----------------------------------------
	my %flags;
	$flags{ aa } = 1 if $local and scalar( @auth );
	$flags{ ra } = 1 if $self->{ _ra };
	push @res, \%flags;			
	
	# zapisujemy odpowiedz w pamieci cache -----------------------------
	$self->{ cache }->set( $key, \@res );
	$self->_log_response( $peerhost, $qtype, $qname, \@res );
	#-------------------------------------------------------------------
	
	return @res;
}
#=======================================================================
sub main_loop {
	my ($self) = @_;
	
	$self->{ log  		}->DEBUG( 'Starting...' );
	$self->{ nameserver }->main_loop;
}
#=======================================================================
1;

=encoding utf8

=head1 NAME

Net::DNS::Nameserver::Trivial - Trivial DNS server, that is based on Net::DNS::Nameserver module.


=head1 SYNOPSIS

	use Net::DNS::Nameserver::Trivial;
	
	# Configuration of zone(s) -----------------------------------------
	
	my $zones = {
		 '_' 	 => {
				  'slaves'      => '10.1.0.1'
				 },
				 
		 'A' 	 => {
				  'ns.example.com'   => '10.11.12.13',
				  'mail.example.com' => '10.11.12.14',
				  'web.example.com'  => '10.11.12.15',
				  'srv.example.com'  => '10.11.12.16'
				 },
				
		 'AAAA'	 => {
				   'v6.example.com'	 =>	'fe80::20c:29ff:fee2:ed62', 
				 },
				 
		 'CNAME' => {
					  'srv.example.com' => 'dns.example.com'
				 },
				 
		 'MX' 	 => {
				   'example.com' => 'mail.example.com'
				 },
				 
		 'NS' 	 => {
					'example.com' => 'ns.example.com'
				 },
				 
		 'SOA' 	 => {
					'example.com' => 'ns.example.com'
				 }
	   };

	# Configuration of server ------------------------------------------
	my $params = {
	
		'FLAGS'	 	=> {
					'ra' => 0, 	# recursion available
				 },

		'RESOLVER'	=> {
					'tcp_timeout'	=> 50,
					'udp_timeout'	=> 50
				 },
				 
		'CACHE'		=> {
					'size'     		=> 32m,	# size of cache
					'expire'    	=> 3d,	# expire time of cache
					'init'			=> 1,	# clear cache at startup
					'unlink'  		=> 1,	# destroy cache on exit
					'file'      	=> '../var/lib/cache.db'	# cache
				 },
				 
		'SERVER'	=> {
					'address'		=> '0.0.0.0', # all interfaces
					'port'			=> 53,
					'verbose'		=> 0,
					'truncate'      => 1,	# truncate too big 
					'timeout'  		=> 5	# seconds
				 },

		'LOG'		=> {
					'file'			=> '/var/log/dns/mainlog.log',
					'level'			=> 'INFO'
				 },
				 
	};

	# Run server -------------------------------------------------------
	
	my $ns = Net::DNS::Nameserver::Trivial->new( $zones, $params );
    $ns->main_loop;
	
	#
	# ...OR SHORT VERSION with configuration files
	#

	use Config::Tiny;
	use Net::DNS::Nameserver::Trivial;
	
	# Read in config of zone -------------------------------------------
	my $zones 	= Config::Tiny->read( '../etc/dom.ini' );
	
	# Read in config of server -----------------------------------------
	my $params 	= Config::Tiny->read( '../etc/dns.ini' );

	# Run server -------------------------------------------------------
	my $ns = Net::DNS::Nameserver::Trivial->new( $zones, $params );
	$ns->main_loop;
	
=head1 DESCRIPTION

The C<Net::DNS::Nameserver::Trivial> is a very simple nameserver, that is 
sufficient for local domains. It supports cacheing, slaves,  zone
transfer and common records such as A, AAAA, SOA, NS, MX, TXT, PTR, 
CNAME. This module was tested in an environment with over 1000 users and 
for now is running in a production environment.

The main goal was to produce server, that is very easy in configuration
and it can be setup in a few seconds. So You should consider BIND if for 
some reasons You need more powerful and complex nameserver.

This module was prepared to cooperete with C<Config::Tiny>, so it is 
possible to prepare configuration files and run server with them,
as it was shown in an example above.

=head1 WARNING

This version is incompatible with previous versions, because of
new format of second configuration file. However modifications are
simple.

=head1 SUBROUTINES/METHODS

=over 4

=item new( $zones, $params )

This is constructor. You have to pass to it hash with configuration of 
zones and second hash - with configuration for server.

The first hash sould contains sections (as shown in a L<SINOPSIS>):

=over 8

=item C<_>

This section is a hash, that should contains information of slaves of
our server. For example:

	'_' => {
		'slaves'      => '10.1.0.1'
	}


=item C<A>

This section is a hash, that is a mapping FDQN to IPv4, for example:

	'A' => {
		  'ns.example.com'   => '10.11.12.13',
		  'mail.example.com' => '10.11.12.14',
		  'web.example.com'  => '10.11.12.15',
		  'srv.example.com'  => '10.11.12.16'
		 }

=item C<AAAA>

This section is a hash, that is a mapping FDQN to IPv6, for example:

	'AAAA' => {
		'v6.example.com'  => 'fe80::20c:29ff:fee2:ed62', 
	}

=item C<MX>

This section is a hash, that contains information about mail servers
for domains. For example, if I<mail.example.com> is a mail server for
domain I<example.com>, a configuration should looks like this:

	'MX' => {
		'example.com' => 'mail.example.com'
	}

=item C<CNAME>

This section is a hash, that contains aliases for hosts. For example,
if alias.example.com and alias1.example.com are aliases for a server
srv.example.com, a configuration should looks like this:

	'CNAME' => {
		'srv.example.com' => 'alias.example.com, alias1.example.com'
	}

=item C<NS>

This section is a hash, that contains information about nameservers
for a domain. For example:

	'NS' => {
		'example.com' => 'ns.example.com'
	}

=item C<SOA>

This section is a hash, that contains information about authoritative 
nameserver for a domain. For example:

	'SOA' => {
		'example.com' => 'ns.example.com'
	}

=back

The second hash should contains variables sufficient for configuration of
server, cache, logs, etc. The meaning of hash elements was shown below.

=over 8

=item C<SERVER>

This section describes options of server.

=over 12

=item C<timeout>

Timeout for idle connections.

=item C<address>

Local IP address to listen on. Server will be listenting on all 
interfecas if You specify C<0.0.0.0>.

=item C<port>

Local port to listen on.

=item C<truncate>

Truncates UDP packets that are to big for the reply

=item C<verbose>

Be verbose. It is useful only for debugging.

=back

=item C<CACHE>

This section describes options of server's cache.

=over 12

=item C<size>

A size of cache, that will be used by server.

=item C<expire>

Expiration time of entries in a cache. It can be diffrent than TTL value. 
It is effective if makeing of connection to other server is too expensive
(i.e. too long).

=item C<init>     

Clear cache at startup.

=item C<file>

A path to cache file.

=item C<unlink>

Unlink a cache file on exit.

=back

=item C<LOG>

This section describes options of server's log.

=over 12

=item C<file>

A path to log file.
       
=item C<level>

Log level.

=back

=item C<RESLOVER>

This section describes options of resolver.

=over 12

=item C<tcp_timeout>

A timeout for TCP connections.
          
=item C<udp_timeout>

A timeout for UDP connections.

=back

=back

=item C<main_loop()>

This method starts main loop of a nameserver. See an example in a SINOPSIS.

=back

=head1 USING CONFIGURATION FILES - examples

C<Net::DNS::Nameserver::Trivial> was prepared to cooperate with 
C<Config::Tiny> module. It is possible to prepare configuration files 
for zones and for server and then make server server run using those 
files. 

Config file for zone I<example.com> could looks like this:

	slaves              = 10.1.0.1

	[NS]
	example.com         = ns.example.com

	[SOA]
	example.com         = ns.example.com

	[MX]
	example.com         = mail.example.com'

	[AAAA]

	[CNAME]
	srv.example.com     = alias.example.com, alias1.example.com

	[A]
	ns.example.com      = 10.11.12.13
	mail.example.com    = 10.11.12.14
	web.example.com     = 10.11.12.15
	srv.example.com     = 10.11.12.16

Config file for server could looks like this:

	[FLAGS]
	ra				= 0

	[RESOLVER]
	tcp_timeout		= 50
	udp_timeout		= 50

	[CACHE]
	size      		= 32m
	expire    		= 3d
	init			= 1
	unlink  		= 1
	file      		= /var/lib/cache.db

	[SERVER]
	address			= 0.0.0.0
	port			= 53
	verbose			= 0
	truncate        = 1
	timeout  		= 5

	[LOG]
	file			= /var/log/dns/mainlog.log
	level			= INFO

And then a code of server shold looks like this:

	use Config::Tiny;
	use Net::DNS::Nameserver::Trivial;
	
	# Read in config of zone -------------------------------------------
	my $zones 	= Config::Tiny->read( '/path/to/zone/file.ini' );
	
	# Read in config of server -----------------------------------------
	my $params 	= Config::Tiny->read( '/path/to/server/config.ini' );

	# Run server -------------------------------------------------------
	my $ns = Net::DNS::Nameserver::Trivial->new( $zones, $params );
	$ns->main_loop;

A complete example is placed in the example directory.

=head1 DEPENDENCIES

=over 4

=item Net::IP::XS

=item Net::DNS

=item Log::Tiny

=item List::MoreUtils

=item Cache::FastMmap

=item Regexp::IPv6

=back

=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

I'm sure, that they must be there :-) ...but if You found one, give me 
a feedback.

=head1 AUTHOR

Strzelecki Łukasz <l.strzelecki@ita.wat.edu.pl>

=head1 LICENCE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html
