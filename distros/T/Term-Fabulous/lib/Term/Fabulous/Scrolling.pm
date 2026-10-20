package Term::Fabulous::Scrolling;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.05';

use Exporter 'import';
our @EXPORT_OK = qw(
	inner_rows page_rows reveal_rows scroll_by_rows scroll_by_columns scroll_by_pages scroll_by_key
	scroll_to_end scroll_to_start scroll_offset max_scroll_offset scrolled_percent
);

use List::Util qw(max min);
use Scalar::Util qw(blessed);
use Term::Fabulous::Check qw(describe one_of);
use Term::Fabulous::Viewport qw(clamp_offset max_offset reveal_range);

sub _checked ( $function, $ui, $widget ) {
	die "Term::Fabulous::Scrolling: $function needs a UI, got " . describe($ui) unless blessed $ui && $ui->can('scroll_state');
	die "Term::Fabulous::Scrolling: $function needs a widget, got " . describe($widget) unless blessed $widget;
	return;
}

sub _checked_count ( $function, $name, $value ) {
	die "Term::Fabulous::Scrolling: $function needs a number of $name, got " . describe($value) unless defined $value && !ref $value && $value =~ /\A-?[0-9]+\z/;
	return $value;
}

# Clay reports the viewport as the whole box of the container; the
# content shows inside the padding the frame declared, which holds the
# border and the scrollbars too (see Term::Fabulous::Role::HasBorderStyle).
sub inner_rows ( $ui, $widget ) {
	_checked( inner_rows => $ui, $widget );
	my $content = $ui->content_box($widget) // return ();
	return ( $content->{y}, $content->{y} + $content->{height} );
}

# A page is the rows the content shows less one, so that the last row
# stays in view as a landmark; at least one row.
sub page_rows ( $ui, $widget ) {
	my ( $top, $bottom ) = inner_rows( $ui, $widget ) or return undef;
	return max( 1, int( $bottom - $top + 0.5 ) - 1 );
}

# Clay keeps the scroll position as a negative offset from the start of
# the content, x for columns, y for rows; this module turns it into a
# positive offset, so a program never has to.
my %AXIS = ( rows => [ y => 'height' ], columns => [ x => 'width' ] );

