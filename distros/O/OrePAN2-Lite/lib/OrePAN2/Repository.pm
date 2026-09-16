package OrePAN2::Repository;

use strict;
use warnings;

use utf8;

use File::Find ();
use File::Spec ();
use File::pushd ();
use OrePAN2::Indexer ();
use OrePAN2::Injector ();
use OrePAN2::Repository::Cache ();

use parent qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(
  qw(
    compress_index
    cache
    directory
    indexer
    injector
    simple
  )
);

our $VERSION = '2.0.0';

sub new {
  my ( $class, @args ) = @_;
  my $options = ref $args[0] ? $args[0] : {@args};

  $options->{compress_index} //= 1;

  my $self = $class->SUPER::new($options);
  $self->_build_cache;
  $self->_build_indexer;
  $self->_build_injector;

  return $self;
}

sub has_cache  { return $_[0]->cache->is_hit( @_[ 1 .. $#_ ] ) }
sub save_cache { return $_[0]->cache->save( @_[ 1 .. $#_ ] ) }

sub _build_cache {
  my ($self) = @_;
  $self->cache( OrePAN2::Repository::Cache->new( directory => $self->directory ) );
}

sub _build_indexer {
  my ($self) = @_;

  return $self->indexer(
    OrePAN2::Indexer->new(
      directory => $self->directory,
      simple    => $self->simple
    )
  );
}

sub _build_injector {
  my ($self) = @_;
  return $self->injector( OrePAN2::Injector->new( directory => $self->directory ) );
}

sub make_index {
  my ($self) = @_;
  return $self->indexer->make_index( no_compress => !$self->compress_index );
}

sub inject {
  my ( $self, $stuff, $opts ) = @_;

  my $tarpath = $self->injector->inject( $stuff, $opts );

  return $self->cache->set( $stuff, $tarpath );
}

sub index_file {
  my ($self) = @_;

  return File::Spec->catfile( $self->directory, 'modules', '02packages.details.txt' . ( $self->compress_index ? '.gz' : q{} ) );
}

sub load_index {
  my ($self) = @_;

  my $index = OrePAN2::Index->new();
  $index->load( $self->index_file );

  return $index;
}

# Remove files that are not referenced by the index file.
sub gc {
  my ( $self, $callback ) = @_;

  return if !-f $self->index_file;

  my $index = $self->load_index;
  my %registered;
  for my $package ( $index->packages ) {
    my ( $version, $path ) = $index->lookup($package);
    $registered{$path}++;
  }

  my $pushd = File::pushd::pushd( File::Spec->catdir( $self->directory, 'authors', 'id' ) );

  return File::Find::find(
    { no_chdir => 1,
      wanted   => sub {
        return if !-f $_;
        $_ = File::Spec->canonpath($_);
        if ( !$registered{$_} ) {
          $callback ? $callback->($_) : unlink $_;
        }
        1;
      },
    },
    q{.}
  );
}

1;

