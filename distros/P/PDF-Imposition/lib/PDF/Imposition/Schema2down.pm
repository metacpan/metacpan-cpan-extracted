package PDF::Imposition::Schema2down;
use strict;
use warnings FATAL => 'all';

use Moo;
extends 'PDF::Imposition::Schema2up';

=head1 NAME

PDF::Imposition::Schema2down - Imposition schema 2down (booklet with binding on the top)

=head1 SYNOPSIS

This class inherit everything from L<PDF::Imposition::Schema2up> and
only alters the C<impose> method to rotate the pages by 90 degrees.
Please refer to the parent class for method documentation.

=head1 SCHEMA EXPLANATION

First go and read the schema explanation in
L<PDF::Imposition::Schema2up> (or better, the whole documentation).
It's the same dynamic kind of imposition.

The only difference is that each I<logical> page is rotated by 90
degrees counter-clockwise, so a signature of 4 pages looks so:

        +------+------+   +------+------+   
        |   4  |  1   |   |   2  |  3   |   
        +------+------+   +------+------+   

Now, showing the number rotated by 90 degrees is a bit complicated in
ASCII-art, but each logical page is B<rotated counter-clockwise>, so
you have to bind it on the short edge (and the final product will look
much more like a notepad than a booklet, as the binding will fall on
the top edge).

I find this schema odd, but I provide it nevertheless.

=cut

sub _do_impose {
    my $self = shift;
    $self->out_pdf_obj->mediabox(
                                 $self->orig_height * 2,
                                 $self->orig_width,
                                );
    my $seq = $self->page_sequence_for_booklet;
    foreach my $p (@$seq) {
        # loop over the pages
        my $left = $self->get_imported_page($p->[0]);
        my $right = $self->get_imported_page($p->[1]);
        my $page = $self->out_pdf_obj->page();
        my $gfx = $page->gfx();
        $gfx->transform (
                          -translate => [$self->orig_height, 0],
                          -rotate => 90
                         );
        if (defined $left) {
            $gfx->formimage($left);
        }
        if (defined $right) {
            $gfx->formimage($right, 0, 0 - $self->orig_height);
        }
    }
}

=head1 INTERNALS

=head2 cropmarks_options

Set twoside to false.

=cut

sub cropmarks_options {
    my %options = (
                   top => 1,
                   bottom => 1,
                   inner => 1,
                   outer => 1,
                   twoside => 0,
                  );
    return %options;
}

1;

=head1 SEE ALSO

L<PDF::Imposition>

=cut


