package Nuvol::Dropbox::File;
use Mojo::Base -role, -signatures;

use Mojo::Asset::File;
use Mojo::UserAgent;

use constant {
  BIG_FILE      => 150 * 1024**2,
  CONTENT_URL   => 'content.dropboxapi.com',
  FRAGMENT_SIZE => 50 * 1024**2,
};

# internal methods

sub _do_remove ($self) {
  return $self->_remove_item;
}

sub _do_slurp ($self) {
  my $res = $self->drive->connector->_ua_post($self->download_url, {$self->_dropbox_header(path => $self->realpath->to_route)});
  Carp::confess $res->message if $res->is_error;

  return $res->body;
}

sub _do_spurt ($self, @data) {
  my $res = $self->drive->connector->_ua_post($self->_upload_request, join '', @data);
  Carp::confess $res->body if $res->is_error;

  $self->_set_metadata($res->json);
}

sub _from_file ($self, $source) {
  my %json = (
    from_path => $source->{path} || $source->{id},
    to_path   => $self->{path}   || $self->{id},
  );
  my $res = $self->drive->connector->_ua_post($self->url('copy_v2'), json => \%json);
  Carp::confess $res->message if $res->is_error;

  $self->_set_metadata($res->json->{metadata});
}

sub _from_host ($self, $source) {
  my $asset = Mojo::Asset::File->new(path => $source);
  if ($asset->size < BIG_FILE) {
    $self->_upload_small($asset);
  } else {
    $self->_upload_large($asset);
  }
}

sub _from_url ($self, $url) {
  $self->_download_upload($url);
}

sub _get_download_url ($self) {
  return $self->url('download')->host(CONTENT_URL);
}

sub _to_host ($self, $target) {
  my $res = $self->drive->connector->_ua_post($self->download_url,
    {$self->_dropbox_header(path => $self->realpath->to_route)});
  Carp::confess $res->message if $res->is_error;

  $res->content->asset->move_to($target);
}

sub _upload_large ($self, $asset) {
  Carp::croak 'Not implemented!';
}

sub _upload_request($self) {
  my @request;
  push @request, $self->url('upload')->host(CONTENT_URL);
  push @request,
    {
    $self->_dropbox_header(mode => 'overwrite', path => $self->realpath->to_route),
    'Content-Type' => 'application/octet-stream',
    };

  return @request;
}

sub _upload_small ($self, $asset) {
  my $res = $self->drive->connector->_ua_post($self->_upload_request, $asset->slurp);
  Carp::confess $res->message if $res->is_error;

  $self->_set_metadata($res->json);
}

1;

=encoding utf8

=head1 NAME

Nuvol::Dropbox::File - Internal methods for Dropbox folders

=head1 DESCRIPTION

L<Nuvol::Dropbox::File> provides internal methods for Dropbox folders.

=head1 SEE ALSO

L<Nuvol::Dropbox>, L<Nuvol::Role::File>.

=cut
