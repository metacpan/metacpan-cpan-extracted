package PDF::Make::Builder::Runs;
use strict;
use warnings;

our $VERSION = '0.10';

# Line breaking across styled runs.
#
# A paragraph is a list of runs, each with its own font. Breaking has to
# happen across run boundaries - "the <b>total</b> due" is three runs and one
# sentence - so the width of a candidate line is the sum of its segments
# rather than one measurement.
#
# Adjacent segments sharing a font object are coalesced into a single string
# before measuring. That is not an optimisation: measure_text sums per-glyph
# advances in double precision, so measuring "a b c" as one string and as
# three pieces differ in the last few bits. Coalescing makes the single-run
# case measure exactly one string per candidate, which is what the legacy
# path in PDF::Make::Builder::Text does, so both produce identical breaks.
# t/45-runs.t holds that equality down.

# Split a run into words, dropping the whitespace between them. Empty strings
# from leading whitespace are skipped; the legacy path tolerates them by
# accident, we do it on purpose.
sub _words {
    my ($text) = @_;
    return grep { length } split /\s+/, defined $text ? $text : '';
}

# Width of a segment list, coalescing runs of the same font.
sub _measure {
    my ($segs) = @_;
    my $w = 0;
    my $i = 0;
    while ($i < @$segs) {
        my $font = $segs->[$i]{font};
        my $text = $segs->[$i]{text};
        my $j = $i + 1;
        while ($j < @$segs && $segs->[$j]{font} == $font) {
            $text .= $segs->[$j]{text};
            $j++;
        }
        $w += $font->measure_text($text);
        $i = $j;
    }
    return $w;
}

# Append a word to a segment list, with a separating space when the line is
# not empty. The space is measured in the font of the segment it follows,
# which keeps it inside that segment's coalesced string.
sub _append {
    my ($segs, $font, $word) = @_;
    my $sep = @$segs ? ' ' : '';
    if (@$segs && $segs->[-1]{font} == $font) {
        $segs->[-1]{text} .= $sep . $word;
    } else {
        $segs->[-1]{text} .= $sep if @$segs && length $sep;
        push @$segs, { font => $font, text => $word };
    }
    return $segs;
}

sub _clone_segs {
    my ($segs) = @_;
    return [ map { { font => $_->{font}, text => $_->{text} } } @$segs ];
}

# Per-segment widths for rendering, plus the line's vertical metrics.
sub _finish_line {
    my ($segs, $is_first) = @_;
    my ($size, $lh) = (0, 0);
    for my $s (@$segs) {
        $s->{w} = $s->{font}->measure_text($s->{text});
        my $fs = $s->{font}->size;
        my $fl = $s->{font}->effective_line_height;
        $size = $fs if $fs > $size;
        $lh   = $fl if $fl > $lh;
    }
    return {
        segs     => $segs,
        w        => _measure($segs),
        is_first => $is_first,
        size     => $size,
        lh       => $lh,
    };
}

=head2 layout

    my $lines = PDF::Make::Builder::Runs->layout(
        runs     => [ { font => $font, text => 'Total ' }, ... ],
        width    => $content_w,
        indent_w => $indent_w,
    );

Greedy first-fit, matching the legacy single-font algorithm word for word.
Returns an arrayref of lines, each a hashref of C<segs> (each with C<font>,
C<text> and C<w>), the total C<w>, C<is_first>, and the line's C<size> and
C<lh> - the largest font size and line height present on it, so a bold or
larger run makes room for itself rather than overprinting the line above.

=cut

sub layout {
    my ($class, %args) = @_;
    my $runs     = $args{runs}     || [];
    my $width    = $args{width}    || 1;
    my $indent_w = $args{indent_w} || 0;

    my @lines;
    my $segs       = [];
    my $first_line = 1;

    for my $run (@$runs) {
        my $font = $run->{font};
        for my $word (_words($run->{text})) {
            my $candidate = _clone_segs($segs);
            _append($candidate, $font, $word);
            my $cw = _measure($candidate) + ($first_line ? $indent_w : 0);

            if ($cw > $width && @$segs) {
                push @lines, _finish_line($segs, $first_line);
                $first_line = 0;
                $segs = [ { font => $font, text => $word } ];
            } else {
                $segs = $candidate;
            }
        }
    }
    push @lines, _finish_line($segs, $first_line) if @$segs;

    return \@lines;
}

1;

__END__

=encoding UTF-8

=head1 NAME

PDF::Make::Builder::Runs - line breaking across styled inline runs

=head1 SYNOPSIS

    my $lines = PDF::Make::Builder::Runs->layout(
        runs => [
            { font => $plain, text => 'Amount due: ' },
            { font => $bold,  text => '£1,240.00' },
            { font => $plain, text => ' by 30 September.' },
        ],
        width => 400,
    );

    for my $line (@$lines) {
        for my $seg (@{ $line->{segs} }) {
            # $seg->{font}, $seg->{text}, $seg->{w}
        }
    }

=head1 DESCRIPTION

Pure layout: no canvas, no page, no side effects. Given runs and a width it
returns the lines they break into. L<PDF::Make::Builder::Text> renders the
result; keeping the two apart is what makes the breaking testable on its own,
and the equality with the legacy single-font path checkable.

Adjacent segments that share a font B<object> (compared by address, not by
value) are measured as one string. Callers that build a font per run should
reuse one object per distinct style, or the coalescing - and with it the
guarantee that single-run text breaks exactly as it did before runs existed -
will not happen.

=head1 SEE ALSO

L<PDF::Make::Builder::Text>, L<PDF::Make::Builder::Font>

=cut
