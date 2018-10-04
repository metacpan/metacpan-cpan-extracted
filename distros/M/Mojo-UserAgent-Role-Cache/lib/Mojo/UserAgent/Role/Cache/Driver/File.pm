package Mojo::UserAgent::Role::Cache::Driver::File;
use Mojo::Base -base;

use Mojo::File;
use Mojo::Util 'md5_sum';

has root_dir => sub { $ENV{MOJO_USERAGENT_CACHE_DIR} || Mojo::File::tempdir('mojo-useragent-cache-XXXXX') };

sub get {
  my $self = shift;
  my $file = $self->_path(shift);
  return -e $file ? $file->slurp : undef;
}

sub remove {
  my $self = shift;
  my $file = $self->_path(shift);
  unlink $file or die "unlink $file: $!" if -e $file;
  return $self;
}

sub set {
  my $self = shift;
  my $file = $self->_path(shift);
  my $dir  = Mojo::File->new($file->dirname);
  $dir->make_path({mode => 0755}) unless -d $dir;
  $file->spurt(shift);
  return $self;
}

sub _path {
  my ($self, $key) = @_;
  my $method = shift @$key;
  my $last = substr md5_sum(pop @$key), 0, 12;

  return Mojo::File->new($self->root_dir, $method, (map { substr md5_sum($_), 0, 12 } @$key), "$last.http");
}

1;

=encoding utf8

=head1 NAME

Mojo::UserAgent::Role::Cache::Driver::File - Default cache driver for Mojo::UserAgent::Role::Cache

=head1 SYNOPSIS

  my $driver = Mojo::UserAgent::Role::Cache::Driver::File->new;

  $driver->set($key, $data);
  $data = $driver->get($key);
  $driver->remove($key);

=head1 DESCRIPTION

L<Mojo::UserAgent::Role::Cache::Driver::File> is the default cache driver for
L<Mojo::UserAgent::Role::Cache>. It should provide the same interface as
L<CHI>.

=head1 ATTRIBUTES

=head2 root_dir

  $str = $self->root_dir;
  $self = $self->root_dir("/path/to/mojo-useragent-cache");

Where to store the cached files. Defaults to the C<MOJO_USERAGENT_CACHE_DIR>
environment variable or a L<tempdir|Mojo::File/tempdir>.

=head1 METHODS

=head2 get

  $data = $self->get($key);

Retrive data from the cache. Returns C<undef()> if the C<$key> is not L</set>.

=head2 remove

  $self = $self->remove($key);

Removes data from the cache, by C<$key>.

=head2 set

  $self = $self->set($key => $data);

Stores new C<$data> in the cache.

=head1 SEE ALSO

L<Mojo::UserAgent::Role::Cache>.

=cut
