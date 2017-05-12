package Mojo::Server::Morbo::Backend::Inotify;

our $VERSION = '0.04';

use Mojo::Base 'Mojo::Server::Morbo::Backend';

use Linux::Inotify2;
use Mojo::File 'path';
use IO::Select;

has _inotify => sub {
  my $self = shift;
  my $i    = Linux::Inotify2->new();
  $i->watch($_, IN_MODIFY)
    or die "Could not watch $_: $!"
    for grep { -e $_ }
    map { path($_)->list_tree({dir => 1})->each, $_ } @{$self->watch};
  $i->blocking(0);
  return $i;
};

sub modified_files {
  my $self = shift;

  my $select = IO::Select->new($self->_inotify->fileno);
  $select->can_read($self->watch_timeout);
  return [map { $_->{w}{name} } $self->_inotify->read];
}

1;

=encoding utf8

=head1 NAME

Mojo::Server::Morbo::Backend::Inotify - Sample Morbo Inotify watcher

=head1 SYNOPSIS

  my $backend=Mojo::Server::Morbo::Backend::Inotify->new();
  if ($backend->modified_files) {...}

=head1 DESCRIPTION

To use this module, start morbo with the argument -b Inotify

=head1 METHODS

L<Mojo::Server::Morbo::Backend::Inotify> inherits all methods from
L<Mojo::Server::Morbo::Backend>.

=head2 modified_files

Looks for modified files using L<Linux::Inotify2>


=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2017, Marcus Ramberg

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

