package PDF::Imposition::Schema1x8x2;
use strict;
use warnings;
use Moo;
with 'PDF::Imposition::Schema';

=head1 NAME

PDF::Imposition::Schema1x8x2 - fixed 16 pages signatures on a single sheet, with triple folding.

=head1 SYNOPSIS

    use PDF::Imposition::Schema1x8x2;
    my $imposer = PDF::Imposition::Schema1x8x2->new(
                                                    file => "test.pdf",
                                                    output => "out.pdf",
                                                    );
    $imposer->impose;

The output pdf will be left in C<< $imposer->output >>

=head1 SCHEMA EXPLANATION

Fixed signature size of 16 pages, printed recto-verso on a single sheet.

Typical usage: print A6 on A3, then fold trice, first along the y
axys, then the x axys and finally the y axys again. You need to trim
the top and right margins before binding.

Not suitable for home-printing because the spine is unstable unless
done by a machine.

Visualization (the prefix C<r> means logical page disposed
upside-down -- rotated 180 degrees):


     +------+------+------+------+
     |      |      |      |      |
     |  r5  |  r12 |  r9  | r8   |
     |      |      |      |      |
     +------+------+------+------+
     |      |      |      |      |
     |  4   |  13  |  16  |   1  |
     |      |      |      |      |
     +------+------+------+------+

     +------+------+------+------+
     |      |      |      |      |
     | r7   | r10  |  r11 | r6   |
     |      |      |      |      |
     +------+------+------+------+
     |      |      |      |      |
     |  2   |  15  |  14  |   3  |
     |      |      |      |      |
     +------+------+------+------+


To complete the block of 16 logical pages, blank pages are inserted if
needed.

=cut

sub _do_impose {
    my $self = shift;
    # set the mediabox doubling them
    $self->out_pdf_obj->mediabox(
                                 $self->orig_width * 4,
                                 $self->orig_height * 2,
                                );
    # here we work with fixed signatures of 16, with the module
    my $total = $self->total_pages;
    my @pages = (1..$total);

    # loop over the pages and compose the 4 physical pages
    while (@pages) {
        my ($p1,  $p2,  $p3,  $p4,
            $p5,  $p6,  $p7,  $p8,
            $p9,  $p10, $p11, $p12,
            $p13, $p14, $p15, $p16) = splice @pages, 0, 16;
        $self->_compose_eight($p4, $p13, $p16, $p1,
                              $p8, $p9, $p12, $p5);
        $self->_compose_eight($p2, $p15, $p14, $p3,
                              $p6, $p11, $p10, $p7);
    }
    
}

sub _compose_eight {
    my ($self, @seq) = @_;
    my $chunk;
    my $page = $self->out_pdf_obj->page;
    my $gfx = $page->gfx;

    $chunk = $self->get_imported_page($seq[0]);
    $gfx->formimage($chunk, 0, 0) if $chunk;

    $chunk = $self->get_imported_page($seq[1]);
    $gfx->formimage($chunk, $self->orig_width, 0) if $chunk;

    $chunk = $self->get_imported_page($seq[2]);
    $gfx->formimage($chunk, $self->orig_width * 2, 0) if $chunk;

    $chunk = $self->get_imported_page($seq[3]);
    $gfx->formimage($chunk, $self->orig_width * 3, 0) if $chunk;

    # translate
    $gfx->transform (
                     -translate => [$self->orig_width * 4,
                                    $self->orig_height * 2],
                     -rotate => 180,
                    );

    $chunk = $self->get_imported_page($seq[4]);
    $gfx->formimage($chunk, 0, 0) if $chunk;
    
    $chunk = $self->get_imported_page($seq[5]);
    $gfx->formimage($chunk, $self->orig_width, 0) if $chunk;

    $chunk = $self->get_imported_page($seq[6]);
    $gfx->formimage($chunk, $self->orig_width *  2, 0) if $chunk;

    $chunk = $self->get_imported_page($seq[7]);
    $gfx->formimage($chunk, $self->orig_width * 3, 0) if $chunk;



}

=head1 INTERNALS

=head2 pages_per_sheet

Returns 16

=head2 cropmarks_options

Set inner to false and force signature to 16.

=cut


sub pages_per_sheet { 16 }

sub cropmarks_options {
    my %options = (
                   top => 1,
                   bottom => 1,
                   inner => 0,
                   outer => 1,
                   # no shifting need
                   twoside => 1,
                   signature => 16,
                  );
    return %options;
}




1;

=head1 SEE ALSO

L<PDF::Imposition>

=cut


