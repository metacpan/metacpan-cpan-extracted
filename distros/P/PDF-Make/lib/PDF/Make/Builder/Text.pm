package PDF::Make::Builder::Text;
use strict;
use warnings;
use Object::Proto;
use PDF::Make::Builder::Font;
use PDF::Make::Builder::Runs;

BEGIN {
    Object::Proto::define('PDF::Make::Builder::Text',
        'text:Str:required',
        'align:Str:default(left)',
        'indent:Int:default(0)',
        'padding:Num:default(0)',
        'spacing:Num:default(0)',
        'pad:Str',
        'pad_end:Str',
        'margin:Num:default(5)',
        'overflow:Bool:default(0)',
        'preformatted:Bool:default(0)',
        'font:HashRef',
        'runs:ArrayRef',
        'x:Num', 'y:Num', 'w:Num', 'h:Num',
        'end_w:Num:default(0)',
        'end_y:Num:default(0)',
    );
    Object::Proto::import_accessors('PDF::Make::Builder::Text');
}

sub _resolve_font {
    my ($self, $builder) = @_;
    my $base = $builder->font;
    my $overrides = font $self;
    if ($overrides) {
        my $f = PDF::Make::Builder::Font->new(
            colour      => $overrides->{colour}      // $base->colour,
            size        => $overrides->{size}         // $base->size,
            family      => $overrides->{family}       // $base->family,
            bold        => $overrides->{bold}         // $base->bold,
            italic      => $overrides->{italic}       // $base->italic,
            line_height => $overrides->{line_height}  // $base->effective_line_height,
        );
        return $f;
    }
    return $base;
}

# Soft-wrap one physical line of preformatted text to $max_w, preserving all
# whitespace. Breaks at whitespace boundaries where possible; a single token
# wider than the line is broken between characters. Returns the wrapped
# segments (continuation segments start at the left margin, not re-indented).
sub _wrap_pre_line {
    my ($font, $line, $max_w) = @_;
    return ($line) if $font->measure_text($line) <= $max_w;

    # Words and whitespace runs, everything preserved. Any atom that is itself
    # wider than the line is pre-split into character-sized chunks.
    my @atoms;
    for my $a (grep { length } split /(\s+)/, $line) {
        if ($font->measure_text($a) <= $max_w) {
            push @atoms, $a;
        } else {
            push @atoms, _char_chunks($font, $a, $max_w);
        }
    }

    my @out;
    my $cur = '';
    for my $a (@atoms) {
        if ($cur eq '' || $font->measure_text($cur . $a) <= $max_w) {
            $cur .= $a;
        } else {
            push @out, $cur;
            $cur = $a;
        }
    }
    push @out, $cur if length $cur;
    return @out;
}

# Break a string into the longest character prefixes that each fit in $max_w.
sub _char_chunks {
    my ($font, $s, $max_w) = @_;
    my @chunks;
    my $cur = '';
    for my $ch (split //, $s) {
        if ($cur eq '' || $font->measure_text($cur . $ch) <= $max_w) {
            $cur .= $ch;
        } else {
            push @chunks, $cur;
            $cur = $ch;
        }
    }
    push @chunks, $cur if length $cur;
    return @chunks;
}

# The plain string behind a run list: what tagged output, extraction and the
# accessibility tree see. Callers that build a Text directly with runs must
# still pass text (the property is required); Builder::add_text derives it.
sub plain_text_from_runs {
    my ($runs) = @_;
    return '' unless ref $runs eq 'ARRAY';
    return join '', map { defined $_->{text} ? $_->{text} : '' } @$runs;
}

# Resolve each run's style overrides against the block font, returning the
# list PDF::Make::Builder::Runs wants. Identical styles share one font object,
# which is what lets adjacent segments coalesce into a single measurement.
sub _resolve_runs {
    my ($self, $builder) = @_;
    my $base = $self->_resolve_font($builder);
    my %cache;
    my @out;

    for my $run (@{ runs $self }) {
        next unless defined $run->{text} && length $run->{text};
        my %spec = (
            colour      => $run->{colour}      // $base->colour,
            size        => $run->{size}        // $base->size,
            family      => $run->{family}      // $base->family,
            bold        => $run->{bold}        // $base->bold,
            italic      => $run->{italic}      // $base->italic,
            line_height => $run->{line_height} // $base->effective_line_height,
        );
        my $key = join "\0", map { defined $spec{$_} ? $spec{$_} : '' }
                             qw(colour size family bold italic line_height);
        $cache{$key} ||= PDF::Make::Builder::Font->new(%spec);
        push @out, { font => $cache{$key}, text => $run->{text} };
    }
    return \@out;
}

