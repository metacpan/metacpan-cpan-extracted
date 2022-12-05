#<<<
use strict; use warnings;
#>>>

package Plack::Middleware::LogAny;

use parent                qw( Plack::Middleware );
use Log::Any              qw();
use Plack::Util::Accessor qw( category logger );

our $VERSION = '0.001002';

sub prepare_app {
  my ( $self ) = @_;
  $self->logger( Log::Any->get_logger( category => defined $self->category ? $self->category : '' ) );
}

sub call {
  my ( $self, $env ) = @_;

  $env->{ 'psgix.logger' } = sub {
    my ( $level, $message ) = @{ $_[ 0 ] }{ qw( level message ) };

    $self->logger->$level( $message );
  };

  $self->app->( $env );
}

1;
