package PDF::Cropmarks;

use utf8;
use strict;
use warnings;

use Moo;
use Types::Standard qw/Maybe Str Object Bool StrictNum Int HashRef ArrayRef/;
use File::Copy;
use File::Spec;
use File::Temp;
use PDF::API2;
use PDF::API2::Util;
use POSIX qw();
use File::Basename qw/fileparse/;
use namespace::clean;
use Data::Dumper;
use constant {
    DEBUG => !!$ENV{AMW_DEBUG},
};

=encoding utf8

=head1 NAME

PDF::Cropmarks - Add cropmarks to existing PDFs

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.11';

=head1 SYNOPSIS

This module prepares PDF for printing adding the cropmarks, usually on
a larger physical page, doing the same thing the LaTeX package "crop"
does. It also takes care of the paper thickness, shifting the logical
pages to compensate the folding.

It comes with a ready-made script, C<pdf-cropmarks.pl>. E.g.

 $ pdf-cropmarks.pl --help # usage
 $ pdf-cropmarks.pl --paper a3 input.pdf output.pdf

To use the module in your code:

  use strict;
  use warnings;
  use PDF::Cropmarks;
  PDF::Cropmarks->new(input => $input,
                      output => $output,
                      paper => $paper,
                      # other options here
                     )->add_cropmarks;

If everything went well (no exceptions thrown), you will find the new
pdf in the output you provided.

=head1 ACCESSORS

The following options need to be passed to the constructor and are
read-only.

=head2 input <file>

The filename of the input. Required.

=head2 output

The filename of the output. Required.

=head2 paper

This module each logical page of the original PDF into a larger
physical page, adding the cropmarks in the margins. With this option
you can control the dimension of the output paper.

You can specify the dimension providing a (case insensitive) string
with the paper name (2a, 2b, 36x36, 4a, 4b, a0, a1, a2, a3, a4, a5,
a6, b0, b1, b2, b3, b4, b5, b6, broadsheet, executive, ledger, legal,
letter, tabloid) or a string with width and height separated by a
column, like C<11cm:200mm>. Supported units are mm, in, pt and cm.

An exception is thrown if the module is not able to parse the input
provided.

=head2 Positioning

The following options control where the logical page is put on the
physical one. They all default to true, meaning that the logical page
is centered. Setting top and bottom to false, or inner and outer to
false makes no sense (you achieve the same result specifing a paper
with the same width or height) and thus ignored, resulting in a
centering.

=over 4

=item top

=item bottom

=item inner

=item outer

=back

=head2 twoside

Boolean, defaults to true.

This option affects the positioning, if inner or outer are set to
false. If C<twoside> is true (default), inner margins are considered
the left ones on an the recto pages (the odd-numbered ones). If set to
false, the left margin is always considered the inner one.

=head2 cropmark_length

Default: 12mm

The length of the cropmark line.

=head2 cropmark_offset

Default: 3mm

The distance from the logical page corner and the cropmark line.

=head2 font_size

Default: 8pt

The font size of the headers and footers with the job name, date, and
page numbers.

=head2 signature

Default to 0, meaning that no signature is needed. If set to 1, means
that all the pages should fit in a single signature, otherwise it
should be a multiple of 4.

=head2 paper_thickness

When passing the signature option, the logical pages are shifted on
the x axys by this amount to compensate the paper folding. Accept a
measure.

This option is active only when the signature is set (default to
false) and twoside is true (the default). Default to 0.1mm, which is
appropriate for the common paper 80g/m2. You can do the math measuring
a stack height and dividing by the number of sheets.

=head2 title

The (optional) job title to put on the markers. It defaults to the
file basename.

=head2 cover

Relevant if signature is passed. Usually the last signature is filled
with blank pages until it's full. With this option turned on, the last
page of the document is moved to the end of the stack. If you have 13
pages, and a signature of 4, you will end up with 16 pages with
cropmarks, and the last three empty. With this option you will have
page 16 with the logical page 13 on it, while the pages 13-14-15 will
be empty (but with cropmarks nevertheless).

