package OrePAN2::S3::Role::Inject;

use strict;
use warnings;

use CLI::Simple::Constants qw(:booleans);
use CLI::Simple::Utils qw(slurp);
use English qw(-no_match_vars);
use File::Basename qw(basename);

use Role::Tiny;

########################################################################
sub cmd_inject {
########################################################################
  my ($self) = @_;

  require IO::Compress::Gzip;
  require OrePAN2::Index;

  my ($file) = $self->get_args;
  $file //= $self->get_distribution;

  die "ERROR: no file specified\n"
    if !$file;

  die "ERROR: $file not found\n"
    if !-e $file;

  my $config = $self->get_config;
  my $prefix = $config->{AWS}{prefix};

  my $base = basename($file);

  # 1. upload the tarball
  my $tarball_key = sprintf '%s/authors/id/%s/%s', $prefix, $self->get_author_path, $base;

  my $content = slurp($file);
  $self->get_s3->put_object( $self->get_bucket_name, $tarball_key, $content, content_type => 'application/gzip', );

  $self->get_logger->info( sprintf 'uploaded %s to %s', $base, $tarball_key );

  # scan the tarball for provides
  my $provides   = $self->scan_provides($file);
  my $index_path = sprintf '%s/%s', $self->get_author_path, $base;

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

1;

__END__

=pod

=head1 NAME

OrePAN2::S3::Role::Inject - Role providing cmd_inject for OrePAN2::S3

=head1 DESCRIPTION

Consumed by L<OrePAN2::S3>. Provides C<cmd_inject> which uploads a
tarball to S3 and updates the DarkPAN index in a single operation.

=cut
