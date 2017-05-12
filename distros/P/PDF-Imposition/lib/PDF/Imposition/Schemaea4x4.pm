package PDF::Imposition::Schemaea4x4;
use strict;
use warnings;
use Moo;
extends 'PDF::Imposition::Schema2x4x2';

=head1 NAME

PDF::Imposition::Schemaea4x4 - fixed size 16 pages on 2 sheets, with double individual folding

=head1 SYNOPSIS

    use PDF::Imposition::Schemaea4x4;
    my $imposer = PDF::Imposition::Schemaea4x4->new(
                                                    file => "test.pdf",
                                                    output => "out.pdf",
                                                    );
    $imposer->impose;

The output pdf will be left in C<< $imposer->output >>

=head1 SCHEMA EXPLANATION

Fixed signature size of 16 pages, printed recto-verso on 2 sheets.

This is B<not> suitable for home-printing.

Scenario: the sheets are printed. Each sheet is folded B<individually>
twice. Then the two folded sheets are inserted one into the other, and
finally the signature is bound and trimmed.

The bounding, to be stable, has to be done by a dedicated machine.

Long story short: if you are not looking exactly for this schema, it's
not what you want.


     +------+------+    +------+------+
     |      |      |    |      |      |
     |  r13 |  r4  |    |  r3  | r14  |
     |      |      |    |      |      |
     +------+------+    +------+------+
     |      |      |    |      |      |
     |  16  |  1   |    |  2   | 15   |
     |      |      |    |      |      |
     +------+------+    +------+------+

     +------+------+    +------+------+
     |      |      |    |      |      |
     | r9   | r8   |    |  r7  | r10  |
     |      |      |    |      |      |
     +------+------+    +------+------+
     |      |      |    |      |      |
     |  12  |  5   |    |  6   |  11  |
     |      |      |    |      |      |
     +------+------+    +------+------+


To complete the block of 16 logical pages, blank pages are inserted if
needed.

=cut

sub _do_impose {
    my $self = shift;
    $self->out_pdf_obj->mediabox(
                                 $self->orig_width * 2,
                                 $self->orig_height * 2,
                                );
    my $total = $self->total_pages;
    my @pages = (1..$total);
    while (@pages) {
        my ($p1,  $p2,  $p3,  $p4,
            $p5,  $p6,  $p7,  $p8,
            $p9,  $p10, $p11, $p12,
            $p13, $p14, $p15, $p16) = splice @pages, 0, 16;
        # initialize
        $self->_compose_quadruple($p16, $p1,  $p4,  $p13);
        $self->_compose_quadruple($p2,  $p15, $p14, $p3);
        $self->_compose_quadruple($p12, $p5,  $p8,  $p9 );
        $self->_compose_quadruple($p6,  $p11, $p10, $p7);
    }
}

1;
