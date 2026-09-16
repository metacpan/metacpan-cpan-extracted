package OrePAN2::Repository::Cache;

use strict;
use warnings;

use utf8;

use Carp ();
use Digest::MD5 ();
use English q(-no_match_vars);
use File::Path ();
use File::Spec ();
use File::stat qw( stat );
use IO::File::AtomicChange ();
use JSON::PP ();

use parent qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(
  qw(
    directory
    data
    filename
    is_dirty
  )
);

our $VERSION = '2.0.0';

sub new {
  my ( $class, @args ) = @_;
  my $options = ref $args[0] ? $args[0] : {@args};

  $options->{is_dirty} //= 0;

  my $self = $class->SUPER::new($options);
  $self->_build_filename;
  $self->_build_data;

  return $self;
}

sub _build_data {
  my ($self) = @_;

  my $data = do {
    if ( open my $fh, '<', $self->filename ) {
      JSON::PP->new->utf8->decode(
        do { local $RS; <$fh> }
      );
    }
    else {
      +{};
    }
  };

  $self->data($data);

  return $data;
}

sub _build_filename {
  my ($self) = @_;

  return $self->filename( File::Spec->catfile( $self->directory, 'orepan2-cache.json' ) );
}

sub is_hit {
  my ( $self, $stuff ) = @_;

  my $entry = $self->data->{$stuff};

  return 0 if !$entry || !$entry->{filename} || !$entry->{md5};

  my $fullpath = File::Spec->catfile( $self->directory, $entry->{filename} );
  return 0 if !-f $fullpath;

  if ( my $stat = stat($stuff) && defined( $entry->{mtime} ) ) {
    return 0
      if $stat->mtime ne $entry->{mtime};
  }

  my $md5 = $self->calc_md5($fullpath);

  return ( !$md5 || $md5 ne $entry->{md5} ) ? 0 : 1;
}

sub calc_md5 {
  my ( $self, $filename ) = @_;

  open my $fh, '<', $filename
    or do {
    return;
    };

  my $md5 = Digest::MD5->new();
  $md5->addfile($fh);

  return $md5->hexdigest;
}

sub set {
  my ( $self, $stuff, $filename ) = @_;

  my $md5 = $self->calc_md5( File::Spec->catfile( $self->directory, $filename ) )
    or Carp::croak("Cannot calculate MD5 for '$filename'");
  $self->data->{$stuff} = +{
    filename => $filename,
    md5      => $md5,
    ( -f $filename ? ( mtime => stat($filename)->mtime ) : () ),
  };

  return $self->is_dirty(1);
}

sub save {
  my ($self) = @_;

  my $filename = $self->filename;

  my $json = JSON::PP->new->pretty(1)->canonical(1)->encode( $self->data );

  File::Path::mkpath( File::Basename::dirname($filename) );

  my $fh = IO::File::AtomicChange->new( $filename, 'w' );
  $fh->print($json);

  return $fh->close();  # MUST CALL close EXPLICITLY
}

1;

