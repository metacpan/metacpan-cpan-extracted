use strict; use warnings;

package Net::OAuth2Server::OIDC::Response;
use parent 'Net::OAuth2Server::Response';
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

sub supported_response_types { qw( code id_token token ) }

sub for_authorization {
	my ( $class, $req, $grant ) = ( shift, @_ );
	my $self = $class->SUPER::for_authorization( @_ );
	return $self if $self->is_error or not $grant;
	$grant->create_id_token( $self, 1 ) if $req->response_type->contains( 'id_token' );
	$self;
}

sub for_token {
	my ( $class, $req, $grant ) = ( shift, @_ );
	my $self = $class->SUPER::for_token( @_ );
	return $self if $self->is_error or not $grant;
	$grant->create_id_token( $self, 0 ) if $grant->scope->contains( 'openid' );
	$self;
}

my %hashed = qw( code c_hash access_token at_hash );

sub add_id_token {
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

our $VERSION = '0.002';
