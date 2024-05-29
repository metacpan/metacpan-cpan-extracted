package OpenSearch::Base;
use strict;
use warnings;
use Moose;
use feature qw(signatures say);
use MooseX::Singleton;
use Mojo::UserAgent;
use Mojo::URL;
use Data::Dumper;
use OpenSearch::Response;

with 'OpenSearch::Helper';

# This is a singleton class. We only want one instance of this class.

has 'user'            => ( is => 'rw', isa => 'Str', required => 0 );   # Not really required since we can use Cert-Auth
has 'pass'            => ( is => 'rw', isa => 'Str', required => 0 );   # Not really required since we can use Cert-Auth
has 'ca_cert'         => ( is => 'rw', isa => 'Str', required => 0 );   # Dunno if that will work right now...
has 'client_cert'     => ( is => 'rw', isa => 'Str', required => 0 );   # Dunno if that will work right now...
has 'client_key'      => ( is => 'rw', isa => 'Str', required => 0 );   # Dunno if that will work right now...
has 'hosts'           => ( is => 'rw', isa => 'ArrayRef[Str]', required => 1 );
has 'secure'          => ( is => 'rw', isa => 'Str',           required => 1 );
has 'allow_insecure'  => ( is => 'rw', isa => 'Str',           required => 0, default => sub { 0; } );
has 'async'           => ( is => 'rw', isa => 'Bool',          required => 0, default => sub { 0; } );
has 'max_connections' => ( is => 'rw', isa => 'Int',           required => 0, default => sub { 5; } );

# Clean attributes after each request. This is a bit of a hack. We should probably use a
# new instance of the class for each request.
has 'clear_attrs' => ( is => 'rw', isa => 'Bool', required => 0, default => sub { 0; } );

# If one host is down, we put it here. Dont know yet how to test if a host is back up again
has 'disabled_hosts' => ( is => 'rw', isa => 'ArrayRef[Str]', default => sub { []; } );

# We pre-create a number of Mojo::UserAgent Objects (dont know if that works)
has 'pool_count' => ( is => 'rw', isa => 'Int', default => sub { 1; } );

# Without this the ua will get out of scope to early and result in a Premature connection close...
has 'ua_pool' => ( is => 'rw', isa => 'ArrayRef[Mojo::UserAgent]', lazy => 1, default => sub { []; } );

sub BUILD( $self, @rest ) {

  while ( scalar( @{ $self->ua_pool } ) <= $self->pool_count ) {
    my $ua = Mojo::UserAgent->new->insecure( $self->allow_insecure )->max_connections( $self->max_connections );

    if ( $self->client_cert && $self->client_key ) {
      $ua->cert( $self->client_cert )->key( $self->client_key )->ca_cert( $self->ca_cert );
    }

    push( @{ $self->ua_pool }, $ua );
  }

}

sub ua($self) {
  my $pool = int( rand( $self->pool_count ) );
  return ( $self->ua_pool->[$pool] );
}

sub url( $self, $suffixes = [], $params = {} ) {
  my $random_host = $self->hosts->[ int( rand( scalar( @{ $self->hosts } ) ) ) ];
  my ( $host, $port ) = split( ':', $random_host );
  $port = $port // 9200;

  my $url = Mojo::URL->new->scheme( $self->secure ? 'https' : 'http' )->host($host)->port($port)
    ->path( join( '/', @{$suffixes} ) )->query($params);

  # Just quick n dirty. There probably is a better way.
  # Maybe we requires AWS auth in the future?
  if ( !$self->client_cert && !$self->client_key ) {
    $url->userinfo( join( ':', $self->user, $self->pass ) );
  }

  return ($url);
}

sub _http_method( $self, $method, $instance, $path = [] ) {
  my $parsed = $self->_generate_params($instance);
  return ( $self->do_request( $method, $self->url( $path, $parsed->{url} ), $parsed->{body} ) );
}

sub do_request( $self, $method, $url, $body ) {
  my ( $promise, $res );

  $promise =
    $self->ua->$method(
    $url => ( ref($body) eq 'HASH' ? 'json' : ( { 'Content-Type' => 'application/json' } ) ) => $body )
    ->then( sub($tx) {
    return ( $self->response($tx) );
    } )->catch( sub($error) {
    return ($error);
    } );

  return ($promise) if $self->async;

  $promise->then( sub { $res = shift; } )->wait;

  return ($res);
}

sub _delete( $self, $instance, $path = [] ) {
  return $self->_http_method( 'delete_p', $instance, $path );
}

sub _get( $self, $instance, $path = [] ) {
  return $self->_http_method( 'get_p', $instance, $path );
}

sub _head( $self, $instance, $path = [] ) {
  return $self->_http_method( 'head_p', $instance, $path );
}

sub _options( $self, $instance, $path = [] ) {
  return $self->_http_method( 'options_p', $instance, $path );
}

sub _patch( $self, $instance, $path = [] ) {
  return $self->_http_method( 'patch_p', $instance, $path );
}

sub _post( $self, $instance, $path = [] ) {
  return $self->_http_method( 'post_p', $instance, $path );
}

sub _put( $self, $instance, $path = [] ) {
  return $self->_http_method( 'put_p', $instance, $path );
}

sub response( $self, $tx ) {
  return ( OpenSearch::Response->new( _response => $tx->result ) );
}

1;