=cut

has cropmark_length => (is => 'ro', isa => Str, default => sub { '12mm' });

has cropmark_offset => (is => 'ro', isa => Str, default => sub { '3mm' });

has font_size => (is => 'ro', isa => Str, default => sub { '8pt' });

has cropmark_length_in_pt => (is => 'lazy', isa => StrictNum);
has cropmark_offset_in_pt => (is => 'lazy', isa => StrictNum);
has font_size_in_pt => (is => 'lazy', isa => StrictNum);
has _font_object => (is => 'rw', isa => Maybe[Object]);
has signature => (is => 'rwp', isa => Int, default => sub { 0 });
has paper_thickness => (is => 'ro', isa => Str, default => sub { '0.1mm' });
has paper_thickness_in_pt => (is => 'lazy', isa => StrictNum);
has cover => (is => 'ro', isa => Bool, default => sub { 0 });

sub _build_paper_thickness_in_pt {
    my $self = shift;
    return $self->_string_to_pt($self->paper_thickness);
}

sub _build_cropmark_length_in_pt {
    my $self = shift;
    return $self->_string_to_pt($self->cropmark_length);
}
sub _build_cropmark_offset_in_pt {
    my $self = shift;
    return $self->_string_to_pt($self->cropmark_offset);
}

sub _build_font_size_in_pt {
    my $self = shift;
    return $self->_string_to_pt($self->font_size);
}

has thickness_page_offsets => (is => 'lazy', isa => HashRef[HashRef]);

sub _build_thickness_page_offsets {
    my $self = shift;
    my $total_pages = $self->total_output_pages;
    my %out = map { $_ => 0 } (1 .. $total_pages);
    if (my $signature = $self->signature) {
        # convert to the real signature
        if ($signature == 1) {
            $signature = $total_pages;
        }
        die "Should have already died, signature not a multiple of four" if $signature % 4;
        my $half = $signature / 2;
        my $offset = $self->paper_thickness_in_pt * ($half / 2);
        my $original_offset = $self->paper_thickness_in_pt * ($half / 2);
        my $signature_number = 0;
        foreach my $page (1 .. $total_pages) {
            my $page_in_sig = $page % $signature || $signature;
            if ($page_in_sig == 1) {
                $offset = $original_offset;
                $signature_number++;
            }
            print "page in sig / $signature_number : $page_in_sig\n" if DEBUG;
            # odd pages triggers a stepping
            if ($page_in_sig % 2) {
                if ($page_in_sig > ($half + 1)) {
                    $offset += $self->paper_thickness_in_pt;
                }
                elsif ($page_in_sig < $half) {
                    $offset -= $self->paper_thickness_in_pt;
                }
            }
            my $rounded = $self->_round($offset);
            print "offset for page is $rounded\n" if DEBUG;
            $out{$page} = {
                           offset => $rounded,
                           signature => $signature_number,
                           signature_page => $page_in_sig,
                          };
        }
    }
    return \%out;
}

has total_input_pages => (is => 'lazy', isa => Int);

sub _build_total_input_pages {
    my $self = shift;
    my $count = $self->in_pdf_object->pages;
    return $count;
}

has total_output_pages => (is => 'lazy', isa => Int);

sub _build_total_output_pages {
    my $self = shift;
    my $total_input_pages = $self->total_input_pages;

    if (my $signature = $self->signature) {
        if ($signature == 1) {
            # all the pages on a single signature
            # round to the next multiple of 4
            my $missing = 0;
            if (my $modulo = $total_input_pages % 4) {
                $missing = 4 - $modulo;
            }
            return $total_input_pages + $missing;
        }
        elsif ($signature % 4) {
            die "Signature must be 1 or a multiple of 4, but I got $signature";
        }
        else {
            my $missing = 0;
            if (my $modulo = $total_input_pages % $signature) {
                $missing = $signature - $modulo;
            }
            return $total_input_pages + $missing;
        }
    }
    else {
        return $total_input_pages;
    }
}


