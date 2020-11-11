use strict; use warnings;

package Net::OAuth2Server::OIDC;

our $VERSION = '0.004';

package Net::OAuth2Server::Request::Authorization::Role::OIDC;

our $VERSION = '0.004';

use Role::Tiny;
use Class::Method::Modifiers 'fresh';

sub fresh__response_type_requiring_nonce { qw( token id_token ) }
sub fresh__valid_parameter_values { (
	display => [qw( page popup touch wap )],
	prompt  => [qw( none login consent select_account )],
) }
fresh response_type_requiring_nonce => \&fresh__response_type_requiring_nonce;
fresh valid_parameter_values => \&fresh__valid_parameter_values;
undef *fresh__response_type_requiring_nonce;
undef *fresh__valid_parameter_values;

sub around__new {
	my $orig = shift;
	my $class = shift;
	my $self = $class->$orig( @_ );
	return $self if $self->error;
	if ( $self->scope->contains( 'openid' ) ) {
		return $self->set_error_invalid_request( 'missing parameter: nonce' )
			if ( not defined $self->param('nonce') )
			and $self->response_type->contains( $self->response_type_requiring_nonce );

		my %validate = $self->valid_parameter_values;
		my @invalid = sort grep {
			my $name = $_;
			my $value = $self->param( $name );
			defined $value and not grep $value eq $_, @{ $validate{ $name } };
		} keys %validate;
		return $self->set_error_invalid_request( "invalid value for parameter: @invalid" ) if @invalid;
	}
	else {
		return $self->set_error_invalid_request( 'id_token requested outside of openid scope' )
			if $self->response_type->contains( 'id_token' );
	}
	$self;
}
around 'new' => \&around__new;
undef *around__new;

package Net::OAuth2Server::Response::Role::OIDC;

our $VERSION = '0.004';

use Role::Tiny;
use Class::Method::Modifiers 'fresh';
use MIME::Base64 ();
use JSON::WebToken ();
use Digest::SHA ();
use Carp ();

# copy-paste from newer MIME::Base64 for older versions without it
my $b64url_enc = MIME::Base64->can( 'encode_base64url' ) || sub {
	my $e = MIME::Base64::encode_base64( shift, '' );
	$e =~ s/=+\z//;
	$e =~ tr[+/][-_];
	return $e;
};

sub fresh__supported_response_types { qw( code id_token token ) }
fresh supported_response_types => \&fresh__supported_response_types;
undef *fresh__supported_response_types;

sub around__for_authorization {
	my $orig = shift;
	my ( $class, $req, $grant ) = ( shift, @_ );
	my $self = $class->$orig( @_ );
	return $self if $self->is_error or not $grant;
	$grant->create_id_token( $self, 1 ) if $req->response_type->contains( 'id_token' );
	$self;
}
around for_authorization => \&around__for_authorization;
undef *around__for_authorization;

sub around__for_token {
	my $orig = shift;
	my ( $class, $req, $grant ) = ( shift, @_ );
	my $self = $class->$orig( @_ );
	return $self if $self->is_error or not $grant;
	$grant->create_id_token( $self, 0 ) if $grant->scope->contains( 'openid' );
	$self;
}
around for_token => \&around__for_token;
undef *around__for_token;

my %hashed = qw( code c_hash access_token at_hash );

sub fresh__add_id_token {
	my ( $self, $nonce, $pay, $head, $key ) = ( shift, @_ );
	Carp::croak 'missing payload' unless $pay;
	Carp::croak 'header and payload must be hashes' if grep 'HASH' ne ref, $pay, $head || ();
	$pay->{'nonce'} = $nonce if $nonce;
	my $p = $self->param;
	my $alg = ( $head && $head->{'alg'} ) || 'none';
	if ( $alg =~ /\A[A-Za-z]{2}([0-9]+)\z/ ) {
		my $sha = Digest::SHA->new( "$1" );
		while ( my ( $k, $k_hash ) = each %hashed ) {
			my $digest = exists $p->{ $k } ? $sha->reset->add( $p->{ $k } )->digest : next;
			$pay->{ $k_hash } = $b64url_enc->( substr $digest, 0, length( $digest ) / 2 );
		}
	}
	$self->add_token( id_token => JSON::WebToken->encode( $pay, $key, $alg, $head ) );
}
fresh add_id_token => \&fresh__add_id_token;
undef *fresh__add_id_token;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::OAuth2Server::OIDC - An OpenID Connect server on top of Net::OAuth2Server

=head1 DISCLAIMER

B<I cannot promise that the API is fully stable yet.>
For that reason, no documentation is provided.

=head1 DESCRIPTION

A usable but tiny implementation of OpenID Connect.

This is also a demonstration of the L<Net::OAuth2Server> design.

=head1 SEE ALSO

This is a very distant descendant of the server portion of L<OIDC::Lite>.

=head1 AUTHOR

Aristotle Pagaltzis <pagaltzis@gmx.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Aristotle Pagaltzis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