sub _offset ( $state, $axis = 'rows' ) {
	my ($position) = @{ $AXIS{$axis} };
	return -( $state->{position}{$position} // 0 );
}

sub _max_offset ( $state, $axis = 'rows' ) {
	my ( undef, $size ) = @{ $AXIS{$axis} };
	return max_offset( $state->{content}{$size}, $state->{viewport}{$size} );
}

# Scrolls to an offset, within the ends. Clay keeps the position in
# fractions of a row; a move of less than half a row is none.
sub _scroll_to ( $ui, $widget, $state, $offset, $axis = 'rows' ) {
	my ( $position, $size ) = @{ $AXIS{$axis} };
	my $from = _offset( $state, $axis );
	my $to   = clamp_offset( $state->{content}{$size}, $state->{viewport}{$size}, $offset );
	return 0 if int( $to + 0.5 ) == int( $from + 0.5 );
	$ui->scroll_to( $widget, { $position => -$to } );
	return 1;
}

sub scroll_offset ( $ui, $widget ) {
	_checked( scroll_offset => $ui, $widget );
	my $state = $ui->scroll_state($widget) // return undef;
	return _offset($state);
}

sub max_scroll_offset ( $ui, $widget ) {
	_checked( max_scroll_offset => $ui, $widget );
	my $state = $ui->scroll_state($widget) // return undef;
	return _max_offset($state);
}

sub scroll_by_rows ( $ui, $widget, $rows ) {
	_checked( scroll_by_rows => $ui, $widget );
	_checked_count( scroll_by_rows => rows => $rows );
	my $state = $ui->scroll_state($widget) // return 0;
	return _scroll_to( $ui, $widget, $state, _offset($state) + $rows );
}

sub scroll_by_columns ( $ui, $widget, $columns ) {
	_checked( scroll_by_columns => $ui, $widget );
	_checked_count( scroll_by_columns => columns => $columns );
	my $state = $ui->scroll_state($widget) // return 0;
	return _scroll_to( $ui, $widget, $state, _offset( $state, 'columns' ) + $columns, 'columns' );
}

sub scroll_by_pages ( $ui, $widget, $pages ) {
	_checked( scroll_by_pages => $ui, $widget );
	_checked_count( scroll_by_pages => pages => $pages );
	my $page = page_rows( $ui, $widget ) // return 0;
	return scroll_by_rows( $ui, $widget, $pages * $page );
}

sub scroll_to_start ( $ui, $widget ) {
	_checked( scroll_to_start => $ui, $widget );
	my $state = $ui->scroll_state($widget) // return 0;
	return _scroll_list_to( $ui, $widget, $state, 'start' ) if _is_list($widget);
	return _scroll_to( $ui, $widget, $state, 0 );
}

sub scroll_to_end ( $ui, $widget ) {
	_checked( scroll_to_end => $ui, $widget );
	my $state = $ui->scroll_state($widget) // return 0;
	return _scroll_list_to( $ui, $widget, $state, 'end' ) if _is_list($widget);
	return _scroll_to( $ui, $widget, $state, _max_offset($state) );
}

# A VirtualList builds only the items near its view and knows the height
# of the others as an estimate, so its content height is one too: it is
# sent to its first or last item, which it measures on the way. Once the
# last item is in view, the end of the content is where the frame put
# it, and the list scrolls there like any container: the start of an
# item taller than the view is not its end.
sub _is_list ($widget) {
	return $widget->isa('Term::Fabulous::Widget::VirtualList') ? 1 : 0;
}

sub _scroll_list_to ( $ui, $list, $state, $end ) {
	my $count = $list->count or return 0;
	my ( $index, $offset ) = $end eq 'start' ? ( 0, 0 ) : ( $count - 1, _max_offset($state) );
	my $visible = $list->visible_items;
	my $in_view = defined $visible && ( $end eq 'start' ? $visible->{first} : $visible->{last} ) == $index;
	return _scroll_to( $ui, $list, $state, $offset ) if $in_view;
	$list->scroll_to_item($index);
	return 1;
}

# The keys of a pager, by set: what each one does.
my %KEY_SETS = (
	pager => {
		PageUp      => [ pages => -1 ],
		PageDown    => [ pages =>  1 ],
		'Ctrl+Home' => ['start'],
		'Ctrl+End'  => ['end'],
	},
	less => {
		Down     => [ rows  =>  1 ],
		j        => [ rows  =>  1 ],
		Up       => [ rows  => -1 ],
		k        => [ rows  => -1 ],
		PageDown => [ pages =>  1 ],
		Space    => [ pages =>  1 ],
		PageUp   => [ pages => -1 ],
		b        => [ pages => -1 ],
		Home     => ['start'],
		g        => ['start'],
		End      => ['end'],
		G        => ['end'],
	},
);

my %MOVE = (
	rows  => \&scroll_by_rows,
	pages => \&scroll_by_pages,
	start => \&scroll_to_start,
	end   => \&scroll_to_end,
);

# undef for a key the set does not have; else whether it moved.
sub scroll_by_key ( $ui, $widget, $key_name, %options ) {
	_checked( scroll_by_key => $ui, $widget );
	my @unknown = grep { $_ ne 'keys' } sort keys %options;
	die "Term::Fabulous::Scrolling: scroll_by_key does not take @unknown (known: keys)" if @unknown;
	my $set  = one_of( 'Term::Fabulous::Scrolling: scroll_by_key', keys => $options{keys}, sort keys %KEY_SETS );
	my $move = defined $key_name ? $KEY_SETS{$set}{$key_name} : undef;
	return undef unless defined $move;
	my ( $how, @count ) = @$move;
	return $MOVE{$how}->( $ui, $widget, @count ) ? 1 : 0;
}

# Screen rows from $from to before $to into view: with the smallest move
# (align nearest), or with the first of them at the top (align top).
# Viewport's functions want one coordinate system: the content's rows,
# counted from the first row inside the padding, which shows the inner
# rows from the offset on.
sub reveal_rows ( $ui, $widget, $from, $to, %options ) {
	_checked( reveal_rows => $ui, $widget );
	my @unknown = grep { $_ ne 'align' } sort keys %options;
	die "Term::Fabulous::Scrolling: reveal_rows does not take @unknown (known: align)" if @unknown;
	my $align = one_of( 'Term::Fabulous::Scrolling: reveal_rows', align => $options{align} // 'nearest', qw(nearest top) );
	my $state = $ui->scroll_state($widget) // return 0;
	my ( $top, $bottom ) = inner_rows( $ui, $widget ) or return 0;
	my $offset  = _offset($state);
	my $inner   = $bottom - $top;
	my $content = $state->{content}{height} - ( $state->{viewport}{height} - $inner );
	my ( $first, $end ) = ( $from - $top + $offset, $to - $top + $offset );
	my $target = $align eq 'top' ? clamp_offset( $content, $inner, $first ) : reveal_range( $content, $inner, $offset, $first, $end );
	return _scroll_to( $ui, $widget, $state, $target );
}

# How far down the content is scrolled, from 0 to 100; content that fits
# is seen whole, 100. undef before the container was laid out.
sub scrolled_percent ( $ui, $widget ) {
	_checked( scrolled_percent => $ui, $widget );
	my $state = $ui->scroll_state($widget) // return undef;
	my $last  = _max_offset($state);
	return 100 unless $last > 0;
	return min( 100, max( 0, int( 100 * _offset($state) / $last + 0.5 ) ) );
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Scrolling - Scroll a container by rows, by pages and to its ends, as a pager does

=head1 SYNOPSIS

	use Term::Fabulous::Scrolling qw(scroll_by_key scroll_by_rows scroll_by_pages scroll_offset scroll_to_end scrolled_percent);

	my $box = $ui->find_by_id('log');    # a ScrollBox, a VirtualList, a document view
	scroll_by_rows( $ui, $box, 1 );      # one row down
	scroll_by_pages( $ui, $box, -1 );    # one page up
	scroll_to_end( $ui, $box );
	say scrolled_percent( $ui, $box ), '%';
	say 'scrolled down by ', scroll_offset( $ui, $box ), ' rows';

	scroll_by_rows( $ui, $box, 1 ) or say 'already at the end';

	# PageUp, PageDown, Ctrl+Home and Ctrl+End, in a KeyPress listener:
	my $moved = scroll_by_key( $ui, $box, $event->main_key_name, keys => 'pager' );
	return Clay::UI::Enum::Result->HANDLED if defined $moved;

=head1 DESCRIPTION

A program that lets the user scroll a container with keys, as a pager
does, needs the same few moves for every container: by a row, by a
page, to either end, and far enough to bring a range of rows into view.
This module provides these moves for any scroll container, such as a
L<Term::Fabulous::Widget::ScrollBox>, a
L<Term::Fabulous::Widget::VirtualList> or a
L<Term::Fabulous::Widget::DocumentView>.
L<Term::Fabulous::Cookbook::DocumentTechniques/Scroll any scroll box like a pager (Term::Fabulous::Scrolling)>
is a recipe that scrolls a ScrollBox with pager keys using these
functions.

All scroll containers are scrolled the same way, with the UI's
L<scroll_state and scroll_to|Term::Fabulous/"bounding_box, content_box, scroll_state, scroll_to">
methods, and this module applies the same rules to all of them:

=over

=item *

A I<page> is the number of rows the container shows inside its border,
padding and scrollbars, less one. The row that is kept stays in view
after the move and helps the reader find their place. A page is at
least one row.

Clay reports the whole box of the container as its viewport, border
included. To find the rows that show content, the module therefore
takes the container's C<content_box> (L<Clay::UI/content_box>): its box
in the last frame less the padding that frame declared for it, which is
where Term::Fabulous reserves the room for the border and the
scrollbars.

=item *

Scrolling stops at the ends of the content. Every function that
scrolls returns 1 when it moved the content and 0 when it did not, for
example because the content is already at that end. A key handler can
use the return value to tell whether the key had an effect.

=item *

Offsets are positive: 0 at the start of the content, growing as it is
scrolled down (or right). Clay keeps the scroll position as a negative
number; this module turns it around, so a program never needs to (see
L</scroll_offset>).

=item *

A L<Term::Fabulous::Widget::VirtualList> (a document view too) knows
the height of the items it has not built only as an estimate, so
L</"scroll_to_start, scroll_to_end"> send it to its first or last
item (L<Term::Fabulous::Widget::VirtualList/scroll_to_item>), which it
measures on the way. Once that item is in view, they scroll to the end
of the content like any container, so a last item taller than the view
ends at the bottom of the view instead of starting at its top.

=item *

Clay keeps the scroll position in fractions of a row. A function
compares the target position with the current one, both rounded to the
nearest whole row; when they round to the same row, it does not scroll
and returns 0.

=back

Before the first frame has laid the container out, Clay knows neither
its size nor its scroll position, so there is nothing to scroll. Until
then the functions that scroll return 0 without doing anything,
L</page_rows>, L</scroll_offset>, L</max_scroll_offset> and
L</scrolled_percent> return C<undef>, and L</inner_rows> returns an
empty list.

The calculations come from L<Term::Fabulous::Viewport>. The functions
take the UI and the container as arguments rather than being methods of
a widget, so any container can use them and a test can exercise them
with a small ScrollBox on a memory terminal. The document view uses
them for its line and page keys, to scroll search matches and links
into view, and for the percentage it reports.

=head1 FUNCTIONS

Nothing is exported by default. Every function takes the UI (a
L<Term::Fabulous> object) and the scroll container as its first two
arguments and dies when the UI cannot report scroll states or the
container is not an object. Counts of rows, columns and pages must be
integers; a negative count scrolls up (or left). Anything else dies.

=head2 scroll_by_rows

	my $moved = scroll_by_rows( $ui, $widget, $rows );

Scrolls the content by C<$rows> rows: down for a positive number, up
for a negative one, and no further than either end. Returns 1 when the
content moved and 0 otherwise.

=head2 scroll_by_columns

	my $moved = scroll_by_columns( $ui, $widget, $columns );

Scrolls the content sideways by C<$columns> columns: right for a
positive number, left for a negative one, and no further than either
end. For a container that scrolls sideways (a ScrollBox with
C<< horizontal =E<gt> 1 >>). Returns 1 when the content moved and 0
otherwise.

=head2 scroll_by_pages

	my $moved = scroll_by_pages( $ui, $widget, $pages );

Scrolls the content by C<$pages> pages of L</page_rows> rows each: down
for a positive number, up for a negative one. Returns 1 when the
content moved and 0 otherwise.

=head2 scroll_to_start, scroll_to_end

	my $moved = scroll_to_start( $ui, $widget );
	my $moved = scroll_to_end( $ui, $widget );

Scroll to the top of the content, or so far down that its last row is
at the bottom of the view. Return 1 when the content moved and 0
otherwise. A VirtualList whose first or last item is out of view is
asked to show that item instead, and 1 means it was asked; once the
item is in view, the list scrolls to the end like any container (an
item taller than the view takes a second call, after the frame that
measured it, for example the next C<follow_end> check or the next
press of the key). 0 means the list is at that end or has no items.

=head2 reveal_rows

	my $moved = reveal_rows( $ui, $widget, $from, $to );
	my $moved = reveal_rows( $ui, $widget, $from, $to, align => 'top' );

Scrolls the rows from screen row C<$from> up to, but not including,
screen row C<$to> into the container's inner rows (see L</inner_rows>).
Both rows are screen coordinates, as
L<Term::Fabulous/"bounding_box, content_box, scroll_state, scroll_to"> reports them.
C<align> says how:

=over

=item C<nearest> (the default)

With the smallest possible move. The content does not move when the
rows are already in view. Rows above the view end up at its top, and
rows below it end up at its bottom. When the rows are more than the
view can show, their first row goes to the top (see
L<Term::Fabulous::Viewport/reveal_range>).

=item C<top>

The first row goes to the top of the view, as far as the content
allows: near the end of the content, the content stops at its end.

=back

Another C<align> or another option dies. Returns 1 when the content
moved and 0 otherwise.

=head2 scroll_by_key

	my $moved = scroll_by_key( $ui, $widget, $event->main_key_name, keys => 'pager' );
	my $moved = scroll_by_key( $ui, $widget, $event->main_key_name, keys => 'less' );

Scrolls as a key of a pager does. C<keys> names the set of keys, and is
required:

=for highlighter language=text

	Set      Key                  Move
	-------  -------------------  ----------------------
	pager    PageDown             one page down
	         PageUp               one page up
	         Ctrl+End             to the end
	         Ctrl+Home            to the start
	less     Down, j              one row down
	         Up, k                one row up
	         PageDown, Space      one page down
	         PageUp, b            one page up
	         End, G               to the end
	         Home, g              to the start

=for highlighter language=perl

C<pager> is for a container whose arrow keys belong to the widgets
inside it, C<less> for one that is read like a text, as
L<Term::Fabulous::Widget::DocumentView> is. Pages are those of
L</scroll_by_pages>. The key is a name as
L<Term::Fabulous::Event::KeyPress/main_key_name> returns it.

Returns C<undef> when the key is not in the set (also for C<undef>), so
that the caller can let it go on; for a key of the set, 1 when the
content moved and 0 when it did not (it is already at that end, or not
laid out yet), either way a key the set uses. Another C<keys> or another
option dies.

=head2 scroll_offset

	my $rows = scroll_offset( $ui, $widget );

How far the content is scrolled down, in rows: 0 at the start, up to
L</max_scroll_offset> at the end. Clay keeps fractions of a row, so the
number may have a fraction too. Returns C<undef> before the first frame
has laid the container out.

=head2 max_scroll_offset

	my $rows = max_scroll_offset( $ui, $widget );

The largest L</scroll_offset>, where the last row of the content is at
the bottom of the view: the content height less the viewport's, at
least 0. Returns C<undef> before the first frame has laid the container
out.

=head2 inner_rows

	my ( $top, $bottom ) = inner_rows( $ui, $widget );

Returns the screen row of the first row of the container's content and
the screen row just below its last one, both inside the border, padding
and scrollbars. C<$bottom - $top> is the number of rows that show
content. Returns an empty list before the first frame has laid the
container out.

=head2 page_rows

	my $rows = page_rows( $ui, $widget );

Returns the number of rows in a page: the inner rows less one, at least
1. Returns C<undef> before the first frame has laid the container out.

=head2 scrolled_percent

	my $percent = scrolled_percent( $ui, $widget );

Returns how far the content is scrolled down, as an integer from 0 at
the top to 100 at the end, rounded to the nearest percent. When all of
the content fits into the view, it returns 100, because the reader
sees all of it. Returns C<undef> before the first frame has laid the
container out.

=head1 SEE ALSO

L<Term::Fabulous::Cookbook::DocumentTechniques>, L<Term::Fabulous::Viewport>,
L<Term::Fabulous::Widget::ScrollBox>, L<Term::Fabulous::Widget::VirtualList>,
L<Term::Fabulous::Widget::DocumentView>, L<Term::Fabulous::Manual::Events/SCROLLING>,
L<Term::Fabulous::Cookbook::LiveData/Scroll a ScrollBox from code (keep a log at the newest line)>,
L<Term::Fabulous::Widget::ScrollBox/follow_end>.

=cut
