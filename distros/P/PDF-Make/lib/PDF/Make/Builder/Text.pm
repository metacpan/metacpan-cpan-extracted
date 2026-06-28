package PDF::Make::Builder::Text;
use strict;
use warnings;
use Object::Proto;

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
        'font:HashRef',
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

sub add {
    my ($self, $builder) = @_;

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

    # Word-wrap
    my $raw = text $self;
    my @words = split /\s+/, $raw;
    return $self unless @words;

    my @lines;
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

    # Render lines
    my $al = align $self;
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

The text content to render.

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
