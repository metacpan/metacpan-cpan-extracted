package PDF::Make::Builder::Layout::Row;
use strict;
use warnings;
use Object::Proto;
use PDF::Make::Builder::Layout::Cell;
use Layout::Flex;

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

    my $canvas  = $page->canvas;
    my $font    = $builder->font;
    my $cx      = $page->content_x;
    my $total_w = $page->width;
    my $cursor  = $page->cursor_y;
    my $margin  = margin $self;
    my $gap     = gap $self;

    my $measure = sub {
        my ($item, $avail_w) = @_;
        my $cell = $cells[$item->{_idx}];
        my $h    = 0;

        for my $ci (@{$cell->content}) {
            if ($ci->{type} eq 'text') {
                my $item_font = $cell->_resolve_item_font($font, $ci);
                my $sz = $ci->{size}        // $item_font->size;
                my $lh = $ci->{line_height} // $sz;

                if (defined $avail_w) {
                    my $inner_w = $avail_w - 2 * $cell->pad;
                    $inner_w    = 1 if $inner_w < 1;
                    my $slack   = $cell->wrap_slack;
                    my @words   = split /\s+/, $ci->{text};
                    my $line    = '';
                    my $lines   = @words ? 1 : 0;
                    for my $word (@words) {
                        my $candidate = $line eq '' ? $word : ($line . ' ' . $word);
                        my $test      = $item_font->measure_text($candidate);
                        if ($test > $inner_w + $slack && $line ne '') {
                            $lines++;
                            $line = $word;
                        } else {
                            $line = $candidate;
                        }
                    }
                    $h += $lines * $lh;
                } else {
                    $h += $ci->{line_height} // $sz;
                }
            } elsif ($ci->{type} eq 'image') {
                $h += $ci->{h} // 50;
            }
        }

        return (0, $h);
    };

    my @flex_items;
    for my $i (0 .. $#cells) {
        push @flex_items, {
            grow      => $cells[$i]->weight,
            basis     => 0,
            text      => '1',
            wrap_text => 1,
            _idx      => $i,
        };
    }

    my @rects = Layout::Flex->compute(
        main_size  => $total_w,
        cross_size => 10000,
        align      => 'start',
        gap        => $gap,
        measure    => $measure,
        items      => \@flex_items,
    );

    my $row_h = height $self;
    unless ($row_h) {
        $row_h = 0;
        for my $i (0 .. $#rects) {
            my $h = $rects[$i][3] + 2 * $cells[$i]->pad;
            $row_h = $h if $h > $row_h;
        }
    }

    my $cell_y = $cursor - $row_h;

    for my $i (0 .. $#cells) {
        my $cell   = $cells[$i];
        my $cell_x = $cx + $rects[$i][0];
        my $cell_w = $rects[$i][2];

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
    }

    $page->advance_y($row_h + $margin);
}

1;
