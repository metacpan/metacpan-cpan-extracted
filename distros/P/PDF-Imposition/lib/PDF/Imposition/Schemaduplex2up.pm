package PDF::Imposition::Schemaduplex2up;

use strict;
use warnings FATAL => 'all';

use Moo;
extends 'PDF::Imposition::Schema2up';

=head1 NAME

PDF::Imposition::Schemaduplex2up - Imposition schema 2up for duplex printers

=head1 SYNOPSIS

This class inherit everything from L<PDF::Imposition::Schema2up> and
only alters the C<impose> method to rotate the odd pages by 180
degrees. Please refer to the parent class for method documentation.

=head1 SCHEMA EXPLANATION

This is exactly as the C<2up> schema, but the PDF is prepared for
duplex printing.

       RECTO S.1     VERSO S.1
     +-----+-----+  +-----+-----+ 
     |     |     |  |     |     | 
     |  1R |  8R |  |  2  |  7  | 
     |     |     |  |     |     | 
     +-----+-----+  +-----+-----+ 

       RECTO S.2     VERSO S.2
     +-----+-----+  +-----+-----+
     |     |     |  |     |     |
     |  3R |  6R |  |  4  |  5  |
     |     |     |  |     |     |
     +-----+-----+  +-----+-----+

=cut


sub _do_impose {
    my $self = shift;
    # prototype
    $self->out_pdf_obj->mediabox(
                                 $self->orig_width * 2,
                                 $self->orig_height,
                                );
    my $seq = $self->page_sequence_for_booklet;
    my $count = 0;
    foreach my $p (@$seq) {
        # loop over the pages
        $count++;
        my $left = $self->get_imported_page($p->[0]);
        my $right = $self->get_imported_page($p->[1]);
        my $page = $self->out_pdf_obj->page();
        my $gfx = $page->gfx();
        if ($count % 2) {
            $gfx->transform (
                             -translate => [$self->orig_width  * 2, $self->orig_height ],
                             -rotate => 180,
                            );
        }
        if (defined $left) {
            $gfx->formimage($left, 0, 0);
        }
        if (defined $right) {
            $gfx->formimage($right, $self->orig_width, 0);
        }
    }
}

1;
