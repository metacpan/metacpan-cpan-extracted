package PayProp::API::Public::Client::Request::Tags;

use strict;
use warnings;

use Mouse;
with qw/ PayProp::API::Public::Client::Role::APIRequest /;

use PayProp::API::Public::Client::Response::Tag;


has '+url' => (
	default => sub {
		my ( $self ) = @_;
		return $self->abs_domain . '/api/agency/' . $self->api_version . '/tags';
	},
);

sub list_p {
	my ( $self, $args ) = @_;

	$args //= {};
	my $params = $args->{params};

	return $self
		->api_request_p({
			params => $params,
			handle_response_cb => sub { $self->_get_tags( @_ ) },
		})
	;
}

sub create_p {
	my ( $self, $args ) = @_;

	$args //= {};
	my $content = $args->{content};

	return $self
		->api_request_p({
			method => 'POST',
			content => { json => $content },
			handle_response_cb => sub { $self->_get_tags( @_ ) },
		})
	;
}

sub link_entities_p {
	my ( $self, $args ) = @_;

	$args //= {};
	my $content = $args->{content};
	my $path_params = $args->{path_params} // {};

	$path_params->{fragment} = 'entities';
	$self->ordered_path_params([qw/ fragment entity_type entity_id /]);

	return $self
		->api_request_p({
			method => 'POST',
			path_params => $path_params,
			content => { json => $content },
			handle_response_cb => sub { $self->_get_tags( @_ ) },
		})
	;
}

sub list_tagged_entities_p {
	my ( $self, $args ) = @_;

	$args //= {};
	my $params = $args->{params};
	my $path_params = $args->{path_params} // {};

	$path_params->{fragment} = 'entities';
	$self->ordered_path_params([qw/ external_id fragment /]);

	return $self
		->api_request_p({
			method => 'GET',
			params => $params,
			path_params => $path_params,
			handle_response_cb => sub { $self->_get_tags( @_ ) },
		})
	;
}

sub update_p {
	my ( $self, $args ) = @_;

	$args //= {};
	my $req_content = $args->{content};
	my $path_params = $args->{path_params} // {};

	$self->ordered_path_params([qw/ external_id /]);

	return $self
		->api_request_p({
			method => 'PUT',
			path_params => $path_params,
			content => { json => $req_content },
			handle_response_cb => sub { $self->_get_tags( @_ ) },
		})
	;
}

sub delete_p {
	my ( $self, $args ) = @_;

	$args //= {};
	my $path_params = $args->{path_params} // {};

	$self->ordered_path_params([qw/ external_id /]);

	return $self
		->api_request_p({
			method => 'DELETE',
			path_params => $path_params,
			handle_response_cb => sub { $self->_get_tags( @_ ) },
		})
	;
}

sub delete_entity_link_p {
	my ( $self, $args ) = @_;

	$args //= {};
	my $params = $args->{params};
	my $path_params = $args->{path_params} // {};

	$path_params->{fragment} = 'entities';
	$self->ordered_path_params([qw/ external_id fragment /]);

	return $self
		->api_request_p({
			params => $params,
			method => 'DELETE',
			path_params => $path_params,
			handle_response_cb => sub { $self->_get_tags( @_ ) },
		})
	;
}

