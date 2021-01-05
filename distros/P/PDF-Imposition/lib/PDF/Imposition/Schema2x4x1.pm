package PDF::Imposition::Schema2x4x1;
use strict;
use warnings;
use Moo;
with 'PDF::Imposition::Schema';

=head1 NAME

PDF::Imposition::Schema2x4x1 - fixed size 8 pages on 1 sheet signature schema, with double folding.

=head1 SYNOPSIS

    use PDF::Imposition::Schema2x4x1;
    my $imposer = PDF::Imposition::Schema2x4x1->new(
                                                    file => "test.pdf",
                                                    output => "out.pdf",
                                                    );
    $imposer->impose;

The output pdf will be left in C<< $imposer->output >>

=head1 SCHEMA EXPLANATION

Fixed signature size of 8 pages, printed recto-verso on 1 sheet.

Typical usage: print A5 on A3, or A6 on A4, then fold twice and cut
the top edge.

Visualization (the prefix C<r> means logical page disposed
upside-down -- rotated 180 degrees):


     +------+------+    +------+------+
     |      |      |    |      |      |
     |  r5  |  r4  |    |  r3  |  r6  |
     |      |      |    |      |      |
     +------+------+    +------+------+
     |      |      |    |      |      |
     |  8   |   1  |    |  2   |   7  |
     |      |      |    |      |      |
     +------+------+    +------+------+


To complete the block of 8 logical pages, blank pages are inserted if
needed.

=cut

sub _do_impose {
    my $self = shift;
    # set the mediabox doubling them
    $self->out_pdf_obj->mediabox(
                                 $self->orig_width * 2,
                                 $self->orig_height * 2,
                                );
    # here we work with fixed signatures of 8, with the module
    my $total = $self->total_pages;
    my @pages = (1..$total);

    # loop over the pages and compose the 4 physical pages
    while (@pages) {
        my ($p1,  $p2,  $p3,  $p4,
            $p5,  $p6,  $p7,  $p8) = splice @pages, 0, 8;
        # initialize
        $self->_compose_quadruple($p8, $p1, $p4, $p5);
        $self->_compose_quadruple($p2, $p7, $p6, $p3);
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

Set inner to false and force signature to 8.

=cut


sub cropmarks_options {
    my %options = (
                   top => 1,
                   bottom => 1,
                   inner => 0,
                   outer => 1,
                   twoside => 1,
                   signature => 8,
                  );
    return %options;
}

sub pages_per_sheet { 8 };

1;

=head1 SEE ALSO

L<PDF::Imposition>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of either: the GNU General Public License as
published by the Free Software Foundation; or the Artistic License.

=head1 AUTHOR

Daniel Drennan ElAwar <drennan@panix.com>

=cut