sub _measure_re {
    return qr{([0-9]+(\.[0-9]+)?)\s*
              (mm|in|pt|cm)}sxi;
}

sub _string_to_pt {
    my ($self, $string) = @_;
    my %compute = (
                   mm => sub { $_[0] / (25.4 / 72) },
                   in => sub { $_[0] / (1 / 72) },
                   pt => sub { $_[0] / 1 },
                   cm => sub { $_[0] / (25.4 / 72) * 10 },
                  );
    my $re = $self->_measure_re;
    if ($string =~ $re) {
        my $size = $1;
        my $unit = lc($3);
        return $self->_round($compute{$unit}->($size));
    }
    else {
        die "Unparsable measure string $string";
    }
}

=head1 METHODS

=head2 add_cropmarks

This is the only public method: create the new pdf from C<input> and
leave it in C<output>.

=cut

has input => (is => 'ro', isa => Str, required => 1);

has output => (is => 'ro', isa => Str, required => 1);

has paper => (is => 'ro', isa => Str, default => sub { 'a4' });

has _tmpdir => (is => 'ro',
                isa => Object,
                default => sub {
                    return File::Temp->newdir(CLEANUP => !DEBUG);
                });

has in_pdf => (is => 'lazy', isa => Str);

has out_pdf => (is => 'lazy', isa => Str);

has basename => (is => 'lazy', isa => Str);

has timestamp => (is => 'lazy', isa => Str);

sub _build_basename {
    my $self = shift;
    my $basename = fileparse($self->input, qr{\.pdf}i);
    return $basename;
}

sub _build_timestamp {
    my $now = localtime();
    return $now;
}

has top => (is => 'ro', isa => Bool, default => sub { 1 });
has bottom => (is => 'ro', isa => Bool, default => sub { 1 });
has inner => (is => 'ro', isa => Bool, default => sub { 1 });
has outer => (is => 'ro', isa => Bool, default => sub { 1 });
has twoside => (is => 'ro', isa => Bool, default => sub { 1 });
has _is_closed => (is => 'rw', isa => Bool, default => sub { 0 });
sub _build_in_pdf {
    my $self = shift;
    my $name = File::Spec->catfile($self->_tmpdir, 'in.pdf');
    copy ($self->input, $name) or die "Cannot copy input to $name $!";
    return $name;
}

sub _build_out_pdf {
    my $self = shift;
    return File::Spec->catfile($self->_tmpdir, 'out.pdf');
}


has in_pdf_object => (is => 'lazy', isa => Object);

sub _build_in_pdf_object {
    my $self = shift;
    my $input = eval { PDF::API2->open($self->in_pdf) };
    if ($input) {
        return $input;
    }
    else {
        die "Cannot open " . $self->in_pdf . " $@" unless $input;
    }
}

has out_pdf_object => (is => 'lazy', isa => Object);

sub _build_out_pdf_object {
    my $self = shift;
    my $pdf = PDF::API2->new;
    my $now = POSIX::strftime(q{%Y%m%d%H%M%S+00'00'}, localtime(time()));

    my %info = ($self->in_pdf_object->info,
                Creator => "PDF::Cropmarks $VERSION",
                CreationDate => POSIX::strftime(q{%Y%m%d%H%M%S+00'00'}, localtime((stat($self->in_pdf))[9])),
                ModDate => POSIX::strftime(q{%Y%m%d%H%M%S+00'00'}, localtime(time())));
    $pdf->info(%info);
    $pdf->mediabox($self->_paper_dimensions);
    return $pdf;
}

