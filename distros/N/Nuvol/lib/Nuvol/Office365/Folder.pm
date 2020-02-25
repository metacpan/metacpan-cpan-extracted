package Nuvol::Office365::Folder;
use Mojo::Base -role, -signatures;

# internal methods

sub _do_make_path ($self, @data) {
  my $drive  = $self->drive;
  my @parts = split '/', $self->{path};
  my @create;
  my $parent = $self;
  while (!$parent->exists) {
    unshift @create, pop @parts;
    $parent = $drive->item(join('/', @parts) . '/');
  }

  for my $folder (@create) {
    my $res
      = $drive->connector->_ua_post($parent->url('children'), json => {name => $folder, folder => {}});
    Carp::confess $res->message if $res->is_error;

    $parent = Nuvol::Item->new($drive, {metadata => $res->json});
  }
  $self->_set_metadata($parent->metadata);

  return $self;
}

sub _do_remove_tree ($self) {
  return $self->_remove_item;
}

1;

=encoding utf8

=head1 NAME

Nuvol::Office365::Folder - Internal methods for Office 365 folders

=head1 DESCRIPTION

L<Nuvol::Office365::Folder> provides internal methods for Office 365 folders.

=head1 SEE ALSO

L<Nuvol::Office365>, L<Nuvol::Role::Folder>.

=cut
