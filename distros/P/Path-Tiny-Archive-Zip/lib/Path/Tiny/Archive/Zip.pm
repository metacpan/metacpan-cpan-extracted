package Path::Tiny::Archive::Zip;

# ABSTRACT: Zip/unzip add-on for file path utility

use strict;
use warnings;

use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Path::Tiny qw( path );

use namespace::clean;

use Exporter qw( import );


our $VERSION = '0.003';

our %EXPORT_TAGS = ( const =>[qw(
    COMPRESSION_DEFAULT
    COMPRESSION_NONE
    COMPRESSION_FASTEST
    COMPRESSION_BEST
)] );
our @EXPORT_OK = @{ $EXPORT_TAGS{const} };


BEGIN {
    push(@Path::Tiny::ISA, __PACKAGE__);
}

use constant {
    COMPRESSION_DEFAULT => COMPRESSION_LEVEL_DEFAULT,           # 6
    COMPRESSION_NONE    => COMPRESSION_LEVEL_NONE,              # 0
    COMPRESSION_FASTEST => COMPRESSION_LEVEL_FASTEST,           # 1
    COMPRESSION_BEST    => COMPRESSION_LEVEL_BEST_COMPRESSION,  # 9
};



sub zip {
    my ($self, $dest, $level) = @_;

    my $zip = Archive::Zip->new;

    if ($self->is_file) {
        $zip->addFile($self->realpath->stringify(), $self->basename, defined $level ? $level : ());
    }
    elsif ($self->is_dir) {
        $zip->addTree($self->realpath->stringify(), '', undef, defined $level ? $level : ());
    }
    else {
        return;
    }

    $dest = path($dest);

    unless ($zip->writeToFileNamed($dest->realpath->stringify()) == AZ_OK) {
        return;
    }

    return $dest;
}


sub unzip {
    my ($self, $dest) = @_;

    my $zip = Archive::Zip->new();

    unless ($zip->read($self->realpath->stringify()) == AZ_OK) {
        return;
    }

    $dest = path($dest);
    if ($dest->exists) {
        return unless $dest->is_dir;
    }
    else {
        $dest->mkpath() or return;
    }

    unless ($zip->extractTree(undef, $dest->realpath->stringify()) == AZ_OK) {
        return;
    }

    return $dest;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Path::Tiny::Archive::Zip - Zip/unzip add-on for file path utility

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use Path::Tiny
    use Path::Tiny::Archive::Zip qw( :const );

    path("foo/bar.txt")->zip("foo/bar.zip", COMPRESSION_BEST);
    path("foo/bar.zip")->unzip("baz");

=head1 DESCRIPTION

This module provides two additional methods for L<Path::Tiny> for working with
zip archives.

=head1 METHODS

=head2 zip

    path("/tmp/foo.txt")->zip("/tmp/foo.zip");
    path("/tmp/foo")->zip("/tmp/foo.zip");

Creates a zip archive and appends a file or directory tree to it. Returns the
path to the zip archive or undef.

You can choose different compression levels.

    path("/tmp/foo")->zip("/tmp/foo.zip", COMPRESSION_FASTEST);

The levels given can be:

=over 4

=item * C<0> or C<COMPRESSION_NONE>: No compression.

=item * C<1> to C<9>: 1 gives the best speed and worst compression, and 9 gives
the best compression and worst speed.

=item * C<COMPRESSION_FASTEST>: This is a synonym for level 1.

=item * C<COMPRESSION_BEST>: This is a synonym for level 9.

=item * C<COMPRESSION_DEFAULT>: This gives a good compromise between speed and
compression, and is currently equivalent to 6 (this is in the zlib code). This
is the level that will be used if not specified.

=back

=head2 unzip

    path("/tmp/foo.zip")->unzip("/tmp/foo");

Extracts a zip archive to specified directory. Returns the path to the
destination directory or undef.

=head1 AUTHOR

Denis Ibaev <dionys@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Denis Ibaev.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
