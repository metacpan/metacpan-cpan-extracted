package PDF::Imposition::Schema2side;
use strict;
use warnings;
use Moo;
with 'PDF::Imposition::Schema';

=head1 NAME

PDF::Imposition::Schema2side - Imposition schema 2side

=head1 SYNOPSIS

    use PDF::Imposition::Schema2side;
    my $imposer = PDF::Imposition::Schema2side->new(
                                                    file => "test.pdf",
                                                    output => "out.pdf",
                                                   );
    $imposer->impose;

The output pdf will be in C<$imposer->output>

=head1 SCHEMA EXPLANATION

This schema is straightforward: it just packs 2 consecutives logical
pages on a physical one. Example usage: you have a A5 pdf, but you
don't want to bother creating a booklet and you just need not to waste
paper on your A4 printer.

This corresponds to C<psnup -2> in the <psutils>.


       Page 1          Page 2
     +-----+-----+  +-----+-----+ 
     |     |     |  |     |     | 
     |  1  |  2  |  |  3  |  4  | 
     |     |     |  |     |     | 
     +-----+-----+  +-----+-----+ 

       Page 3         Page 4
     +-----+-----+  +-----+-----+
     |     |     |  |     |     |
     |  5  |  6  |  |  7  |  8  |
     |     |     |  |     |     |
     +-----+-----+  +-----+-----+

The last logical page will be empty if the number of pages of the
original PDF is odd.

=cut

sub _do_impose {
    my $self = shift;
    $self->out_pdf_obj->mediabox(
                                 $self->orig_width * 2,
                                 $self->orig_height,
                                );
    my $total = $self->total_pages;
    my ($page, $gfx, $chunk);
    my @pages = (1..$total);
    while (@pages) {
        $page = $self->out_pdf_obj->page;
        $gfx = $page->gfx;

        # first
        $chunk = $self->get_imported_page(shift(@pages));
        $gfx->formimage($chunk, 0, 0) if $chunk;

        # second
        $chunk = $self->get_imported_page(shift(@pages));
        $gfx->formimage($chunk, $self->orig_width, 0) if $chunk;
    }
}

=head1 INTERNALS

=head2 pages_per_sheet

Returns 4

=head2 cropmarks_options

Set outer to false and force signature to 4.

=cut


sub cropmarks_options {
    my %options = (
                   top => 1,
                   bottom => 1,
                   inner => 1,
                   outer => 0,
                   twoside => 1,
                   signature => 4,
                  );
    return %options;
}

sub pages_per_sheet { 4 };

1;

=head1 SEE ALSO

L<PDF::Imposition>

=cut


