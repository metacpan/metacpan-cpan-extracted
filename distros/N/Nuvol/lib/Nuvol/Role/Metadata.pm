package Nuvol::Role::Metadata;
use Mojo::Base -role, -signatures;

requires qw|_build_url _get_description _get_name _load_metadata|;

# methods

sub description ($self) { return $self->_load->_get_description; }
sub id ($self)          { return $self->_load->{id}; }
sub metadata ($self)    { return $self->_load->{metadata}; }
sub name ($self)        { return $self->_load->_get_name; }
sub url ($self, @path)  { return $self->_build_url(@path); }

# internal methods

sub _parse_parameters ($self, $params) {
  if ($params->{metadata}) {
    $self->_set_metadata($params->{metadata});
  } elsif ($params->{id}) {
    $self->{id} = $params->{id};
  } elsif ($params->{path}) {
    $self->{path} = $params->{path};
    $self->{path} =~ s|(.+)/$|$1|;
  }

  return $self;
}

sub _load ($self) {
  $self->_set_metadata($self->_load_metadata) unless $self->{metadata};

  return $self;
}

sub _set_metadata ($self, $metadata) {
  $self->{metadata} = $metadata;
  $self->{id}       = $metadata->{id};

  return $self;
}

1;

=encoding utf8

=head1 NAME

Nuvol::Role::Metadata - Role for metadata

=head1 SYNOPSIS

    $object->description;
    $object->id;
    $object->metadata;
    $object->name;
    $object->url;

=head1 DESCRIPTION

L<Nuvol::Role::Metadata> is a role to access metadata. It is automatically applied to all Nuvol objects.

=head1 METHODS

=head2 description

    $description = $object->description;

Getter for the human readable description of the object.

=head2 id

    $id = $object->id;

Getter for the id.

=head2 metadata

    $metadata = $object->metadata;

Getter for the unstructured metadata.

=head2 name

    $name = $object->name;

Getter for the name.

=head2 url

    $url = $object->url;
    $url = $object->url($path);

Getter for the URL of the object itself or a path below it. Returns a L<Mojo::URL>.

=head1 SEE ALSO

L<Nuvol::Connector>, L<Nuvol::Drive>, L<Nuvol::Item>.

=cut
