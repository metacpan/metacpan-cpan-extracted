package Path::Tiny::Archive::Tar;

# ABSTRACT: Tar/untar add-on for file path utility

use strict;
use warnings;

use Archive::Tar qw( COMPRESS_GZIP COMPRESS_BZIP );
use Compress::Raw::Zlib ();
use Path::Tiny qw( path );

use namespace::clean;

use Exporter qw( import );


our $VERSION = '0.002';

our %EXPORT_TAGS = ( const =>[qw(
    COMPRESSION_NONE
    COMPRESSION_GZIP
    COMPRESSION_GZIP_DEFAULT
    COMPRESSION_GZIP_NONE
    COMPRESSION_GZIP_FASTEST
    COMPRESSION_GZIP_BEST
    COMPRESSION_BZIP2
)] );
our @EXPORT_OK = @{ $EXPORT_TAGS{const} };


BEGIN {
    push(@Path::Tiny::ISA, __PACKAGE__);
}

use constant {
    COMPRESSION_NONE         => undef,
    # Hack for Archive::Tar: true so don't use default compression and pass
    # this level to IO::Zlib. And hack for Compress::Zlib: not digit so use
    # default compression (letters may specify other compression modes).
    COMPRESSION_GZIP         => '-',
    COMPRESSION_GZIP_DEFAULT => '-',
    # Hack for Archive::Tar: zero but true so pass 0 level to IO::Zlib.
    COMPRESSION_GZIP_NONE    => '00',
    COMPRESSION_GZIP_FASTEST => Compress::Raw::Zlib::Z_BEST_SPEED,
    COMPRESSION_GZIP_BEST    => Compress::Raw::Zlib::Z_BEST_COMPRESSION,
    COMPRESSION_BZIP2        => COMPRESS_BZIP,
};


sub tar {
    my ($self, $dest, $level) = @_;

    $dest = path($dest);

    my $tar = Archive::Tar->new;

    if ($self->is_file) {
        my $file = Archive::Tar::File->new(file => $self->stringify());

        return unless $file;

        $file->name($self->basename);
        $file->prefix('');

        $tar->add_files($file) or return;
    }
    elsif ($self->is_dir) {
        my $paths = $self->iterator({ recurse => 1 });

        while (my $path = $paths->()) {
            my $file = Archive::Tar::File->new(file => $path->stringify());

            return unless $file;

            $file->rename($path->relative($self));

            $tar->add_files($file) or return;
        }
    }
    else {
        return;
    }

    $tar->write($dest->stringify(), defined $level ? $level : ()) or return;

    return $dest;
}


sub untar {
    my ($self, $dest) = @_;

    $dest = path($dest);

    my $files = Archive::Tar->iter($self->stringify());

    return unless $files;

    while (my $file = $files->()) {
        $file->extract($dest->child($file->full_path)->stringify()) or return;
    }

    return $dest;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Path::Tiny::Archive::Tar - Tar/untar add-on for file path utility

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use Path::Tiny
    use Path::Tiny::Archive::Tar qw( :const );

    path("foo/bar.txt")->tar("foo/bar.tgz", COMPRESSION_GZIP);
    path("foo/bar.zip")->untar("baz");

=head1 DESCRIPTION

This module provides two additional methods for L<Path::Tiny> for working with
tar archives.

=head1 METHODS

=head2 tar

    path("/tmp/foo.txt")->tar("/tmp/foo.tar");
    path("/tmp/foo")->tar("/tmp/foo.tar");

Creates a tar archive and appends a file or directory tree to it. Returns the
path to the archive or undef.

You can choose different compression types and levels.

    path("/tmp/foo")->zip("/tmp/foo.tgz", COMPRESSION_GZIP);

The types and levels given can be:

=over 4

=item * C<COMPRESSION_NONE>: No compression. This is the type that will be used
if not specified.

=item * C<COMPRESSION_GZIP>: Compress using C<gzip>.

=over 8

=item * C<1> to C<9>: This is C<gzip> compression levels. 1 gives the best
speed and worst compression, and 9 gives the best compression and worst speed.

=item * C<COMPRESSION_GZIP_NONE>: This is a synonym for C<gzip> level 0. No
compression.

=item * C<COMPRESSION_GZIP_FASTEST>: This is a synonym for C<gzip> level 1.

=item * C<COMPRESSION_GZIP_BEST>: This is a synonym for C<gzip> level 9.

=item * C<COMPRESSION_GZIP_DEFAULT>: This gives a good compromise between speed
and compression for C<gzip>, and is currently equivalent to 6 (this is in the
zlib code). This is a synonym for C<COMPRESSION_GZIP>.

=back

=item * C<COMPRESSION_BZIP2>: Compress using C<bzip2>.

=back

=head2 untar

    path("/tmp/foo.tar")->untar("/tmp/foo");

Extracts a tar archive to specified directory. Returns the path to the
destination directory or undef.

=head1 AUTHOR

Denis Ibaev <dionys@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Denis Ibaev.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
