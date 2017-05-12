package Mite::Config;

use feature ':5.10';

use Mouse;
with qw(Mite::Role::HasYAML);

use Mite::Types;
use Path::Tiny;
use Method::Signatures;
use Carp;

has mite_dir_name =>
  is            => 'ro',
  isa           => 'Str',
  default       => '.mite';

has mite_dir =>
  is            => 'ro',
  isa           => 'Path',
  coerce        => 1,
  lazy          => 1,
  default       => method {
      return $self->find_mite_dir ||
        die "No @{[$self->mite_dir_name]} directory found.\n";
  };

has config_file =>
  is            => 'ro',
  isa           => 'Path',
  coerce        => 1,
  lazy          => 1,
  default       => method {
      return $self->mite_dir->child("config");
  };

has data =>
  is            => 'rw',
  isa           => 'HashRef',
  lazy          => 1,
  default       => method {
      return $self->yaml_load( $self->config_file->slurp_utf8 );
  };

has search_for_mite_dir =>
  is            => 'rw',
  isa           => 'Bool',
  default       => 1;

method make_mite_dir($dir=Path::Tiny->cwd) {
    return path($dir)->child($self->mite_dir_name)->mkpath;
}

method write_config(HashRef $data=$self->data) {
    $self->config_file->spew_utf8( $self->yaml_dump( $data ) );
    return;
}

method dir_has_mite($dir) {
    my $maybe_mite = path($dir)->child($self->mite_dir_name);
    return $maybe_mite if -d $maybe_mite;
    return;
}

method find_mite_dir($current=Path::Tiny->cwd) {
    do {
        my $maybe_mite = $self->dir_has_mite($current);
        return $maybe_mite if $maybe_mite;

        $current = $current->parent;
    } while $self->search_for_mite_dir && !$current->is_rootdir;

    return;
}

1;
