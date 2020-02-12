package Nuvol::Office365::Drive;
use Mojo::Base -role, -signatures;

use Mojo::Util 'url_unescape';

use constant SERVICE => 'Office365';

# internal methods

sub _build_url ($self, @path) {
  if ($self->{metadata}) {
    unshift @path, 'drives', $self->{metadata}{id};
  } elsif ($self->{id}) {
    unshift @path, 'drives', $self->{id};
  } elsif ($self->{path} eq '~') {
    unshift @path, qw|me drive|;
  } else {
    unshift @path, $self->{path}, 'drive';
  }

  return $self->connector->url(@path);
}

sub _get_description ($self) {
  my $rv       = ucfirst $self->name . ' ';
  my $metadata = $self->metadata;
  if ($rv eq 'OneDrive') {
    $rv .= ucfirst "$metadata->{driveType} $metadata->{owner}{user}{displayName}";
  } else {
    $self->metadata->{webUrl} =~ m|https://(.*)|;
    $rv .= url_unescape $1;
  }

  return $rv;
}

sub _get_name ($self) {
  return $self->metadata->{name};
}

sub _load_metadata ($self) {
  my $res = $self->connector->_ua_get($self->url);
  Carp::confess $res->message if $res->is_error;

  return $res->json;
}

1;

=encoding utf8

=head1 NAME

Nuvol::Office365::Drive - Internal methods for Office 365 drives

=head1 DESCRIPTION

L<Nuvol::Office365::Drive> provides internal methods for Office 365 drives.

=head1 SEE ALSO

L<Nuvol::Drive>, L<Nuvol::Office365>.

=cut
