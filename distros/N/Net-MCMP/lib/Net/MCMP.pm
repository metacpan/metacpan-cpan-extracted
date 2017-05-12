package Net::MCMP;

use strict;
use warnings;

use HTTP::Request;
use LWP::UserAgent;

our $VERSION = '0.08';

sub new {
	my ( $class, $ref ) = @_;

	unless ( exists $ref->{uri} ) {
		die 'missing uri';
	}

	$ref->{uri} =~ s/\s+//g;

	my $self = { _uri => $ref->{uri} };

	if ( exists $ref->{debug} && $ref->{debug} ) {
		$self->{_debug} = 1;
	}

	bless $self, $class;
	return $self;
}

sub uri {
	return $_[0]->{_uri};
}

sub debug {
	return ($_[0]->{_debug} || $ENV{MCMP_TRACE} || undef);
}

use constant DEFAULT_MCMP_CONFIG => {
	Balancer            => 'mycluster',
	StickySession       => 'yes',
	StickySessionCookie => 'JSESSIONID',
	StickySessionPath   => 'jsessionid',
	StickySessionRemove => 'no',
	StickySessionForce  => 'yes',
	WaitWorker          => 0,
	MaxAttempts         => 1,
	JvmRoute            => undef,
	Domain              => 'mycluster',
	Host                => 'localhost',
	Port                => '8009',
	Type                => 'ajp',
	FlushPackets        => 'off',
	FlushWait           => 1,
	Ping                => 10,
	Smax                => undef,
	Ttl                 => 60,
	Timeout             => 0,
	Context             => undef,
	Alias               => undef,
};

# FROM: https://community.jboss.org/wiki/Mod-Clusternodebalancer
#
# JvmRoute: See http://wiki.jboss.org/wiki/Mod-ClusterManagementProtocol Default: Mandatory
# Domain: See http://wiki.jboss.org/wiki/Mod-ClusterManagementProtocol Default: "" empty string
# Host: See http://wiki.jboss.org/wiki/Mod-ClusterManagementProtocol Default: "localhost"
# Port: See http://wiki.jboss.org/wiki/Mod-ClusterManagementProtocol Default: "8009"
# Type: See http://wiki.jboss.org/wiki/Mod-ClusterManagementProtocol Default: "ajp"
# flushpackets: Tell how to flush the packets. On: Send immediately, Auto wait for flushwait time before sending, Off don't flush. Default: "Off"
# flushwait: Time to wait before flushing. Value in milliseconds. Default: 10
# ping: Time to wait for a pong answer to a ping. 0 means we don't try to ping before sending. Value in secondes Default: 10
# smax: soft max inactive connection over that limit after ttl are closed. Default depends on the mpm configuration (See below for more information)
# ttl: max time in seconds to life for connection above smax. Default 60 seconds.
# Timeout: Max time httpd will wait for the backend connection. Default 0 no timeout value in seconds.

# Balancer: Name of the balancer. max size: 40 Default: "mycluster"
# StickySession: Yes: use JVMRoute to stick a request to a node, No: ignore JVMRoute. Default: "Yes"
# StickySessionCookie: Name of the cookie containing the sessionid. Max size: 30 Default: "JSESSIONID"
# StickySessionPath: Name of the parametre containing the sessionid. Max size: 30. Default: "jsessionid"
# StickySessionRemove: Yes: remove the sessionid (cookie or parameter) when the request can't be routed to the right node. No: send it anyway. Default: "No"
# StickySessionForce: Yes: Return an error if the request can't be routed according to JVMRoute, No: Route it to another node. Default: "Yes"
# WaitWorker: value in seconds: time to wait for an available worker. Default: "0" no wait.
# Maxattempts: value: number of attemps to send the request to the backend server. Default: "1".

