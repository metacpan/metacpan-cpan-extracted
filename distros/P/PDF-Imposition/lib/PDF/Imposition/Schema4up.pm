package PDF::Imposition::Schema4up;

use strict;
use warnings FATAL => 'all';
use Moo;
extends 'PDF::Imposition::Schema2up';

=head1 NAME

PDF::Imposition::Schema4up - Imposition schema 4up (booklet)

=head1 SYNOPSIS

See L<PDF::Imposition>.

=head1 SCHEMA EXPLANATION

This schema is basically the same (with the same options and features)
of L<PDF::Imposition::Schema2up>. But while with the C<2up> schema you
get 2 logical pages on each physical page, with the C<4up> you get 4
pages on each side of the sheet. Hence, the signature must be a
multiple of 8.

To actually use this schema, paper cutting is needed. First print
recto-verso, then cut horizontally and put the lower stack on the
upper one and proceed as you would with the C<2up>.

It's basically a shortcut to save paper if you impose, e.g. A6 on A4.


        RECTO          VERSO
     +-----+-----+  +-----+-----+
     |     |     |  |     |     |
     |  8  |  1  |  |  2  |  7  |
     |     |     |  |     |     |
     8<----+---->8  8<----+---->8
     |     |     |  |     |     |
     |  6  |  3  |  |  4  |  5  |
     |     |     |  |     |     |
     +-----+-----+  +-----+-----+

=head2 INTERNALS

=head3 pages_per_sheet

Always return 8.


=cut

sub pages_per_sheet { 8 };

sub _do_impose {
    my $self = shift;
    # each physical page, 4 logical pages, recto-verso = 8
    die if $self->pages_per_sheet != 8;
    if ($self->computed_signature % 8) {
        die "Signature must be a multiple of 8!\n";
    }

    $self->out_pdf_obj->mediabox(
                                 $self->orig_width * 2,
                                 $self->orig_height  * 2,
                                );
    # get the 2up sequence
    my @seq = @{ $self->page_sequence_for_booklet };

    die "Number of pages is off : " . scalar(@seq) . " should be a multiple of 2!"
      if  @seq % 2;
    my $half = @seq / 2;

    my @upper = splice @seq, 0, $half;
    my @lower = splice @seq;

    die "Odd arrays!" if @upper != @lower;
    my @final_seq;
    while (@upper && @lower) {
        push @final_seq, [ @{ shift(@upper) }, @{ shift(@lower) } ];
    }
    die "Odd arrays!" if @upper || @lower;
    while (@final_seq) {
        my ($page, $gfx, $chunk);
        $page = $self->out_pdf_obj->page;
        $gfx = $page->gfx;
        my ($one, $two, $three, $four) = @{ shift(@final_seq) };
        $chunk = $self->get_imported_page($three);
        $gfx->formimage($chunk, 0, 0) if $chunk;

        $chunk = $self->get_imported_page($four);
        $gfx->formimage($chunk, $self->orig_width, 0) if $chunk;

        $chunk = $self->get_imported_page($two);
        $gfx->formimage($chunk,
                        $self->orig_width,
                        $self->orig_height) if $chunk;

        $chunk = $self->get_imported_page($one);
        $gfx->formimage($chunk,
                        0,
                        $self->orig_height) if $chunk;
    }
}


1;
