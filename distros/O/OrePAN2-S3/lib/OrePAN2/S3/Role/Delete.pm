package OrePAN2::S3::Role::Delete;

use strict;
use warnings;

use Carp qw(croak);
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

  my $s3 = $self->get_s3;

  my $bucket_name = $self->get_bucket_name;

  die "ERROR: no file specified\n"
    if !$file;

  my $config = $self->get_config;
  my $prefix = $config->{AWS}{prefix};

  if ( $file !~ /[.]tar[.]gz$/xsm ) {
    my $path    = sprintf '%s/authors/id/%s/%s', $prefix, $self->get_author_path, $file;
    my @objects = $s3->list_all_objects_v2( $bucket_name, prefix => $path );

    if ( @objects == 1 ) {
      $file = $objects[0]->{key};
    }
    elsif ( !$self->get_delete_all || $self->get_dryrun ) {
      $self->get_logger->warn( sprintf qq{Multiple objects match "%s" (%d) - use --delete-all to remove all objects\n},
        $file, scalar @objects );

      return $SUCCESS;
    }
    else {
      $file = [ map { $_->{key} } @objects ];

      print {*STDOUT} sprintf "You are about to delete these objects:\n%s\n", join "\n", @{$file};

      return $FAILURE
        if !$self->confirm('Proceed?');
    }
  }
  else {
    my $key  = sprintf '%s/authors/id/%s/%s', $prefix, $self->get_author_path, basename($file);
    my $meta = $s3->head_object( $bucket_name, $key );

    if ( !$meta ) {
      $self->get_logger->warn( sprintf '"%s" does not exist...deleting docs only', $key );
    }
  }

  $file = ref $file ? $file : [$file];

  foreach my $key ( @{$file} ) {
    my $obj = sprintf '%s/authors/id/%s/%s', $prefix, $self->get_author_path, basename($key);
    $self->get_logger->info( sprintf 'deleting %s%s', $obj, $self->get_dryrun ? ' (dryrun)' : q{} );

    if ( !$self->get_dryrun ) {
      $s3->delete_object( $bucket_name, $obj );
    }
  }

  $self->_delete_docs( $s3, $bucket_name, basename( $file->[0] ) );

  $self->set_upload($TRUE);

  $self->update_index(
    sub {
      my ($index) = @_;

      my @packages;

      foreach ( @{$file} ) {
        push @packages, $self->_packages_for_archive( $index, sprintf '%s/%s', $self->get_author_path, basename($_) );
      }

      foreach my $p (@packages) {
        $self->get_logger->info( sprintf 'deleting %s from index', $p );
        $index->delete_index($p);
      }

      return $TRUE;
    }
  );

  if ( my $packages_index = $self->has_packages_version_index ) {
    $self->_delete_from_packages_version_index( $packages_index, $file );
  }

  if ( $self->get_invalidate_index ) {
    $self->get_logger->info( sprintf 'invalidating index...%s', $self->get_dryrun ? '(dryrun)' : q{} );
    if ( !$self->get_dryrun ) {
      $self->_invalidate_index;
    }
  }

  return $SUCCESS;
}

########################################################################
sub _delete_from_packages_version_index {
########################################################################
  my ( $self, $packages_index, $files ) = @_;

  require DarkPAN::Indexer;

  my $indexer = DarkPAN::Indexer->new( config => $self->get_config );

  foreach my $dist ( @{$files} ) {
    $self->get_logger->info( sprintf 'deleting %s from %s', $dist, $packages_index );
    $indexer->delete_from_index( distribution => $dist );
  }

  return;
}

########################################################################
sub confirm {
########################################################################
  my ( $self, $prompt ) = @_;

  print "$prompt [y/N] ";

  my $answer = <STDIN>;
  return 0 if !defined $answer;

  chomp $answer;

  return $answer =~ /\Ay(?:es)?\z/i ? 1 : 0;
}

########################################################################
sub _delete_docs {
########################################################################
  my ( $self, $s3, $bucket_name, $file ) = @_;

  my ($dir) = $file =~ /^(.*?)[-]\d/xsm;

  my @objects = $s3->list_all_objects_v2( $bucket_name, prefix => "docs/$dir" );

  my @doc_files = map { $_->{key} } @objects;

  foreach my $key (@doc_files) {
    $self->get_logger->info( sprintf 'deleting %s%s', $key, $self->get_dryrun ? ' (dryrun)' : q{} );
    next if $self->get_dryrun;

    $s3->delete_object( $bucket_name, $key );
  }

  return;
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
