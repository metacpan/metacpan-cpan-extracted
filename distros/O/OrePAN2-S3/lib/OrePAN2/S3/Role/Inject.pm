package OrePAN2::S3::Role::Inject;

use strict;
use warnings;

use CLI::Simple::Constants qw(:booleans);
use CLI::Simple::Utils qw(slurp);
use English qw(-no_match_vars);
use File::Basename qw(basename);
use File::Temp qw(tempfile);

use Role::Tiny;

use Readonly;
Readonly::Scalar our $PACKAGE_INDEX => '02packages.details.txt.gz';

########################################################################
sub cmd_inject {
########################################################################
  my ($self) = @_;

  my ($file) = $self->get_args;
  $file //= $self->get_distribution;

  die "ERROR: no file specified\n" if !$file;
  die "ERROR: $file not found\n"   if !-e $file;

  my $config = $self->get_config;
  my $prefix = $config->{AWS}{prefix};
  my $base   = basename($file);

  my $tarball_key = sprintf '%s/authors/id/%s/%s', $prefix, $self->get_author_path, $base;

  my $content = slurp($file);
  $self->get_s3->put_object( $self->get_bucket_name, $tarball_key, $content, content_type => 'application/gzip', );

  $self->get_logger->info( sprintf 'uploaded %s to %s', $base, $tarball_key );

  return $SUCCESS if $self->get_upload_only;

  return $self->_index_tarball($file);
}

########################################################################
sub _index_tarball {
########################################################################
  my ( $self, $file, $basename ) = @_;

  require IO::Compress::Gzip;
  require OrePAN2::Index;

  $basename //= basename($file);

  my $provides   = $self->scan_provides($file);
  my $index_path = sprintf '%s/%s', $self->get_author_path, $basename;

  $self->update_index(
    sub {
      my ($index) = @_;
      for my $package ( sort keys %{$provides} ) {
        my $version = $provides->{$package}{version};
        $index->add_index( $package, $version, $index_path );
        $self->get_logger->info( sprintf 'indexed %s %s', $package, $version // 'undef' );
      }
    }
  );

  return $SUCCESS;
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
  my ($entry) = grep { $_->name =~ m{/META\.(?:json|yml|yaml)$}xsm } $tar->get_files;

  if ( !$entry ) {
    $self->get_logger->warn("no META file found in $file");
    return {};
  }

  my ($prefix) = ( split m{/}xsm, $entry->name )[0];

  for my $metafile (qw(META.json META.yml META.yaml)) {
    my $content = eval { $tar->get_content("$prefix/$metafile") };
    next if !$content;

    my $meta = eval { CPAN::Meta->load_string($content) };
    next if !$meta || $EVAL_ERROR;

    return $meta->{provides} if $meta->{provides};
  }

  # Should not happen - injecting tarballs we create with CPAN::Maker
  $self->get_logger->warn("META found but no provides in $file");

  return {};
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

  $code->($index);

  my $gz_content;

  my $gz = IO::Compress::Gzip->new( \$gz_content )
    or die "gzip failed\n";

  $gz->print( $index->as_string );

  $gz->close;

  my $index_key = sprintf '%s/modules/02packages.details.txt.gz', $prefix;
  $self->get_s3->put_object( $self->get_bucket_name, $index_key, $gz_content, content_type => 'application/gzip', );

  $self->get_logger->info( sprintf 'updated index at %s', $index_key );

  return;
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
