package PDF::Imposition::Schema1repeat2side;
use strict;
use warnings;
use Moo;
with "PDF::Imposition::Schema";

=head1 NAME

PDF::Imposition::Schema1repeat2side - put two identical pages side by side on the same physical sheet

=head1 SYNOPSIS

    use PDF::Imposition::Schema1repeat2side;
    my $imposer = PDF::Imposition::Schema1repeat2side->new(
                                                          file => "test.pdf",
                                                          output => "out.pdf",
                                                         );
    $imposer->impose;

=head1 SCHEMA EXPLANATION

     +-----+-----+    +-----+-----+
     |     |     |    |     |     |
     |  1  |  1  |    |  2  |  2  |
     |     |     |    |     |     |
     +-----+-----+    +-----+-----+

The same logical page is inserted twice, side by side, on the same
sheet, nothing else. Typical usage scenario: printing A5 leaflets on
A4, then cut the sheets vertically.

=cut


sub _do_impose {
    my $self = shift;
    $self->out_pdf_obj->mediabox(
                                 $self->orig_width * 2,
                                 $self->orig_height,
                                );
    foreach my $pageno (1..$self->total_pages) {
        my ($page, $gfx, $chunk);
        $page = $self->out_pdf_obj->page;
        $gfx = $page->gfx;
        $chunk = $self->get_imported_page($pageno);
        $gfx->formimage($chunk, 0, 0) if $chunk;
        $chunk = $self->get_imported_page($pageno);
        $gfx->formimage($chunk, $self->orig_width, 0) if $chunk;
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
                   # no shifting need
                   twoside => 0,
                   signature => 0,
                  );
    return %options;
}

1;
