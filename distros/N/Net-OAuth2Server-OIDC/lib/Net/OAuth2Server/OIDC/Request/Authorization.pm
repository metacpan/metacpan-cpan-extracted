use strict; use warnings;

package Net::OAuth2Server::OIDC::Request::Authorization;
use parent 'Net::OAuth2Server::Request::Authorization';

sub response_type_requiring_nonce { qw( token id_token ) }
sub valid_parameter_values { (
	display => [qw( page popup touch wap )],
	prompt  => [qw( none login consent select_account )],
) }

sub validated {
	my $self = shift;
	if ( $self->scope->contains( 'openid' ) ) {
		return $self->with_error_invalid_request( 'missing parameter: nonce' )
			if ( not defined $self->param('nonce') )
			and $self->response_type->contains( $self->response_type_requiring_nonce );

		my %validate = $self->valid_parameter_values;
		my @invalid = sort grep {
			my $name = $_;
			my $value = $self->param( $name );
			defined $value and not grep $value eq $_, @{ $validate{ $name } };
		} keys %validate;
		return $self->with_error_invalid_request( "invalid value for parameter: @invalid" ) if @invalid;
	}
	else {
		return $self->with_error_invalid_request( 'id_token requested outside of openid scope' )
			if $self->response_type->contains( 'id_token' );
	}
	$self;
}

our $VERSION = '0.002';
