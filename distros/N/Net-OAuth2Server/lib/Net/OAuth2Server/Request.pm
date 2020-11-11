use strict; use warnings;

package Net::OAuth2Server::Request;
use Net::OAuth2Server::Set ();
use Net::OAuth2Server::Response ();
use MIME::Base64 ();
use Carp ();

sub request_body_methods  { 'POST' }
sub allowed_methods       {}
sub accepted_auth         {}
sub required_parameters   {}
sub set_parameters        { 'scope' }
sub confidential_parameters {}

use Object::Tiny::Lvalue qw( method headers parameters confidential scope error );

my $ct_rx = qr[ \A application/x-www-form-urlencoded [ \t]* (?: ; | \z ) ]xi;

my $loaded;
sub from_psgi {
	my ( $class, $env ) = ( shift, @_ );
	my $body;
	$body = do { $loaded ||= require Plack::Request; Plack::Request->new( $env )->content }
		if ( $env->{'CONTENT_TYPE'} || '' ) =~ $ct_rx
		and grep $env->{'REQUEST_METHOD'} eq $_, $class->request_body_methods;
	$class->from(
		$env->{'REQUEST_METHOD'},
		$env->{'QUERY_STRING'},
		{ map /\A(?:HTTPS?_)?((?:(?!\A)|\ACONTENT_).*)/s ? ( "$1", $env->{ $_ } ) : (), keys %$env },
		$body,
	);
}

my %auth_parser = ( # XXX not sure about this design...
	Bearer => sub { [ access_token => $_[0] ] },
	Basic  => sub {
		my @k = qw( client_id client_secret );
		my @v = split /:/, MIME::Base64::decode( $_[0] ), 2;
		[ map { ( shift @k, $_ ) x ( '' ne $_ ) } @v ];
	},
);

sub from {
	my ( $class, $meth, $query, $hdr, $body ) = ( shift, @_ );

	Carp::croak 'missing request method' unless defined $meth and '' ne $meth;

	%$hdr = map { my $k = $_; y/-/_/; ( lc, $hdr->{ $k } ) } $hdr ? keys %$hdr : ();

	if ( grep $meth eq $_, $class->request_body_methods ) {
		return $class->new( method => $meth, headers => $hdr )->set_error_invalid_request( 'bad content type' )
			if ( $hdr->{'content_type'} || '' ) !~ $ct_rx;
	} else {
		undef $body;
	}

	for ( $query, $body ) {
		defined $_ ? y/+/ / : ( $_ = '' );
		# parse to k/v pairs, ignoring empty pairs, ensuring both k&v are always defined
		$_ = [ / \G (?!\z) [&;]* ([^=&;]*) =? ([^&;]*) (?: [&;]+ | \z) /xg ];
		s/%([0-9A-Fa-f]{2})/chr hex $1/ge for @$_;
	}

	my $auth = $class->accepted_auth;
	if ( $auth and ( $hdr->{'authorization'} || '' ) =~ /\A\Q$auth\E +([^ ]+) *\z/ ) {
		my $parser = $auth_parser{ $auth }
			or Carp::croak "unsupported HTTP Auth type '$auth' requested in $class";
		$auth = $parser->( "$1" );
	}
	else { $auth = [] }

	my ( %param, %visible, %dupe );
	for my $list ( $auth, $body, $query ) {
		while ( @$list ) {
			my ( $name, $value ) = splice @$list, 0, 2;
			if ( exists $param{ $name } and $value ne $param{ $name } ) {
				$dupe{ $name } = 1;
			}
			else {
				$param{ $name } = $value;
				$visible{ $name } = 1 if $list == $query;
			}
		}
	}

	if ( my @dupe = sort keys %dupe ) {
		my $self = $class->new( method => $meth, headers => $hdr );
		return $self->set_error_invalid_request( "duplicate parameter: @dupe" );
	}

	while ( my ( $k, $v ) = each %param ) { delete $param{ $k } if '' eq $v }

	my %confidential = map +( $_, 1 ), grep !$visible{ $_ }, keys %param;

	$class->new(
		method       => $meth,
		headers      => $hdr,
		parameters   => \%param,
		confidential => \%confidential,
	);
}

sub new {
	my $class  = shift;
	my $self   = bless { @_ }, $class;
	$self->method or Carp::croak 'missing request method';
	$self->confidential ||= {};
	my $params = $self->parameters ||= {};
	$self->$_ ||= Net::OAuth2Server::Set->new( $params->{ $_ } ) for $self->set_parameters;
	$self->ensure_method( $self->allowed_methods ) or return $self;
	$self->ensure_confidential( $self->confidential_parameters ) or return $self;
	$self->ensure_required( $self->required_parameters ) or return $self;
	$self;
}

#######################################################################

sub ensure_method {
	my $self = shift;
	my $meth = $self->method;
	my $disallowed = not grep $meth eq $_, @_;
	$self->set_error_invalid_request( "method not allowed: $meth" ) if $disallowed;
	not $disallowed;
}

sub ensure_required {
	my $self = shift;
	my $p = $self->parameters;
	my @missing = sort grep !exists $p->{ $_ }, @_;
	$self->set_error_invalid_request( "missing parameter: @missing" ) if @missing;
	not @missing;
}

sub ensure_confidential {
	my $self = shift;
	my $p = $self->parameters;
	my $confidential = $self->confidential;
	my @visible = sort grep exists $p->{ $_ } && !$confidential->{ $_ }, @_;
	$self->set_error_invalid_request( "parameter not accepted in query string: @visible" ) if @visible;
	not @visible;
}

#######################################################################

sub params { my $p = shift->parameters; @$p{ @_ } }
sub param  { my $p = shift->parameters; $$p{ $_[0] } }
sub param_if_confidential {
	my ( $self, $name ) = ( shift, @_ );
	$self->confidential->{ $name } ? $self->parameters->{ $name } : ();
}

#######################################################################

sub set_error { my $self = shift; $self->error = Net::OAuth2Server::Response->new_error( @_ ); $self }
sub set_error_invalid_token             { shift->set_error( invalid_token             => @_ ) }
sub set_error_invalid_request           { shift->set_error( invalid_request           => @_ ) }
sub set_error_invalid_client            { shift->set_error( invalid_client            => @_ ) }
sub set_error_invalid_grant             { shift->set_error( invalid_grant             => @_ ) }
sub set_error_unauthorized_client       { shift->set_error( unauthorized_client       => @_ ) }
sub set_error_access_denied             { shift->set_error( access_denied             => @_ ) }
sub set_error_unsupported_response_type { shift->set_error( unsupported_response_type => @_ ) }
sub set_error_unsupported_grant_type    { shift->set_error( unsupported_grant_type    => @_ ) }
sub set_error_invalid_scope             { shift->set_error( invalid_scope             => @_ ) }
sub set_error_server_error              { shift->set_error( server_error              => @_ ) }
sub set_error_temporarily_unavailable   { shift->set_error( temporarily_unavailable   => @_ ) }

our $VERSION = '0.003';
