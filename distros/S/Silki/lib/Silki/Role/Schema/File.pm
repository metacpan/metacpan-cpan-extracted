package Silki::Role::Schema::File;
{
  $Silki::Role::Schema::File::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;
use autodie;

use Digest::SHA qw( sha256_hex );
use File::stat;
use Image::Magick;
use Image::Thumbnail;
use Silki::Config;
use Silki::Types qw( File Maybe Str );

use Moose::Role;

requires 'filename';

has file_on_disk => (
    is       => 'ro',
    isa      => File,
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_file_on_disk',
    clearer  => '_clear_file_on_disk',    # for testing
);

has _filename_with_hash => (
    is       => 'ro',
    isa      => Str,
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_filename_with_hash',
);

has small_image_file => (
    is       => 'ro',
    isa      => Maybe [File],
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_small_image_file',
);

has thumbnail_file => (
    is       => 'ro',
    isa      => Maybe [File],
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_thumbnail_file',
);

has mini_image_file => (
    is       => 'ro',
    isa      => Maybe [File],
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_mini_image_file',
);

sub _build_small_image_file {
    my $self = shift;

    $self->_build_resized_image(
        Silki::Config->instance()->small_image_dir(),
        '150x400',
    );
}

sub _build_thumbnail_file {
    my $self = shift;

    $self->_build_resized_image(
        Silki::Config->instance()->thumbnails_dir(),
        '75x200',
    );
}

sub _build_mini_image_file {
    my $self = shift;

    $self->_build_resized_image(
        Silki::Config->instance()->mini_image_dir(),
        '40x40',
    );
}

sub _build_resized_image {
    my $self       = shift;
    my $dir        = shift;
    my $dimensions = shift;

    my $file = $dir->file( $self->_filename_with_hash() );

    return $file
        if -f $file
            && ( File::stat::populate( CORE::stat(_) ) )->mtime()
            >= $self->creation_datetime()->epoch();

    Image::Thumbnail->new(
        module     => 'Image::Magick',
        size       => $dimensions,
        create     => 1,
        inputpath  => $self->file_on_disk()->stringify(),
        outputpath => $file->stringify(),
    );

    return $file;
}

sub _build_file_on_disk {
    my $self = shift;

    my $dir = Silki::Config->instance()->files_dir();

    my $file = $dir->file( $self->_filename_with_hash() );

    return $file
        if -f $file
            && ( File::stat::populate( CORE::stat(_) ) )->mtime()
            >= $self->creation_datetime()->epoch();

    open my $fh, '>', $file;
    print {$fh} $self->contents();
    close $fh;

    return $file;
}

sub _build_filename_with_hash {
    my $self = shift;

    return join q{-},
        sha256_hex( $self->pk_values_hash(), Silki::Config->instance()->secret() ),
        $self->filename();
}

1;