sub _paper_dimensions {
    my $self = shift;
    my $paper = $self->paper;
    my %sizes = PDF::API2::Util::getPaperSizes();
    my $measure_re = $self->_measure_re;
    if (my $dimensions = $sizes{lc($self->paper)}) {
        return @$dimensions;
    }
    elsif ($paper =~ m/\A\s*
                       $measure_re
                       \s*:\s*
                       $measure_re
                       \s*\z/sxi) {
        # 3 + 3 captures
        my $xsize = $1;
        my $xunit = $3;
        my $ysize = $4;
        my $yunit = $6;
        return ($self->_string_to_pt($xsize . $xunit),
                $self->_string_to_pt($ysize . $yunit));
    }
    else {
        die "Cannot get dimensions from $paper, using A4";
    }
}

sub add_cropmarks {
    my $self = shift;
    die "add_cropmarks already called!" if $self->_is_closed;
    my $needed = $self->total_output_pages - $self->total_input_pages;
    die "Something is off, pages needed: $needed pages" if $needed < 0;
    my @sequence = (1 .. $self->total_input_pages);
    if ($needed) {
        my $last;
        if ($self->cover) {
            $last = pop @sequence;
        }
        while ($needed > 0) {
            push @sequence, undef;
            $needed--;
        }
        if ($last) {
            push @sequence, $last;
        }
    }
    my $as_page_number = 0;
    print Dumper(\@sequence) if DEBUG;
    $self->_font_object($self->out_pdf_object->corefont('Courier'));
    foreach my $src_page_number (@sequence) {
        $as_page_number++;
        # and set it as page_number
        $self->_import_page($src_page_number, $as_page_number);
    }
    print "Saving " . $self->out_pdf . "\n" if DEBUG;
    $self->out_pdf_object->saveas($self->out_pdf);
    $self->_cleanup;

    move($self->out_pdf, $self->output)
      or die "Cannot copy " . $self->out_pdf . ' to ' . $self->output;

    return $self->output;
}

sub _round {
    my ($self, $float) = @_;
    print "Rounding $float\n" if DEBUG;
    return 0 unless $float;
    if ($float < 0.001 && $float > -0.001) {
        return 0;
    }
    return sprintf('%.3f', $float);
}

has output_dimensions => (is => 'lazy', isa => ArrayRef);

has title => (is => 'ro', isa => Maybe[Str]);

sub _build_output_dimensions {
    my $self = shift;
    # get the first page
    my $in_page = $self->in_pdf_object->openpage(1);
    return [ $in_page->get_mediabox ];
}

