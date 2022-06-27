package Mite::Config;
use Mite::MyMoo;
with qw(Mite::Role::HasYAML);

has mite_dir_name =>
  is            => ro,
  isa           => Str,
  default       => '.mite';

has mite_dir =>
  is            => ro,
  isa           => Path,
  coerce        => true,
  lazy          => true,
  default       => sub {
      my $self = shift;
      return $self->find_mite_dir ||
        croak "No @{[$self->mite_dir_name]} directory found.\n";
  };

has config_file =>
  is            => ro,
  isa           => Path,
  coerce        => true,
  lazy          => true,
  default       => sub {
      my $self = shift;
      return $self->mite_dir->child("config");
  };

has data =>
  is            => rw,
  isa           => HashRef,
  lazy          => true,
  default       => sub {
      my $self = shift;
      return $self->yaml_load( $self->config_file->slurp_utf8 );
  };

has search_for_mite_dir =>
  is            => rw,
  isa           => Bool,
  default       => true;

sub make_mite_dir {
    my ( $self, $dir ) = ( shift, @_ );
    $dir //= Path::Tiny->cwd;

    return Path::Tiny::path($dir)->child($self->mite_dir_name)->mkpath;
}

sub write_config {
    my ( $self, $data ) = ( shift, @_ );
    $data //= $self->data;

    $self->config_file->spew_utf8( $self->yaml_dump( $data ) );
    return;
}

sub dir_has_mite {
    my ( $self, $dir ) = ( shift, @_ );

    my $maybe_mite = Path::Tiny::path($dir)->child($self->mite_dir_name);
    return $maybe_mite if -d $maybe_mite;
    return;
}

sub find_mite_dir {
    my ( $self, $current ) = ( shift, @_ );
    $current //= Path::Tiny->cwd;

    do {
        my $maybe_mite = $self->dir_has_mite($current);
        return $maybe_mite if $maybe_mite;

        $current = $current->parent;
    } while $self->search_for_mite_dir && !$current->is_rootdir;

    return;
}

sub should_tidy {
    my $self = shift;
    $self->data->{perltidy} && eval { require Perl::Tidy; 1 };
}

1;
