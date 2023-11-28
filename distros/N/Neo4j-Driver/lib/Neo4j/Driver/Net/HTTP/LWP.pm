use 5.010;
use strict;
use warnings;
use utf8;

package Neo4j::Driver::Net::HTTP::LWP;
# ABSTRACT: HTTP network adapter for libwww-perl
$Neo4j::Driver::Net::HTTP::LWP::VERSION = '0.41';

use Carp qw(croak);
our @CARP_NOT = qw(Neo4j::Driver::Net::HTTP);

use JSON::MaybeXS 1.003003 qw();
use LWP::UserAgent 6.04 qw();
use URI 1.31;

my $CONTENT_TYPE = 'application/json';


sub new {
	my ($class, $driver) = @_;
	
	my $self = bless {
		json_coder => JSON::MaybeXS->new(utf8 => 1, allow_nonref => 0),
	}, $class;
	
	my $uri = $driver->config('uri');
	if (my $auth = $driver->config('auth')) {
		croak "Only HTTP Basic Authentication is supported" if $auth->{scheme} ne 'basic';
		my $userid = $auth->{principal}   // '';
		my $passwd = $auth->{credentials} // '';
		my $userinfo = join ':', map {
			utf8::encode $_ if utf8::is_utf8 $_;  # uri_escape doesn't handle wide characters
			URI::Escape::uri_escape $_;
		} $userid, $passwd;
		$uri = $uri->clone;
		$uri->userinfo($userinfo);
	}
	$self->{uri_base} = $uri;
	
	my $version = $Neo4j::Driver::Net::HTTP::LWP::VERSION;
	my $agent = $self->{agent} = LWP::UserAgent->new(
		# User-Agent: Neo4j-Driver/0.21 libwww-perl/6.52
		agent => sprintf("Neo4j-Driver%s ", $version ? "/$version" : ""),
		timeout => $driver->config('timeout'),
	);
	$agent->default_headers->header( 'X-Stream' => 'true' );
	
	if ($uri->scheme eq 'https') {
		my $unencrypted = defined $driver->config('encrypted') && ! $driver->config('encrypted');
		croak "HTTPS does not support unencrypted communication; use HTTP" if $unencrypted;
		$agent->ssl_opts( verify_hostname => 1 );
		if (defined( my $trust_ca = $driver->config('trust_ca') )) {
			croak "trust_ca file '$trust_ca' can't be used: $!" if ! open(my $fh, '<', $trust_ca);
			$agent->ssl_opts( SSL_ca_file => $trust_ca );
		}
	}
	else {
		croak "HTTP does not support encrypted communication; use HTTPS" if $driver->config('encrypted');
	}
	
	return $self;
}


sub protocol {
	# uncoverable pod (see Deprecations.pod)
	my ($self) = @_;
	warnings::warnif deprecated => __PACKAGE__ . "->protocol() is deprecated";
	return $self->{response}->protocol // 'HTTP';
}


sub agent {
	# uncoverable pod (see Deprecations.pod)
	my ($self) = @_;
	warnings::warnif deprecated => __PACKAGE__ . "->agent() is deprecated; call ua() instead";
	return $self->{agent};
}


sub ua { shift->{agent} }

sub uri { shift->{uri_base} }

sub json_coder { shift->{json_coder} }

sub http_reason { shift->{response}->message // '' }

sub date_header { scalar shift->{response}->header('Date') // '' }


sub http_header {
	my $response = shift->{response};
	my $header = {
		content_type => scalar $response->header('Content-Type') // '',
		location     => scalar $response->header('Location') // '',
		status       => $response->code // '',
		success      => $response->is_success,
	};
	if ( ! $header->{success} && $response->header('Client-Warning') // '' eq 'Internal response' ) {
		$header->{content_type} = '';
		$header->{status}       = '';
	}
	return $header;
}


sub fetch_event {
	my ($self) = @_;
	$self->{buffer} = [grep { length } split m/\n|\x{1e}/, $self->fetch_all] unless defined $self->{buffer};
	return shift @{$self->{buffer}};
}


sub fetch_all {
	my ($self) = @_;
	return $self->{response}->content;
}


sub request {
	my ($self, $method, $url, $json, $accept, $mode) = @_;
	
	$self->{buffer} = undef;
	
	$url = URI->new_abs( $url, $self->{uri_base} );
	$method = lc $method;
	if ($json) {
		$self->{response} = $self->{agent}->$method(
			$url,
			'Accept' => $accept,
			'Content' => $self->{json_coder}->encode($json),
			'Content-Type' => $CONTENT_TYPE,
			$mode ? ('Access-Mode' => $mode) : ()
		);
	}
	else {
		$self->{response} = $self->{agent}->$method(
			$url,
			'Accept' => $accept,
		);
	}
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Neo4j::Driver::Net::HTTP::LWP - HTTP network adapter for libwww-perl

=head1 VERSION

version 0.41

=head1 SYNOPSIS

 use parent 'Neo4j::Driver::Plugin';
 
 sub register {
   my ($self, $manager) = @_;
   $manager->add_handler(
     http_adapter_factory => sub {
       my ($continue, $driver) = @_;
       my $adapter = Neo4j::Driver::Net::HTTP::LWP->new($driver);
       ...
       return $adapter;
     },
   );
 }

You can also extend this module through inheritance:

 use parent 'Neo4j::Driver::Net::HTTP::LWP';
 
 sub new {
   my $self = shift->SUPER::new(@_);
   $self->ua->proxy('http', 'http://proxy.example.net:8081/');
   return $self;
 }

=head1 DESCRIPTION

The L<Neo4j::Driver::Net::HTTP::LWP> package is an HTTP network
adapter for L<Neo4j::Driver>, using L<LWP::UserAgent> to connect to
the Neo4j server via HTTP or HTTPS.

HTTPS connections require L<LWP::Protocol::https> to be installed.

=head1 METHODS

L<Neo4j::Driver::Net::HTTP::LWP> implements the following methods;
see L<Neo4j::Driver::Plugin/"Network adapter API for HTTP">.

=over

=item * C<date_header>

=item * C<fetch_all>

=item * C<fetch_event>

=item * C<http_header>

=item * C<http_reason>

=item * C<json_coder>

=item * C<request>

=item * C<uri>

=back

In this module, C<request()> always blocks until the HTTP response
has been fully received. Therefore none of the other methods will
ever block.

In addition to the methods listed above,
L<Neo4j::Driver::Net::HTTP::LWP> implements the following methods.

=head2 new

 $adapter = Neo4j::Driver::Net::HTTP::LWP->new( $driver );

Creates a new L<Neo4j::Driver::Net::HTTP::LWP> adapter and
configures it using the given L<Neo4j::Driver>.

=head2 ua

 use parent 'Neo4j::Driver::Net::HTTP::LWP';
 sub foo {
   my $self = shift;
   $ua = $self->ua;
   ...
 }

Returns the L<LWP::UserAgent> instance in use.
Meant to facilitate reuse.

=head1 BUGS

The C<fetch_event()> method has not yet been optimised.

=head1 SEE ALSO

L<Neo4j::Driver::Net>

=head1 AUTHOR

Arne Johannessen <ajnn@cpan.org>

If you contact me by email, please make sure you include the word
"Perl" in your subject header to help beat the spam filters.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016-2023 by Arne Johannessen.

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 or (at your option) the same terms
as the Perl 5 programming language system itself.

=cut
