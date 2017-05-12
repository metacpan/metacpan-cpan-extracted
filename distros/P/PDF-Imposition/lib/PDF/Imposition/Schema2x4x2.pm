package PDF::Imposition::Schema2x4x2;
use strict;
use warnings;
use Moo;
with 'PDF::Imposition::Schema';

=head1 NAME

PDF::Imposition::Schema2x4x2 - fixed size 16 pages on 2 sheets signature schema, with double folding.

=head1 SYNOPSIS

    use PDF::Imposition::Schema2x4x2;
    my $imposer = PDF::Imposition::Schema2x4x2->new(
                                                    file => "test.pdf",
                                                    output => "out.pdf",
                                                    );
    $imposer->impose;

The output pdf will be left in C<< $imposer->output >>

=head1 SCHEMA EXPLANATION

Fixed signature size of 16 pages, printed recto-verso on 2 sheets.

Typical usage: print A5 on A3, or A6 on A4, then fold twice and cut
the edges.

Visualization (the prefix C<r> means logical page disposed
upside-down -- rotated 180 degrees):


     +------+------+    +------+------+
     |      |      |    |      |      |
     |  r9  |  r8  |    |  r7  | r10  |
     |      |      |    |      |      |
     +------+------+    +------+------+
     |      |      |    |      |      |
     |  16  |  1   |    |  2   | 15   |
     |      |      |    |      |      |
     +------+------+    +------+------+

     +------+------+    +------+------+
     |      |      |    |      |      |
     | r11  | r6   |    |  r5  | r12  |
     |      |      |    |      |      |
     +------+------+    +------+------+
     |      |      |    |      |      |
     |  14  |  3   |    |  4   |  13  |
     |      |      |    |      |      |
     +------+------+    +------+------+


To complete the block of 16 logical pages, blank pages are inserted if
needed.

=cut

sub _do_impose {
    my $self = shift;
    # set the mediabox doubling them
    $self->out_pdf_obj->mediabox(
                                 $self->orig_width * 2,
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
        # initialize
        $self->_compose_quadruple($p16, $p1, $p8, $p9);
        $self->_compose_quadruple($p2, $p15, $p10, $p7);
        $self->_compose_quadruple($p14, $p3, $p6, $p11);
        $self->_compose_quadruple($p4, $p13, $p12, $p5);
    }
}

sub _compose_quadruple {
    my ($self, @seq) = @_;
    my $chunk;
    my $page = $self->out_pdf_obj->page;
    my $gfx = $page->gfx;

    $chunk = $self->get_imported_page($seq[0]);
    $gfx->formimage($chunk, 0, 0) if $chunk;

    $chunk = $self->get_imported_page($seq[1]);
    $gfx->formimage($chunk, $self->orig_width, 0) if $chunk;

    # translate
    $gfx->transform (
                     -translate => [$self->orig_width  * 2,
                                    $self->orig_height * 2],
                     -rotate => 180,
                    );

    $chunk = $self->get_imported_page($seq[2]);
    $gfx->formimage($chunk, 0, 0) if $chunk;
    
    $chunk = $self->get_imported_page($seq[3]);
    $gfx->formimage($chunk, $self->orig_width, 0) if $chunk;
}

=head1 INTERNALS

=head2 pages_per_sheet

Returns 8

=head2 cropmarks_options

Set inner to false and force signature to 16.

=cut


sub cropmarks_options {
    my %options = (
                   top => 1,
                   bottom => 1,
                   inner => 0,
                   outer => 1,
                   twoside => 1,
                   signature => 16,
                  );
    return %options;
}

sub pages_per_sheet { 8 };

1;

=head1 SEE ALSO

L<PDF::Imposition>

=cut


