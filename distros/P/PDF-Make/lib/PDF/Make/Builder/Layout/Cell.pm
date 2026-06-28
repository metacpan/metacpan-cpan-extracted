package PDF::Make::Builder::Layout::Cell;
use strict;
use warnings;
use overload '%{}' => '_as_hashref', fallback => 1;
use Object::Proto;
use PDF::Make::Builder::Font;

BEGIN {
    Object::Proto::define('PDF::Make::Builder::Layout::Cell',
        'row',
        'weight:Num:default(1)',
        'align:Str:default(left)',
        'valign:Str:default(top)',
        'pad:Num:default(5)',
        'bg:Str',
        'border:Str',
        'text_border:Str',
        'text_border_width:Num:default(0.5)',
        'wrap_slack:Num:default(0)',
        'content:ArrayRef:default([])',
    );
    Object::Proto::import_accessors('PDF::Make::Builder::Layout::Cell');
}

sub text {
    my ($self, $str, %args) = @_;
    my $content = content $self;
    push @$content, { type => 'text', text => $str, %args };
    return $self;
}

sub image {
    my ($self, $path, %args) = @_;
    my $content = content $self;
    push @$content, { type => 'image', path => $path, %args };
    return $self;
}

sub _as_hashref {
    my ($self) = @_;
    return {
        row               => row($self),
        weight            => weight($self),
        align             => align($self),
        valign            => valign($self),
        pad               => pad($self),
        bg                => bg($self),
        border            => border($self),
        text_border       => text_border($self),
        text_border_width => text_border_width($self),
        wrap_slack        => wrap_slack($self),
        content           => content($self),
    };
}

sub _resolve_item_font {
    my ($self, $base_font, $item) = @_;

    return $base_font
        if !defined($item->{size})
        && !defined($item->{family})
        && !defined($item->{bold})
        && !defined($item->{italic});

    return PDF::Make::Builder::Font->new(
        colour      => $item->{colour}      // $base_font->colour,
        size        => $item->{size}        // $base_font->size,
        family      => $item->{family}      // $base_font->family,
        bold        => $item->{bold}        // $base_font->bold,
        italic      => $item->{italic}      // $base_font->italic,
        line_height => $item->{line_height} // $base_font->effective_line_height,
    );
}

sub measure_height {
    my ($self, $font, $cell_w) = @_;
    my $h = 0;
    my $inner_w = $cell_w - 2 * (pad $self);
    for my $item (@{content $self}) {
        if ($item->{type} eq 'text') {
            my $item_font = $self->_resolve_item_font($font, $item);
            my $sz = $item->{size} // $item_font->size;
            my $lh = $item->{line_height} // $sz;
            my $text_w = $item_font->measure_text($item->{text});
            my $lines = int($text_w / ($inner_w || 1)) + 1;
            $h += $lines * $lh;
        } elsif ($item->{type} eq 'image') {
            $h += $item->{h} // 50;
        }
    }
    return $h;
}

sub render_content {
    my ($self, $canvas, $font, $page, $cx, $cy, $cw, $ch) = @_;

    if (my $tb = text_border $self) {
        my ($r, $g, $b) = $font->hex_to_rgb($tb);
        my $bw = text_border_width $self;
        $canvas->q->w($bw)->RG($r, $g, $b)->re($cx, $cy, $cw, $ch)->S->Q;
    }

    my $text_y = $cy + $ch - (pad $self);
    my $align = align $self;

    for my $item (@{content $self}) {
        next unless $item->{type} eq 'text';

        my $item_font = $self->_resolve_item_font($font, $item);
        my $sz = $item->{size} // $item_font->size;
        my $lh = $item->{line_height} // $sz;
        my $colour = $item->{colour} // $item_font->colour;
        my ($r, $g, $b) = $item_font->hex_to_rgb($colour);
        my $res = $item_font->ensure_loaded($page->xs_page);

        my @words = split /\s+/, $item->{text};
        my $line = '';
        my $line_w = 0;

        for my $word (@words) {
            my $candidate = $line eq '' ? $word : ($line . ' ' . $word);
            my $test = $item_font->measure_text($candidate);
            my $slack = wrap_slack $self;

            if ($test > $cw + $slack && $line ne '') {
                $text_y -= $lh;
                last if $text_y < $cy;
                my $tx = $cx;
                if ($align eq 'center') {
                    $tx = $cx + ($cw - $line_w) / 2;
                } elsif ($align eq 'right') {
                    $tx = $cx + $cw - $line_w;
                }
                $canvas->BT->Tf($res, $sz)->rg($r, $g, $b)
                    ->Td($tx, $text_y)->Tj($line)->ET;
                $line = $word;
                $line_w = $item_font->measure_text($line);
            } else {
                $line = $candidate;
                $line_w = $test;
            }
        }

        if ($line ne '') {
            $text_y -= $lh;
            if ($text_y >= $cy) {
                my $tx = $cx;
                if ($align eq 'center') {
                    $tx = $cx + ($cw - $line_w) / 2;
                } elsif ($align eq 'right') {
                    $tx = $cx + $cw - $line_w;
                }
                $canvas->BT->Tf($res, $sz)->rg($r, $g, $b)
                    ->Td($tx, $text_y)->Tj($line)->ET;
            }
        }
    }
}

1;
