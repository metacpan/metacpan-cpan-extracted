package Nuvol::Dropbox::Item;
use Mojo::Base -role, -signatures;

use Mojo::JSON 'to_json';

use constant SERVICE => 'Dropbox';

# internal methods

sub _build_realpath ($self) {
  return $self->{path} // $self->metadata->{path_display};
}

sub _build_url ($self, @path) {
  return $self->drive->url('files', @path);
}

sub _check_existence ($self) {
  my $metadata = $self->metadata;
  return $metadata && $metadata->{id};
}

sub _dropbox_header ($self, %params) {
  my %rv = ('Dropbox-API-Arg' => to_json(\%params));

  return %rv;
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
    $rv = ucfirst $params->{metadata}{'.tag'};
  } else {
    $rv = $params->{type};
  }

  return $rv;
}

sub _load_metadata ($self) {
  my $rv;

  my %params = (path => $self->{id} || $self->{path});
  my $res = $self->drive->connector->_ua_post($self->url('get_metadata'), json => \%params);
  if ($res->is_error) {
    if ($res->code == 409) {
      $rv = {};
    } else {
      Carp::confess $res->message;
    }
  } else {
    $rv = $res->json;
  }

  return $rv;
}

sub _remove_item ($self) {
  my $res = $self->drive->connector->_ua_post($self->url('delete_v2'),
    json => {path => $self->{id} || $self->realpath->to_route});
  Carp::confess $res->message if $res->is_error;

  $self->_set_metadata({});

  return $self;
}

1;

=encoding utf8

=head1 NAME

Nuvol::Dropbox::Item - Internal methods for Dropbox items

=head1 DESCRIPTION

L<Nuvol::Dropbox::Item> provides internal methods for Dropbox items.

=head1 SEE ALSO

L<Nuvol::Dropbox>, L<Nuvol::Item>.

=cut
