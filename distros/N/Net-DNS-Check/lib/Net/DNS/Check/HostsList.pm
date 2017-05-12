package Net::DNS::Check::HostsList;
                                                                                
use strict;
use Net::DNS::Check::Config;
use Net::DNS::Check::Host;

                                                                                
sub new {
	my ($pkg, %param) = @_;
	my $self;

	$self->{domain}		= $param{domain};
 
	# Quotiamo i '.'
	$self->{qdomain}	= $param{domain};
	$self->{qdomain}	=~ s/\./\\./g;


	$self->{config}		= $param{config} || new Net::DNS::Check::Config;

	$self->{debug} 		= $param{debug} || $self->{config}->debug_default();

	$self->{list}		= {};

	bless $self, $pkg;

	if ($param{load_predefined}) {
		$self->load_predefined_host();
	} 

	return $self;
}


sub load_predefined_host() {
    my $self = shift;

	# Precaricamento dei predefined_hosts
	foreach my $prehost ( keys %{$self->{config}->{predefined_hosts} } ) {
		my $host_obj = new Net::DNS::Check::Host(
			init_only  => 1,
			debug      => $self->{debug},
			host       => $prehost,
			config     => $self->{config},
			ip         => $self->{config}->{predefined_hosts}->{$prehost}
		);

		$self->{list}->{$prehost} = $host_obj;
	}

	return 1;
}


sub add_host {
	my $self 		= shift;
	my %param		= @_;
	my $hostname 	= lc $param{hostname}; # nome del dns
	my $ip 			= $param{ip} 		|| []; # ip array pointer (facoltativo)
	my $ip_orig 	= $param{ip_orig} 	|| []; # ip array pointer (facoltativo)

	return undef if (!$hostname);

	if ( exists $self->{list}->{$hostname} ) {
		# print "$hostname: already present\n";
		# Se c'e' gia' riportiamo il record gia' presente
		return $self->{list}->{$hostname}; 
	} else {
		# Passiamo l'IP (query non ricorsiva) solo se l'host
		# fa parte del dominio che stiamo analizzando 
		# print "$hostname: not present found: ";
		my $host;

		my @temp;
		@temp = split('\.', $self->{domain});
		my $domcount = scalar @temp;
		@temp = split('\.', $hostname);
		my $hostcount = (scalar @temp)-1;

		if ( ($self->{domain} eq $hostname) || $self->{domain} && $hostname =~ /.*$self->{qdomain}$/ && $domcount == $hostcount ) {
# print "$hostname inside query /$self->{domain}, $domcount, $hostcount\n";
			$host = new Net::DNS::Check::Host(
				debug 	=> $self->{debug},
				host 	=> $hostname,
				config	=> $self->{config},
				ip   	=> $ip, 
				ip_orig	=> $ip_orig
			);
		} else {
# print "$hostname outside query /$self->{domain}, $domcount, $hostcount\n";
			$host = new Net::DNS::Check::Host(
				debug 	=> $self->{debug},
				config	=> $self->{config},
				host 	=> $hostname,
				ip_orig	=> $ip_orig
			);
		}

		$self->{list}->{$hostname} = $host;

		return $host;
	}
}


# Rimuove un host dalla HostsList. Servira'? Boh?
sub rm_host() {
	my $self = shift;
	my $hostname = shift;

	if (exists $self->{list}->{$hostname} ) {
		delete $self->{list}->{$hostname};
		return 1;
	}

	return undef;
}



# Riporta la lista degli oggetti Host contenuti nella HostsList (che giro
# di parole!!)
sub get_list() {
	my $self = shift;

	return keys %{$self->{list}};
}


# Riporta l'oggetto host specifico corrispondente all'hostname passato come
# parametro
sub get_host() {
	my $self = shift;
	my $hostname = shift;

	if (exists $self->{list}->{$hostname} ) {
		return $self->{list}->{$hostname};
	}

	return undef;
}

1;

__END__

=head1 NAME

Net::DNS::Check::HostsList - Class for maintaining a list of Net::DNS::Check::Host objects.

=head1 DESCRIPTION

This class is used for maintaing a list of L<Net::DNS::Check::Host> objects. At present L<Net::DNS::Check> maintains two kind of this lists (Net::DNS::Check::HostsList object) one for every authoritative nameservers and one general list used by all the authoritative nameservers.

The are several methods implemented by this class, but at present are all for internal use only and L<Net::DNS::Check> users don't need to directly create  Net::DNS::Check::HostsList object and call his methods.

Anyway a complete documentation of all methods will be released as soon as possible.

=head1 COPYRIGHT

Copyright (c) 2005 Lorenzo Luconi Trombacchi - IIT-CNR

All rights reserved.  This program is free software; you may redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<perl(1)>

=cut
