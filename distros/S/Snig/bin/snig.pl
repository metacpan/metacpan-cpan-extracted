#!/usr/bin/env perl

our $VERSION = '1.001'; # VERSION
# PODNAME: snig.pl
# ABSTRACT: Generate a html image gallery from a directory of images

use Getopt::Long qw( GetOptions );
use Log::Any::Adapter ( split(/\s+/, ($ENV{LOGADAPTER} || 'Stderr')), log_level => $ENV{LOGLEVEL} || 'info' );
use Log::Any qw($log);

use Snig;

my %opts = ( force => []);
GetOptions( \%opts, qw(name:s th_size:s detail_size:s sort_by:s input:s output:s force:s@));

Snig->new( %opts )->run;

__END__

=pod

=encoding UTF-8

=head1 NAME

snig.pl - Generate a html image gallery from a directory of images

=head1 VERSION

version 1.001

=head1 SYNOPSIS

  snig.pl --name "Holiday 2025" --output /document_root/2025_summer --input path/to/dir/with/images

=head1 DESCRIPTION

This will generate a simple, static HTML image gallery from all jpgs found in C<path/to/dir/with/images> in the directory C</document_root/2025_summer>.

Each image will be copied and the filename prefixed with C<orig_>. There will be a thumbnail (200px) and a preview image (1000px). Each image will get a small HTML page, linking to the next and previous image using the preview image. And there will be an index showing all images as thumbnails. All original images will be packed into a ZIP archive and linked for download.

=head1 COMMAND LINE OPTIONS

=head3 C<--input>

The input directory containing the source images

=head3 C<--output>

The directory name of the image gallery to create

=head3 <--name>

A human readable name of the gallery, used in the HTML output

=head3 C<--sort_by>

Default: C<created>

Options: C<created>, C<mtime>

Sort the images by EXIF creation time (default) or file mtime.

=head3 C<--force>

Options: C<resize>, C<zip>

Resize images even if we already did that. And/or recreate zip file, even if it already exists

=head3 C<--th_size>

Default: 200

Width of thumbnails in pixel

=head3 C<--preview_size>

Default: 1000

Width of preview images in pixel

=head2 ENV

Currently logging can be turned on/off via an env var C<LOGLEVEL>, values are L<Log::Any> log levels. The Log::Any logger defaults to C<STDERR> and can be changed via env var C<LOGADAPTER>.

=head1 AUTHOR

Thomas Klausner <domm@plix.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
