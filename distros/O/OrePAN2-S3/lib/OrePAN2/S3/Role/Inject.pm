package OrePAN2::S3::Role::Inject;

use strict;
use warnings;

use Carp;
use CLI::Simple::Constants qw(:booleans);
use CLI::Simple::Utils qw(slurp);
use Data::Dumper;
use English qw(-no_match_vars);
use File::Basename qw(basename);
use File::Temp qw(tempfile);

use Role::Tiny;

use Readonly;
Readonly::Scalar our $PACKAGE_INDEX => '02packages.details.txt.gz';

our $VERSION = '2.1.1';

########################################################################
sub cmd_inject {
########################################################################
  my ($self) = @_;

  $self->cmd_upload;

  return $self->_index_tarball( $self->get_distribution ) ? $SUCCESS : $FAILURE;
}

########################################################################
sub _index_tarball {
########################################################################
  my ( $self, $file, $basename ) = @_;

  require IO::Compress::Gzip;
  require OrePAN2::Index;

  $basename //= basename($file);

  my $provides = $self->scan_provides($file);

  if ( !$provides ) {
    $self->get_logger->error( sprintf 'ERROR: tarball %s does not provide anything!' . $file );
    return $FALSE;
  }

  my $index_path = sprintf '%s/%s', $self->get_author_path, $basename;

  return $self->update_index(
    sub {
      my ($index) = @_;

      for my $package ( sort keys %{$provides} ) {
        my $version = $provides->{$package}{version};
        if ( $index->add_index( $package, $version, $index_path ) ) {
          $self->get_logger->info( sprintf 'indexed %s %s', $package, $version // 'undef' );
        }
        else {
          $self->get_logger->error( sprintf '"%s" was not indexed!', $package );
          return $FALSE;
        }
      }

      return $TRUE;
    }
  );
}

########################################################################
sub scan_provides {
########################################################################
  my ( $self, $file ) = @_;

  require Archive::Tar;
  require CPAN::Meta;

  my $tar = Archive::Tar->new;
  $tar->read($file);

  # find the top-level prefix, e.g. "CPAN-Maker-1.8.2"
  my ($entry) = grep { $_->name =~ m{META\.(?:json|yml|yaml)$}xsm } $tar->get_files;

  if ( !$entry ) {
    $self->get_logger->warn( sprintf 'ERROR: no META file found in %s', $file );
    return;
  }

  $self->get_logger->debug( sprintf 'entry: %s', $entry->name );

  my $meta = eval {
    my $name    = $entry->prefix ? sprintf( q{%s/%s}, $entry->prefix, $entry->name ) : $entry->name;
    my $content = eval { $tar->get_content($name); };
    return CPAN::Meta->load_string($content);
  };

  return $meta->{provides}
    if $meta && $meta->{provides};

  # Should not happen - injecting tarballs we create with CPAN::Maker
  if ( !$meta ) {
    $self->get_logger->error( sprintf 'ERROR: META found but no provides in %s', $file );
    return;
  }

  $self->get_logger->error( sprintf 'ERROR: could not load metadata from %s in %s', $entry->name, $file );
  return;
}

########################################################################
sub fetch_orepan_index {
########################################################################
  my ($self) = @_;

  my ( $fh, $filename ) = tempfile(
    'XXXXXX',
    SUFFIX => '.gz',
    UNLINK => $FALSE,
    DIR    => '/tmp',
  );

  my $config = $self->get_config;

  my $key = sprintf '%s/modules/%s', $config->{AWS}{prefix}, $PACKAGE_INDEX;
  $self->get_s3->get_object( $self->get_bucket_name, $key, filename => $filename );

  return $filename;
}

########################################################################
sub update_index {
########################################################################
  my ( $self, $code ) = @_;

  require IO::Compress::Gzip;
  require OrePAN2::Index;

  my $config = $self->get_config;
  my $prefix = $config->{AWS}{prefix};

  my $index_file = $self->fetch_orepan_index;
  my $index      = OrePAN2::Index->new;
  $index->load($index_file);
  unlink $index_file;

  return
    if !$code->($index);

  my $gz_content;

  my $gz = IO::Compress::Gzip->new( \$gz_content )
    or die "gzip failed\n";

  $gz->print( $index->as_string );

  $gz->close;

  my $index_key = sprintf '%s/modules/02packages.details.txt.gz', $prefix;

  if ( !$self->get_dryrun ) {
    $self->get_s3->put_object( $self->get_bucket_name, $index_key, $gz_content, content_type => 'application/gzip', );
  }

  $self->get_logger->info( sprintf 'updated package index: %s%s', $index_key, $self->get_dryrun ? ' (dryrun)' : q{} );

  if ( $self->get_update_site_index ) {
    $self->get_logger->info( sprintf 'creating site index...%s', $self->get_dryrun ? '(dryrun)' : q{} );

    if ( !$self->get_dryrun ) {
      $self->cmd_create_site_index;
    }
  }

  if ( $self->get_save_index || $self->get_dryrun ) {
    $self->get_logger->info('writing local copy of 02packages.details.txt.gz');

    open my $fh, '>', '02packages.details.txt.gz'
      or die "ERROR: could not open 02packages.details.txt.gz for writing\n$OS_ERROR";

    print {$fh} $gz_content;

    close $fh;
  }

  return $TRUE;
}

1;

__END__

=pod

=head1 NAME

OrePAN2::S3::Role::Inject - Role providing cmd_inject for OrePAN2::S3

=head1 DESCRIPTION

Consumed by L<OrePAN2::S3>. Provides C<cmd_inject> which uploads a
tarball to S3 and updates the DarkPAN index in a single operation.

=cut
