package Net::DNS::Check::Host;
                                                                                
use strict;

use Net::DNS;
use Net::DNS::Resolver::Recurse;
use Net::DNS::Check::Config;
use Carp;
                                                                                
sub new {
	my ($class, %param) = @_;
         
	my $self = {};

	$self->{class}		= $class;

	# Hostname 
	$self->{host}		= lc($param{host});
	
	# Nameserver IP Address to query 
	$self->{ip}			= $param{ip} || [];

	# Original IP 
	$self->{ip_orig}	= $param{ip_orig} || [];

	# If there isn't a config we create a new one 
	$self->{config}		= $param{config} || new Net::DNS::Check::Config;

	if ( defined $param{debug} ) {
		$self->{debug}		= $param{debug};
	} else {
		$self->{debug}		= $self->{config}->debug_default();
	}

	# True if we want to create a statc host without query 
	$self->{init_only}  	= $param{init_only};

	$self->{qtype}		= uc($param{qtype}) || 'A';
	$self->{query_AAAA}	= $self->{config}->query_AAAA();
	$self->{query_AAAA}	= 0 if ($self->{qtype} eq 'PTR');


	# max_depth for cname resolution (endless loop protection)
	$self->{depth}			= 0;
	$self->{max_depth}		= 10;

	# This is set to 1 if we found the IP address of $self->{host} with recursion
	# or set to 2 if we found IP with init_only
	$self->{recurse}			= 0;


	bless $self, $class;


	if ($self->{debug} && 0 ) {
		my ($ips) = '';
		my ($init_only) = '';

		$ips = join(' ', @{ $self->{ip} });

		if ( $self->{init_only} )
		{
			$init_only = 'init_only';	
		}


		print <<END_OF_TEXT;


****************************************************
Location: 		$self->{class}::new $init_only
Looking for host: $self->{host}
IP to query: 		$ips
Query type: 		A
****************************************************

END_OF_TEXT
   }


	# init_only is used when we want to set an host object with predefined
	# value 
	if ( ! $self->{init_only} ) {

		if ( $self->{host} ) {
            # If we have an IP we use it to make a direct query using _queryIP function 
            if ( scalar @{$self->{ip}} > 0) {

                $self->_queryIP(
                    host => $self->{host},
                    ip   => $self->{ip},
                    qtype => $self->{qtype}
                );

                # Check for AAAA records
                if ($self->{query_AAAA}) {
                    $self->_queryIP(
                        host => $self->{host},
                        ip   => $self->{ip},
                        qtype => 'AAAA'
                    );
                }
            } else {
				# If there isn't an IP we use recursion
                $self->_queryIPrecurse(
                    host => $self->{host},
                    qtype => $self->{qtype}
                );

                # Check for AAAA records
                if ($self->{query_AAAA}) {
                    $self->_queryIPrecurse(
                        host => $self->{host},
                        qtype => 'AAAA'
                    );
                }
            }
		} else {
			confess(<<"ERROR");

FATAL ERROR
=============== 
Wrong call of constructor: $class
host param not found!

ERROR
		}
	} else {
		$self->{ipfound} 	= $self->{ip};
		$self->{type} 		= 'A';
		$self->{recurse} 	= 2;
	}
 
	return $self;
}



# Query for A RR for $self->{host}
# using $self->{ip} as resolver
sub _queryIP() {
	my $self 	= shift;
	my %param   = @_;
	my $host 	= $param{host} || $self->{host}; 
	my $ip 		= $param{ip} || $self->{ip};
	my $qtype 	= $param{qtype} || $self->{qtype};

	return undef if (! $host || ! $ip); 

	$self->{recurse} 	= 0;

	if ($self->{debug} > 0) {
		my $ips = join(' ', @{ $ip });

		print <<END_OF_TEXT;
 Trying to resolve $host using [ $ips ]
END_OF_TEXT
  
	}

	my $res = Net::DNS::Resolver->new(
		nameservers 	=> $ip,
		recurse     	=> 0,
		debug  	     	=> ($self->{debug} > 2),
		retrans     	=> $self->{config}->query_retrans(),
		retry			=> $self->{config}->query_retry(),
		tcp_timeout     => $self->{config}->query_tcp_timeout(),
	);

	my $packet = $res->send($host, $qtype);


	if ( ! $packet && $qtype ne 'AAAA') {

		if ($self->{debug} > 0) {
			my $qerror = $res->errorstring;
			print <<END_OF_TEXT;
 Query Error: $qerror
END_OF_TEXT
		}

		$self->{error} = 'NOANSWER';

	} else {
		return $self->_decodePacket(
			packet 	=> $packet, 
			host 	=> $host, 
			qtype 	=> $qtype
		); 
	}
}


