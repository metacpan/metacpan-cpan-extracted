package OrePAN2::S3::Role::Delete;

use strict;
use warnings;

use CLI::Simple::Constants qw(:booleans);
use English qw(-no_match_vars);
use File::Basename qw(basename);

use Role::Tiny;

########################################################################
sub cmd_delete {
########################################################################
  my ($self) = @_;

  my ($file) = $self->get_args;
  $file //= $self->get_distribution;

  die "ERROR: no file specified\n" if !$file;

  my $config      = $self->get_config;
  my $prefix      = $config->{AWS}{prefix};
  my $base        = basename($file);
  my $tarball_key = sprintf '%s/authors/id/%s/%s', $prefix, $self->get_author_path, $base;

  $self->get_s3->delete_object( $self->get_bucket_name, $tarball_key );
  $self->get_logger->info( sprintf 'deleted %s', $tarball_key );

  $self->update_index(
    sub {
      my ($index) = @_;

      my @packages = $self->_packages_for_archive( $index, sprintf '%s/%s', $self->get_author_path, $base );

      foreach (@packages) {
        $index->delete_index($_);
      }
    }
  );

  return $SUCCESS;
}

1;

__END__

=pod

=head1 NAME

OrePAN2::S3::Role::Delete - Role providing cmd_delete for OrePAN2::S3

=head1 DESCRIPTION

Consumed by L<OrePAN2::S3>. Provides C<cmd_delete> which deletes a
distribution from the DarkPAN index in a single operation.

=cut
