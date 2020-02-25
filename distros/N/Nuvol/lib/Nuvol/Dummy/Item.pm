package Nuvol::Dummy::Item;
use Mojo::Base -role, -signatures;

use constant SERVICE => 'Dummy';

# internal methods

sub _build_realpath ($self) {
  return $self->{path} // unpack('u', $self->{id}) =~ s/^p://r;
}

sub _build_url ($self, @path) {
  unshift @path, $self->realpath->@*;
  return $self->drive->url(@path);
}

sub _check_existence ($self) {
  return -e $self->_path;
}

sub _path ($self) {
  return Mojo::File->new($self->url->path->to_route);
}

sub _get_description ($self) {
  return SERVICE . ' item ' . $self->name;
}

sub _get_name ($self) {
  return $self->metadata->{path};
}

sub _get_type ($self, $params) {
  my $rv;
  if ($params->{metadata}) {
    $rv = $params->{metadata}{type};
  } else {
    $rv = $params->{type};
  }

  return $rv;
}

sub _load_metadata ($self) {
  my %metadata = (owner => 'Dummy Owner',);

  if ($self->{id}) {
    $metadata{id}   = $self->{id};
    $metadata{path} = unpack('u', $self->{id}) =~ s/^p://r;
  } else {
    $metadata{path} = $self->{path};
    chomp($metadata{id} = pack 'u', "p:$metadata{path}");
  }

  return \%metadata;
}

1;

=encoding utf8

=head1 NAME

Nuvol::Dummy::Item - Internal methods for dummy items

=head1 DESCRIPTION

L<Nuvol::Dummy::Item> provides internal methods for dummy items.

=head1 SEE ALSO

L<Nuvol::Dummy>, L<Nuvol::Item>.

=cut