# 
#  We use recursion 
sub _queryIPrecurse() {
	my $self 	= shift;
	my %param   = @_;
	my $host 	= $param{host} || $self->{host}; 
	my $qtype 	= $param{qtype} || $self->{qtype};


	return undef if (!$host);

	$self->{recurse} 	= 1;

	if ($self->{debug} > 0) {
		print <<END_OF_TEXT;
 Trying to resolve $host using RECURSION
END_OF_TEXT

	}

	my $res = Net::DNS::Resolver::Recurse->new(
		recurse		=> 1,
		debug		=> ($self->{debug} > 2),
		retrans		=> $self->{config}->query_retrans(),
		retry		=> $self->{config}->query_retry(),
		tcp_timeout	=> $self->{config}->query_tcp_timeout(),
	);

	$res->hints( @{$self->{config}->rootservers()} );

	my $packet =  $res->query_dorecursion( $host , $qtype);

    if ( ! $packet && $qtype ne 'AAAA') {
		if ($self->{debug} > 0 ) {
			my $qerror = $res->errorstring;
			print <<END_OF_TEXT;
 Query Error: 		$qerror
END_OF_TEXT
		}
		$self->{error} = 'NOANSWER';
    } else {
		return $self->_decodePacket(
			packet 	=> $packet, 
			host 	=> $host, 
			qtype 	=> $qtype
		); 
	}
}



sub _decodePacket() {
	my $self = shift;

	my %param   = @_;
	my $packet 	= $param{packet};
	my $host 	= $param{host} || $self->{host}; 
	my $qtype 	= $param{qtype} || $self->{qtype};

	return undef if (! $packet);

	my $cname;
	my $iscname = 0;
	my $ip = [];

	foreach my $rr ( $packet->answer ) {
		# Saltiamo risposte sulla base della cache 
		# ovvero risposte che non si riferiscono
		# al record che stiamo chiedendo ($host)
		# Attenzione nel caso di PTR questo non e' corretto
		# 193.205.245.5 -> 5.245.205.193.in-addr.arpa
		next if ($rr->name() ne $host);

		if ($rr->type() eq 'A') {
			push(@{$ip}, $rr->address);
			next;
		}

		if ($rr->type() eq 'AAAA') {
			push(@{$ip}, $rr->address);
			next;
		}

		if ($rr->type() eq 'PTR') {
			push(@{$ip}, $rr->ptrdname);
			next;
		}

		if ($rr->type() eq 'CNAME') {
			$cname = $rr->cname;
			$iscname = 1;
			next;
		}
	}

	# Se abbiamo un CNAME ma non IP
	# bisogna fare la risoluzione del cname host trovato
	# L'algoritmo e ricorsivo fintanto che non trovo un record A
	# Viene fermata la ricerca dopo 'max_depth' ricorsioni
	if ($cname && ! scalar @{$ip} && $self->{depth} <= $self->{max_depth}) {
		$self->{depth}++;

		if ($self->{debug} > 0 ) {
			print <<END_OF_TEXT;
 Found RR CNAME: $cname

END_OF_TEXT
		}
		
		# return undef;
		
		# Se abbiamo un IP di nameserver da interrogare e se il cname host 
		# fa parte del dominio che stiamo analizzando facciamo
		# un query diretta utilizzando _queryIP altrimenti andiamo
		# per ricorsione partendo dai root nameservers  
		if ( scalar @{$self->{ip}} > 0 ) {
			$ip = $self->_queryIP( 
				host 	=> $cname, 
				ip 		=> $self->{ip}
			);
		} else {
			$ip = $self->_queryIPrecurse( host => $cname );
		}
		$ip = [] if (!$ip); # Forziamo $ip ad essere almeno un puntatore vuoto
	}


	if ($iscname) {
		$self->{type} 	= 'CNAME'; 
		$self->{cname} 	= $cname;
	} 

	if ( scalar @{$ip} ) {

		$self->{type} 	= 'AAAA'; 

		my $ips = join(' ', @{ $ip });
		if ($qtype eq "AAAA") {

			$self->{ip6found} = $ip;

			if ($self->{debug} > 0  && !$iscname) { # added && !$iscname for better debug output
				print <<END_OF_TEXT;
 Found RR AAAA: $ips

END_OF_TEXT
			}

		} else {

			$self->{type} 	= 'A'; 
			$self->{ipfound} = $ip;

			if ($self->{debug} > 0 && !$iscname) { # added && !$iscname for better debug output
				print <<END_OF_TEXT;
 Found RR A: $ips
  
END_OF_TEXT
			}
		}

		return $ip;

	} else {
		# Nessun IP trovato
		$self->{error} = 'NXDOMAIN';
	#	$self->{type} 	= ''; 
		if ($self->{debug} > 0 && !$iscname) { # added && !$iscname for better debug output
				print <<END_OF_TEXT;
 No Record Found

END_OF_TEXT
			}
		return undef;
	}
}


