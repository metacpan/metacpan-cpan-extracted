use strict;
use warnings;

package POE::Component::Server::Postfix::UNIX;
our $VERSION = '0.001';


use MooseX::POE;
extends 'POE::Component::Server::Postfix';

has path => (is => 'ro', isa => 'Str', required => 1);
has mode => (is => 'ro', default => 0755);


sub socketfactory_args {
  my ($self) = @_;
  return (
    SocketDomain => Socket::AF_UNIX,
    BindAddress  => $self->path,
  );
}

sub _unlink {
  my ($self) = @_;
  if (-e $self->path) {
    unlink $self->path or die "Can't unlink " . $self->path . ": $!";
  }
}

sub _build_server {
  my ($self) = @_;
  $self->_unlink;
  my $server = $self->SUPER::_build_server;
  chmod $self->mode, $self->path or die "Can't chmod " . $self->path . ": $!";
  return $server;
}

sub STOP { shift->_unlink }

1;

__END__
=head1 NAME

POE::Component::Server::Postfix::UNIX

=head1 VERSION

version 0.001

=head1 METHODS

=head2 socketfactory_args

=head1 AUTHOR

  Hans Dieter Pearcey <hdp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Hans Dieter Pearcey.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

