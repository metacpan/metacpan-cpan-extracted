package PDF::Make::Builder::Layout::Row;
use strict;
use warnings;
use Object::Proto;
use PDF::Make::Builder::Layout::Cell;

BEGIN {
    Object::Proto::define('PDF::Make::Builder::Layout::Row',
        'layout:required',
        'height:Num',
        'margin:Num:default(5)',
        'gap:Num:default(0)',
        'cells:ArrayRef:default([])',
    );
    Object::Proto::import_accessors('PDF::Make::Builder::Layout::Row');
}

sub cell {
    my ($self, %args) = @_;
    my $cells = cells $self;
    my %cell_args = (
        row    => $self,
        weight => $args{weight} // 1,
        align  => $args{align}  // 'left',
        valign => $args{valign} // 'top',
        pad    => $args{pad}    // 5,
        text_border_width => $args{text_border_width} // 0.5,
        wrap_slack => $args{wrap_slack} // 0,
    );
    $cell_args{bg} = $args{bg} if defined $args{bg};
    $cell_args{border} = $args{border} if defined $args{border};
    $cell_args{text_border} = $args{text_border} if defined $args{text_border};
    push @$cells, PDF::Make::Builder::Layout::Cell->new(%cell_args);
    return $cells->[-1];
}

sub render {
    my ($self, $builder, $page) = @_;
    my @cells = @{cells $self};
    return unless @cells;

    my $canvas = $page->canvas;
    my $font = $builder->font;
    my $cx = $page->content_x;
    my $total_w = $page->width;
    my $cursor = $page->cursor_y;
    my $margin = margin $self;

    my $total_weight = 0;
    $total_weight += $_->weight for @cells;
    my $gap = gap $self;
    my $available = $total_w - ($#cells * $gap);

    my $row_h = height $self;
    unless ($row_h) {
        $row_h = 0;
        for my $cell (@cells) {
            my $ch = $cell->measure_height($font, $available * $cell->weight / $total_weight);
            $row_h = $ch if $ch > $row_h;
        }
        $row_h += 10;
    }

    my $cell_y = $cursor - $row_h;
    my $cell_x = $cx;

    for my $cell (@cells) {
        my $cell_w = $available * $cell->weight / $total_weight;

        if (defined $cell->bg) {
            my ($r, $g, $b) = $font->hex_to_rgb($cell->bg);
            $canvas->q->rg($r, $g, $b)->re($cell_x, $cell_y, $cell_w, $row_h)->f->Q;
        }

        if (defined $cell->border) {
            my ($r, $g, $b) = $font->hex_to_rgb($cell->border);
            $canvas->q->w(0.5)->RG($r, $g, $b)
                ->re($cell_x + 0.25, $cell_y + 0.25, $cell_w - 0.5, $row_h - 0.5)->S->Q;
        }

        $cell->render_content($canvas, $font, $page,
            $cell_x + $cell->pad, $cell_y, $cell_w - 2 * $cell->pad, $row_h);

        $cell_x += $cell_w + $gap;
    }

    $page->advance_y($row_h + $margin);
}

1;
