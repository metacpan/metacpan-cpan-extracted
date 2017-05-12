package Net::LibLO::Address;

################
#
# liblo: perl bindings
#
# Copyright 2005 Nicholas J. Humfrey <njh@aelius.com>
#

use Carp;
use Net::LibLO;
use strict;



sub new {
    my $class = shift;
    my $self = { address => undef };
    
    # Bless the hash into an object
    bless $self, $class;

    # 1 parameter = lo_addres, URL or port
    # 2 parameters = host and port
    if (scalar(@_)==1) {
    
    	# Is it a number ?
    	if (ref($_[0]) eq 'lo_address') {
  			my ($address) = @_;
			$self->{address} = $address;
			# Don't free memory we didn't allocate
			$self->{dontfree} = 1;
		} elsif ($_[0] =~ /^\d+$/) {
  			my ($port) = @_;
			$self->{address} = Net::LibLO::lo_address_new( 'localhost', $port );
		} else {
			my ($url) = @_;
			$self->{address} = Net::LibLO::lo_address_new_from_url( $url );
		}
    	
    } elsif (scalar(@_)==2) {
    	my ($host, $port) = @_;
		$self->{address} = Net::LibLO::lo_address_new( $host, $port );
    	
    } else {
    	croak( "Invalid number of parameters" );
    }
    
    # Was there an error ?
    if (!defined $self->{address} || $self->errno()) {
    	carp("Error creating lo_address");
    	undef $self;
    }
    
   	return $self;
}

sub errno {
	my $self=shift;

	return Net::LibLO::lo_address_errno( $self->{address} );
}

sub errstr {
	my $self=shift;

	return Net::LibLO::lo_address_errstr( $self->{address} );
}


sub get_hostname {
    my $self=shift;

	return Net::LibLO::lo_address_get_hostname( $self->{address} );
}

sub get_port {
    my $self=shift;

	return Net::LibLO::lo_address_get_port( $self->{address} );
}

sub get_url {
    my $self=shift;

	return Net::LibLO::lo_address_get_url( $self->{address} );
}


sub DESTROY {
    my $self=shift;
   
    if (defined $self->{address}) {
    	# Don't free memory we didn't allocate
		unless ($self->{dontfree}) {
    		Net::LibLO::lo_address_free( $self->{address} );
    	}
    	undef $self->{address};
    }
}


1;

__END__

=pod

=head1 NAME

Net::LibLO::Address

=head1 SYNOPSIS

  use Net::LibLO::Address;

  my $addr = new Net::LibLO::Address( 'localhost', 3340 );
  my $port = $addr->get_port();
  my $hostname = $addr->get_hostname();


=head1 DESCRIPTION

Net::LibLO::Address is a perl class which represents an address to send messages to

=over 4

=item B<new( hostname, port )>

Create a new OSC address, from a hostname and port

=item B<new( port )>

Create a new OSC address, from port. Localhost is assumed.

=item B<new( url )>

Create a new OSC address, from a URL

=item B<get_hostname( )>

Returns the hostname portion of an OSC address.

=item B<get_port( )>

Returns the port portion of an OSC address.

=item B<get_url( )>

Returns the URL for an OSC address.

=item B<errno( )>

Return the error number from the last failure.

=item B<errstr( )>

Return the error string from the last failure.

=back

=head1 AUTHOR

Nicholas J. Humfrey, njh@aelius.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 Nicholas J. Humfrey

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

=cut
