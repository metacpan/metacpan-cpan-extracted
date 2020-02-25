package Nuvol::Dropbox::Folder;
use Mojo::Base -role, -signatures;

# internal methods

sub _do_make_path ($self, @data) {
  my $res = $self->drive->connector->_ua_post($self->url('create_folder_v2'),
    json => {path => $self->realpath->to_route});
  Carp::confess $res->message if $res->is_error;

  $self->_set_metadata($res->json->{metadata});

  return $self;
}

sub _do_remove_tree ($self) {
  return $self->_remove_item;
}

1;

=encoding utf8

=head1 NAME

Nuvol::Dropbox::Folder - Internal methods for Dropbox folders

=head1 DESCRIPTION

L<Nuvol::Dropbox::Folder> provides internal methods for Dropbox folders.

=head1 SEE ALSO

L<Nuvol::Dropbox>, L<Nuvol::Role::Folder>.

=cut
