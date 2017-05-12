package PDF::Imposition::Schema1x4x2cutfoldbind;

use strict;
use warnings;

use Types::Standard qw/Bool/;
use namespace::clean;

use Moo;
with 'PDF::Imposition::Schema';

=head1 NAME

PDF::Imposition::Schema1x4x2cutfoldbind - 1x4x2cutfoldbind imposition schema

=head1 SYNOPSIS

  use PDF::Imposition::Schema1x4x2cutfoldbind;
  my $imposer = PDF::Imposition::Schema1x4x2cutfoldbind
        ->new(
              file => "test.pdf",
              output => "out.pdf",
             );
  $imposer->impose;

=head1 SCHEMA EXPLANATION

  +-----+-----+    +-----+-----+
  |     |     |    |     |     |
  |  4  |  1  |    |  2  |  3  |
  |     |     |    |     |     |
  +-----+-----+    +-----+-----+
  |     |     |    |     |     |
  |  8  |  5  |    |  6  |  7  |
  |     |     |    |     |     |
  +-----+-----+    +-----+-----+

The schema uses fixes signatures of 8 logical pages, layed out on a
single sheet, printed recto-verso.

To get a booklet out of this schema, you first have to B<cut> the
sheets along the x-axys in the middle, then B<fold> each half along
the y-axys, stack them, repeat for each sheet, and finally glue or
B<bind> the spine. (Hence the name of the module).

Does it sound weird? Well, kind of. Looks like a lot of manual work.
But if it works for you, it works for me as well.

=head1 METHODS

=head2 cover

This schema supports the cover option.

=cut

has cover => (is => 'rw', isa => Bool);

sub pages_per_sheet { 8 }

sub signature { 8 }

=head1 INTERNALS

=head2 signature

Returns 8.

=head2 pages_per_sheet

Returns 8.

=head2 cropmarks_options

Set inner to false and force the signature to 4 for cropmarks purposes.

=cut

sub cropmarks_options {
    my %options = (
                   top => 1,
                   bottom => 1,
                   inner => 0,
                   outer => 1,
                   twoside => 1,
                   # for the purpose of the cropping, the signature is 4
                   signature => 4,
                  );
    return %options;
}

sub _do_impose {
    my $self = shift;
    # set the mediabox doubling them
    $self->out_pdf_obj->mediabox(
                                 $self->orig_width * 2,
                                 $self->orig_height * 2,
                                );
    my $total = $self->total_pages;
    my @pages = (1..$total);
    if ($self->cover) {
        if (my $modulo = $total % 4) {
            my $blanks = 4 - $modulo;
            my $last = pop @pages;
            for (1 .. $blanks) {
                push @pages, undef;
            }
            push @pages, $last;
        }
    }
    while (@pages) {
        my ($p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8) = splice @pages, 0, 8;
        $self->_compose_quadruple($p8, $p5, $p1, $p4);
        $self->_compose_quadruple($p6, $p7, $p3, $p2);
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
    $chunk = $self->get_imported_page($seq[2]);
    $gfx->formimage($chunk, $self->orig_width, $self->orig_height) if $chunk;
    $chunk = $self->get_imported_page($seq[3]);
    $gfx->formimage($chunk, 0, $self->orig_height) if $chunk;
}

1;





