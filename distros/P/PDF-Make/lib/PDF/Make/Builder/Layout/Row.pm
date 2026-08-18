package PDF::Make::Builder::Layout::Row;
use strict;
use warnings;
use Object::Proto;
use PDF::Make::Builder::Layout::Cell;
use Layout::Flex;
use Scalar::Util ();

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

# A cell keeps a reference to its row and the row keeps its cells, which is a
# cycle: reference counting never collects either, so every laid-out row was
# leaked for the life of the process. A document with a table used to cost
# around 90KB that was never given back, which is invisible in a script and
# fatal in a server rendering documents all day.
#
# The back-reference is weakened rather than removed: cells genuinely need to
# reach their row. The slot is found by identity rather than by index so that
# reordering the property list in the define() above cannot silently turn this
# back into a leak, and t/55-layout-cycle.t checks it still bites.
sub _weaken_row_ref {
    my ($cell, $row) = @_;
    for my $i (0 .. $#$cell) {
        next unless ref $cell->[$i];
        next unless $cell->[$i] == $row;
        Scalar::Util::weaken($cell->[$i]);
        return 1;
    }
    return 0;
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
    my $cell = PDF::Make::Builder::Layout::Cell->new(%cell_args);
    _weaken_row_ref($cell, $self);
    push @$cells, $cell;
    return $cell;
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
                if ($ci->{runs}) {
                    my $inner = defined $avail_w
                        ? $avail_w - 2 * $cell->pad : undef;
                    $h += $cell->runs_height($font, $ci,
                        defined $inner && $inner > 1 ? $inner : 1);
                    next;
                }
                my $item_font = $cell->_resolve_item_font($font, $ci);
                my $sz = $ci->{size}        // $item_font->size;
                # spacing rides on the slot, exactly as the renderer takes it
                my $lh = ($ci->{line_height} // $sz)
                       + PDF::Make::Builder::Layout::Cell::item_spacing($ci);

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
                    $h += $lh;
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

    my $cross = 10000;
    my @rects = Layout::Flex->compute(
        main_size  => $total_w,
        cross_size => $cross,
        align      => 'start',
        gap        => $gap,
        measure    => $measure,
        items      => \@flex_items,
    );

    my $row_h = height $self;
    unless ($row_h) {
        $row_h = 0;
        for my $i (0 .. $#rects) {
            my $h = $rects[$i][3];
            # A cell with no content measures zero, and Layout::Flex hands a
            # zero-height item the whole cross size back. Taken at face value
            # that made one empty <td> a ten-thousand point row: the cursor
            # ran off the page, clamped to the top, and every row after it
            # drew in the same place. An empty cell contributes nothing to the
            # row height, which is what it looks like on the page.
            $h = 0 if $h >= $cross;
            $h += 2 * $cells[$i]->pad;
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
