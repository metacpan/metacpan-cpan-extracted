package Term::Fabulous::Widget::VirtualList;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

use Clay::UI::Role::Core::Preparable;
use Term::Fabulous::Widget::ScrollBox;

our $VERSION = '0.02';

class Term::Fabulous::Widget::VirtualList
	:isa(Term::Fabulous::Widget::ScrollBox)
	:does(Clay::UI::Role::Core::Preparable)
	:strict(params)
{
	use Clay::UI::Enum::Result;
	use Clay::XS qw(sizing_fit sizing_fixed sizing_grow CLAY_TOP_TO_BOTTOM CLAY_ALIGN_X_LEFT);
	use List::Util qw(max min);
	use Scalar::Util qw(blessed refaddr weaken);
	use Term::Fabulous::Check qw(describe non_negative_integer optional);
	use Term::Fabulous::Widget::Box;

	field $count    :param = 0;
	field $build    :param;
	field $estimate :param = 1;
	field $overscan :param = undef;

	# The column holds the window: a spacer as tall as the items above it,
	# the attached items, a spacer as tall as the items below it.
	field $_column;
	field %_spacer;    # above => Box, below => Box
	field %_spacer_rows;    # the rows each spacer was last sized to

	# Per item: the built widget, the slot that is attached to the column
	# for it (the widget itself, or a box around a text widget), the rows
	# measured in a frame and the rows the estimate gave, both for a width
	# of $_columns. The offsets are the row each item starts at, with the
	# total after the last; they are dropped whenever a height changes.
	field @_built;
	field @_slot;
	field %_index_by_widget;    # refaddr => item index, for every built widget
	field @_measured;
	field @_estimated;
	field $_columns = 0;
	field $_gap     = 0;
	field $_offsets;

	# The attached items, first to last (undef when none), and whether the
	# next preparation must choose them again whatever the viewport shows.
	field $_first;
	field $_last;
	field $_window_stale = 1;

	# The item scroll_to_item wants at the top, until a frame shows it
	# measured; the anchor rebuild took before it forgot the heights; and
	# whether an after_draw callback is queued.
	field $_target;
	field $_kept_anchor;
	field $_watching = 0;

	ADJUST {
		$count    = non_negative_integer( $self, count => $count );
		$build    = _checked_builder( $self, $build );
		$estimate = _checked_estimate( $self, $estimate );
		$overscan = non_negative_integer( $self, overscan => $overscan ) if defined $overscan;

		$_column = Term::Fabulous::Widget::Box->new( layout => $self->_column_layout );
		%_spacer = map { $_ => Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_fixed(0), height => sizing_fixed(0) } } ) } qw(above below);
		$self->add_internal_children($_column);

		weaken( my $weak = $self );
		$self->on( OnScroll => sub { $weak->request_prepare if defined $weak; return Clay::UI::Enum::Result->CONTINUE } );    # the event bubbles on
		$self->request_prepare;
	}

	sub _checked_builder ( $owner, $code ) {
		die ref($owner) . ': build must be a code reference that returns the widget of an item, got ' . describe($code) unless ref $code eq 'CODE';
		return $code;
	}

	# The estimate is kept as a function of the item and the width; a
	# number of rows becomes one.
	sub _checked_estimate ( $owner, $value ) {
		return $value if ref $value eq 'CODE';
		die ref($owner) . ': estimate must be a code reference or a non-negative integer number of rows, got ' . describe($value)
			unless defined $value && !ref $value && $value =~ /\A[0-9]+\z/;
		my $rows = $value + 0;
		return sub { $rows };
	}

	# ---------------------------------------------------------------------
	# Parameters
	# ---------------------------------------------------------------------

	method count (@new) {
		return $count unless @new;
		my $new_count = non_negative_integer( $self, count => $new[0] );
		$self->_drop_items_from($new_count);
		$count = $new_count;
		$self->_forget_offsets;
		$_window_stale = 1;
		$self->request_prepare;
		return $count;
	}

	method build (@new) {
		return $build unless @new;
		$build = _checked_builder( $self, $new[0] );
		$self->rebuild;
		return $build;
	}

	method estimate (@new) {
		return $estimate unless @new;
		$estimate   = _checked_estimate( $self, $new[0] );
		@_estimated = ();
		$self->_forget_offsets;
		$self->request_prepare;
		return $estimate;
	}

	method overscan (@new) {
		return $overscan unless @new;
		$overscan      = optional( \&non_negative_integer, $self, overscan => $new[0] );
		$_window_stale = 1;
		$self->request_prepare;
		return $overscan;
	}

	# Forgets every built widget and every height: the next frame builds
	# the window again from build and estimate, with the item at the top
	# of the viewport where it is now.
	method rebuild () {
		$_kept_anchor = $self->_current_anchor;
		$self->_drop_items_from(0);
		@_measured  = ();
		@_estimated = ();
		$self->_forget_offsets;
		$_window_stale = 1;
		$self->request_prepare;
		return $self;
	}

	# The anchor for what the last frame shows, undef without a frame.
	method _current_anchor () {
		my $ui       = $self->ui             // return undef;
		my $geometry = $self->_geometry($ui) // return undef;
		return $count ? $self->_anchor( $geometry->{top} ) : undef;
	}

	method item ($index) {
		return $self->_item( $self->_checked_index( item => $index ) );
	}

	method scroll_to_item ($index) {
		$_target = $self->_checked_index( scroll_to_item => $index );
		$self->request_prepare;
		return $self;
	}

	method window () {
		return defined $_first ? { first => $_first, last => $_last } : undef;
	}

	method visible_items () {
		my $ui       = $self->ui             // return undef;
		my $geometry = $self->_geometry($ui) // return undef;
		return undef unless $count;
		return { first => $self->_item_at( $geometry->{top} ), last => $self->_item_at( _last_row( $geometry->{top}, $geometry->{viewport} ) ) };
	}

	method _checked_index ( $method, $index ) {
		die ref($self) . ": $method needs an item index, got " . describe($index) unless defined $index && !ref $index && $index =~ /\A[0-9]+\z/;
		die ref($self) . ": $method: item $index does not exist, the list has $count items" unless $index < $count;
		return $index + 0;
	}

	# ---------------------------------------------------------------------
	# Children: the list builds its own
	# ---------------------------------------------------------------------

	method add_child            :override (@kids)            { die $self->_unsupported('add_child') }
	method insert_children      :override ( $offset, @kids ) { die $self->_unsupported('insert_children') }
	method clear_children       :override ()                 { die $self->_unsupported('clear_children') }
	method remove_child         :override (@kids)            { die $self->_unsupported('remove_child') }
	method remove_child_with_id :override ($target_id)       { die $self->_unsupported('remove_child_with_id') }
	method remove_children_with :override ($predicate)       { die $self->_unsupported('remove_children_with') }

	method _unsupported ($method) {
		return ref($self) . ": $method is not supported; a VirtualList builds its children from build, set count and build instead";
	}

	# A list whose place in a tree changed is prepared for its new place.
	method tree_changed :override () {
		$self->SUPER::tree_changed;
		$self->request_prepare;
		return;
	}

	# ---------------------------------------------------------------------
	# Items and their heights
	# ---------------------------------------------------------------------

	method _item ($index) {
		return $_built[$index] //= $self->_build_item($index);
	}

	method _build_item ($index) {
		my $widget = $build->($index);
		die ref($self) . ": build must return a widget for item $index, got " . describe($widget)
			unless blessed $widget && ( $widget->DOES('Clay::UI::Role::Core::Element') || $widget->DOES('Clay::UI::Role::Core::TextNode') );
		die ref($self) . ": build returned a widget that already has a parent for item $index" if defined $widget->parent;
		my $other = $_index_by_widget{ refaddr $widget };
		die ref($self) . ": build returned the widget of item $other again for item $index" if defined $other;
		$_index_by_widget{ refaddr $widget } = $index;
		return $widget;
	}

	# A text widget has no Clay element of its own, so it has no bounding
	# box to measure: it is laid out inside a box. Any other widget is
	# attached as it is.
	method _slot ($index) {
		return $_slot[$index] //= _new_slot( $self->_item($index) );
	}

	sub _new_slot ($item) {
		return $item unless $item->DOES('Clay::UI::Role::Core::TextNode');
		my $slot = Term::Fabulous::Widget::Box->new;
		$slot->add_child($item);
		return $slot;
	}

	# Forgets the widgets and the heights of the items from $from on: when
	# the list grows again, the items at these indices are new ones. Those
	# still attached leave the column at the next preparation.
	method _drop_items_from ($from) {
		delete @_index_by_widget{ map { refaddr $_ } grep { defined } @_built[ $from .. $#_built ] };
		$#_built     = $from - 1;
		$#_slot      = $from - 1;
		$#_measured  = $from - 1 if $#_measured >= $from;
		$#_estimated = $from - 1 if $#_estimated >= $from;
		( $_first, $_last ) = ( undef, undef ) if defined $_first && $_first >= $from;
		$_last   = min( $_last, $from - 1 ) if defined $_last;
		$_target = undef if defined $_target && $_target >= $from;
		return;
	}

	method _rows_of ($index) {
		return $_measured[$index] // ( $_estimated[$index] //= $self->_estimated_rows($index) );
	}

	method _estimated_rows ($index) {
		my $rows = $estimate->( $index, $_columns );
		die ref($self) . ": estimate must return a non-negative integer number of rows for item $index, got " . describe($rows)
			unless defined $rows && !ref $rows && $rows =~ /\A[0-9]+\z/;
		return $rows + 0;
	}

	# Every height is for one width: a new width starts over.
	method _forget_heights ($columns) {
		$_columns   = $columns;
		@_measured  = ();
		@_estimated = ();
		$self->_forget_offsets;
		return;
	}

	method _forget_offsets () {
		$_offsets = undef;
		return;
	}

	# [ the first row of each item, the total height ]: items follow each
	# other with the gap between them.
	method _offsets () {
		return $_offsets if defined $_offsets;
		my ( $row, @offsets ) = (0);
		foreach my $index ( 0 .. $count - 1 ) {
			push @offsets, $row;
			$row += $self->_rows_of($index) + $_gap;
		}
		push @offsets, $count ? $row - $_gap : 0;
		return $_offsets = \@offsets;
	}

	# The item a row belongs to: the last one starting at or before it.
	method _item_at ($row) {
		my $offsets = $self->_offsets;
		my ( $low, $high ) = ( 0, $count - 1 );
		while ( $low < $high ) {
			my $middle = int( ( $low + $high + 1 ) / 2 );
			if   ( $offsets->[$middle] <= $row ) { $low  = $middle }
			else                                 { $high = $middle - 1 }
		}
		return $low;
	}

	# ---------------------------------------------------------------------
	# Preparing a frame
	# ---------------------------------------------------------------------

	# Where the last frame put the list: the width the items wrap to, the
	# rows of the viewport and the first row it shows; undef before the
	# first frame, or while the list is not laid out.
	method _geometry ($ui) {
		my $state  = $ui->scroll_state($self)    // return undef;
		my $column = $ui->bounding_box($_column) // return undef;
		return {
			columns  => int( $column->{width} + 0.5 ),
			viewport => int( $state->{viewport}{height} + 0.5 ),
			top      => int( -$state->{position}{y} + 0.5 ),
		};
	}

	# The last row a viewport of $viewport rows shows from $top on.
	sub _last_row ( $top, $viewport ) {
		return $top + max( $viewport, 1 ) - 1;
	}

	# Brings the column up to date with the frame about to be laid out:
	# learns the heights the last frame gave the attached items, keeps the
	# item at the top of the viewport where it was (or shows the target
	# item), then attaches the items the viewport and the overscan need.
	method prepare_layout () {
		my $ui = $self->ui // return;
		$self->_prepare_column;

		my $geometry = $self->_geometry($ui);
		my ( $top, $viewport ) = ( 0, $ui->height );
		if ( defined $geometry ) {
			my $anchor = $_kept_anchor // ( $count ? $self->_anchor( $geometry->{top} ) : undef );
			$_kept_anchor = undef;
			$self->_harvest( $ui, $geometry );
			( $top, $viewport ) = ( $self->_place( $ui, $geometry, $anchor ), $geometry->{viewport} );
		}
		elsif ( $_columns != $ui->width ) {
			$self->_forget_heights( $ui->width );
		}

		$self->_choose_window( $top, $viewport );
		$self->_arrange;
		$self->_watch($ui);
		return;
	}

	# The items take the list's gap and horizontal alignment.
	method _column_layout () {
		my $layout = $self->layout;
		return {
			layout_direction => CLAY_TOP_TO_BOTTOM,
			sizing           => { width => sizing_grow(), height => sizing_fit() },
			child_gap        => $layout->{child_gap} // 0,
			child_alignment  => { x => $layout->{child_alignment}{x} // CLAY_ALIGN_X_LEFT },
		};
	}

	method _prepare_column () {
		my $layout = $self->_column_layout;
		my $before = $_column->layout;
		$_column->layout($layout) if $layout->{child_gap} != $before->{child_gap} || $layout->{child_alignment}{x} != $before->{child_alignment}{x};
		return if $_gap == $layout->{child_gap};
		$_gap = $layout->{child_gap};
		$self->_forget_offsets;
		return;
	}

	# What the user is looking at, as an item and a row offset from its
	# start, so that it can be found again once heights have changed. A
	# measured item makes a firm anchor: the nearest one at or below the
	# top of the viewport (the rows between them are about to be measured,
	# so the offset, negative, comes out exact), else the nearest one above
	# (nothing between them changes, so the position holds). With no
	# measured item near, the item at the top as the model places it.
	method _anchor ($top) {
		my $index    = $self->_item_at($top);
		my $measured = $self->_measured_from( $index, 1 ) // $self->_measured_from( $index - 1, -1 );
		my $anchor   = $measured                          // $index;
		return { index => $anchor, within => $top - $self->_offsets->[$anchor], firm => defined $measured ? 1 : 0 };
	}

	# The first measured item from $index on, walking in $direction.
	method _measured_from ( $index, $direction ) {
		for ( my $candidate = $index; $candidate >= 0 && $candidate < $count; $candidate += $direction ) {
			return $candidate if defined $_measured[$candidate];
		}
		return undef;
	}

	# The row that puts the anchor back where it was. An offset into the
	# item at the top (the anchor the model gave) stays inside the item
	# when the item turns out shorter; a firm anchor's offset spans the
	# items between and is kept as it is.
	method _row_of_anchor ($anchor) {
		my $index  = min( $anchor->{index}, $count - 1 );
		my $within = $anchor->{within};
		$within = min( $within, max( 0, $self->_rows_of($index) - 1 ) ) unless $anchor->{firm};
		return max( 0, $self->_offsets->[$index] + $within );
	}

	# The heights the last frame gave the attached items, for its width.
	method _harvest ( $ui, $geometry ) {
		$self->_forget_heights( $geometry->{columns} ) if $geometry->{columns} != $_columns;
		return unless defined $_first;
		foreach my $index ( $_first .. $_last ) {
			my $rows = $self->_frame_rows( $ui, $index ) // next;
			next if defined $_measured[$index] && $_measured[$index] == $rows;
			$_measured[$index] = $rows;
			$self->_forget_offsets;
		}
		return;
	}

	# The rows an attached item took in the last frame, undef when the
	# frame did not lay it out.
	method _frame_rows ( $ui, $index ) {
		my $box = $ui->bounding_box( $_slot[$index] ) // return undef;
		return int( $box->{height} + 0.5 );
	}

	# The first row this frame shows: the target item's, else the anchor's
	# with the heights learnt. Moves the scroll position when that differs
	# from where the last frame was, and returns the row it got.
	method _place ( $ui, $geometry, $anchor ) {
		my $wanted = $geometry->{top};
		if ( defined $_target ) {
			$wanted  = $self->_offsets->[$_target];
			$_target = undef if defined $_measured[$_target];
		}
		elsif ( defined $anchor ) {
			$wanted = $self->_row_of_anchor($anchor);
		}
		return $wanted if $wanted == $geometry->{top};
		my $position = $ui->scroll_to( $self, { y => -$wanted } ) // return $geometry->{top};
		return int( -$position->{y} + 0.5 );
	}

	# Keeps the window while it covers the viewport; otherwise chooses the
	# items of the viewport and an overscan of rows on either side.
	method _choose_window ( $top, $viewport ) {
		unless ($count) {
			( $_first, $_last ) = ( undef, undef );
			return;
		}
		my $last_row = _last_row( $top, $viewport );
		return if !$_window_stale && $self->_covers( $top, $last_row );
		my $margin = $overscan // $viewport;
		( $_first, $_last ) = ( $self->_item_at( max( 0, $top - $margin ) ), $self->_item_at( $last_row + $margin ) );
		$_window_stale = 0;
		return;
	}

	method _covers ( $top, $last_row ) {
		return defined $_first && $_first <= $self->_item_at($top) && $_last >= $self->_item_at($last_row) ? 1 : 0;
	}

	# Makes the column's children the spacers and the window: what leaves
	# is detached, what enters is inserted where it belongs, what stays is
	# not touched (so it keeps focus and hover).
	method _arrange () {
		my @wanted;
		if ( defined $_first ) {
			push @wanted, $_spacer{above} if $_first > 0;
			push @wanted, map { $self->_slot($_) } $_first .. $_last;
			push @wanted, $_spacer{below} if $_last < $count - 1;
		}
		$self->_size_spacers;

		my %stays = map { refaddr($_) => 1 } @wanted;
		$_column->remove_children_with( sub { !$stays{ refaddr $_ } } );

		my @runs;    # [ $offset, @children ]: the entering children, run by run
		foreach my $index ( 0 .. $#wanted ) {
			my $child = $wanted[$index];
			next if $self->_holds($child);
			push @runs,          [$index] unless @runs && $runs[-1][0] + $#{ $runs[-1] } == $index;
			push @{ $runs[-1] }, $child;
		}
		foreach my $run (@runs) {
			my ( $offset, @children ) = @$run;
			$_column->insert_children( $offset, @children );
		}
		return;
	}

	method _holds ($child) {
		my $parent = $child->parent;
		return defined $parent && refaddr($parent) == refaddr($_column) ? 1 : 0;
	}

	# A spacer stands in for the items on its side of the window; the gap
	# between it and the window is Clay's.
	method _size_spacers () {
		return unless defined $_first;
		my $offsets = $self->_offsets;
		$self->_size_spacer( above => $offsets->[$_first] - $_gap ) if $_first > 0;
		$self->_size_spacer( below => $offsets->[$count] - ( $offsets->[$_last] + $self->_rows_of($_last) ) - $_gap ) if $_last < $count - 1;
		return;
	}

	method _size_spacer ( $side, $rows ) {
		return if defined $_spacer_rows{$side} && $_spacer_rows{$side} == $rows;
		$_spacer_rows{$side} = $rows;
		$_spacer{$side}->layout( { sizing => { width => sizing_fixed(0), height => sizing_fixed($rows) } } );
		return;
	}

	# ---------------------------------------------------------------------
	# After a frame
	# ---------------------------------------------------------------------

	# After every frame the list checks whether the frame showed something
	# it was not prepared for: a new width, items still unmeasured, or a
	# position the window does not cover (reached by scroll_to or by Clay's
	# own clamping). The callback stays queued while the list is in a UI.
	method _watch ($ui) {
		return if $_watching || !$ui->can('after_draw');
		weaken( my $weak = $self );
		$ui->after_draw( sub { $weak->_frame_drawn if defined $weak; return } );
		$_watching = 1;
		return;
	}

	method _frame_drawn () {
		$_watching = 0;
		my $ui = $self->ui // return;
		$self->request_prepare if $self->_needs_prepare($ui);
		$self->_watch($ui);
		return;
	}

	method _needs_prepare ($ui) {
		my $geometry = $self->_geometry($ui) // return 0;
		return 1 if $geometry->{columns} != $_columns;
		return 1 if defined $_first && grep { $self->_frame_differs( $ui, $_ ) } $_first .. $_last;
		return 0 unless $count;
		return $self->_covers( $geometry->{top}, _last_row( $geometry->{top}, $geometry->{viewport} ) ) ? 0 : 1;
	}

	# Whether the last frame gave an attached item a height the list does
	# not know yet.
	method _frame_differs ( $ui, $index ) {
		my $rows = $self->_frame_rows( $ui, $index ) // return 0;
		return !defined $_measured[$index] || $_measured[$index] != $rows ? 1 : 0;
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Widget::VirtualList - A ScrollBox that attaches only the items near the viewport

=head1 SYNOPSIS

	use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);
	use Term::Fabulous::Widget::VirtualList;
	use Term::Fabulous::Widget::RichText;

	my @paragraphs = ...;    # tens of thousands of markup strings

	my $document = Term::Fabulous::Widget::VirtualList->new(
		id       => 'document',                                   # required
		count    => scalar @paragraphs,
		build    => sub ($index) {
			return Term::Fabulous::Widget::RichText->new( markup => $paragraphs[$index] );
		},
		estimate => sub ( $index, $columns ) {                    # rows, before the item was laid out
			return 1 + int( length( $paragraphs[$index] ) / $columns );
		},
		layout   => { sizing => { width => sizing_grow(), height => sizing_grow() }, child_gap => 1 },
	);

	$document->scroll_to_item(5000);    # show paragraph 5001 at the top

=head1 DESCRIPTION

A VirtualList is a L<Term::Fabulous::Widget::ScrollBox> for a long
list of items, such as the paragraphs of a document or the rows of a
large log: thousands of items, far more than fit on the screen. It
keeps the items as data and builds a widget only for the items near the
viewport, so a frame costs what the visible part costs, however long
the list is.

Why not a ScrollBox with every item as a child: Clay only paints what
is visible, but it lays out every attached widget in every frame, and
it measures every text it lays out word by word with a cache of a fixed
size (see L<Term::Fabulous/LIMITATIONS>). A ScrollBox with a few
thousand paragraphs is slow to scroll, and one with more words than the
cache holds dies.

The list calls C<build> for an item when the item comes near the
viewport and keeps the widget it returns, so an item is built once. The
widgets of the items above and below the attached ones are replaced by
two invisible spacers as tall as those items would be, so the scrollbar,
the mouse wheel and
L<scroll_state and scroll_to|Term::Fabulous/"bounding_box, scroll_state, scroll_to">
see the whole list.

How tall an item is becomes known when it was laid out once at the
current width; until then the list uses C<estimate>. The sum of the
heights decides where every item starts, so a wrong estimate moves the
items below it when the real height arrives. The list corrects for
that: the item at the top of the viewport stays where it is while the
heights above it change, and when the terminal gets wider or narrower.
A good estimate keeps the scrollbar's thumb steady; an exact one (the
line count of a text that does not wrap, say) makes jumps impossible.

Scrolling and the scrollbar work as on a ScrollBox. Keys do not scroll
the list; L</scroll_to_item> and
L<scroll_to|Term::Fabulous/"bounding_box, scroll_state, scroll_to">
move it from code. A VirtualList needs an C<id>, like every ScrollBox.

=head1 CONSTRUCTOR

=head2 new

	my $list = Term::Fabulous::Widget::VirtualList->new( id => 'log', build => sub ($index) { ... }, %parameters );

Unknown parameters die. A VirtualList takes every parameter of
L<Term::Fabulous::Widget::ScrollBox> (an C<id> is required there) plus:

=over

=item C<build>

B<Required>. A code reference called as C<< $build->($index) >> with
the index of an item, from 0 to C<count - 1>, when the item comes near
the viewport. It returns the item's widget: any widget without a
parent, a L<Term::Fabulous::Widget::Text>, a
L<Term::Fabulous::Widget::RichText>, a L<Term::Fabulous::Widget::Box>
with children, anything. The list keeps the widget and never calls
C<build> for that index again until L</rebuild>. A return value that
is not a widget, a widget that has a parent, or the widget of another
item dies when the item is built.

=item C<count>

A non-negative integer, default 0. How many items the list has.

=item C<estimate>

A code reference, or a non-negative integer. Default: 1. How many rows
an item takes before it was laid out: a number of rows for every item,
or a code reference called as C<< $estimate->($index, $columns) >> with
the index of the item and the columns the items wrap to, which returns
a non-negative integer. It is called once per item and width. Anything
else dies.

=item C<overscan>

A non-negative integer or C<undef>. Default: C<undef>. How many rows
beyond the viewport, above and below, the list keeps attached. The
viewport scrolls through the attached items without a change to the
widget tree; when it leaves them, the list attaches the items of the
viewport and the overscan again. C<undef> means the height of the
viewport. More overscan costs more layout work per frame and changes
the tree less often.

=back

The layout of the list applies to the items as on a Box: C<child_gap>
is the gap between items, C<child_alignment>'s C<x> aligns them. The
items take the list's width (minus border, padding and scrollbar), so a
text among them wraps to it. Give the list a C<grow>, C<fixed> or
C<percent> height, like a ScrollBox.

=head1 METHODS

A VirtualList has all methods of L<Term::Fabulous::Widget::ScrollBox>
and L<Term::Fabulous::Widget> except the ones that add or remove
children (L</children> below), plus:

=head2 count

	$list->count(12_000);

Accessor. Without an argument it returns the number of items; with one
it sets it and returns the new value (an invalid value dies). The
widgets and heights of items that still exist are kept, so a log that
grows only builds its new lines. The change shows in the next frame.

=head2 build, estimate

	$list->build( sub ($index) { ... } );
	$list->estimate( sub ( $index, $columns ) { ... } );

Accessors for the callbacks (C<estimate> returns a code reference even
when it was given as a number). Setting C<build> forgets every built
widget and every height, like L</rebuild>; setting C<estimate> forgets
the estimated heights. The change shows in the next frame.

=head2 overscan

	$list->overscan(50);

Accessor for the overscan rows, used like L</count>; C<undef> means the
height of the viewport.

=head2 rebuild

	$list->rebuild;

Forgets every built widget and every height, so the next frame calls
C<build> and C<estimate> again for the items near the viewport. Call it
when the data behind the items changed. The scroll position stays, and
the item at the top of the viewport stays there. Returns the list.

=head2 item

	my $widget = $list->item(42);

The widget of an item, built now if the list has not built it yet. Dies
for an index the list does not have. The widget is attached while the
item is near the viewport and detached otherwise; it is the same object
each time. A text widget (a L<Term::Fabulous::Widget::Text> or
L<Term::Fabulous::Widget::RichText>) is laid out inside a
L<Term::Fabulous::Widget::Box> of its own, because a text has no box
the list could measure; its C<parent> is that box.

=head2 scroll_to_item

	$list->scroll_to_item(5000);

Scrolls so that the item starts at the top of the viewport (or as near
as the end of the list allows) in the next frame. Dies for an index the
list does not have. Returns the list.

=head2 window

	my $window = $list->window;    # { first => 118, last => 171 }, or undef

The indexes of the first and last item attached at the moment, or
C<undef> while none is (before the first frame, or with no items).

=head2 visible_items

	my $visible = $list->visible_items;    # { first => 140, last => 152 }, or undef

The indexes of the first and last item inside the viewport in the last
frame, as the list knows their heights, or C<undef> while the list was
not laid out or has no items.

=head2 children

	$list->children;    # always empty

A VirtualList has no children of its own: C<add_child>,
C<insert_children>, C<clear_children>, C<remove_child>,
C<remove_child_with_id> and C<remove_children_with> die. The items are
the children of an internal column; reach one with L</item>.

=head1 EVENTS

Those of L<Term::Fabulous::Widget::ScrollBox/EVENTS>: C<OnScroll> in
every frame in which the mouse wheel or the scrollbar moved the list,
and C<Mouse> for wheel notches and clicks.

A widget inside an item receives events like any widget while the item
is attached. When its item is detached it loses the focus and the hover,
like any removed widget.

=head1 KDL PROPERTIES

None: a VirtualList cannot be built from a layout file, because
C<build> is code. Build it in your program and add it to a Box the
layout file defines.

=head1 CAVEATS

An item's height comes from its first layout; until then the estimate
stands in. Dragging the scrollbar far jumps into unmeasured items, so
the items may shift once when their real heights arrive. The item at
the top of the viewport is kept in place through such shifts, and
L</scroll_to_item> repeats its scroll until its item has been measured.

The list learns a frame's heights when the next frame is prepared, so a
change of the terminal size shows its effect on the window in the frame
after the one that shows the new size.

An item widget that changes its height on its own (a text whose
C<text> is set) is measured again in the frame after the change shows,
while it is attached; the list does not know about changes to detached
items until they are attached again.

=head1 SEE ALSO

L<Term::Fabulous::Widget::ScrollBox>, L<Term::Fabulous/LIMITATIONS>,
L<Term::Fabulous::Manual::Layout/Scrolling content>, the example
program F<examples/widgets/virtual-list.pl>.

=cut
