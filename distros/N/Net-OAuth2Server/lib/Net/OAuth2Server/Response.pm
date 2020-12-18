use strict; use warnings;

package Net::OAuth2Server::Response;
use Object::Tiny::Lvalue qw( parameters is_error redirect_uri use_fragment );
use URI::Escape ();
use Carp ();

sub supported_response_types { qw( code token ) }

sub new { my $class = shift; bless { parameters => {}, @_ }, $class }


sub new_error {
	my ( $class, $type, $desc, %param ) = ( shift, @_ );
	$param{'error'} = $type or Carp::croak 'missing error type';
	$param{'error_description'} = $desc if defined $desc;
	$class->new( is_error => 1, parameters => \%param );
}

sub for_authorization {
	my ( $class, $req, $grant ) = ( shift, @_ );

	$req->set_error_unsupported_response_type
		unless Net::OAuth2Server::Set
			->new( $class->supported_response_types )
			->contains_all( $req->response_type->list );

	my $self;
	if    ( $self = $req->error ) {}
	elsif ( $grant ) {
		$self = $class->new;
		$grant->create_access_token( $self ) if $req->response_type->contains( 'token' );
		$grant->create_auth_code( $self )    if $req->response_type->contains( 'code' );
	}
	else { $self = $class->new_error( 'access_denied' ) }

	$self->redirect_uri = $req->redirect_uri;
	$self->use_fragment = $req->response_type->contains( 'token' ); # some kind of hybrid flow
	$self->add( state => $req->param( 'state' ) );
}

sub for_token {
	my ( $class, $req, $grant ) = ( shift, @_ );
	return $_ for $req->error || ();
	return $class->new_error( 'invalid_grant' ) unless $grant;
	my $self = $class->new;
	$grant->create_access_token( $self );
	$grant->create_refresh_token( $self ) if $grant->provides_refresh_token;
	$self->add( scope => $grant->scope->as_string );
}

#######################################################################

sub params    { my $p = shift->parameters; @$p{ @_ } }
sub param     { my $p = shift->parameters; $$p{ $_[0] } }
sub has_param { my $p = shift->parameters; exists $$p{ $_[0] } }

sub add {
	my ( $self, $key, $value ) = ( shift, @_ );
	$self->parameters->{ $key } = $value if defined $value and '' ne $value;
	$self;
}

sub add_token {
	my ( $self, %arg ) = ( shift, @_ );
	Carp::croak 'cannot add token to an error response' if $self->is_error;
	Carp::croak "missing $_[0]" if not defined $_[1];
	@{ $self->parameters }{ keys %arg } = values %arg;
	$self;
}

sub add_auth_code { shift->add_token( code => @_ ) }

sub add_access_token {
	my ( $self, $type, $token, $expires_in, %arg ) = ( shift, @_ );
	$self->add_token( %arg, (
		token_type   => $type  || ( Carp::croak 'missing token_type' ),
		access_token => $token || ( Carp::croak 'missing access_token' ),
		( expires_in => $expires_in ) x defined $expires_in,
	) );
}

sub add_bearer_token { shift->add_access_token( Bearer => @_ ) }

sub add_refresh_token { shift->add_token( refresh_token => @_ ) }

#######################################################################

sub status { shift->is_error ? 400 : 200 }

sub as_bearer_auth_header {
	my $self = shift;
	Carp::croak 'cannot create auth header from non-error response' if not $self->is_error;
	my $p = $self->parameters;
	'Bearer ' . join ', ', sort map qq{$_="$p->{ $_ }"}, keys %$p;
}

my $e = \&URI::Escape::uri_escape;
sub as_uri {
	my $self = shift;
	my $uri = $self->redirect_uri or return;
	my $p = $self->parameters;
	my $idx = -1;
	my $qps = join '&', map $e->( $_ ).'='.$e->( $p->{ $_ } ), keys %$p;
	my $sep = $self->use_fragment ? '#' : $uri =~ /\?/ ? '&' : '?';
	$uri . $sep . $qps;
}

our $VERSION = '0.004';
