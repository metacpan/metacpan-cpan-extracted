use 5.010;
use strict;
use warnings;
use utf8;

package Neo4j::Driver::Net::HTTP::REST;
# ABSTRACT: HTTP agent adapter for REST::Client
$Neo4j::Driver::Net::HTTP::REST::VERSION = '0.20';

use Carp qw(croak);
our @CARP_NOT = qw(Neo4j::Driver::Net::HTTP);
use Scalar::Util qw(blessed);
use Try::Tiny;

use JSON::MaybeXS 1.003003 qw();
use REST::Client 134;


our $JSON_CODER;
BEGIN { $JSON_CODER = sub {
	return JSON::MaybeXS->new(utf8 => 1, allow_nonref => 0);
}}

my $CONTENT_TYPE = 'application/json';


# Initialise the object. May or may not establish a network connection.
# May access driver config options using the config() method only.
sub new {
	my ($class, $driver) = @_;
	
	my $self = bless {
		json_coder => $JSON_CODER->(),
	}, $class;
	
	my $uri = $driver->{uri};
	if ($driver->{auth}) {
		croak "Only HTTP Basic Authentication is supported" if $driver->{auth}->{scheme} ne 'basic';
		$uri = $uri->clone;
		$uri->userinfo( $driver->{auth}->{principal} . ':' . $driver->{auth}->{credentials} );
	}
	
	my $client = REST::Client->new({
		host => "$uri",
		timeout => $driver->{http_timeout},
		follow => 1,
	});
	if ($uri->scheme eq 'https') {
		$client->setCa($driver->{tls_ca});
		croak "TLS CA file '$driver->{tls_ca}' doesn't exist (or is not a plain file)" if defined $driver->{tls_ca} && ! -f $driver->{tls_ca};  # REST::Client 273 doesn't support symbolic links
		croak "HTTPS does not support unencrypted communication; use HTTP" if defined $driver->{tls} && ! $driver->{tls};
	}
	else {
		croak "HTTP does not support encrypted communication; use HTTPS" if $driver->{tls};
	}
	$client->addHeader('Content-Type', $CONTENT_TYPE);
	$client->addHeader('X-Stream', 'true');
	$self->{client} = $client;
	
	$driver->{client_factory}->($self) if $driver->{client_factory};  # used for testing
	
	return $self;
}


# Return a JSON:XS-compatible coder object (for result parsers).
# The coder object must offer the methods encode() and decode().
# For boolean handling, encode() must accept the values \1 and \0
# and decode() should produce JSON::PP::true and JSON::PP::false.
sub json_coder {
	my ($self) = @_;
	return $self->{json_coder};
}


# Return server base URL as string or URI object (for ServerInfo).
# At least scheme, host, and port must be included.
sub uri {
	my ($self) = @_;
	return $self->{client}->getHost();
}


# Return the HTTP version (e. g. "HTTP/1.1") from the last response,
# or just "HTTP" if the version can't be determined.
# May block until the response headers have been fully received.
sub protocol {
	my ($self) = @_;
	
	if ( blessed $self->{client}->{_res} && $self->{client}->{_res}->can('protocol') ) {
		return $self->{client}->{_res}->protocol;
	}
	else {
		return 'HTTP';
	}
}


# Return the HTTP Date header from the last response.
# If the server doesn't have a clock, the header will be missing;
# in this case, the value returned must be either the empty string or
# (optionally) the current time in non-obsolete RFC5322:3.3 format.
# May block until the response headers have been fully received.
sub date_header {
	my ($self) = @_;
	return $self->{client}->responseHeader('Date') // '';
}


# Return a hashref with the following entries, representing
# headers and status of the last response:
# - content_type  (eg "application/json")
# - location      (URI reference)
# - status        (eg "404")
# - success       (truthy for 2xx status)
# - reason        (eg "Not Found")
# All of these must exist and be defined scalars.
# Unavailable values must use the empty string.
# Blocks until the response headers have been fully received.
sub http_header {
	my ($self) = @_;
	my $client = $self->{client};
	my $headers = {};
	$headers->{content_type} = $client->responseHeader('Content-Type') // '';
	$headers->{location} = $client->responseHeader('Location') // '';
	$headers->{status} = $client->responseCode() // '';
	$headers->{success} = $headers->{status} =~ m/^2[0-9][0-9]$/;
	if ( blessed $client->{_res} && $client->{_res}->can('message') ) {
		$headers->{reason} = $client->{_res}->message;
	}
	else {
		$headers->{reason} = '';
	}
	return $headers;
}


# Block until the response to the last network request has been fully
# received, then return the entire content of the response buffer.
# This method is idempotent; it does not empty the response buffer.
sub fetch_all {
	my ($self) = @_;
	
	return $self->{client}->responseContent();
}


# Start an HTTP request on the network and keep a reference to that
# request. May or may not block until the response has been received.
sub request {
	my ($self, $method, $url, $json, $accept) = @_;
	
	$self->{buffer} = undef;
	
	# The ordering of the $json hash's keys is significant: Neo4j
	# requires 'statements' to be the first member in the JSON object.
	# Luckily, in recent versions of Neo4j, it is also the only member.
	
	$json = $self->{json_coder}->encode($json) if $json;
	$self->{client}->request( $method, "$url", $json, {Accept => $accept} );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Neo4j::Driver::Net::HTTP::REST - HTTP agent adapter for REST::Client

=head1 VERSION

version 0.20

=head1 DESCRIPTION

The L<Neo4j::Driver::Net::HTTP::REST> package is not part of the
public L<Neo4j::Driver> API.

=head1 AUTHOR

Arne Johannessen <ajnn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016-2021 by Arne Johannessen.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
