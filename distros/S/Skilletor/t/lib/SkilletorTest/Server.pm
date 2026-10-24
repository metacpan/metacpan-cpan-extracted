package SkilletorTest::Server;
# ABSTRACT: Handle on the test HTTP server SkilletorTest::serve_http starts

use strict;
use warnings;

use Path::Tiny qw( path );
use Skilletor::JSON qw( js_parse js_stringify );

sub new {
  my ( $class, %args ) = @_;
  return bless {%args}, $class;
}

sub url {
  my ( $self, $p ) = @_;
  return 'http://127.0.0.1:'.$self->{port}.$p;
}

# Set what a path answers: { status, headers, body, status_for => { etag => status } }.
sub route {
  my ( $self, $p, $r ) = @_;
  ( my $key = $p ) =~ s/[^A-Za-z0-9]/_/g;
  my %stored = (
    status   => $r->{status} // 200,
    headers  => $r->{headers} // {},
    body_hex => unpack( 'H*', $r->{body} // '' ),
    ( $r->{status_for} ? ( status_for => $r->{status_for} ) : () ),
  );
  path( $self->{dir}, 'route'.$key.'.tmp' )->spew_utf8( js_stringify( \%stored ) );
  rename path( $self->{dir}, 'route'.$key.'.tmp' ), path( $self->{dir}, 'route'.$key );
}

sub requests {
  my ( $self ) = @_;
  my $log = path( $self->{dir}, 'log' );
  return [] unless $log->exists;
  return [ map { js_parse($_) } $log->lines_utf8( { chomp => 1 } ) ];
}

sub stop {
  my ( $self ) = @_;
  return unless $self->{pid};
  kill 'TERM', $self->{pid};
  waitpid $self->{pid}, 0;
  delete $self->{pid};
}

sub DESTROY { $_[0]->stop }

1;
