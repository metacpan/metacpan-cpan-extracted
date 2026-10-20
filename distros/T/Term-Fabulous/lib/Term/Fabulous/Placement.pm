package Term::Fabulous::Placement;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.05';

use Exporter 'import';
our @EXPORT_OK = qw(place_popup TOPMOST_Z_INDEX);

use List::Util qw(max min);
use Scalar::Util qw(looks_like_number);
use Term::Fabulous::Check qw(describe one_of);

# The highest z_index Clay has (int16): a popup belongs to the focused
# widget, so it floats over everything, a dialog included.
use constant TOPMOST_Z_INDEX => 32767;

my %IS_OPTION = map { $_ => 1 } qw(anchor size screen prefer align);

# The side a popup opens to when it fits there, or when the other side
# has no more room; [ the rows on that side, the rows on the other ].
my %SIDES = (
	below => sub ( $anchor, $screen_height ) { ( $screen_height - $anchor->{y} - $anchor->{height}, $anchor->{y} ) },
	above => sub ( $anchor, $screen_height ) { ( $anchor->{y},                                      $screen_height - $anchor->{y} - $anchor->{height} ) },
);
my %OTHER_SIDE = ( below => 'above', above => 'below' );

sub place_popup (%options) {
	my @unknown = grep { !$IS_OPTION{$_} } sort keys %options;
	die "Term::Fabulous::Placement: place_popup does not take @unknown (known: align anchor prefer screen size)" if @unknown;
	my $anchor = _box( $options{anchor} );
	my ( $width, $height )               = _pair( size => $options{size} );
	my ( $screen_width, $screen_height ) = _pair( screen => $options{screen} );
	my $prefer = one_of( 'Term::Fabulous::Placement: place_popup', prefer => $options{prefer} // 'below', qw(below above at) );
	my $align  = one_of( 'Term::Fabulous::Placement: place_popup', align  => $options{align}  // 'left',  qw(left right) );

	my ( $side, $flipped, $rows ) = _side( $prefer, $anchor, $height, $screen_height );
	my $x = $align eq 'left' ? $anchor->{x} : $anchor->{x} + $anchor->{width} - $width;
	my $y = $side eq 'below' ? $anchor->{y} + $anchor->{height} : $side eq 'above' ? $anchor->{y} - $height : $anchor->{y};
	return {
		x       => max( 0, min( $x, $screen_width - $width ) ),
		y       => max( 0, min( $y, $screen_height - $height ) ),
		flipped => $flipped,
		rows    => $rows,
	};
}

# A popup opens to the side it prefers when it fits there or the other
# side has no more room; at its anchor it may take the whole height.
sub _side ( $prefer, $anchor, $height, $screen_height ) {
	return ( 'at', 0, $screen_height ) if $prefer eq 'at';
	my ( $room, $other_room ) = $SIDES{$prefer}->( $anchor, $screen_height );
	return ( $prefer,              0, $room ) if $height <= $room || $other_room <= $room;
	return ( $OTHER_SIDE{$prefer}, 1, $other_room );
}

sub _box ($anchor) {
	my $is_box = ref $anchor eq 'HASH' && !grep { !looks_like_number( $anchor->{$_} // '' ) } qw(x y width height);
	die "Term::Fabulous::Placement: place_popup anchor must be a hash reference with the numbers x, y, width and height, got " . describe($anchor) unless $is_box;
	return $anchor;
}

sub _pair ( $name, $pair ) {
	my $is_pair = ref $pair eq 'ARRAY' && @$pair == 2 && !grep { !looks_like_number( $_ // '' ) || $_ < 0 } @$pair;
	die "Term::Fabulous::Placement: place_popup $name must be an array reference of two numbers of at least 0, got " . describe($pair) unless $is_pair;
	return @$pair;
}

1;

__END__

=head1 NAME

Term::Fabulous::Placement - Where a popup goes on the screen

=head1 SYNOPSIS

	use Term::Fabulous::Placement qw(place_popup TOPMOST_Z_INDEX);

	# A list of 6 rows under a field at row 15 of a 40 x 20 screen:
	my $place = place_popup(
		anchor => { x => 30, y => 15, width => 10, height => 1 },
		size   => [ 20, 6 ],
		screen => [ 40, 20 ],
		prefer => 'below',
	);
	# { x => 20, y => 9, flipped => 1, rows => 15 }: above the field
	# (too little room below), moved left to stay on the screen

=head1 DESCRIPTION

The popups of Term::Fabulous (the list of a
L<Term::Fabulous::Widget::Dropdown>, a L<Term::Fabulous::Widget::Menu>
opened under a widget or at a point, the column chooser of a
L<Term::Fabulous::Widget::Table>) float over everything, attached to
the root at the position this module works out from the box of their
anchor, their own size and the size of the screen. One rule places
them all and keeps them on the screen. A custom popup can use it the
same way: compose L<Term::Fabulous::Role::Popup>, return the position
from its C<popup_position> and float at L</TOPMOST_Z_INDEX>.

=head1 FUNCTIONS

Nothing is exported by default.

=head2 place_popup

	my $place = place_popup( anchor => $box, size => [ $width, $height ], screen => [ $columns, $rows ], prefer => 'below', align => 'left' );

Returns a hash reference: the C<x> and C<y> of the popup's top left
corner, whether it C<flipped> to the other side of its anchor (1 or 0),
and the C<rows> the screen has on the side it opened to. The options:

=over

=item C<anchor>

Required. The box the popup belongs to, a hash reference with C<x>,
C<y>, C<width> and C<height> (as L<Clay::UI/bounding_box> returns
them). For a popup at a point, a box of width and height 0 there.

=item C<size>

Required. C<[ width, height ]> of the popup, border included.

=item C<screen>

Required. C<[ columns, rows ]> of the screen.

=item C<prefer>

Where the popup goes: C<below> the anchor (the default), C<above> it,
or C<at> it (its top at the anchor's top, over the anchor). A popup
below or above its anchor goes to the other side when it does not fit
on its own side and the other side has more room; C<rows> is the room
of the side it opened to, so a popup that can shrink (the dropdown's
list) takes no more rows than that. A popup at its anchor never flips;
its C<rows> is the height of the screen.

=item C<align>

C<left> (the default): the popup's left edge at the anchor's left
edge. C<right>: its right edge at the anchor's right edge.

=back

Finally the popup is moved left and up as far as it takes to end on
the screen, and right and down to start on it: a popup wider or taller
than the screen starts at its left or top edge.

Dies with a message that starts with C<Term::Fabulous::Placement:
place_popup> for an unknown option, an anchor that is not such a box,
a size or screen that is not two numbers of at least 0, or a C<prefer>
or C<align> not listed above.

=head2 TOPMOST_Z_INDEX

The highest C<z_index> Clay has, 32767. A popup belongs to the focused
widget, so it floats over every other floating widget, a dialog
included.

=head1 SEE ALSO

L<Term::Fabulous::Role::Popup>, L<Term::Fabulous::Widget::Menu>, L<Term::Fabulous::Widget::Dropdown>,
L<Term::Fabulous::Widget::Table/open_column_chooser>,
L<Term::Fabulous::Manual::Layout>.

=cut
