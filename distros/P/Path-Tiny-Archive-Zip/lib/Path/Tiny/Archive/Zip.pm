package Path::Tiny::Archive::Zip;

# ABSTRACT: Zip/unzip add-on for file path utility

use strict;
use warnings;

use Archive::Zip qw( :ERROR_CODES );
#use Carp qw( croak );
use Path::Tiny qw( path );


our $VERSION = '0.002';


BEGIN {
    push(@Path::Tiny::ISA, __PACKAGE__);
}


sub zip {
    my ($self, $dest) = @_;

    my $zip = Archive::Zip->new;

    if ($self->is_file) {
        $zip->addFile($self->realpath->stringify(), $self->basename);
    }
    elsif ($self->is_dir) {
        $zip->addTree($self->realpath->stringify(), '');
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
    if ($dest->is_file) {
        return;
    }
    unless ($dest->is_dir) {
        $dest->mkpath();
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

version 0.002

=head1 DESCRIPTION

This module provides two additional methods for L<Path::Tiny> for working with
zip archives.

=head1 METHODS

=head2 zip

    path("/tmp/foo.txt")->zip("/tmp/foo.zip");
    path("/tmp/foo")->zip("/tmp/foo.zip");

Creates a zip archive and appends a file or directory tree to it.

=head2 unzip

    path("/tmp/foo.zip")->zip("/tmp/foo");

Extracts a zip archive to specified directory.

=head1 AUTHOR

Denis Ibaev <dionys@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Denis Ibaev.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
