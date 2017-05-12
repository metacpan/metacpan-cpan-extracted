#!/usr/bin/env perl

use utf8;
use strict;
use warnings;

use Getopt::Long;
use PDF::Cropmarks;
use Pod::Usage;

my $paper = 'a4';
my ($help, $version);
my ($no_top, $no_bottom, $no_inner, $no_outer, $oneside) = (0,0,0,0,0);
my ($font_size, $cropmark_length, $cropmark_offset, $paper_thickness, $signature, $cover);
GetOptions(
           'paper=s' => \$paper,
           'no-top' => \$no_top,
           'no-bottom' => \$no_bottom,
           'no-inner' => \$no_inner,
           'no-outer' => \$no_outer,
           'one-side' => \$oneside,
           'font-size=s' => \$font_size,
           'cropmark-length=s' => \$cropmark_length,
           'cropmark-offset=s' => \$cropmark_offset,
           help => \$help,
           version => \$version,
           'signature=i' => \$signature,
           'paper-thickness=s' => \$paper_thickness,
           cover => \$cover,
          ) or die;

if ($help) {
    pod2usage(get_version());
    exit;
}

if ($version) {
    print get_version();
    exit;
}


my ($input, $output) = @ARGV;
die "Missing input file (try $0 --help)\n" unless $input && -f $input;
die "Missing output file (try $0 --help)\n" unless $output && $output =~ m/\w/;

if (-e $output) {
    unlink $output or die "Cannot remove $output: $!\n";
}

if ($no_top && $no_bottom) {
    warn "You specified no-top and no-bottom, centering instead\n";
}

if ($no_inner && $no_outer) {
    warn "You specified no-inner and no-outer, centering instead\n";
}

my %args = (
            input => $input,
            output => $output,
            paper => $paper,
            top => !$no_top,
            bottom => !$no_bottom,
            inner => !$no_inner,
            outer => !$no_outer,
            twoside => !$oneside,
            cover => $cover,
           );

if ($font_size) {
    $args{font_size} = $font_size;
}
if ($cropmark_length) {
    $args{cropmark_length} = $cropmark_length;
}
if ($cropmark_offset) {
    $args{cropmark_offset} = $cropmark_offset;
}
if ($paper_thickness) {
    $args{paper_thickness} = $paper_thickness;
}
if ($signature) {
    $args{signature} = $signature;
}

my $crop = PDF::Cropmarks->new(%args);
$crop->add_cropmarks;

sub get_version {
    return "Using PDF::Cropmarks version " . $PDF::Cropmarks::VERSION . "\n";
}

=head1 NAME

pdf-cropmarks.pl -- Use PDF::Cropmarks to add cropmarks to an existing PDF.

=head1 SYNOPSIS

  pdf-cropmarks.pl [ options ] input.pdf output.pdf

Both the input file and output file must be specified. The output file
is replaced if already exists.

=head2 Options

=over 4

=item --paper

The dimensions of the output PDF.

You can specify the dimension providing a (case insensitive) string
with the paper name (2a, 2b, 36x36, 4a, 4b, a0, a1, a2, a3, a4, a5,
a6, b0, b1, b2, b3, b4, b5, b6, broadsheet, executive, ledger, legal,
letter, tabloid) or a string with width and height separated by a
column, like C<11cm:200mm>. Supported units are mm, in, pt and cm.

=item --no-top

No margins (and no cropmarks on the top of the page).

=item --no-bottom

No margins (and no cropmarks on the bottom of the page).

=item --no-inner

No margins (and no cropmarks) on the inner margins of the page. By
default inner sides are the left margins on odd pages, and right
margins on even pages. If --one-side is specified, the inner margins
are always the left one.

=item --no-outer

Same as --no-inner, but for the outer margins.

=item --one-side

Affects how to consider --no-outer or --no-inner. If this flag is set,
outer margins are always the right one, and inner are always the left
ones.

=item --cropmark-length 12mm

Size of the cropmark lines. Defaults to 12mm.

=item --cropmark-offset 3mm

The distance from the logical page corner and the cropmark line.
Defaults to 3mm.

=item --font-size 8pt

The font size of the headers and footers with the job name, date, and
page numbers. Defaults to 8pt.

=item --signature <int>

If set to 1, means that all the pages should fit in a single
signature, otherwise it should be a multiple of 4. By default no
signature is computed. Ignored if --one-side is passed. This is needed
if you want to take account of the paper thickness for the cutting
correction.

=item --paper-thickness <measure>

This option is active only when the signature is active. Default to
0.1mm, which is appropriate for the common paper 80g/m2. You can do
the math measuring a stack height and dividing by the number of
sheets.

=item --cover

Relevant if signature is passed. Usually the last signature is filled
with blank pages until it's full. With this option turned on, the last
page of the document is moved to the end of the stack. If you have 13
pages, and a signature of 4, you will end up with 16 pages with
cropmarks, and the last three empty. With this option you will have
page 16 with the logical page 13 on it, while the pages 13-14-15 will
be empty (but with cropmarks nevertheless).

=item --help

Show this help and exit.

=item --version

Show the PDF::Cropmarks version and exit.

=back

=cut