sub config {
	my ( $self, $ref ) = @_;

	unless ( ref $ref eq 'HASH' ) {
		die 'passed reference must be a HASH reference';
	}

	foreach my $key ( keys %{ $self->DEFAULT_MCMP_CONFIG } ) {
		unless ( defined $ref->{$key} ) {
			$ref->{$key} = $self->DEFAULT_MCMP_CONFIG->{$key};
		}
	}

	unless ( $ref->{JvmRoute} ) {
		die 'JvmRoute is missing';
	}
	
	if ( length $ref->{JvmRoute} > 80 ) {
		die 'JvmRoute cannot exceed 80 characters';
	}

	if ( length $ref->{Balancer} > 40 ) {
		die 'Balancer cannot exceed 40 characters';
	}

	if ( $ref->{StickySession} !~ /^(yes|no)$/i ) {
		die 'invalid StickySession value, should be yes|no';
	}

	if ( length $ref->{StickySessionCookie} > 30 ) {
		die 'StickySessionCookie cannot exceed 30 characters';
	}

	if ( length $ref->{StickySessionPath} > 30 ) {
		die 'StickySessionCookie cannot exceed 30 characters';
	}

	if ( $ref->{StickySessionRemove} !~ /^(yes|no)$/i ) {
		die 'invalid StickySessionRemove value, should be yes|no';
	}

	if ( $ref->{StickySessionForce} !~ /^(yes|no)$/i ) {
		die 'invalid StickySessionForce value, should be yes|no';
	}

	if ( $ref->{WaitWorker} < 0 ) {
		die 'WaitWorker cannot be less than 0';
	}

	if ( $ref->{MaxAttempts} < 1 ) {
		die 'MaxAttempts cannot be less than 1';
	}

	if ( length $ref->{Domain} > 20 ) {
		die 'Domain cannot exceed 20 characters';
	}

	if ( length $ref->{Host} > 64 ) {
		die 'Host cannot exceed 64 characters';
	}

	if ( length $ref->{Port} < 0 || length $ref->{Port} > 65545 ) {
		die 'Port must be between 0 and 65545';
	}

	if ( $ref->{Type} !~ /^(https|http|ajp)$/i ) {
		die 'invalid Type value, should be https|http|ajp';
	}

	if ( $ref->{FlushPackets} !~ /^(on|off|auto)$/i ) {
		die 'invalid FlushPackets value, should be on|off|auto';
	}

	if ( $ref->{FlushWait} < 0 ) {
		die 'FlushWait cannot be less than 0';
	}

	if ( $ref->{Ping} < 0 ) {
		die 'Ping cannot be less than 0';
	}

	if ( $ref->{Ttl} < 0 ) {
		die 'Ttl cannot be less than 0';
	}

	if ( $ref->{Timeout} < 0 ) {
		die 'Timeout cannot be less than 0';
	}

	return $self->request( 'CONFIG', $self->uri, $ref );

}

use constant DEFAULT_MCMP_APP => {
	JvmRoute => undef,
	Context  => undef,
	Alias    => undef,
};

sub enable_app {
	shift->_app( 'ENABLE-APP', @_ );
}

sub disable_app {
	shift->_app( 'DISABLE-APP', @_ );
}

sub stop_app {
	shift->_app( 'STOP-APP', @_ );
}

sub remove_app {
	shift->_app( 'REMOVE-APP', @_ );
}

sub _app {
	my ( $self, $method, $ref ) = @_;

	unless ( ref $ref eq 'HASH' ) {
		die 'passed reference must be a HASH reference';
	}

	foreach my $key ( keys %{ $self->DEFAULT_MCMP_APP } ) {
		unless ( defined $ref->{$key} ) {
			$ref->{$key} = $self->DEFAULT_MCMP_APP->{$key};
		}
	}

	unless ( $ref->{JvmRoute} ) {
		die 'JvmRoute is missing';
	}

	unless ( $ref->{Context} ) {
		die 'Context is missing';
	}

	unless ( $ref->{Alias} ) {
		die 'Alias is missing';
	}

	return $self->request( $method, $self->uri, $ref );
}

sub enable_route {
	shift->_route( 'ENABLE-APP', @_ );
}

sub disable_route {
	shift->_route( 'DISABLE-APP', @_ );
}

sub stop_route {
	shift->_route( 'STOP-APP', @_ );
}

sub remove_route {
	shift->_route( 'REMOVE-APP', @_ );
}

