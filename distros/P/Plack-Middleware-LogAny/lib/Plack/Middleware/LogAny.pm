#<<<
use strict; use warnings;
#>>>

package Plack::Middleware::LogAny;

our $VERSION = '0.002001';

use parent                qw( Plack::Middleware );
use subs                  qw( _name_to_key );
use Log::Any              qw();
use Plack::Util::Accessor qw( category context logger );

sub prepare_app {
  my ( $self ) = @_;
  $self->logger( Log::Any->get_logger( category => defined $self->category ? $self->category : '' ) );
}

sub call {
  my ( $self, $env ) = @_;

  my %header;
  if ( my $context = $self->context ) {
    foreach my $name ( @{ $context } ) {
      my $key = _name_to_key $name;
      $header{ $name } = $env->{ $key } if defined $env->{ $key };
    }
  }

  my $logger = $self->logger;
  local @{ $logger->context }{ keys %header } = values %header if %header;

  $env->{ 'psgix.logger' } = sub {
    my ( $level, $message ) = @{ $_[ 0 ] }{ qw( level message ) };

    @_ = ( $logger, $message );
    goto &{ $logger->can( $level ) };
  };

  $self->app->( $env );
}

sub _name_to_key ( $ ) {
  my ( $name ) = @_;

  ( my $key = $name ) =~ s/-/_/g;
  $key = uc $key;
  if ( $key !~ /\A(?:CONTENT_LENGTH|CONTENT_TYPE)\z/ ) {
    $key = "HTTP_$key";
  }

  return $key;
}

1;
