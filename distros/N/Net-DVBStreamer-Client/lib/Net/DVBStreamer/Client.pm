package Net::DVBStreamer::Client;

################
#
# DVBStreamer client module
#
# Nicholas J Humfrey
# njh@cpan.org
#

use strict;
use Carp;

use IO::Socket::INET;

use vars qw/$VERSION/;
our $VERSION="0.01";
our $AUTOLOAD;

my $BASE_PORT = 54197;
my $RESPONSE_PREFIX = 'DVBStreamer/';



sub new {
    my $class = shift;
    my ($host, $adaptor) = @_;

	# Create self
    my $self = {
    	'host' => $host || 'localhost',
    	'adaptor' => $adaptor || 0,
    	'server_version' => undef,
    	'errno' => 0,
    	'response' => '',
    	'sock' => undef,
    };
    bless $self, $class;


    # Create INET Socket
	$self->{'sock'} = new IO::Socket::INET(
		PeerAddr => $self->{'host'},
		PeerPort => $BASE_PORT + $self->{'adaptor'},
		Proto    => 'tcp') ||
	croak( "Error: failed to connect to DVBStreamer server '$self->{'host'}'." );


	# Read the response line and check it is a DVBStreamer server
	my $line = $self->{'sock'}->getline();
	croak "Error: remote server is not a DVBStreamer server.\n" if ($line !~ /^$RESPONSE_PREFIX/);	
	
	# Parse the rest of the response line
	my ($errno, $response) = $self->_parse_reponse_line( $line );
	croak "Error: remote server is returned error number $errno: $response.\n" if ($errno != 0);	
	carp "Warning: remote server is not ready: $response.\n" if ($response ne 'Ready');	
	
	return $self;
}


#
# Send a command a parse the response
#
sub send_command {
	my $self = shift;
	my ($command, @params) = @_;
	my @result = ();
	
	croak "Usage: send_command( $command, [@params] )" unless (defined $command);

	
	# Send the command
	$self->{'sock'}->print( join(' ', $command, @params)."\n" );
	
	# Read the result line by line
	while (my $line = $self->{'sock'}->getline()) {
		if ($line =~ /^$RESPONSE_PREFIX/) {
			my ($errno, $response) = $self->_parse_reponse_line( $line );
			if ($errno != 0) {
				# Error
				return undef;
			} elsif (scalar(@result)==1) {
				# Success - return the single line as scalar
				return $result[0];
			} elsif (scalar(@result)) {
				# Success - return the multiple lines as array
				return @result;
			} else {
				# Success - return the response message
				return $response;
			}
		} else {
			chomp( $line );
			push(@result, $line);
		}
	}


	# Never saw a response line
	$self->{'errno'} = -1;
	$self->{'response'} = "Failed to read response from server";
	return undef;
}

#
# Return the version number of the remote server
#
sub server_version {
	my $self = shift;
	return $self->{'server_version'};
}

#
# Returns the error number from the last command sent
#
sub errno {
	my $self = shift;
	return $self->{'errno'};
}

#
# Returns the response message from the last command sent
#
sub response {
	my $self = shift;
	return $self->{'response'};
}


#
# Authenticate with the remote server
#
sub authenticate {
	my $self = shift;
	return $self->send_command( 'auth', @_ );
}




#
# Internal method to parse a server response message
#
sub _parse_reponse_line {
	my $self = shift;
	my ($line) = @_;
	
	my ($version, $errno, $response) = ($line =~ /^$RESPONSE_PREFIX([\d\.]+)\/(\d+)\s(.*)\n$/);
	$self->{'server_version'} = $version;
	$self->{'errno'} = $errno;
	$self->{'response'} = $response;
	
	return ($errno, $response);
}


#
# Pass unhandled method calls on to send_command()
#
sub AUTOLOAD {
	my $self = shift;
	
	my $cmd = substr($AUTOLOAD, rindex($AUTOLOAD, '::')+2);
	return $self->send_command( $cmd, @_ );
}


#
# Close the socket before the object is destroyed
#
sub DESTROY {
    my $self=shift;
    
    if (defined $self->{'sock'}) {
    	$self->{'sock'}->close();
    	undef $self->{'sock'};
    }
}


1;

__END__

=pod

=head1 NAME

Net::DVBStreamer::Client

=head1 SYNOPSIS

  use Net::DVBStreamer::Client;

  my $dvbs = new Net::DVBStreamer::Client();


  $dvbs->close();


=head1 DESCRIPTION

Net::DVBStreamer::Client blah blah blah


=head2 METHODS

=over 4

=item $sap = new Net::DVBStreamer::Client( [$host], [$adaptor] )

The new() method is the constructor for the C<Net::DVBStreamer::Client> class.

If no host if specified, then 'localhost' is used.


=item $result = $dvbs->send_command( $command, [@params] )


=item $result = $dvbs->server_version()


=item $result = $dvbs->errno()


=item $result = $dvbs->response()


=item $result = $dvbs->authenticate()







=back

=head1 TODO

- Add timeout when waiting for response

- Detect server closing connection


=head1 SEE ALSO

L<IO::Socket::INET>, perl(1)

L<http://dvbstreamer.sourceforge.net/>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-net-dvbstreamer@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you will automatically
be notified of progress on your bug as I make changes.

=head1 AUTHOR

Nicholas J Humfrey, njh@cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 Nicholas J Humfrey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.005 or,
at your option, any later version of Perl 5 you may have available.

=cut
