package Nuvol::Dummy::Drive;
use Mojo::Base -role, -signatures;

use Mojo::File 'path';

use constant SERVICE => 'Dummy';

# internal methods

sub _build_url ($self, @path) {
  if ($self->{metadata}) {
    unshift @path, 'drives', unpack 'u', $self->{metadata}{id};
  } elsif ($self->{id}) {
    unshift @path, 'drives', unpack 'u', $self->{id};
  } else {
    unshift @path, 'drives', $self->{path} eq '~' ? 'Home' : $self->{path};
  }
  return $self->connector->url(@path);
}

sub _get_description ($self) {
  return SERVICE . ' drive ' . $self->name;
}

sub _get_name ($self) {
  return path($self->metadata->{folder})->basename;
}

sub _load_metadata ($self) {
  my %metadata = (owner => 'Dummy Owner',);

  if ($self->{id}) {
    $metadata{id}     = $self->{id};
    $metadata{folder} = unpack 'u', $self->{id};
  } else {
    my $path = $self->{path} eq '~' ? 'Home' : $self->{path};
    $metadata{folder} = path($self->connector->configfile)->dirname->child('drives', $path);
    chomp($metadata{id} = pack 'u', $path);
  }

  return \%metadata;
}

1;

=encoding utf8

=head1 NAME

Nuvol::Dummy::Drive - Internal methods for Dummy drives

=head1 SYNOPSIS

    use Nuvol::Connector;

    my $connector = Nuvol::Connector->new($configfile, 'Dummy');
    my $drive     = $connector->drive;

=head1 DESCRIPTION

L<Nuvol::Dummy::Drive> provides internal methods for Dummy drives.

=head1 SEE ALSO

L<Nuvol::Drive>, L<Nuvol::Dummy>.

=cut
