package Net::DNS::Check::NSQuery;
                                                                                
use strict;

use Net::DNS;
use Net::DNS::Check::Host;
use Net::DNS::Check::HostsList;
use Net::DNS::Check::Config;
use Carp;
# use Data::Dumper;
                                                                                
sub new {
	my ($class, %param) = @_;
         

	return 0 if (!$param{domain} || ! $param{nserver});
                                                                         
	my $self = {};

	# Nome del dominio
	$self->{domain} 		= $param{domain};
	$self->{qdomain} 		= $param{domain};
	$self->{qdomain}     	=~ s/\./\\./g;

	# Nome del namserver da interrogare
	$self->{nserver} 	= $param{nserver};

	my $fatal = 0;
	my $msg_error =<<ERROR;

FATAL ERROR
===============
Wrong call of constructor: $class
ERROR


	unless ( $self->{domain} ) {
		$fatal = 1;
		$msg_error .= "\ndomain param not found!\n";
	}

	unless ( $self->{nserver} ) {
		$fatal = 1;
		$msg_error .= "\nnserver param not found!\n";
	}

	if ( $fatal ) {
		confess($msg_error . "\n");
	}



	# IP del namserver da interrogare
	# il parametro e' facoltativo. Se non viene passato
	# viene utilizzata la ricorsione per determinare
	# l'IP. Ovviamente per i nameserver appartenenti al dominio
	# sul quale staimo operando DOVREBBE essere passato l'IP.
	# Se non viene passato l'IP per quest'ultimi si utilizza
	# la ricorsione che funzionera' solo se il dominio e' gia'
	# esistente
	$self->{ip} 	= $param{ip};


	$self->{config} 	= $param{config} || new Net::DNS::Check::Config;

	if ( defined $param{debug} ) {
		$self->{debug}      = $param{debug};
    	} else {
        	$self->{debug}      = $self->{config}->debug_default();
    	}


	
	# External/General Hostslist.
	$self->{hostslist} = $param{hostslist} ||  new Net::DNS::Check::HostsList( 
			domain 	=> $self->{domain}, 
			debug 	=> ($self->{debug} > 2), 
			config 	=> $self->{config}
		);

	# Internal HostsList 
	$self->{myhostslist} = new Net::DNS::Check::HostsList( 
		domain 	=> $self->{domain}, 
		debug 	=> ($self->{debug} > 2), 
		config 	=> $self->{config}
	);
   



	# Array of NS or MX hostnames 
	$self->{result}->{NS} = [];
	$self->{result}->{MX} = [];


	bless $self, $class;

	if ($self->{debug} > 0 ) {
		print <<DEBUG;

Query for RR ANY for $self->{domain} to $self->{nserver} 
=======================================================
DEBUG
	}



	# Creiamo l'oggetto resolver usando il resolver di sistema
	$self->{res} = Net::DNS::Resolver->new(
		recurse     	=> 0,
		debug       	=> ($self->{debug} > 2),
		retrans     	=> $self->{config}->query_retrans,
		retry       	=> $self->{config}->query_retry,
		tcp_timeout     => $self->{config}->query_tcp_timeout
	);


	# La add_host crea un oggetto host e lo aggiunge alla lista se non esiste 
	# o ritorna l'oggetto host gia' presente nella hostslist
	# $self->{host} = $self->{hostslist}->add_host( $self->{nserver}, $self->{ip} );


	# if an ip doesn't exist we try to find it using add_host function 
	# (that it uses hostslist object functions)
	unless ( @{$self->{ip}} ) {

		if ($self->{debug} > 0 ) {
			my $ips = join(' ', @{$self->{ip}});
			print <<DEBUG;
 Search for $self->{nserver} IP

DEBUG
		}

	    $self->{host} = $self->_add_host( $self->{nserver} );
		$self->{ip} = $self->{host}->get_ip();

	}

	# We found an IP address to query so we make query 
	# .... otherwise we have an error
	if ( @{$self->{ip}} ) { 
		# $self->{type} = $type;

		if ($self->{debug} > 0 ) {
			my $ips = join(' ', @{$self->{ip}});
			print <<DEBUG;
 $self->{nserver} IP : $ips 
DEBUG
		}

		# We set resolver to the ip found 
		$self->{res}->nameservers(@{ $self->{ip} });

		if ($self->{debug} > 2) {
			print "\n\n";
			$self->{res}->print;
		}

		# Query of type ANY for $self->{domain} to $self->{ip}
		$self->_queryANY();

	} else {

		$self->{error} = 'NOIP';

		if ($self->{debug} > 0 ) {
			my $ips = join(' ', @{$self->{ip}});
			print <<DEBUG;
 $self->{nserver} IP : Not Found 
DEBUG
		}
	}

	return $self;
}


sub _queryANY() {
	my $self = shift;

	# Creazione query per il dominio 
	my $packet = $self->{res}->send($self->{domain},'ANY'); 

	if ($packet) {
		$self->{result}->{header} = $packet->header; 

		if ($self->{debug} > 0 ) {
			print <<DEBUG;
 Getting query answer 

DEBUG
		}

		if ($self->{debug} > 1 ) {
			my $result = $packet->string;
			print <<DEBUG;
$result
DEBUG
		}


		if ( $self->header_aa() && scalar $packet->answer() ) {
			foreach my $rr ( $packet->answer ) { 

				if ($rr->type eq 'SOA') {
					$self->{result}->{SOA} = $rr;
					next;
				}
	
				if ($rr->type eq 'NS') {
					push (@{$self->{result}->{NS}}, lc($rr->{nsdname}));
					$self->_add_host( lc($rr->{nsdname}) );
					next;
				}
	
				if ($rr->type eq 'MX') {
					push (@{$self->{result}->{MX}}, lc($rr->{exchange}));
					$self->_add_host( lc($rr->{exchange}) );
					next;
				}
			}
		} else {
			$self->{error} = 'NOAUTH';
		}
	} else {

		# Query Error... no answer (time out) 
		$self->{error} = 'NOANSWER';

		if ($self->{debug} > 0 ) {
			my $qerror = $self->{res}->errorstring;
			print <<DEBUG;
 Query Error:       $qerror
DEBUG
		}

	}
}



