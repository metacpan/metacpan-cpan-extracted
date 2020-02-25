package Nuvol::Office365::Item;
use Mojo::Base -role, -signatures;

use constant SERVICE => 'Office365';

# internal methods

sub _build_realpath ($self) {
  my $rv;
  if (defined $self->{path}) {
    $rv = $self->{path};
  } else {
    my $metadata = $self->metadata;
    $rv = "$metadata->{parentReference}{path}/$metadata->{name}" =~ s|.*root:/||r;
  }

  return $rv;
}

sub _build_url ($self, @path) {
  if ($self->{id}) {
    unshift @path, 'items', $self->{id};
  } else {
    my @parts = $self->realpath->@*;
    if (@parts) {
      $parts[-1] .= ':';
      unshift @path, 'root:', @parts;
    } else {
      unshift @path, 'root';
    }
  }

  return $self->drive->url(@path);
}

sub _check_existence ($self) {
  my $metadata = $self->metadata;
  return $metadata && $metadata->{id};
}

sub _get_description ($self) {
  return join ' ', SERVICE, $self->type, $self->name;
}

sub _get_name ($self) {
  my $rv;

  if ($self->exists) {
    $rv = $self->{metadata}{name};
  } else {
    $rv = (split '/', $self->{path})[-1];
  }

  return $rv;
}

sub _get_type ($self, $params) {
  my $rv;

  if ($params->{metadata}) {
    if ($params->{metadata}{file}) {
      $rv = 'File';
    } elsif ($params->{metadata}{folder}) {
      $rv = 'Folder';
    }
  } else {
    $rv = $params->{type};
  }

  return $rv;
}

sub _load_metadata ($self) {
  my $rv;

  my $res = $self->drive->connector->_ua_get($self->url);
  if ($res->is_error) {
    if ($res->code == 404) {
      $rv = {};
    } else {
      Carp::confess $res->message;
    }
  } else {
    $rv = $res->json;
  }

  return $rv;
}

sub _parent_reference ($self) {
  my %rv;

  if ($self->{metadata}) {
    %rv = $self->{metadata}{parentReference}->%*;
  } elsif ($self->{path}) {
    $self->{path} =~ m|(.+)/|;
    %rv = (driveId => $self->drive->id, path => $1);
  }

  return \%rv;
}

sub _remove_item ($self) {
  my $res = $self->drive->connector->_ua_delete($self->url);
  Carp::confess $res->message if $res->is_error;

  $self->_set_metadata($res->json);

  return $self;
}

1;

=encoding utf8

=head1 NAME

Nuvol::Office365::Item - Internal methods for Office 365 items

=head1 DESCRIPTION

L<Nuvol::Office365::Item> provides internal methods for Office 365 items.

=head1 SEE ALSO

L<Nuvol::Office365>, L<Nuvol::Item>.

=cut