sub _route {
	my ( $self, $method, $ref ) = @_;

	unless ( ref $ref eq 'HASH' ) {
		die 'passed reference must be a HASH reference';
	}

	unless ( $ref->{JvmRoute} ) {
		die 'JvmRoute is missing';
	}

	return $self->request( $method, $self->uri . '/*', $ref );
}

sub status {
	my ( $self, $ref ) = @_;

	unless ( ref $ref eq 'HASH' ) {
		die 'passed reference must be a HASH reference';
	}

	unless ( $ref->{JvmRoute} ) {
		die 'JvmRoute is missing';
	}

	unless ( $ref->{Load} ) {
		die 'Load is missing';
	}
	return $self->request( 'STATUS', $self->uri, $ref );
}

sub ping {
	my ( $self, $ref ) = @_;

	unless ( ref $ref eq 'HASH' ) {
		die 'passed reference must be a HASH reference';
	}

	unless ( $ref->{JvmRoute} ) {
		die 'JvmRoute is missing';
	}

	return $self->request( 'PING', $self->uri, $ref );
}

sub dump {
	my ($self) = @_;

	return $self->request( 'DUMP', $self->uri );
}

sub info {
	my ($self) = @_;

	return $self->request( 'INFO', $self->uri );
}

sub request {
	my ( $self, $method, $uri, $params ) = @_;

	unless ( exists $self->{_ua} ) {
		$self->{_ua} = LWP::UserAgent->new;
	}

	my $ua   = $self->{_ua};
	my $path = URI->new();
	if ( defined $params ) {
		foreach my $key ( qw/Context Alias/ ) {
			next unless defined $params->{$key};
			$params->{$key} =~ s/\s+//g;
		}
		
		$path->query_form($params);
	}

	if ( $self->debug ) {
		if ( $path->query ) {
			warn "Making a $method request to $uri with these params: "
			  . $path->query;
		}
		else {
			warn "Making a $method request to $uri";
		}

	}
	my $req = HTTP::Request->new( $method, $uri, undef, $path->query || undef );
	$req->header( 'Accept' => 'text/plain' );
	$req->header( 'Content-Type' => 'application/x-www-form-urlencoded' );
	my $response = $ua->request($req);

	if ( $response->is_success ) {
		if ( $response->content ) {

			if ( $self->debug ) {
				warn "RESPONSE: " . $response->content;
			}

			if ( $method eq 'DUMP' ) {

				# dump parser
				return $response->content;
			}
			elsif ( $method eq 'INFO' ) {

				# info parser
				return $response->content;
			}
			else {
				my $resp_uri        = URI->new( '?' . $response->content );
				my %parsed_response = $resp_uri->query_form;

				# fix return inconsistencies
				foreach my $key ( keys %parsed_response ) {
					if ( $key =~ /jvmroute/i ) {
						$parsed_response{JvmRoute} = $parsed_response{$key};
						delete $parsed_response{$key};
					}
				}

				return \%parsed_response;

			}
		}
		else {
			return 1;
		}
	}
	else {
		$self->error( $response->header('mess') );
		if ( $self->debug ) {
			if ( $path->query ) {
				warn "CURL for debugging: curl -X $method '$uri' -d '"
				  . $path->query . "'";
			}
			else {
				warn "CURL for debugging: curl -X $method '$uri'";
			}

		}
		return undef;
	}
}

sub has_error {
	return exists $_[0]->{_error};
}

sub error {
	my ( $self, $error ) = @_;
	if ($error) {
		if ( $self->debug ) {
			warn "FAILURE: $error";
		}
		$self->{_error} = $error;
	}
	else {
		return $self->{_error} || undef;
	}
}

1;

__END__

=head1 NAME

Net::MCMP - Mod Cluster Management Protocol client