sub _add_host() {
	my $self 		= shift;
	my ($hostname) 	= shift;

	unless ($hostname) {
		confess("hostname parm not found!\n");
	}

	my ($host, @temp);

	@temp = split('\.', $self->{domain});
	my $domcount = scalar @temp;

	@temp = split('\.', $hostname);
	my $hostcount = (scalar @temp)-1;


	# Questo e' da rivedere. 
	if ( ($hostname eq $self->{domain}) || $hostname =~ /.*$self->{qdomain}$/ && $domcount == $hostcount ) {
		# Se l'hostname fa parte del dominio lo aggiungiamo alla hostslist
		# locale e usiamo per la risluzione l'ip del namserver
		# con cui abbiamo creato l'oggetto NSQuery
		#print "inside ";
		$host = $self->{myhostslist}->add_host( hostname => $hostname, ip => $self->{ip} );
	} else {
		# Se l'hostname non fa parte del dominio lo aggiungiamo alla
		# hostslist globale
		#print "outside ";
		$host = $self->{hostslist}->add_host( hostname => $hostname );
	}
	return $host;
}



# Riporta 1 se le risposte del dns sono autoritativo
# Riporta 0 se la risposta non e' autoritativa
# Riporta -1 se non c'e' nessun header 
sub header_aa() {
	my $self = shift;

	return undef if (! defined $self->{result}->{header});

	return $self->{result}->{header}->aa(); 
}


# Riporta l'oggetto Net::DNS::Header oppure false se non c'e' l'oggetto
sub header() {
	my $self = shift;

	return 0 if (! defined $self->{result}->{header});

	return $self->{result}->{header}; 
}


# Riporta un array vuoto se non ci sono record NS altrimenti riporta 
# l'array contenente la lista dei DNS autoritativi
sub ns_list() {
	my $self = shift;

	return () unless defined $self->{result}->{NS};

	return @{ $self->{result}->{NS} }; 
}


# Riporta un array vuoto se non ci sono record MX altrimenti 
# Altrimenti riporta l'array dei contenente la lista degli 
# exchange server 
sub mx_list() {
	my $self = shift;

	return () unless defined $self->{result}->{MX};

	return @{ $self->{result}->{MX} }; 
}

# Riporta undef se non esiste un'oggetto SOA o non esiste un master altrimenti riporta il master nameserver che appare nel SOA 
sub soa_mname() {
	my $self = shift;

	return if (! defined $self->{result}->{SOA} );

	return lc($self->{result}->{SOA}->mname()); 
}

# Riporta undef se non esiste un'oggetto SOA altrimenti
# Riporta il serial che appare nel SOA 
sub soa_serial() {
	my $self = shift;

	return if (! defined $self->{result}->{SOA} ); 

	return $self->{result}->{SOA}->serial(); 
}



# Riporta 0 se non esiste un'oggetto SOA o non esiste un refresh 
# Riporta il refresh che che appare nel SOA 
sub soa_refresh() {
	my $self = shift;

	return 0 if (! defined $self->{result}->{SOA} );

	return $self->{result}->{SOA}->refresh(); 
}

# Riporta 0 se non esiste un'oggetto SOA o non esiste un retry 
# Riporta il retry che che appare nel SOA 
sub soa_retry() {
	my $self = shift;

	return 0 if (! defined $self->{result}->{SOA} );

	return $self->{result}->{SOA}->retry(); 
}

# Riporta 0 se non esiste un'oggetto SOA o non esiste un expire 
# Riporta il expire che che appare nel SOA 
sub soa_expire() {
	my $self = shift;

	return 0 if (! defined $self->{result}->{SOA} );

	return $self->{result}->{SOA}->expire(); 
}

# Riporta 0 se non esiste un'oggetto SOA o non esiste un minimum 
# Riporta il minimum che che appare nel SOA 
sub soa_minimum() {
	my $self = shift;

	return 0 if (! defined $self->{result}->{SOA} );

	return $self->{result}->{SOA}->minimum(); 
}

# Riporta 0 se non esiste un'oggetto SOA o non esiste un minimum 
# Riporta il minimum che che appare nel SOA 
sub soa_mail() {
	my $self = shift;

	return 0 if (! defined $self->{result}->{SOA} );

	return $self->{result}->{SOA}->rname(); 
}

# Riporta il nome del nameserver che stiamo interrogando 
sub ns_name() {
	my $self = shift;

	return $self->{nserver};
}


sub error() {
	my $self = shift;

	return $self->{error};
}

sub hostslist() {
	my $self = shift;

	return $self->{myhostslist};
}

1;

__END__

=head1 NAME

Net::DNS::Check::NSQuery - Class to query authoritative nameservers for the domain name you want to check.

=head1 DESCRIPTION

This class is used to query nameservers for the domain name you want to check.

The are several methods implemented by this class, but at present are all for internal use only and L<Net::DNS::Check> users don't need to directly create  Net::DNS::Check::NSQuery object and call his methods.

Anyway a complete documentation of all methods will be released as soon as possible.

=head1 COPYRIGHT

Copyright (c) 2005 Lorenzo Luconi Trombacchi - IIT-CNR

All rights reserved.  This program is free software; you may redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<perl(1)>

=cut



