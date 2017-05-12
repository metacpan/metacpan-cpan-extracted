package Net::RCON;
$Net::RCON::VERSION = '1.0';
use warnings;
use strict;

use IO::Socket::INET;

use constant {
	SERVERDATA_RESPONSE_VALUE => 0,
	SERVERDATA_AUTH_RESPONSE  => 2,
	SERVERDATA_EXECCOMMAND    => 2,
	SERVERDATA_AUTH           => 3
};

sub new {
	my ( $class, $args ) = @_;

	my $self = {
		host     => $args->{host},
		port     => $args->{port},
		password => $args->{password},
		id       => 0
	};

	$self->{sock} = IO::Socket::INET->new(
		PeerHost => $self->{host},
		PeerPort => $self->{port},
		Proto    => 'tcp'
	) or die "Unable to connect to the RCON server: $!\n";

	my $object = bless ( $self, $class );

	# Send a SERVERDATA_AUTH packet
	$object->_send_rcon( SERVERDATA_AUTH, $self->{password} );

	# Check is SERVERDATA_AUTH_RESPONSE came back as valid
	if( !$self->_recv_rcon( SERVERDATA_AUTH_RESPONSE ) ) {
		warn "Authentication to the RCON server failed";
		return undef;
	}

	return $object;
}

sub DESTROY {
	my ( $self ) = @_;

	$self->{sock}->close();
}

sub send {
	my ( $self, $command ) = @_;

	$self->_send_rcon( SERVERDATA_EXECCOMMAND, $command );
	my $response = $self->_recv_rcon( SERVERDATA_RESPONSE_VALUE );

	if( $response ) {
		return $response;
	} else {
		warn "RCON command $command failed. Unexpected response from the RCON server";
		return undef;
	}
}

sub _send_rcon {
	my ( $self, $type, $message ) = @_;

	# Build RCON packet
	my $data = pack( "VV", 1, $type ) . $message . pack("xx");

	# Prepend packet size
	$data = pack( "V", length( $data ) ).$data;

	return $self->{sock}->send( $data );
}

sub _recv_rcon {
	my ( $self, $type ) = @_;

	# Get response
	my $response = "";
	$self->{sock}->recv( $response, 4096 );

	# Unpack response packet
	my ( $size, $response_id, $response_type, $response_body ) = unpack( "VVVa*", $response );

	# Make sure the response id is what we sent
	if( $response_id == 1 && $response_type == $type && $size >= 10 && $size <= 4096 ) {
		return $response_body;
	} else {
		return undef;
	}
}
1;

# ABSTRACT: This module provides an interface to an RCON (remote console) server. RCON is typically implemented by game servers to allow servers admins to control their game servers without direct access to the machine the server is running on. This module is based on the spec detailed here, https://developer.valvesoftware.com/wiki/Source_RCON_Protocol

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::RCON - This module provides an interface to an RCON (remote console) server. RCON is typically implemented by game servers to allow servers admins to control their game servers without direct access to the machine the server is running on. This module is based on the spec detailed here, https://developer.valvesoftware.com/wiki/Source_RCON_Protocol

=head1 VERSION

version 1.0

=head1 SYNOPSIS

	use Net::RCON;

	my $rcon = Net::RCON->new({
		host => "127.0.0.1",
		port => "27015",
		password => "password"
	});

	print $rcon->send("users");

=head1 METHODS

=over

=item new()

Authenticates with the RCON server and, if successful, returns a new Net::RCON object. If unable to connect or authenticate it returns undef.

=over

=item host

IP address or hostname of the RCON server.

=item port

RCON port.

=item password

RCON password.

=back

=back

=over

=item send()

Sends an RCON command and returns the response. If there is no response it returns an empty string. If there was an error it returns undef.

=back

=head1 AUTHOR

Chris Handwerker <chris.handwerker@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Chris Handwerker.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
