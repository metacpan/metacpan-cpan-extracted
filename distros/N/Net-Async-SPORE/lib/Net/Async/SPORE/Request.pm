package Net::Async::SPORE::Request;
$Net::Async::SPORE::Request::VERSION = '0.003';
use strict;
use warnings;

=head1 NAME

Net::Async::SPORE::Definition - holds information about a SPORE definition

=head1 VERSION

Version 0.003

=head1 DESCRIPTION

=cut

use URI;
use URI::QueryParam;
use URI::Escape qw(uri_escape_utf8);

=head1 METHODS

=cut

=head2 new

Instantiate this request. Any named parameters will be
used to populate the environment.

=cut

sub new {
	my $class = shift;
	bless { env => { @_ } }, $class
}

=head2 env

Returns the environment hashref.

=cut

sub env { shift->{env} }

=head2 as_request

Returns an L<HTTP::Request> object representing this
environment.

=cut

sub as_request {
	my ($self) = @_;

	require HTTP::Request;
	my $uri = URI->new(
		$self->scheme . '://' . $self->server_name
	);

	my $path = $self->request_uri;

	# Apply our parameters
	my @param = @{$self->params};
	while(my ($k, $v) = splice @param, 0, 2) {
		unless($path =~ s/:$k/uri_escape_utf8($v)/ge) {
			$uri->query_param_append($k => $v);
		}
	}

	$uri->path($path);

	# Convert this into a request
	my $req = HTTP::Request->new(
		$self->request_method => $uri
	);
	$req->protocol('HTTP/1.1');
	$req->content($self->payload) if length $self->payload;

	my $env = $self->env;
	for my $k (grep /^HTTPS?_/, keys %$env) {
		my ($name) = $k =~ /^HTTPS?_(.*)/;
		$req->header($name => $env->{$k});
	}
	return $req;
}

=head1 METHODS - Environment accessors

These provide accessor/mutator support for the environment entries.

=head2 request_method

=cut

sub request_method {
	my ($self) = shift;
	return $self->env->{REQUEST_METHOD} unless @_;
	$self->env->{REQUEST_METHOD} = shift;
	return $self;
}

=head2 script_name

=cut

sub script_name {
	my ($self) = shift;
	return $self->env->{SCRIPT_NAME} unless @_;
	$self->env->{SCRIPT_NAME} = shift;
	return $self;
}

=head2 path_info

=cut

sub path_info {
	my ($self) = shift;
	return $self->env->{PATH_INFO} unless @_;
	$self->env->{PATH_INFO} = shift;
	return $self;
}

=head2 request_uri

=cut

sub request_uri {
	my ($self) = shift;
	return $self->env->{REQUEST_URI} unless @_;
	$self->env->{REQUEST_URI} = shift;
	return $self;
}

=head2 server_name

=cut

sub server_name {
	my ($self) = shift;
	return $self->env->{SERVER_NAME} unless @_;
	$self->env->{SERVER_NAME} = shift;
	return $self;
}

=head2 server_port

=cut

sub server_port {
	my ($self) = shift;
	return $self->env->{SERVER_PORT} unless @_;
	$self->env->{SERVER_PORT} = shift;
	return $self;
}

=head2 query_string

=cut

sub query_string {
	my ($self) = shift;
	return $self->env->{QUERY_STRING} unless @_;
	$self->env->{QUERY_STRING} = shift;
	return $self;
}

=head2 payload

=cut

sub payload {
	my ($self) = shift;
	return $self->env->{payload} unless @_;
	$self->env->{payload} = shift;
	return $self;
}

=head2 params

=cut

sub params {
	my ($self) = shift;
	return $self->env->{params} unless @_;
	$self->env->{params} = shift;
	return $self;
}

=head2 redirections

=cut

sub redirections {
	my ($self) = shift;
	return $self->env->{redirections} unless @_;
	$self->env->{redirections} = shift;
	return $self;
}

=head2 scheme

=cut

sub scheme {
	my ($self) = shift;
	return $self->env->{scheme} unless @_;
	$self->env->{scheme} = shift;
	return $self;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2012-2014. Licensed under the same terms as Perl itself.