sub _get_tags {
	my ( $self, $response_json ) = @_;

	return $response_json if $response_json->{message};

	my $want_array = ref $response_json->{items} ? 1 : 0;

	return PayProp::API::Public::Client::Response::Tag->new(
		id => $response_json->{id},
		name => $response_json->{name},
	) unless $want_array;

	my @tags;
	for my $tag ( @{ $response_json->{items} // [] } ) {
		my $Tag = PayProp::API::Public::Client::Response::Tag->new(
			id => $tag->{id},
			name => $tag->{name},

			( $tag->{type} ? ( type => $tag->{type} ) : () ),
			( $tag->{links} ? ( links => $tag->{links} ) : () ),
		);

		push( @tags, $Tag );
	}

	return \@tags;
}

__PACKAGE__->meta->make_immutable;

__END__

=encoding utf-8

=head1 NAME

PayProp::API::Public::Client::Request::Tags - Tags module.

=head1 SYNOPSIS

	my $Tags = PayProp::API::Public::Client::Request::Tags->new(
		domain => 'API_DOMAIN.com',                                         # Required: API domain.
		authorization => C<PayProp::API::Public::Client::Authorization::*>, # Required: Instance of an authorization module.
	);

=head1 DESCRIPTION

Implementation for creating, retrieving, updating and deleting (CRUD) tags via API.
This module is intended to be accessed via instance of C<PayProp::API::Public::Client>.

=head1 METHODS

=head2 list_p(\%args)

Issues a C<HTTP GET> request to PayProp API C</tags> endpoint. It takes an optional C<HASHREF> of query parameters.

See L</"QUERY PARAMETERS"> for a list of expected parameters.

	$Tags
		->list_p({ params => {...} })
		->then( sub {
			my ( \@tags ) = @_;
			...;
		} )
		->catch( sub {
			my ( $Exception ) = @_;
			...;
		} )
		->wait
	;

Returns a list of L<PayProp::API::Public::Client::Response::Tag> objects on success or L<PayProp::API::Public::Client::Exception::Response> on error.

=head2 create_p(\%args)

Issues a C<HTTP POST> request to PayProp API C</tags> endpoint.

See L</"REQUEST BODY FIELDS"> for a list of expected request body fields.

	$Tags
		->create_p({ content => {...} })
		->then( sub {
			my ( $ResponseTag ) = @_;
			...;
		} )
		->catch( sub {
			my ( $Exception ) = @_;
			...;
		} )
		->wait
	;

Returns L<PayProp::API::Public::Client::Response::Tag> on success or L<PayProp::API::Public::Client::Exception::Response> on error.

=head2 link_entities_p(\%args)

Issues a C<HTTP POST> request to PayProp API C</tags> endpoint.

See L</"REQUEST BODY FIELDS"> for a list of expected request body fields and L</"PATH PARAMETERS"> for a list of expected parameters.

	$Tags
		->link_entities_p({ path_params => { ... }, content => {...} })
		->then( sub {
			my ( \@tags ) = @_;
			...;
		} )
		->catch( sub {
			my ( $Exception ) = @_;
			...;
		} )
		->wait
	;

Returns a list of L<PayProp::API::Public::Client::Response::Tag> objects on success or L<PayProp::API::Public::Client::Exception::Response> on error.

=head2 list_tagged_entities_p(\%args)

Issues a C<HTTP GET> request to PayProp API C</tags> endpoint.

See L</"QUERY PARAMETERS"> and L</"PATH PARAMETERS"> for a list of expected parameters.

	$Tags
		->link_entities_p({ params => { ... }, path_params => {...} })
		->then( sub {
			my ( \@tags ) = @_;
			...;
		} )
		->catch( sub {
			my ( $Exception ) = @_;
			...;
		} )
		->wait
	;

Returns a list of L<PayProp::API::Public::Client::Response::Tag> objects on success or L<PayProp::API::Public::Client::Exception::Response> on error.

=head2 update_p(\%args)

Issues a C<HTTP PUT> request to PayProp API C</tags> endpoint.

See L</"REQUEST BODY FIELDS"> for a list of expected request body fields and L</"PATH PARAMETERS"> for a list of expected parameters.

	$Tags
		->update_p({ path_params => {...}, content => {...} })
		->then( sub {
			my ( $ResponseTag ) = @_;
			...;
		} )
		->catch( sub {
			my ( $Exception ) = @_;
			...;
		} )
		->wait
	;

Returns a L<PayProp::API::Public::Client::Response::Tag> object on success or L<PayProp::API::Public::Client::Exception::Response> on error.

=head2 delete_p(\%args)

Issues a C<HTTP DELETE> request to PayProp API C</tags> endpoint.

See L</"PATH PARAMETERS"> for a list of expected parameters.

	$Tags
		->delete_p({ path_params => {...} })
		->then( sub {
			my ( $json_response ) = @_;
			...;
		} )
		->catch( sub {
			my ( $Exception ) = @_;
			...;
		} )
		->wait
	;

Returns a C<JSON> response with a C<message> key on success or L<PayProp::API::Public::Client::Exception::Response> on error.

=head2 delete_entity_link_p(\%args)

Issues a C<HTTP DELETE> request to PayProp API C</tags> endpoint.

See L</"QUERY PARAMETERS"> and L</"PATH PARAMETERS"> for a list of expected parameters.

	$Tags
		->delete_entity_link_p({ params => { ... }, path_params => {...} })
		->then( sub {
			my ( $json_response ) = @_;
			...;
		} )
		->catch( sub {
			my ( $Exception ) = @_;
			...;
		} )
		->wait
	;

Returns a C<JSON> response with a C<message> key on success or L<PayProp::API::Public::Client::Exception::Response> on error.

=head1 REQUEST BODY FIELDS

=head2 name

B<string> C<[1..50]>
Tag name.

=head1 QUERY PARAMETERS

=head2 name

B<string> C<[1..50]>
Tag name.

=head2 external_id

B<string> C<[1..32] characters /^[a-zA-Z0-9]+$/>
Tag external ID.

=head2 entity_type

Enum: C<"property"> C<"beneficiary"> C<"property">
Tagged entity type.

=head2 entity_id

B<string> C<[1..32] characters /^[a-zA-Z0-9]+$/>
Tagged entity's external ID.

=head1 PATH PARAMETERS

=head2 external_id

B<string> C<[1..32] characters /^[a-zA-Z0-9]+$/>
External ID of tag.

=head1 AUTHOR

Yanga Kandeni E<lt>yangak@cpan.orgE<gt>

Valters Skrupskis E<lt>malishew@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2023- PayProp

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

If you would like to contribute documentation
or file a bug report then please raise an issue / pull request:

L<https://github.com/Humanstate/api-client-public-module>

=cut
