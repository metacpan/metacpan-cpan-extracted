# $Id: Client.pm 4435 2012-01-14 01:13:46Z augie $
# Provides an interface to communicate with PowerDNS::Control::Server which
# is used to control both the Authoritative and Recursive servers.

package PowerDNS::Control::Client;

use warnings;
use strict;

use IO::Socket;
use English;
use Carp;

=head1 NAME

PowerDNS::Control::Client - Provides an interface to control the PowerDNS daemon.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

	use PowerDNS::Control::Client;

        # Setting parameters and their default values.
	my $params = {	servers		=>	['localhost:988'],
			auth_cred	=>	'pa55word',
	};

	my $pdns = PowerDNS::Control::Client->new($params);

=head1 DESCRIPTION

	PowerDNS::Control::Client provides a client interface to interact
	with the PowerDNS::Control::Server server.

	It is maintained in tandem with PowerDNS::Control::Server and is
	intended to be used with that code; it also serves as a point of
	reference for anyone who wishes to create their own client code.

	The methods described below are based on those available in the
	PowerDNS::Control::Server module which are in turn based on the
	pdns_control and rec_control programs. Documentation for these 
	programs can be found at:

        http://docs.powerdns.com/

        Note: All the commands may not be supported in this module, but the list of
        supported commands is listed in the Methods section below. Methods that begin
        with 'auth' control the Authoritative PowerDNS Server and methods that begin
        with 'rec' control the Recursive PowerDNS Server.


=head1 METHODS

=head2 new(\%params)

	my $params = {	servers		=>	['localhost:988'],
			auth_cred	=>	'pa55word',
	};

	my $pdns = PowerDNS::Control::Client->new($params);

	Creates a new PowerDNS::Control::Client object.

=over 4

=item servers

A list of servers and ports to connect to. Default is 'localhost:988'.

=item auth_cred

The authentication credentials the client should provide when the server
asks for authentication.

=back

=cut

sub new
{
	my $class = shift;
	my $params= shift;
	my $self  = {};

	$OUTPUT_AUTOFLUSH = 1;

        bless $self , ref $class || $class;

	$self->{'servers'} = defined $params->{'servers'} ? $params->{'servers'} : ['localhost:988'];
	$self->{'auth_cred'} = defined $params->{'auth_cred'} ? $params->{'auth_cred'} : undef;

	return $self;
}

=head2 tell($command_string)

Internal method.
Expects a scalar command string to send to all of the servers
in the 'servers' param; i.e. tell the servers what to do.
Returns 0 on success and an Error Message if there was a problem.

=cut

sub tell
{
	my $self = shift;
	my $command = shift;
	my $errmsg = '';

	for my $server ( @{ $self->{'servers'} } )
	{
		# Try and connect to the server.
		my $conn = $self->connect(\$server);

		if ( ! defined $conn )
		{
			$errmsg .= "Could not connect to server ($server), trying next server if there is one.\n";
			next;
		}

		# Tell the server what to do.
		print $conn "$command\n";

		# Check what the server returned for errors.
		my $line = <$conn>;
		chomp $line;

		if ( $line =~ /^-ERR/ )
		{
			$errmsg .= "Command ($command) on server ($server) failed: $line\n";
		}

		# Tell the server we are done sending data.
		print $conn "quit\n";
	}
	
	return $errmsg ? $errmsg : 0 ;
}

=head2 connect(\$server)

Internal method.
Connects to a server and handle authentication if need be.
Expects a scalar reference to a single server to connect to.
Returns a socket object that can be used to communicate with 
the server or undef if there was a problem.

=cut

sub connect
{
	my $self = shift;
	my $server = shift;

	my $sock = new IO::Socket::INET (
		PeerAddr => $$server,
		Proto    => 'tcp'); 
	
	if ( ! $sock )
	{
		carp "Could not connect to $$server : $!";
		return undef;
	}

	my $line = <$sock>;
	chomp $line;

	# Check to see if we need to provide authentication.
	if ( $line eq '+OK ready for authentication' )
	{
		print $sock "AUTH $self->{'auth_cred'}\n";

		$line = <$sock>;
		chomp $line;
		# Check if we were authenticated.
		if ( ! $line eq '+OK Auth sucessful' )
		{
			carp "Authentication failed\n";
			return undef;
		}
	}
	elsif ($line !~ /^\+OK Welcome/ ) #check that we got the proper banner.
	{
		carp "Did not receive proper banner from server; got '$line' instead.\n";
		return undef;
	}

	return $sock;
}

=head2 auth_retrieve($domain)

Tells the Authoritative PowerDNS Server to retrieve a domain.
Expects a scalar domain name.
Returns 0 on success, error message otherwise.

=cut

sub auth_retrieve
{
	my $self = shift;
	my $domain = shift;
	return $self->tell("auth_retrieve $domain");
}

=head2 auth_wipe_cache($domain)

Tells the Authoritative PowerDNS server to wipe $domain out of its cache.
Expects a scalar domain name.
Returns 0 on success, error message otherwise.

=cut

sub auth_wipe_cache
{
	my $self = shift;
	my $domain = shift;
	return $self->tell("auth_wipe_cache $domain");
}

=head2 rec_wipe_cache($domain)

Tells the Recursive PowerDNS server to wipe $domain out of its cache.
Expects a scalar domain name.
Returns 0 on success, error message otherwise.

=cut

sub rec_wipe_cache
{
	my $self = shift;
	my $domain = shift;
	return $self->tell("rec_wipe_cache $domain");
}

=head2 rec_ping

Asks the server if the recursor is running.
Expects nothing.
Returns 0 on success, error message otherwise.

=cut

sub rec_ping
{
	my $self = shift;
	my $domain = shift;
	return $self->tell("rec_ping");
}

=head2 auth_ping

Asks the server if the authoritative server is running.
Expects nothing.
Returns 0 on success, error message otherwise.

=cut

sub auth_ping
{
	my $self = shift;
	my $domain = shift;
	return $self->tell("auth_ping");
}

=head1 AUTHOR

Augie Schwer, C<< <augie at cpan.org> >>

http://www.schwer.us

=head1 BUGS

Please report any bugs or feature requests to
C<bug-powerdns-control-client at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PowerDNS-Control-Client>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PowerDNS::Control::Client

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/PowerDNS-Control-Client>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/PowerDNS-Control-Client>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=PowerDNS-Control-Client>

=item * Search CPAN

L<http://search.cpan.org/dist/PowerDNS-Control-Client>

=back

=head1 ACKNOWLEDGEMENTS

I would like to thank Sonic.net for allowing me to release this to the public.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Augie Schwer, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 VERSION

        0.03
        $Id: Client.pm 4435 2012-01-14 01:13:46Z augie $

=cut

1; # End of PowerDNS::Control::Client
