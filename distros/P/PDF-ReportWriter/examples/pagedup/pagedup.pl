#
# A more elaborate example where we duplicate
# and compose a PDF document onto another bigger PDF
# document (A4 page).
#
# Cosimo Streppone <cosimo@cpan.org>
# 2006-03-23
#
# $Id: pagedup.pl 16 2006-03-27 16:51:09Z cosimo $

use strict;
use PDF::ReportWriter;

sub applyPage
{
    my($self, $pdfrw_obj, $posx, $posy, $scale) = @_;
    my $label_file = $pdfrw_obj->{destination};
    my $pdf_obj = PDF::API2->open($label_file);
    my $page = $self->{pages}->[-1] || $self->new_page;
    my $pdf  = $self->{pdf};
    my $xo   = $pdf->importPageIntoForm($pdf_obj, 1);
    my $gfx  = $page->gfx();
    $gfx->formimage($xo, $posx, $posy, $scale);
    return($self);
}

sub distrib_iterator
{
    require POSIX;
    my($labelw, $labelh, $pagew, $pageh) = @_;

    my $x_labels = POSIX::floor($pagew / $labelw);
    my $y_labels = POSIX::floor($pageh / $labelh);

    my $n_label = 0;
    my $n_labels = $x_labels * $y_labels;

    # Return an "iterator method"
    my $iterator = sub {

        # Iteration endpoint
        if( $n_label == $n_labels ) {
            $n_label = 0;
            return(undef);
        }

        my $x = $n_label % $x_labels;
        my $y = POSIX::floor($n_label / $x_labels);
           $x *= $labelw;
           $y *= $labelh;

        $n_label++;

        return [ $x, $y ];
    };

    return($iterator);
}

my $label = PDF::ReportWriter->new();
$label->render_report('./pagedup.xml');
$label->save();

my $newpdf = PDF::ReportWriter->new({
    paper       => 'A4',
    orientation => 'portrait',
    destination => 'pagedup.pdf'
});

# Compose labels onto an A4 page
my $iter = distrib_iterator(
    297, 140,      # label dimensions
    595, 842       # A4 page
);

while( my $coord = $iter->() )
{
    #
    # Apply $label page onto $newpdf document
    # at position ($coord->[0], $coord->[1]) with scale 1:1
    #
    applyPage($newpdf, $label, @$coord, 1.0);
}

$newpdf->save();

