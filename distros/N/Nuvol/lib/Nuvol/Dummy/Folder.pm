package Nuvol::Dummy::Folder;
use Mojo::Base -role, -signatures;

# internal methods

sub _do_make_path ($self, @data) {
  $self->_path->make_path;
  return $self;
}

sub _do_remove_tree ($self) {
  $self->_path->remove_tree;
  return $self;
}

1;

=encoding utf8

=head1 NAME

Nuvol::Dummy::Folder - Internal methods for dummy folders

=head1 DESCRIPTION

L<Nuvol::Dummy::Folder> provides internal methods for dummy folders.

=head1 SEE ALSO

L<Nuvol::Dummy>, L<Nuvol::Role::Folder>.

=cut