sub _import_page {
    my ($self, $src_page_number, $page_number) = @_;
    my $in_page = (defined $src_page_number ? $self->in_pdf_object->openpage($src_page_number) : undef);
    my $page = $self->out_pdf_object->page;
    my ($llx, $lly, $urx, $ury) = $page->get_mediabox;
    die "mediabox origins for output pdf should be zero" if $llx + $lly;
    print "$llx, $lly, $urx, $ury\n" if DEBUG;
    my ($inllx, $inlly, $inurx, $inury) = ($in_page ? $in_page->get_mediabox : @{$self->output_dimensions});
    print "$inllx, $inlly, $inurx, $inury\n" if DEBUG;
    die "mediabox origins for input pdf should be zero" if $inllx + $inlly;
    # place the content into page

    my $offset_x = $self->_round(($urx - $inurx) / 2);
    my $offset_y = $self->_round(($ury - $inury) / 2);

    # adjust offset if bottom or top are missing. Both missing doesn't
    # make much sense
    my ($top_middle_mark, $bottom_middle_mark,
        $left_middle_mark, $right_middle_mark) = (1, 1, 1, 1);

    if (!$self->bottom && !$self->top) {
        # warn "bottom and top are both false, centering\n";
    }
    elsif (!$self->bottom) {
        $offset_y = 0;
        $bottom_middle_mark = 0;
    }
    elsif (!$self->top) {
        $offset_y *= 2;
        $top_middle_mark = 0;
    }

    if (!$self->inner && !$self->outer) {
        # warn "inner and outer are both false, centering\n";
    }
    elsif (!$self->inner) {
        # even pages
        if ($self->twoside and !($page_number % 2)) {
            $offset_x *= 2;
            $right_middle_mark = 0;
        }
        else {
            $offset_x = 0;
            $left_middle_mark = 0;
        }
    }
    elsif (!$self->outer) {
        # odd pages
        if ($self->twoside and !($page_number % 2)) {
            $offset_x = 0;
            $left_middle_mark = 0;
        }
        else {
            $offset_x *= 2;
            $right_middle_mark = 0;
        }
    }

    my $signature_mark = '';
    if ($self->signature && $self->twoside) {
        my $spec = $self->thickness_page_offsets->{$page_number};
        my $paper_thickness = $spec->{offset};
        die "$page_number not defined in " . Dumper($self->thickness_page_offsets)
          unless defined $paper_thickness;
        # recto pages, increase
        if ($page_number % 2) {
            $offset_x += $paper_thickness;
        }
        # verso pages, decrease
        else {
            $offset_x -= $paper_thickness;
        }
        $signature_mark = ' #' . $spec->{signature} . '/' . $spec->{signature_page};
    }

    print "Offsets are $offset_x, $offset_y\n" if DEBUG;
    if ($in_page) {
        my $xo = $self->out_pdf_object->importPageIntoForm($self->in_pdf_object,
                                                           $src_page_number);
        my $gfx = $page->gfx;
        $gfx->formimage($xo, $offset_x, $offset_y);
    }
    if (DEBUG) {
        my $line = $page->gfx;
        $line->strokecolor('black');
        $line->linewidth(0.5);
        $line->rectxy($offset_x, $offset_y,
                      $offset_x + $inurx, $offset_y + $inury);
        $line->stroke;
    }
    my $crop = $page->gfx;
    $crop->strokecolor('black');
    $crop->linewidth(0.5);
    my $crop_width = $self->cropmark_length_in_pt;
    my $crop_offset = $self->cropmark_offset_in_pt;
    # left bottom corner
    $self->_draw_line($crop,
                      ($offset_x - $crop_offset,               $offset_y),
                      ($offset_x - $crop_width - $crop_offset, $offset_y));


    $self->_draw_line($crop,
                      ($offset_x, $offset_y - $crop_offset),
                      ($offset_x, $offset_y - $crop_offset - $crop_width));

    if ($bottom_middle_mark) {
        $self->_draw_line($crop,
                          ($offset_x + ($inurx / 2),
                           $offset_y - $crop_offset),
                          ($offset_x + ($inurx / 2),
                           $offset_y - $crop_offset - ($crop_width / 2)));
    }

    # right bottom corner
    $self->_draw_line($crop,
                      ($offset_x + $inurx + $crop_offset, $offset_y),
                      ($offset_x + $inurx + $crop_offset + $crop_width,
                       $offset_y));
    $self->_draw_line($crop,
                      ($offset_x + $inurx,
                       $offset_y - $crop_offset),
                      ($offset_x + $inurx,
                       $offset_y - $crop_offset - $crop_width));

    if ($right_middle_mark) {
        $self->_draw_line($crop,
                          ($offset_x + $inurx + $crop_offset,
                           $offset_y + ($inury/2)),
                          ($offset_x + $inurx + $crop_offset + ($crop_width / 2),
                           $offset_y + ($inury/2)));
    }

    # top right corner
    $self->_draw_line($crop,
                      ($offset_x + $inurx + $crop_offset,
                       $offset_y + $inury),
                      ($offset_x + $inurx + $crop_offset + $crop_width,
                       $offset_y + $inury));

    $self->_draw_line($crop,
                      ($offset_x + $inurx,
                       $offset_y + $inury + $crop_offset),
                      ($offset_x + $inurx,
                       $offset_y + $inury + $crop_offset + $crop_width));

    if ($top_middle_mark) {
        $self->_draw_line($crop,
                          ($offset_x + ($inurx / 2),
                           $offset_y + $inury + $crop_offset),
                          ($offset_x + ($inurx / 2),
                           $offset_y + $inury + $crop_offset + ($crop_width / 2)));
    }

    # top left corner
    $self->_draw_line($crop,
                      ($offset_x, $offset_y + $inury + $crop_offset),
                      ($offset_x,
                       $offset_y + $inury + $crop_offset + $crop_width));

    $self->_draw_line($crop,
                      ($offset_x - $crop_offset,
                       $offset_y + $inury),
                      ($offset_x - $crop_offset - $crop_width,
                       $offset_y + $inury));

    if ($left_middle_mark) {
        $self->_draw_line($crop,
                          ($offset_x - $crop_offset,
                           $offset_y + ($inury / 2)),
                          ($offset_x - $crop_offset - ($crop_width / 2),
                           $offset_y + ($inury / 2)));
    }
    # and stroke
    $crop->stroke;

    # then add the text
    my $text = $page->text;
    my $marker = sprintf('Pg %.4d', $page_number);
    $text->font($self->_font_object,
                $self->_round($self->font_size_in_pt));
    $text->fillcolor('black');

    # bottom left
    $text->translate($offset_x - (($crop_width + $crop_offset)),
                     $offset_y - (($crop_width + $crop_offset)));
    $text->text($marker);

    # bottom right
    $text->translate($inurx + $offset_x + $crop_offset,
                     $offset_y - (($crop_width + $crop_offset)));
    $text->text($marker);

    # top left
    $text->translate($offset_x - (($crop_width + $crop_offset)),
                     $offset_y + $inury + $crop_width);
    $text->text($marker);

    # top right
    $text->translate($inurx + $offset_x + $crop_offset,
                     $offset_y + $inury + $crop_width);
    $text->text($marker);

    my $text_marker = ($self->title || $self->basename)
      . ' ' . $self->timestamp .
      ' page ' . $page_number . $signature_mark;
    # and at the top and and the bottom add jobname + timestamp
    $text->translate(($inurx / 2) + $offset_x,
                     $offset_y + $inury + $crop_width);
    $text->text_center($text_marker);

    $text->translate(($inurx / 2) + $offset_x,
                     $offset_y - ($crop_width + $crop_offset));
    $text->text_center($text_marker);
}

