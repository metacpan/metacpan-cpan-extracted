package OrePAN2::S3::Role::UploadArtifacts;

use strict;
use warnings;

use CLI::Simple::Constants qw(:booleans);
use CLI::Simple::Utils qw(slurp);
use Digest::MD5 qw(md5_base64);

use Role::Tiny;

########################################################################
sub cmd_upload_artifacts {
########################################################################
  my ($self) = @_;

  require LWP::MediaTypes;

  my $config = $self->get_config;
  my $files  = $config->{index}{files} // {};

  if ( !keys %{$files} ) {
    $self->get_logger->info('no artifacts configured ');
    return $SUCCESS;
  }

  my $config_dirty = $FALSE;

  for my $src ( sort keys %{$files} ) {
    my $entry = $files->{$src};

    my $path = $src !~ /^\//xsm ? $src : sprintf '%s/%s', $self->get_dist_dir, $src;

    my $dest = ref $entry ? $entry->{dest} : $entry;

    if ( !-e $path ) {
      $self->get_logger->warn("$path not found, skipping...");
      next;
    }

    my $content = slurp($path);
    my $md5     = md5_base64($content);
    my $stored  = ref $entry ? $entry->{md5} : undef;

    if ( defined $stored && $stored eq $md5 ) {
      $self->get_logger->info("$src unchanged, skipping...");
      next;
    }

    $self->get_s3->put_object( $self->get_bucket_name, $dest, $content,
      content_type => LWP::MediaTypes::guess_media_type($path), );

    $self->get_logger->info( sprintf 'uploaded %s => %s', $path, $dest );

    $files->{$src} = { dest => $dest, md5 => $md5 };
    $config_dirty = $TRUE;
  }

  if ($config_dirty) {
    $self->write_config($config);
  }

  return $SUCCESS;
}

1;

__END__

=head1 NAME

OrePAN2::S3::Role::UploadArtifacts - Role providing cmd_upload_artifacts for OrePAN2::S3

=head1 DESCRIPTION

Consumed by L<OrePAN2::S3>. Provides C<cmd_upload_artifacts> which uploads 
multiple files listed in the configuration file to S3.

=cut
