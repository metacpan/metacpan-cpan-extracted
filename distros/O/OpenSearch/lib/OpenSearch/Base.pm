package OpenSearch::Base;
use strict;
use warnings;
use Moose;
use feature qw(signatures);
use MooseX::Singleton;
use Mojo::UserAgent;
use Mojo::URL;

with 'OpenSearch::Helper';

use Data::Dumper;

has 'user'           => ( is => 'rw', isa => 'Str', required => 0 );    # Not really required since we can use Cert-Auth
has 'pass'           => ( is => 'rw', isa => 'Str', required => 0 );    # Not really required since we can use Cert-Auth
has 'client_cert'    => ( is => 'rw', isa => 'Str', required => 0 );    # Dunno if that will work right now...
has 'client_key'     => ( is => 'rw', isa => 'Str', required => 0 );    # Dunno if that will work right now...
has 'hosts'          => ( is => 'rw', isa => 'ArrayRef[Str]', required => 1 );
has 'secure'         => ( is => 'rw', isa => 'Str',           required => 1 );
has 'allow_insecure' => ( is => 'rw', isa => 'Str',           required => 0, default => sub { 0; } );

# If one host is down, we put it here. Dont know yet how to test if a host is back up again
has 'disabled_hosts' => ( is => 'rw', isa => 'ArrayRef[Str]', default => sub { []; } );

# We pre-create a number of Mojo::UserAgent Objects (dont know if that works)
has 'pool_count' => ( is => 'rw', isa => 'Int', default => sub { 1; } );

# We need ua to be static. Without this the ua will get out of scope to early and result in a Premature connection close...
has 'ua_pool' => ( is => 'rw', isa => 'ArrayRef[Mojo::UserAgent]', lazy => 1, default => sub { []; } );

sub BUILD( $self, @rest ) { $self->_generate_ua_pool; }

sub _generate_ua_pool($self) {
  while ( scalar( @{ $self->ua_pool } ) <= $self->pool_count ) {
    my $ua = Mojo::UserAgent->new->insecure( $self->allow_insecure );

    if ( $self->client_cert && $self->client_key ) {
      $ua->cert( $self->client_cert )->key( $self->client_key );
    }

    push( @{ $self->ua_pool }, $ua );
  }
}

sub ua($self) { $self->_ua; }

sub _ua($self) {
  my $pool = int( rand( $self->pool_count ) );

  #warn("Using ua_pool: " . $pool . "\n");
  #print Dumper $self->ua_pool->[$pool];
  return ( $self->ua_pool->[$pool] );
}

sub url( $self, $suffixes = [], $params = {} ) {
  my $random_host = $self->hosts->[ int( rand( scalar( @{ $self->hosts } ) ) ) ];
  my ( $host, $port ) = split( ':', $random_host );
  $port = $port // 9200;

  #warn("Using $host:$port for connection!\n");

  my $url = Mojo::URL->new->scheme( $self->secure ? 'https' : 'http' )->host($host)->port($port)
    ->path( join( '/', @{$suffixes} ) )->query($params);

  # Just quick n dirty. There probably is a better way.
  # Maybe we requires AWS auth in the future?
  if ( !$self->client_cert && !$self->client_key ) {
    $url->userinfo( join( ':', $self->user, $self->pass ) );
  }

  return ($url);
}

sub _prepare_data( $self, $instance, $path = [], $params = {} ) {
  return (
    $self->url( $path, $self->_build_params( $instance, $params, 'url' ) ),
    $self->_build_params( $instance, $params, 'body' ),
  );
}

sub _http_method( $self, $method, $instance, $path = [], $params = {} ) {
  my ( $url,  $body ) = $self->_prepare_data( $instance, $path, $params );
  my ( $host, $port ) = ( $url->host, $url->port );

  $method .= '_p';

  $self->do_request( $method, $url, $body );
}

sub do_request( $self, $method, $url, $body ) {
  my $res;

  # TODO: We need to check if $body is a hashref. When using i.e. MULTI_SEARCH we need to send multiple JSON "bodys":
  #       https://opensearch.org/docs/latest/api-reference/multi-search/
  #       We should check if $body is a string (already encoded JSON) and if so, just send it as is.
  #       These fuckers accept shit like:
  #       GET _msearch
  #       { "index": "opensearch_dashboards_sample_data_logs"}
  #       { "query": { "match_all": {} }, "from": 0, "size": 10}
  #       { "index": "opensearch_dashboards_sample_data_ecommerce", "search_type": "dfs_query_then_fetch"}
  #       { "query": { "match_all": {} } }
  my $promise = $self->_ua->$method( $url => json => $body )->then( sub($tx) {
    return ( $self->response($tx) );
  } )->catch( sub($error) {
    warn( 'There was an error: ' . $error );
    return ($error);
  } );

  # We want to return a Promise
  if ( $method =~ /_p$/ ) {
    return ($promise);
  } else {
    $promise->then( sub { $res = shift; } )->wait;
    return ($res);
  }
}

sub _delete( $self, $instance, $path = [], $params = {} ) {
  $self->_http_method( 'delete', $instance, $path, $params );
}

sub _get( $self, $instance, $path = [], $params = {} ) {
  $self->_http_method( 'get', $instance, $path, $params );
}

sub _head( $self, $instance, $path = [], $params = {} ) {
  $self->_http_method( 'head', $instance, $path, $params );
}

sub _options( $self, $instance, $path = [], $params = {} ) {
  $self->_http_method( 'options', $instance, $path, $params );
}

sub _patch( $self, $instance, $path = [], $params = {} ) {
  $self->_http_method( 'patch', $instance, $path, $params );
}

sub _post( $self, $instance, $path = [], $params = {} ) {
  $self->_http_method( 'post', $instance, $path, $params );
}

sub _put( $self, $instance, $path = [], $params = {} ) {
  $self->_http_method( 'put', $instance, $path, $params );
}

sub response( $self, $tx ) { my $res = $tx->result->json; return ($res); }

1;
