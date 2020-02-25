package Nuvol::Office365::File;
use Mojo::Base -role, -signatures;

use Mojo::Asset::File;
use Mojo::UserAgent;

use constant {BIG_FILE => 4 * 1024**2, FRAGMENT_SIZE => 10 * 1024**2,};

# internal methods

sub _do_remove ($self) {
  return $self->_remove_item;
}

sub _do_slurp ($self) {
  my $res = Mojo::UserAgent->new->get($self->download_url)->result;
  Carp::confess $res->message if $res->is_error;

  return $res->body;
}

sub _do_spurt ($self, @data) {
  my $res = $self->drive->connector->_ua_put($self->url('content'), join '', @data);
  Carp::confess $res->message if $res->is_error;

  $self->_set_metadata($res->json);

  return $self;
}

sub _from_file ($self, $source) {

  # issue copy command
  my %target = (
    parentReference => $self->_parent_reference,
    name            => $self->name,
  );
  my $res = $source->drive->connector->_ua_post($source->url('copy'), json => \%target);
  Carp::confess $res->message if $res->is_error;
  my $location = $res->headers->location;
  my $ua       = Mojo::UserAgent->new;

  # wait for process to finish
  $res = $ua->get($location)->result;
  Carp::confess $res->message if $res->is_error;
  while (!$res->json->{resourceId}) {
    sleep 1;
    $res = $ua->get($location)->result;
    Carp::confess $res->message if $res->is_error;
  }

  delete $self->{metadata};
  $self->{id} = $res->json->{resourceId};
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
  my $url = $self->metadata->{'@microsoft.graph.downloadUrl'}
    or Carp::confess 'Download URL not available!';
  return $url;
}

sub _to_host ($self, $target) {
  my $res = Mojo::UserAgent->new->get($self->download_url)->result;
  Carp::confess $res->message if $res->is_error;

  $res->content->asset->move_to($target);
}

sub _upload_large ($self, $asset) {
  my $connector = $self->drive->connector;

  # create upload session
  my $res = $connector->_ua_post($self->url('createUploadSession'));
  Carp::confess $res->message if $res->is_error;

  my $upload_url = $res->json->{uploadUrl};

  # upload portions
  my $size     = $asset->size;

  for my $portion (1 .. ceil($size / FRAGMENT_SIZE)) {
    my $from = ($portion - 1) * FRAGMENT_SIZE;
    my $to   = $portion * FRAGMENT_SIZE;
    $to = $size if $to > $size;
    $to--;

    $res = $connector->_ua_put(
      $upload_url,
      {'Content-Range' => "bytes $from-$to/$size"},
      $asset->get_chunk($from, FRAGMENT_SIZE)
    );
    Carp::confess $res->message if $res->is_error;
  }

  $self->_set_metadata($res->json);
}

sub _upload_small ($self, $asset) {
  my $res = $self->drive->connector->_ua_put($self->url('content'), $asset->slurp);
  Carp::confess $res->message if $res->is_error;

  $self->_set_metadata($res->json);
}

1;

=encoding utf8

=head1 NAME

Nuvol::Office365::File - Internal methods for Office 365 files

=head1 DESCRIPTION

L<Nuvol::Office365::File> provides internal methods for Office 365 files.

=head1 SEE ALSO

L<Nuvol::Office365>, L<Nuvol::Role::File>.

=cut
