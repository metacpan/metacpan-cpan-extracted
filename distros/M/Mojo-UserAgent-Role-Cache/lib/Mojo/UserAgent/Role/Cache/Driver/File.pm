package Mojo::UserAgent::Role::Cache::Driver::File;
use Mojo::Base -base;

use Mojo::File;
use Mojo::Util qw(md5_sum url_unescape);

use constant DEBUG  => $ENV{MOJO_CLIENT_DEBUG}    || $ENV{MOJO_UA_CACHE_DEBUG} || 0;
use constant RENAME => $ENV{MOJO_UA_CACHE_RENAME} || 0;

has root_dir => sub { $ENV{MOJO_USERAGENT_CACHE_DIR} || Mojo::File::tempdir('mojo-useragent-cache-XXXXX') };

sub get {
  my ($self, $key) = @_;
  my $file = $self->_path($key);
  $self->_try_to_rename($file, @$key) if RENAME and !-e $file;
  my $exists = -e $file;
  warn qq(-- Reading Mojo::UserAgent cache file $file\n) if DEBUG and $exists;
  return $exists ? $file->slurp : undef;
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
  warn qq(-- Writing Mojo::UserAgent cache file $file\n) if DEBUG;
  $dir->make_path({mode => 0755}) unless -d $dir;
  $file->spurt(shift);
  return $self;
}

sub _path {
  my ($self, @key) = ($_[0], @{$_[1]});

  my $safe = sub {
    my $len = length;
    ($len < 100 && $len != 32 && m!^[\w+\.-]+$!) ? $_ : md5_sum($_);
  };

  my $last = $safe->(local $_ = pop @key);
  return Mojo::File->new($self->root_dir, (map { $safe->() } @key), "$last.http");
}

# Will be removed in the future
sub _try_to_rename {
  my ($self, $to, @key) = @_;
  my @old = (shift @key, shift @key);    # method and host
  my $body = $key[-1] =~ s!^\?b=!! ? pop @key : undef;

  my $url = Mojo::URL->new('/');
  $url->query->parse($1) if $key[-1] =~ m!^\?q=(.*)!;
  pop @key;
  $url->path->parts([map { url_unescape $_ } @key]);
  push @old, $url->path_query;

  push @old, $body if defined $body;

  my $last   = substr md5_sum(pop @old), 0, 12;
  my $from   = Mojo::File->new($self->root_dir, shift @old, (map { substr md5_sum($_), 0, 12 } @old), "$last.http");
  my $to_dir = Mojo::File->new($to->dirname);

  $to_dir->make_path({mode => 0755}) unless -d $to_dir;
  rename $from, $to or die "Rename $from $to: $!" if -e $from;
}

1;

=encoding utf8

=head1 NAME

Mojo::UserAgent::Role::Cache::Driver::File - Default cache driver for Mojo::UserAgent::Role::Cache

=head1 SYNOPSIS

  my $driver = Mojo::UserAgent::Role::Cache::Driver::File->new;

  $driver->set(\@key, $data);
  $data = $driver->get(\@key);
  $driver->remove(\@key);

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

  $data = $self->get(\@key);

Retrive data from the cache. Returns C<undef()> if the C<@key> is not L</set>.

=head2 remove

  $self = $self->remove(\@key);

Removes data from the cache, by C<@key>.

=head2 set

  $self = $self->set(\@key => $data);

Stores new C<$data> in the cache.

=head1 SEE ALSO

L<Mojo::UserAgent::Role::Cache>.

=cut
