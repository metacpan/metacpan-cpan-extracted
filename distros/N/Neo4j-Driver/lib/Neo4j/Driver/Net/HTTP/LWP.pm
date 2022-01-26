use 5.010;
use strict;
use warnings;
use utf8;

package Neo4j::Driver::Net::HTTP::LWP;
# ABSTRACT: HTTP agent adapter for libwww-perl
$Neo4j::Driver::Net::HTTP::LWP::VERSION = '0.28';

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
			croak "tls_ca file '$trust_ca' can't be used: $!" if ! open(my $fh, '<', $trust_ca);
			$agent->ssl_opts( SSL_ca_file => $trust_ca );
		}
	}
	else {
		croak "HTTP does not support encrypted communication; use HTTPS" if $driver->config('encrypted');
	}
	
	return $self;
}


sub agent { shift->{agent} }

sub uri { shift->{uri_base} }

sub json_coder { shift->{json_coder} }

sub result_handlers { }

sub protocol { shift->{response}->protocol // 'HTTP' }

sub http_reason { shift->{response}->message // '' }

sub date_header { scalar shift->{response}->header('Date') // '' }


sub http_header {
	my $response = shift->{response};
	return {
		content_type => scalar $response->header('Content-Type') // '',
		location     => scalar $response->header('Location') // '',
		status       => $response->code // '',
		success      => $response->is_success,
	};
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
	my ($self, $method, $url, $json, $accept) = @_;
	
	$self->{buffer} = undef;
	
	$url = URI->new_abs( $url, $self->{uri_base} );
	$method = lc $method;
	if ($json) {
		$self->{response} = $self->{agent}->$method(
			$url,
			'Accept' => $accept,
			'Content' => $self->{json_coder}->encode($json),
			'Content-Type' => $CONTENT_TYPE,
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

Neo4j::Driver::Net::HTTP::LWP - HTTP agent adapter for libwww-perl

=head1 VERSION

version 0.28

=head1 SYNOPSIS

 use Neo4j::Driver::Net::HTTP::LWP;
 $driver->config( net_module => 'Neo4j::Driver::Net::HTTP::LWP' );

You can also extend this module through inheritance:

 use Local::MyProxy;
 $driver->config( net_module => 'Local::MyProxy' );
 
 package Local::MyProxy;
 use parent 'Neo4j::Driver::Net::HTTP::LWP';
 sub new {
   my $self = shift->SUPER::new(@_);
   $self->agent->proxy('http', 'http://proxy.example.net:8081/');
   return $self;
 }

=head1 DESCRIPTION

The L<Neo4j::Driver::Net::HTTP::LWP> package is an HTTP networking
module for L<Neo4j::Driver>, using L<LWP::UserAgent> to connect to
the Neo4j server via HTTP or HTTPS.

HTTPS connections require L<LWP::Protocol::https> to be installed.

=head1 METHODS

L<Neo4j::Driver::Net::HTTP::LWP> implements the following methods;
see L<Neo4j::Driver::Net/"API of an HTTP networking module">.

=over

=item * C<date_header>

=item * C<fetch_all>

=item * C<fetch_event>

=item * C<http_header>

=item * C<http_reason>

=item * C<json_coder>

=item * C<new>

=item * C<request>

=item * C<result_handlers>

=item * C<uri>

=back

In this module, C<request()> always blocks until the HTTP response
has been fully received. Therefore none of the other methods will
ever block.

In addition to the methods listed above,
L<Neo4j::Driver::Net::HTTP::LWP> implements the following methods.

=head2 agent

 use parent 'Neo4j::Driver::Net::HTTP::LWP';
 sub foo {
   my $self = shift;
   $ua = $self->agent;
   ...
 }

Returns the L<LWP::UserAgent> instance in use.
Meant to facilitate subclassing.

=head2 protocol

Returns the HTTP version of the last response (typically
C<"HTTP/1.1">). Since version 0.26, this method is no longer
required for a net module and using it is now discouraged.

=head1 BUGS

The C<fetch_event()> method has not yet been optimised.

=head1 SEE ALSO

L<Neo4j::Driver::Net>

=head1 AUTHOR

Arne Johannessen <ajnn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016-2022 by Arne Johannessen.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