sub _draw_line {
    my ($self, $gfx, $from_x, $from_y, $to_x, $to_y) = @_;
    if (DEBUG) {
        print "Printing line from ($from_x, $from_y) to ($to_x, $to_y)\n";
    }
    $gfx->move($from_x, $from_y);
    $gfx->line($to_x, $to_y);
    my $radius = 3;
    $gfx->circle($to_x, $to_y, $radius);
    $gfx->move($to_x - $radius, $to_y);
    $gfx->line($to_x + $radius, $to_y);
    $gfx->move($to_x, $to_y - $radius);
    $gfx->line($to_x, $to_y + $radius);
}

sub _cleanup {
    my $self = shift;
    if ($self->_is_closed) {
        return;
    }
    else {
        $self->_font_object(undef);
        $self->in_pdf_object->end;
        $self->out_pdf_object->end;
        $self->_is_closed(1);
        print "Objects closed\n" if DEBUG;
    }
}

sub DESTROY {
    my $self = shift;
    $self->_cleanup;
}

=head1 AUTHOR

Marco Pessotto, C<< <melmothx at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to the CPAN's RT or at
L<https://github.com/melmothx/pdf-cropmarks-perl/issues>. If you find
a bug, please provide a minimal example file which reproduces the
problem.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of either: the GNU General Public License as
published by the Free Software Foundation; or the Artistic License.

=cut


1;
