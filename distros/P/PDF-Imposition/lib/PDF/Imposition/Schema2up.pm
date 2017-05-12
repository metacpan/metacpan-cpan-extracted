package PDF::Imposition::Schema2up;
use strict;
use warnings;

use Types::Standard qw/Bool/;
use namespace::clean;

use Moo;
with 'PDF::Imposition::Schema';



=head1 NAME

PDF::Imposition::Schema2up - Imposition schema 2up (booklet)

=head1 SYNOPSIS

    use PDF::Imposition::Schema2up;
    my $imposer = PDF::Imposition::Schema2up->new(
                                                  signature => "10-20",
                                                  file => "test.pdf",
                                                  output => "out.pdf",
                                                  cover => 1,
                                                 );
    # or call the methods below to set the values, and then call:
    $imposer->impose;

The output pdf will be in C<$imposer->output>

=head1 SCHEMA EXPLANATION

This schema is a variable and dynamic method. The signature, i.e., the
booklets which compose the document, are not fixed-sized, but can be
altered. The purpose is to have 1 or more booklets that you print
recto-verso and just fold to have your home-made book (this schema is
aimed to DIY people).

Say you have a text with 60 pages in A5: you would print it on A4,
double-side, take the pile out of the printer, fold it and clip it.

The schema looks like (for a signature of 8 pages on 2 sheets):

       RECTO S.1     VERSO S.1
     +-----+-----+  +-----+-----+ 
     |     |     |  |     |     | 
     |  8  |  1  |  |  2  |  7  | 
     |     |     |  |     |     | 
     +-----+-----+  +-----+-----+ 

       RECTO S.2     VERSO S.2
     +-----+-----+  +-----+-----+
     |     |     |  |     |     |
     |  6  |  3  |  |  4  |  5  |
     |     |     |  |     |     |
     +-----+-----+  +-----+-----+

=head1 METHODS

=head2 Public methods

=head3 signature

The signature, must be a multiple of 4, or a range, like the string
"20-100". If a range is selected, the signature is determined
heuristically to minimize the white pages left on the last signature.
The wider the range, the best the results.

This is useful if you are doing batch processing, and you don't know
the number of page in advance (so you can't tweak the source pdf to
have a suitable number of page via text-block dimensions or font
changes).

Typical case: you define a signature of 60 pages, and your PDF happens
to have 61 pages. How unfortunate, and you just can't put out a PDF
with 59 blank pages. The manual solution is to change something in the
document to get it under 60 pages, but this is not always viable or
desirable. So you define a dynamic range for signature, like 20-60,
(so the signature will vary between 20 and 60) and the routine will
find the best one, which in this particular case happens to be 32 (so
the text will have two booklets, and the second will have 3 blank
pages).

Es.

  $imposer->signature("20-60");

Keep in mind that a signature with more than 100 pages is not suitable
to be printed and folded at home (too thick), so to get some
acceptable result, the sheets must be cut and glued together by a
binder, so in this case you want to go with the single signature for
the whole pdf.

If no signature is specified, the whole text will be imposed on a
single signature, regardeless of its size.


=cut

sub pages_per_sheet { 4 };

=head3 cover

This schema supports the cover option.

=cut

has cover => (is => 'rw', isa => Bool);


=head2 INTERNALS

=head3 pages_per_sheet

Always return 4.

=head3 page_sequence_for_booklet($pages, $signature)

Algorithm taken/stolen from C<psbook> (Angus J. C. Duggan 1991-1995).
The C<psutils> are still a viable solution if you want to go with the
PDF->PS->PDF route.

=cut

sub page_sequence_for_booklet {
    my ($self, $pages, $signature) = @_;
    # if set to 0, get the actual number
    $signature ||= $self->computed_signature;
    $pages ||= $self->total_pages;
    my $maxpage = $self->total_output_pages;
    my @pgs;
    {
        use integer;
    for (my $currentpg = 0; $currentpg < $maxpage; $currentpg++) {
        my $actualpg = $currentpg - ($currentpg % $signature);
        my $modulo = $currentpg % 4;
        if ($modulo == 0 or $modulo == 3) {
            $actualpg += $signature - 1 - (($currentpg % $signature) / 2);
        }
        elsif ($modulo == 1 or $modulo == 2) {
            $actualpg += ($currentpg % $signature) / 2;
        }
        if ($actualpg < $pages) {
            $actualpg++;
        } else {
            $actualpg = undef;
        }
        push @pgs, $actualpg;
    }
    }
    my @out;
    # if we want a cover, we need to find the index of the last page,
    # and the first undef page, which could be at the beginning of the
    # last signature, so we have to scan the array.
    if ($self->cover) {
        my $last;
        my $firstundef;

        # find the last page
        for (my $i = 0; $i < @pgs; $i++) {
            if ($pgs[$i] and $pgs[$i] == $pages) {
                $last = $i;
            }
        }

        # find the first empty page (inserted by us)
        for (my $i = 0; $i < @pgs; $i++) {
            if (not defined $pgs[$i]) {
                $firstundef = $i;
                last;
            }
        }

        # if we don't find a white page, there is nothing to do
        if (defined $firstundef) {
            # there is an undef, so swap;
            $pgs[$firstundef] = $pgs[$last];
            $pgs[$last] = undef;
        }
    }
    while (@pgs) {
        push @out, [ shift(@pgs), shift(@pgs) ];
    }
    return \@out;
}

sub _do_impose {
    my $self = shift;
    # prototype
    $self->out_pdf_obj->mediabox(
                                 $self->orig_width * 2,
                                 $self->orig_height,
                                );
    my $seq = $self->page_sequence_for_booklet;
    foreach my $p (@$seq) {
        # loop over the pages
        my $left = $self->get_imported_page($p->[0]);
        my $right = $self->get_imported_page($p->[1]);
        my $page = $self->out_pdf_obj->page();
        my $gfx = $page->gfx();
        if (defined $left) {
            $gfx->formimage($left, 0, 0);
        }
        if (defined $right) {
            $gfx->formimage($right, $self->orig_width, 0);
        }
    }
}

=head1 INTERNALS

=head2 cropmarks_options

Set inner to false.

=cut


sub cropmarks_options {
    my %options = (
                   top => 1,
                   bottom => 1,
                   inner => 0,
                   outer => 1,
                   twoside => 1,
                  );
    return %options;
}


1;

=head1 SEE ALSO

L<PDF::Imposition>

=cut

