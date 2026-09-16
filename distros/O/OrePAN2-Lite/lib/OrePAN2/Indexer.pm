package OrePAN2::Indexer;
use strict;
use warnings;

use utf8;

use Archive::Tar;
use CPAN::Meta 2.131560 ();
use English qw(-no_match_vars);
use File::Basename ();
use File::Find qw( find );
use File::Spec ();
use File::Temp qw( tempdir );
use File::pushd qw( pushd );
use IO::Zlib ();
use OrePAN2::Index ();
use Parse::LocalDistribution ();
use Path::Tiny ();

use Role::Tiny::With;
with 'OrePAN2::Role::HasLogger';

use parent qw(Class::Accessor::Fast);

our $VERSION = '2.0.0';

__PACKAGE__->mk_accessors(qw(directory simple));

########################################################################
sub new {
########################################################################
  my ( $class, @args ) = @_;
  my $options = ref $args[0] ? $args[0] : {@args};
  $options->{simple} //= 0;
  return $class->SUPER::new($options);
}

########################################################################
sub make_index {
########################################################################
  my ( $self, %args ) = @_;

  my $no_compress = $args{no_compress};

  my @files = $self->list_archive_files();

  my $index = OrePAN2::Index->new();
  for my $archive_file (@files) {
    $self->add_index( $index, $archive_file );
  }
  $self->write_index( $index, $no_compress );
  return $index;
}

########################################################################
sub add_index {
########################################################################
  my ( $self, $index, $archive_file ) = @_;
  my $tmpdir = tempdir( 'orepan2.XXXXXX', TMPDIR => 1, CLEANUP => 1 );

  my $tar = Archive::Tar->new;
  $tar->read($archive_file);
  {
    my $guard = pushd($tmpdir);  # setcwd alternative: extract relative to tmpdir
    $tar->extract;
  }

  my $provides = $self->scan_provides( $tmpdir, $archive_file );
  my $path     = $self->_orepan_archive_path($archive_file);

  foreach my $package ( sort keys %{$provides} ) {
    $index->add_index( $package, $provides->{$package}->{version}, $path, );
  }

  return;
}

########################################################################
sub _orepan_archive_path {
########################################################################
  my $self         = shift;
  my $archive_file = shift;
  my $path         = File::Spec->abs2rel( $archive_file, File::Spec->catfile( $self->directory, 'authors', 'id' ) );
  $path =~ s!\\!/!g;
  return $path;
}

########################################################################
sub scan_provides {
########################################################################
  my ( $self, $dir, $archive_file ) = @_;

  my $guard = pushd( glob("$dir/*") );
  for my $mfile ( 'META.json', 'META.yml', 'META.yaml' ) {
    next if !-f $mfile;
    my $meta = eval { CPAN::Meta->load_file($mfile) };
    return $meta->{provides} if $meta && $meta->{provides};

    if ($EVAL_ERROR) {
      $self->log->warn( sprintf q{Error using '%s' from '%s'}, $mfile, $archive_file );
      $self->log->warn("$EVAL_ERROR");
      $self->log->warn('Attempting to continue...');
    }
  }

  $self->log->info( sprintf q{Found META file in '%s' but it does not contain 'provides'}, $archive_file );
  $self->log->info('Scanning for provided modules...');

  my $provides = eval { $self->_scan_provides('.') };
  return $provides
    if $provides;

  $self->log->warn("Error scanning: $EVAL_ERROR");

  # Return empty provides.
  return {};
}

########################################################################
sub _scan_provides {
########################################################################
  my ( $self, $dir, $meta ) = @_;

  my $provides = Parse::LocalDistribution->new( { ALLOW_DEV_VERSION => 1 } )->parse($dir);
  return $provides;
}

########################################################################
sub write_index {
########################################################################
  my ( $self, $index, $no_compress ) = @_;

  my $pkgfname
    = File::Spec->catfile( $self->directory, 'modules', $no_compress ? '02packages.details.txt' : '02packages.details.txt.gz' );
  mkdir File::Basename::dirname($pkgfname);

  my $fh = do {
    if ($no_compress) {
      open my $fh, '>:raw', $pkgfname;
      $fh;
    }
    else {
      IO::Zlib->new( $pkgfname, 'w' )
        or die "Cannot open $pkgfname for writing: $!\n";
    }
  };

  print {$fh} $index->as_string( { simple => $self->simple } );
  close $fh;

  return;
}

########################################################################
sub list_archive_files {
########################################################################
  my $self = shift;

  my $authors_dir = File::Spec->catfile( $self->directory, 'authors' );
  return () if !-d $authors_dir;

  my @files;
  find(
    { wanted => sub {
        return if $_ !~ m{
                    (?:
                          [.]tar[.]gz
                        | [.]tgz
                        | [.]zip
                    )
                \z}xsm;
        push @files, $_;
      },
      no_chdir => 1,
    },
    $authors_dir
  );

  # Sort files by modication time so that we can index distributions from
  # earliest to latest version.
  my @sorted_files = reverse sort { -M $a <=> -M $b } @files;

  return @sorted_files;
}

1;
