package PayProp::API::Public::Client::Role::Request;

use strict;
use warnings;

use Mouse::Role;
with qw/ PayProp::API::Public::Client::Role::Attribute::UA /;

use Mojo::URL;
use PayProp::API::Public::Client::Exception::Connection;

=head1 NAME

	PayProp::API::Public::Client::Role::Request - Role to encapsulate async requests.

=head1 SYNOPSIS

	package Module::Requiring::Requests;
	with qw/ PayProp::API::Public::Client::Role::Request /;

	...;

	sub query_params { [qw/ ... /] }

	__PACKAGE__->meta->make_immutable;

	my $Module = Module::Requiring::Requests->new( url => 'https://mock.com' );
	my $Promise = $Module
		->get_req_p({ params => {}, headers => {} })
		->then(sub {
			my ( $Transaction, ... ) = @_;
			...;
		})
		->wait
	;

=head1 DESCRIPTION

Define methods to make async requests via C<Mojo::UserAgent> and return C<Mojo::Promise>.

=cut

requires qw/ _query_params /;

has url => (
	is => 'rw',
	isa => 'Str',
	default => sub { die 'you must override default url value' }
);

=head2 get_req_p

Perform GET request and return C<Mojo::Promise>.
See L<https://docs.mojolicious.org/Mojo/UserAgent#get_p> for returned values.

	$self
		->get_req_p({
			params => {},
			headers => {},
		})
		->then( sub {
			my ( $Transaction, ... ) = @_;
			...;
		} )
		->wait
	;

=cut

sub get_req_p { shift->_handle_request( 'get_p', @_ ) }

=head2 post_req_p

Perform POST request and return C<Mojo::Promise>.
See L<https://docs.mojolicious.org/Mojo/UserAgent#post_p> for returned values.

	$self
		->post_req_p({
			params => {},
			headers => {},
			content => { json => { ... } },
		})
		->then( sub {
			my ( $Transaction, ... ) = @_;
			...;
		} )
		->wait
	;

=cut

sub put_req_p { shift->_handle_request( 'put_p', @_ ) }
sub post_req_p { shift->_handle_request( 'post_p', @_ ) }

sub _handle_request {
	my ( $self, $http_verb, $args ) = @_;

	$args //= {};
	my $params = $args->{params} // {};
	my $content = $args->{content} // {};
	my $headers = $args->{headers} // {};

	return
		$self->ua->$http_verb(
			$self->_build_url( $params ),
			$headers,
			( ref $content ? $content->%* : $content ),
		)
		->catch( sub {
			my ( $error ) = @_;
			PayProp::API::Public::Client::Exception::Connection->throw("$error");
		} )
	;
}

sub _build_url {
	my ( $self, $params ) = @_;

	$params //= {};
	my $path_params = delete $params->{path_params} // {};

	my $URL = Mojo::URL->new( $self->url . ( $path_params->%* ? '/' : '' ) ); # trailing slash preserves "route path"

	$URL->path( join( '/', map { $path_params->{ $_ } } ( grep { exists $path_params->{ $_ } } $self->_path_params->@* ) ) )
		if $path_params->%*
	;

	return $URL
		->query({ map { $_ => $params->{ $_ } } ( grep { exists $params->{ $_ } } $self->_query_params->@* ) })
		->to_string
	;
}

1;