=head1 SYNOPSIS

    use Net::MCMP;
    my $mcmp = Net::MCMP->new( { uri => 'http://127.0.0.1:6666' } );
    $mcmp->config(
        {
            JvmRoute => 'MyJVMRoute',
            Host     => 'localhost',
            Port     => '3000',
            Type     => 'http',
            Context  => '/myContext',
            Alias    => 'Vhost',
        }
    );

    $mcmp->enable_app(
        {
            JvmRoute => 'MyJVMRoute',
            Alias    => 'Vhost',
            Context  => '/myContext'
        }
    );

    $mcmp->remove_app(
        {
            JvmRoute => 'MyJVMRoute',
            Alias    => 'SomeHost',
            Context  => '/cluster'
        }
    );

    $mcmp->remove_route(
        {
            JvmRoute => 'MyJVMRoute',
        }
    );

    $mcmp->status(
        {
            JvmRoute => 'MyJVMRoute',
            Load     => 55,
        }
    );

    $mcmp->disable_app(
        {
            JvmRoute => 'MyJVMRoute',
            Alias    => 'SomeHost',
            Context  => '/cluster'
        }
    );

    $mcmp->stop_app(
        {
            JvmRoute => 'MyJVMRoute',
            Alias    => 'SomeHost',
            Context  => '/cluster'
        }
    );

=head1 DESCRIPTION

I<Net::MCMP> is an implementation of the Mod Cluster
Management Protocol (MCMP). I<Net::MCMP> uses I<LWP::UserAgent> and I<HTTP::Request> for its
communication with mod_cluster. 

MCMP stands for Mod Cluster Management Protocol and is a method of
adding proxy settings dynamically, as appose to
creating static apache rules. 

Official documentation of MCMP can be found here: https://community.jboss.org/wiki/Mod-ClusterManagementProtocol

=head1 USAGE

=head2 Net::MCMP->new(\%args)

Creates a new MCMP object, and returns a I<Net::MCMP> object 
representing that connection.

	my $mcmp = Net::MCMP({ uri => 'http://127.0.0.1:6666', debug => 0});

I<%args> can contain:

=over 4

=item * uri (required)

The URI of a mod_cluster handler.

=item * debug (optional)

If set to a true value, debugging messages will be printed out
for every request and respons to mod_cluster.

=back


=head2 $mcmp->config(\%conig)

Sends configuration for a node or set of nodes

If a low-level protocol error or unexpected local error occurs,
we die with an error message.

	$mcmp->config({
		JvmRoute            => "MyAppNode1",
		Balancer            => 'MyApp',
		Domain              => 'MyApp',
		StickySessionCookie => 'myapp_session',
		StickySessionPath   => 'myapp',
		Host                => '192.168.0.101',
		Port                => '3000',
		Type                => 'http',
		Context             => '/myapp',
		Alias               => "MyApp",	
	});

I<%config> can contain: 

=over 4

=item * JvmRoute (required)

Name of the node.

=item * Alias (required)

List the virtual hosts. ex. localhost,localhost2.

=item * Host (optional)

IP address (or hostname) where the node is going to receive requests from httpd (Defaults to localhost)

=item * Port (optional)

Port on which the node except to receive requests (Defaults to 8009)

=item * Type (optional)

http/https/ajp The protocol to use between httpd and application to process requests (Defaults to ajp)

=item * Domain (optional)

domain corresponding to the node (ie LB group), (Defaults to mycluster)

=item * Balancer (optional)

is the name of the balancer in httpd (Defaults to mycluster)

=item * StickySession (optional)

stick a request to a node "yes"/"no" (Defaults to "yes")

=item * StickySessionCookie (optional)

Name of the cookie containing the sessionid (Defaults to "JSESSIONID")

=item * StickySessionPath (optional)

Name of the parameter containing the sessionid (Defaults to "jsessionid")

=item * StickySessionRemove (optional)

remove the sessionid (cookie or parameter) when the request can't be routed to the right node "yes"/"no" (Defaults to "no")

=item * StickySessionForce (optional)

Return an error if the request can't be routed according to JVMRoute (Defaults to "yes")

=item * WaitWorker (optional)

value in seconds: time to wait for an available worker. (Defaults to 0, no wait)

=item * MaxAttempts (optional)

number of attemps to send the request to the backend server (Defaults to 1)

=item * FlushPackets (optional)

Tell how to flush the packets. On: Send immediately, Auto wait for flushwait time before sending, Off don't flush. (Defaults to "off")

=item * FlushWait (optional)

Time to wait before flushing. Value in seconds (Defaults to 10)

=item * Ping (optional)

Time to wait for a pong answer to a ping. 0 means we don't try to ping before sending. Value in secondes (Defaults to 10)

