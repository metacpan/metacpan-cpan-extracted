package Nuvol::Dummy::File;
use Mojo::Base -role, -signatures;

use Mojo::UserAgent;

# internal methods

sub _do_remove ($self) {
  $self->_path->remove;
  delete $self->{id};
  return $self;
}

sub _do_slurp ($self) {
  return $self->_path->slurp;
}

sub _do_spurt ($self, @data) {
  $self->_path->spurt(@data);
  return $self;
}

sub _from_file ($self, $source) {
  $source->_path->copy_to($self->_path);
}

sub _from_url ($self, $url) {
  my $res = Mojo::UserAgent->new->get($url)->result;
  Carp::confess $res->message if $res->is_error;

  $res->save_to($self->_path);
}

sub _from_host ($self, $source) {
  $source->copy_to($self->_path);
}

sub _get_download_url ($self) {
  return $self->url;
}

sub _to_host ($self, $target) {
   $self->_path->copy_to($target); 
}

1;

=encoding utf8

=head1 NAME

Nuvol::Dummy::File - Internal methods for dummy files

=head1 DESCRIPTION

L<Nuvol::Dummy::File> provides internal methods for Dummy files.

=head1 SEE ALSO

L<Nuvol::Dummy>, L<Nuvol::Role::File>.

=cut
