package Term::Fabulous::Viewport;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.03';

use Exporter 'import';
our @EXPORT_OK = qw(max_offset clamp_offset reveal_range scroll_thumb);

use List::Util qw(max min);

# How far the content can scroll: the part of it the viewport cannot
# show at once.
sub max_offset ( $content, $viewport ) {
	return max( 0, $content - $viewport );
}

sub clamp_offset ( $content, $viewport, $offset ) {
	return min( max( $offset, 0 ), max_offset( $content, $viewport ) );
}

# The offset nearest to $offset that shows the range [from, to); a range
# taller than the viewport shows its start.
sub reveal_range ( $content, $viewport, $offset, $from, $to ) {
	my $wanted
		= $from < $offset           ? $from
		: $to > $offset + $viewport ? min( $from, $to - $viewport )
		:                             $offset;
	return clamp_offset( $content, $viewport, $wanted );
}

# The thumb of a scrollbar track of $track cells: [ first cell, cells ].
# Its size is the visible part of the content, at least one cell; its
# place is the offset's share of the scrolling distance. Content that
# fits fills the track.
sub scroll_thumb ( $content, $viewport, $offset, $track ) {
	return [ 0, max( 0, $track ) ] if $track < 1 || $content <= $viewport;
	my $size  = max( 1, min( $track, int( $track * $viewport / $content + 0.5 ) ) );
	my $first = int( ( $track - $size ) * $offset / max_offset( $content, $viewport ) + 0.5 );
	return [ max( 0, min( $track - $size, $first ) ), $size ];
}

1;

__END__

=head1 NAME

Term::Fabulous::Viewport - The arithmetic of a scrolled view

=head1 SYNOPSIS

	use Term::Fabulous::Viewport qw(max_offset clamp_offset reveal_range scroll_thumb);

	# 40 rows of content in a view of 10 rows, scrolled down by 12:
	my $limit = max_offset( 40, 10 );                  # 30
	my $top   = clamp_offset( 40, 10, $top + 3 );      # within 0 .. 30
	$top      = reveal_range( 40, 10, $top, 25, 26 );  # row 25 in view: 16
	my ( $first, $size ) = @{ scroll_thumb( 40, 10, $top, 10 ) };    # the thumb of a 10-cell track

=head1 DESCRIPTION

Pure functions over the three numbers that describe a scrolled view:
the size of the I<content>, the size of the I<viewport> that shows part
of it, and the I<offset>, how far the viewport is scrolled from the
start of the content (0 at the start). The unit is up to the caller:
rows of a list, visual rows of a text, cells of a laid out box. Every
widget of Term::Fabulous that scrolls by itself uses them, so a list, a
text area and a table keep a row in view and draw their scrollbars by
the same rules. Nothing is exported by default.

=head1 FUNCTIONS

=head2 max_offset

	my $limit = max_offset( $content, $viewport );

The largest offset: the content minus the viewport, or 0 when the
content fits.

=head2 clamp_offset

	my $offset = clamp_offset( $content, $viewport, $offset );

The offset limited to 0 .. L</max_offset>.

=head2 reveal_range

	my $offset = reveal_range( $content, $viewport, $offset, $from, $to );

The offset that shows the range from C<$from> to before C<$to> with the
smallest change: the offset itself when the range is in view, the
start of the range when it lies above, and the offset that puts its end
at the end of the viewport when it lies below. A range larger than the
viewport shows its start. The result is clamped (L</clamp_offset>).

=head2 scroll_thumb

	my ( $first, $size ) = @{ scroll_thumb( $content, $viewport, $offset, $track ) };

The thumb of a scrollbar whose track is C<$track> cells long, as an
array reference: the first cell of the thumb and its length in cells.
The length is the viewport's share of the content (at least one cell,
at most the track), the place the offset's share of
L</max_offset>, rounded and kept inside the track. When the content
fits the viewport, or the track has no cells, the thumb is the whole
track (C<[0, $track]>, C<[0, 0]> for no cells).
L<Term::Fabulous::Widget::Scrollbar/paint_track> paints it.

=head1 SEE ALSO

L<Term::Fabulous::Widget::Scrollbar>, L<Term::Fabulous::TextView>.

=cut