=item * Smax (optional)

soft max inactive connection over that limit after ttl are closed. Default depends on the mpm configuration

=item * Ttl (optional)

max time in seconds to life for connection above smax. (Defaults to 60)

=item * Timeout (optional)

Max time httpd will wait for the backend connection. (Defaults to 0, no timeout)

=item * Context (optional)

List of the contexts that node supports. ex. /myapp,/ourapp.

=back

=head2 $mcmp->ping(\%ping)

Request a ping to httpd or node

	my $ping_resp = $mcmp->ping(
		{
			JvmRoute => 'MyAppNode1',
		}
	);
	
	# SAMPLE $ping_response
	#$VAR1 = {
	#    'id' => '-540134453',
	#    'JvmRoute' => 'MyJVMRoute',
	#    'State' => 'OK',
	#    'Type' => 'PING-RSP'
	#};
		
=head2 $mcmp->enable_app(\%enable_app)

Sends request to enable newly configured Node

	$mcmp->enable_app(
		{
			JvmRoute => 'MyAppNode1',
			Alias    => 'MyApp',
			Context  => '/myapp'
		}
	);
	
=head2 $mcmp->status(\%status)

Sends load metrics for configured node, number from 1-100

	my $status_response = $mcmp->status(
		{
			JvmRoute => 'MyAppNode1',
			Load    => 99,
		}
	);

	# SAMPLE $status_response
	# $VAR1 = {
	#     'State' => 'OK',
	#     'JvmRoute' => 'MyJVMRoute',
	#     'id' => '-297586570',
	#     'Type' => 'STATUS-RSP'
	# };
	
	
=head2 $mcmp->disable_app(\%disable_app)

Apache should not create new session for this webapp, but still continue serving existing session on this node

	$mcmp->disable_app(
		{
			JvmRoute => 'MyAppNode1',
			Alias    => 'MyApp',
			Context  => '/myapp'
		}
	);

=head2 $mcmp->stop_app(\%stop_app)

New requests for this webapp should not be sent to this node.

	$mcmp->stop_app(
		{
			JvmRoute => 'MyAppNode1',
			Alias    => 'MyApp',
			Context  => '/myapp'
		}
	);

=head2 $mcmp->remove_app(\%remove_app)

Remove registered context from registered node.

	$mcmp->remove_app(
		{
			JvmRoute => 'MyAppNode1',
			Alias    => 'MyApp',
			Context  => '/myapp'
		}
	);
	
=head2 $mcmp->enable_route(\%enable_route)

Sends request to enable all of the registered contexts in a selected node

	$mcmp->enable_route(
		{
			JvmRoute => 'MyAppNode1',
		}
	);

=head2 $mcmp->disable_route(\%disable_route)

Sends request to disable all of the registered contexts in a selected node

	$mcmp->disable_route(
		{
			JvmRoute => 'MyAppNode1',
		}
	);

=head2 $mcmp->stop_route(\%stop_route)

Sends request to stop all of the registered contexts in a selected node

	$mcmp->stop_route(
		{
			JvmRoute => 'MyAppNode1',
		}
	);
	
=head2 $mcmp->remove_route(\%remove_route)

Sends request to remove registered node

	$mcmp->remove_route(
		{
			JvmRoute => 'MyAppNode1',
		}
	);
	
=head2 $mcmp->debug()

Sends request to receive unparsed DEBUG content of mod_cluster

	my $debug_response = $mcmp->debug();

=head2 $mcmp->info()

Sends request to receive unparsed INFO content of mod_cluster

	my $info_response = $mcmp->info();

=head2 $mcmp->has_errors()

Checks if a remote call returned any errors

	my $has_errors = $mcmp->has_errors();

=head2 $mcmp->error()

Error string that was returned from mod_cluster handler.

	my $error_string = $mcmp->error();
		
=head1 SUPPORT

For samples/tutorials, take a look at provided tests in F<t/> in
the distribution directory.

Please report all bugs via github at
https://github.com/winfinit/Net-MCMP

=head1 AUTHOR

Roman Jurkov (winfinit) E<lt>winfinit@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2014 the Net::MCMP L</AUTHORS> as listed above.

=head1 LICENSE

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
