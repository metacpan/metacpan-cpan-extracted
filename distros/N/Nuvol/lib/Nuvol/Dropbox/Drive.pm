package Nuvol::Dropbox::Drive;
use Mojo::Base -role, -signatures;

use Mojo::Util 'url_unescape';

use constant SERVICE => 'Dropbox';

# internal methods

sub _build_url ($self, @path) {
  return $self->connector->url(@path);
}

sub _get_description ($self) {
  return $self->connector->description;
}

sub _get_name ($self) {
  return $self->connector->name;
}

sub _load_metadata ($self) {
  return $self->connector->_load_metadata;
}

1;

=encoding utf8

=head1 NAME

Nuvol::Dropbox::Drive - Internal methods for Dropbox drives

=head1 DESCRIPTION

L<Nuvol::Dropbox::Drive> provides internal methods for Dropbox drives. There is no distinction of
drives on Dropbox, so these objects always point to the same location and the
L<Metadata|Nuvol::Role::Metadata> of a L<Drive|Nuvol::Drive> are identical to those of its
L<Connector|Nuvol::Connector>.

=head1 SEE ALSO

L<Nuvol::Drive>, L<Nuvol::Dropbox>.

=cut
