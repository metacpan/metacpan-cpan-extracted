#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::Repositorio::Server::Docker::Index;

use Mojo::Base 'Mojolicious::Controller';

our $VERSION = '1.2.1'; # VERSION

sub index {
  my ($self) = @_;
  $self->render( json => { ok => 1 } );
}

sub ping {
  my ($self) = @_;
  $self->render( text => 'true' );
}

1;