# Effettua la risoluzione inversa per il momento solo di IPv4
# il supporto del reverse IPv6 di Net::DNS e' limitato
sub _queryReverse() {
	my $self = shift;

	return undef if (! $self->{ipfound}); 

	my $res = Net::DNS::Resolver::Recurse->new(
		recurse         => 1,
		debug           => ($self->{debug} > 2),
		retrans         => $self->{config}->query_retrans(),
		retry           => $self->{config}->query_retry(),
		tcp_timeout     => $self->{config}->query_tcp_timeout(),
	);
	$res->hints( @{$self->{config}->rootservers()} );

	foreach my $ip (@{$self->{ipfound}}) {
		warn("Reverse di $ip\n");

		my $packet =  $res->query_dorecursion( $ip , 'PTR' );

		if ($packet) {
			foreach my $rr ( $packet->answer ) {
				if ($rr->type() eq 'PTR') {
					$self->{reverse}->{$ip} = $rr->ptrdname; 
				}
			}
		} else {
			# Query error
		}
	}

	return 1;
}


# Ritorna il tipo di record trovato: A o CNAME
sub get_type() {
	my $self = shift;

	return undef if (!$self->{type});
    
	return $self->{type};
}


# Ritorna una array ref degli IP trovati (se ce ne sono)
sub get_ip() {
	my $self = shift;

	return [] if (!$self->{ipfound});
    
	return $self->{ipfound};
}

# Ritorna una array ref degli IP trovati (se ce ne sono)
sub get_ip_orig() {
	my $self = shift;

	return $self->{ip_orig};
}


# Ritorna una array ref degli IPV6 trovati (se ce ne sono)
sub get_ip6() {
	my $self = shift;

	return [] if (!$self->{ip6found});
    
	return $self->{ip6found};
}


 
sub get_cname() {
	my $self = shift;

	return $self->{cname};
}


sub found() {
	my $self = shift;

	return ( scalar @{$self->{ip}} );
}

sub error() {
	my $self = shift;

	return $self->{error}; 
}


sub get_recurse() {
	my $self = shift;

	return $self->{recurse};
}

sub get_hostname() {
	my $self = shift;

	return $self->{host};
}

1;

__END__

=head1 NAME

Net::DNS::Check::Host - Class for name server resolution of hostnames

=head1 DESCRIPTION

This class is used for name server resolution of hostnames found during the domain check phase. The are several methods implemented by this class, but at present are all for internal use only and L<Net::DNS::Check> users don't need to directly create  Net::DNS::Check::Host obkect and call his methods.

Anyway a complete documentation of all methods will be released as soon as possible.

=head1 COPYRIGHT

Copyright (c) 2005 Lorenzo Luconi Trombacchi - IIT-CNR

All rights reserved.  This program is free software; you may redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<perl(1)>

=cut

