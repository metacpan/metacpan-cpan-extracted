use strict;
use warnings;

package POE::Component::Server::Postfix::TCP;
our $VERSION = '0.001';


use MooseX::POE;
extends 'POE::Component::Server::Postfix';

has port => (is => 'ro', isa => 'Int', required => 1);
has host => (is => 'ro', isa => 'Str', default => '0.0.0.0');


sub socketfactory_args {
  my ($self) = @_;
  return (
    SocketDomain => Socket::AF_INET,
    BindAddress => $self->host,
    BindPort    => $self->port,
  );
}

1;

__END__
=head1 NAME

POE::Component::Server::Postfix::TCP

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

