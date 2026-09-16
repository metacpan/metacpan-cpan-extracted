package OrePAN2::S3::Role::Upload;

use strict;
use warnings;

use CLI::Simple::Constants qw(:booleans);
use CLI::Simple::Utils qw(slurp);
use English qw(-no_match_vars);
use File::Basename qw(basename);

use Role::Tiny;

########################################################################
sub cmd_upload {  # alias add
########################################################################
  my ( $self, $distribution ) = @_;

  my ($file) = $self->get_args;
  $file //= $self->get_distribution;

  die "ERROR: no file specified or not found\n"
    if !$file || !-f $file;

  die "ERROR: not a tar ball\n"
    if $file !~ /[.]tar[.]gz$/xsm;

  $self->set_distribution($file);

  my $dirty = $self->_check_dirty($file);

  if ($dirty) {
    if ( !$self->get_force ) {
      print {*STDOUT} "ERROR: You're trying to upload an uncommitted distribution. Use --force to force upload\n";
      return $FAILURE;
    }

    print {*STDOUT} "WARNING: You're uploading an uncommitted distribution - $dirty\n";
  }

  $self->_upload($file);

  return $SUCCESS;
}

########################################################################
sub _check_dirty {
########################################################################
  my ( $self, $file ) = @_;

  return
    if !$self->get_dirty_check;

  require Archive::Tar;

  my $tar = Archive::Tar->new;
  $tar->read($file);

  my $name = $file;
  $name =~ s/[-]\d.*$//xsm;
  $name =~ s/[-]/\//xsmg;

  my $content = eval { $tar->get_content( sprintf '%s/lib/%s.pm', basename( $file, '.tar.gz' ), $name ); };

  return
    if !$content;

  my ($dirty) = $content =~ /GIT_DIRTY\s*=\s['"](.*?)['"];\n/xsm;

  return
    if !$dirty || $dirty !~ /dirty/xsm;

  return $dirty;
}

########################################################################
sub _upload {
########################################################################
  my ( $self, $file ) = @_;

  my $config      = $self->get_config;
  my $prefix      = $config->{AWS}{prefix};
  my $base        = basename($file);
  my $tarball_key = sprintf '%s/authors/id/%s/%s', $prefix, $self->get_author_path, $base;

  $self->get_s3->put_object( $self->get_bucket_name, $tarball_key, slurp($file) );
  $self->get_logger->info( sprintf 'uploaded %s => %s', $file, $tarball_key );

  return $TRUE;
}

1;

__END__

=pod

=head1 NAME

OrePAN2::S3::Role::Upload - Role providing upload functionality for OrePAN2::S3

=head1 SYNOPSIS

  use Role::Tiny::With;
  with 'OrePAN2::S3::Role::Upload';

=head1 DESCRIPTION

C<OrePAN2::S3::Role::Upload> is consumed by L<OrePAN2::S3>. It provides the 
C<cmd_upload> method to upload distribution tarballs directly to the DarkPAN 
S3 bucket without triggering index updates.

=head1 METHODS

=head2 cmd_upload( [ $distribution ] )

Validates that the given file exists and ends in C<.tar.gz>, sets the distribution 
attribute on the instance, and uploads the object to S3 under C<< <prefix>/authors/id/... >>.

Returns C<$SUCCESS> (1) on completion.

=cut