sub add {
    my ($self, $builder) = @_;

    my $runs = runs $self;
    return $self->_add_runs($builder) if ref $runs eq 'ARRAY' && @$runs;

    my $page = $builder->page;
    my $canvas = $page->canvas;
    my $font = $self->_resolve_font($builder);
    my $res_name = $font->ensure_loaded($page->xs_page);
    my $font_size = $font->size;
    my $lh = $font->effective_line_height;
    my $line_spacing = spacing $self;
    $line_spacing = 0 if !defined($line_spacing) || $line_spacing < 0;
    my ($cr, $cg, $cb) = $font->hex_to_rgb($font->colour);

    my $pad = padding $self;
    $pad = 0 if !defined($pad) || $pad < 0;

    my $text_w = ($self->w // $page->width) - (2 * $pad);
    $text_w = 1 if $text_w < 1;
    my $cx = ($self->x // $page->content_x) + $pad;
    my $cy = $self->y;

    # Explicit y is already in builder/PDF bottom-left coordinates
    if (!defined $cy) {
        $cy = $page->cursor_y;
    }
    $cy -= $pad;

    # Apply indent
    my $indent_w = 0;
    my $ind = indent $self;
    if ($ind > 0) {
        $indent_w = $font->space_width * $ind;
    }

    # Build the list of physical lines to render.  Each entry is
    # [ line_text, line_width, is_first ].
    my $raw = text $self;
    my $preformatted = preformatted $self;

    my @lines;

    if ($preformatted) {
        # Verbatim: preserve hard newlines and all in-line whitespace (leading
        # spaces indent via the space glyph's advance), expand tabs to four
        # spaces, and never collapse runs of whitespace. Physical lines wider
        # than the content width are soft-wrapped (at whitespace where
        # possible, mid-token otherwise) so nothing runs off the page.
        return $self unless length $raw;
        for my $phys (split /\n/, $raw, -1) {
            $phys =~ s/\t/    /g;
            if ($phys eq '') {
                push @lines, ['', 0, 0];   # blank line -> vertical space
                next;
            }
            for my $seg (_wrap_pre_line($font, $phys, $text_w)) {
                push @lines, [$seg, $font->measure_text($seg), 0];
            }
        }
        # A trailing newline yields one empty line; drop it so a block that
        # merely ends in "\n" doesn't gain a spurious blank line.
        pop @lines if @lines > 1 && $lines[-1][0] eq '';
    }
    else {
        # Word-wrap: collapse whitespace and reflow to the content width.
        my @words = split /\s+/, $raw;
        return $self unless @words;

        my $line = '';
        my $line_w = $indent_w;
        my $first_line = 1;

        for my $word (@words) {
            my $candidate = $line eq '' ? $word : ($line . ' ' . $word);
            my $candidate_w = $font->measure_text($candidate);
            my $test_w = $candidate_w + ($first_line ? $indent_w : 0);
            my $max_w = $text_w;

            if ($test_w > $max_w && $line ne '') {
                push @lines, [$line, $line_w, $first_line];
                $first_line = 0;
                $line = $word;
                $line_w = $font->measure_text($line);
            } else {
                $line = $candidate;
                $line_w = $test_w;
            }
        }
        push @lines, [$line, $line_w, $first_line] if $line ne '';
    }

    # Render lines. Preformatted text is always left-aligned; reflow-only
    # features (alignment, dot-leader padding) don't apply to it.
    my $al = $preformatted ? 'left' : align $self;
    my $can_overflow = overflow $self;

    for my $idx (0 .. $#lines) {
        my $entry = $lines[$idx];
        my ($line_text, $lw, $is_first) = @$entry;

        # Check if we have room
        if ($cy - $lh < $page->bottom_y) {
            # Try next column first
            if ($page->has_next_column) {
                $page->next_column;
                $cx = $page->content_x + $pad;
                $cy = $page->cursor_y - $pad;
                $text_w = $page->width - (2 * $pad);
                $text_w = 1 if $text_w < 1;
            } elsif ($can_overflow) {
                # All columns full — overflow to new page
                # Inherit settings from current page
                my $cols = $page->columns;
                my $psz  = $page->page_size;
                my $page_pad = $page->padding;
                my $bg   = $page->background;
                $builder->add_page(
                    page_size  => $psz,
                    padding    => $page_pad,
                    columns    => $cols,
                    background => $bg,
                );
                $page = $builder->page;
                $canvas = $page->canvas;
                $res_name = $font->ensure_loaded($page->xs_page);
                $cx = $page->content_x + $pad;
                $cy = $page->cursor_y - $pad;
                $text_w = $page->width - (2 * $pad);
                $text_w = 1 if $text_w < 1;
            } else {
                last;
            }
        }

        # Baseline sits near top of the line slot (font_size below cursor).
        # The full line_height advances the cursor to the bottom of the slot.
        my $baseline_y = $cy - $font_size;

        # Calculate x based on alignment
        my $tx = $cx;
        my $extra_indent = $is_first ? $indent_w : 0;
        if ($al eq 'center') {
            $tx = $cx + ($text_w - $lw) / 2;
        } elsif ($al eq 'right') {
            $tx = $cx + $text_w - $lw;
        } else {
            $tx += $extra_indent;
        }

        # Pad support (for TOC dot leaders)
        my $pad_char = pad $self;
        if ($pad_char && length($pad_char)) {
            my $pad_end_text = pad_end($self) // '';
            my $pad_w = $font->measure_word($pad_char);
            my $end_w = length($pad_end_text) ? $font->measure_text($pad_end_text) : 0;
            my $gap = $text_w - $lw - $end_w;
            if ($gap > $pad_w) {
                my $num_pads = int($gap / $pad_w);
                $line_text .= ' ' . ($pad_char x $num_pads);
                $line_text .= $pad_end_text if length($pad_end_text);
            }
        }

        $canvas->BT
               ->rg($cr, $cg, $cb)
               ->Tf($res_name, $font_size)
               ->Tm(1, 0, 0, 1, $tx, $baseline_y)
               ->Tj($line_text)
               ->ET;

        $cy -= $lh;
        $cy -= $line_spacing if $idx < $#lines;
    }

    # Update page cursor - spacing applies after the entire block
    my $final_y = $cy - (margin $self) - $line_spacing - $pad;
    $page->y($final_y);
    if (@lines) {
        end_w $self, $lines[-1][1];
        end_y $self, $cy;  # bottom of last line slot
    }

    return $self;
}

# Styled-run rendering. Deliberately a separate path from add() above: the
# single-font code there produces bytes that existing documents depend on,
# and the safest way to keep them is not to touch it. The two agree on where
# lines break for single-run input, which t/45-runs.t asserts directly.
sub _add_runs {
    my ($self, $builder) = @_;

    my $page   = $builder->page;
    my $canvas = $page->canvas;
    my $rruns  = $self->_resolve_runs($builder);
    return $self unless @$rruns;

    my $line_spacing = spacing $self;
    $line_spacing = 0 if !defined($line_spacing) || $line_spacing < 0;

    my $pad = padding $self;
    $pad = 0 if !defined($pad) || $pad < 0;

    my $text_w = ($self->w // $page->width) - (2 * $pad);
    $text_w = 1 if $text_w < 1;
    my $cx = ($self->x // $page->content_x) + $pad;
    my $cy = $self->y;
    $cy = $page->cursor_y if !defined $cy;
    $cy -= $pad;

    my $indent_w = 0;
    my $ind = indent $self;
    if ($ind > 0) {
        $indent_w = $rruns->[0]{font}->space_width * $ind;
    }

    my $lines = PDF::Make::Builder::Runs->layout(
        runs     => $rruns,
        width    => $text_w,
        indent_w => $indent_w,
    );
    return $self unless @$lines;

    my $al           = align $self;
    my $can_overflow = overflow $self;
    my %ensured;

    for my $idx (0 .. $#$lines) {
        my $line = $lines->[$idx];
        my $lh   = $line->{lh};

        if ($cy - $lh < $page->bottom_y) {
            if ($page->has_next_column) {
                $page->next_column;
                $cx     = $page->content_x + $pad;
                $cy     = $page->cursor_y - $pad;
                $text_w = $page->width - (2 * $pad);
                $text_w = 1 if $text_w < 1;
            } elsif ($can_overflow) {
                $builder->add_page(
                    page_size  => $page->page_size,
                    padding    => $page->padding,
                    columns    => $page->columns,
                    background => $page->background,
                );
                $page   = $builder->page;
                $canvas = $page->canvas;
                %ensured = ();          # font resources are per page
                $cx     = $page->content_x + $pad;
                $cy     = $page->cursor_y - $pad;
                $text_w = $page->width - (2 * $pad);
                $text_w = 1 if $text_w < 1;
            } else {
                last;
            }
        }

        # One baseline per line, set by the tallest run on it, so a larger or
        # bold segment sits on the same line as its neighbours instead of
        # drifting.
        my $baseline_y = $cy - $line->{size};

        my $tx = $cx;
        if ($al eq 'center') {
            $tx = $cx + ($text_w - $line->{w}) / 2;
        } elsif ($al eq 'right') {
            $tx = $cx + $text_w - $line->{w};
        } elsif ($line->{is_first}) {
            $tx += $indent_w;
        }

        $canvas->BT;
        for my $seg (@{ $line->{segs} }) {
            my $font = $seg->{font};
            my $key  = "$font";
            my $res  = $ensured{$key} ||= $font->ensure_loaded($page->xs_page);
            my ($r, $g, $b) = $font->hex_to_rgb($font->colour);
            $canvas->rg($r, $g, $b)
                   ->Tf($res, $font->size)
                   ->Tm(1, 0, 0, 1, $tx, $baseline_y)
                   ->Tj($seg->{text});
            $tx += $seg->{w};
        }
        $canvas->ET;

        $cy -= $lh;
        $cy -= $line_spacing if $idx < $#$lines;
    }

    my $final_y = $cy - (margin $self) - $line_spacing - $pad;
    $page->y($final_y);
    end_w $self, $lines->[-1]{w};
    end_y $self, $cy;

    return $self;
}

1;

__END__

=encoding UTF-8

=head1 NAME

PDF::Make::Builder::Text - Word-wrapped text paragraph for PDF::Make

=head1 SYNOPSIS

    $builder->add_text(
        text     => 'Hello, world!',
        align    => 'center',
        margin   => 10,
        overflow => 1,
        font     => { size => 12, colour => '#333' },
    );

=head1 DESCRIPTION

Renders a word-wrapped text paragraph at the current cursor position, handling
line breaking, alignment, indentation, and automatic page overflow.

=head1 PROPERTIES

=over 4

=item B<text> (Str, required)

The text content to render. When C<runs> is given this is the plain string
behind them, which tagged output and extraction read; C<add_text> derives it
for you.

=item B<runs> (ArrayRef)

Styled inline runs, for text whose style changes mid-sentence:

    $pdf->add_text(runs => [
        { text => 'Amount due: ' },
        { text => '1,240.00', bold => 1 },
        { text => ' by 30 September.', italic => 1, colour => '#aa0000' },
    ]);

Each run is a hashref of C<text> plus any of C<bold>, C<italic>, C<colour>,
C<size>, C<family> and C<line_height>, each defaulting to the block font.
Lines break across run boundaries, and a line's baseline and height come from
the largest run on it, so a bigger or bolder segment makes room for itself.

When C<runs> is absent the original single-font path renders the block, and
its output is unchanged - documents produced before runs existed still render
byte for byte as they did. For a single run the two paths choose the same
line breaks, which C<t/45-runs.t> asserts against the shipped algorithm.

=item B<align> (Str, default C<'left'>)

Horizontal alignment: C<'left'>, C<'center'>, or C<'right'>.

=item B<indent> (Int, default 0)

Number of space-widths to indent the first line.

=item B<padding> (Num, default 0)

Inset in points applied on all sides of the text block.

=item B<spacing> (Num, default 0)

Extra vertical spacing in points between wrapped lines, and after the entire text block.

=item B<pad> (Str)

Padding character used for dot leaders (e.g. in TOC entries).

=item B<pad_end> (Str)

Text appended after the pad characters (e.g. a page number).

=item B<margin> (Num, default 5)

Vertical margin in points added after the text block.

=item B<overflow> (Bool, default 0)

When true, automatically creates new pages if the text exceeds the remaining
space on the current page.

=item B<preformatted> (Bool, default 0)

When true, the text is rendered verbatim: hard newlines and all in-line
whitespace are preserved (leading spaces indent), and tabs are expanded to
four spaces. Whitespace is never collapsed, but physical lines longer than
the content width are soft-wrapped (at whitespace where possible, mid-token
otherwise) so nothing runs off the page. Preformatted text is always
left-aligned, and C<align>, C<indent>, and C<pad> are ignored; page
C<overflow> still applies. Use this for code blocks and other pre-formatted
content where the default whitespace-collapsing word-wrap would destroy the
layout.

=item B<font> (HashRef)

Font overrides: C<colour>, C<size>, C<family>, C<line_height>.

=item B<end_w> (Num, default 0)

Set after rendering to the width of the last rendered line.

=back

=head1 METHODS

=over 4

=item B<add($builder)>

Renders the word-wrapped text onto the builder's current page, advancing the
cursor.  Returns C<$self>.

=back

=head1 SEE ALSO

L<PDF::Make::Builder>, L<PDF::Make::Builder::Font>,
L<PDF::Make::Builder::Text::H1>

=cut
