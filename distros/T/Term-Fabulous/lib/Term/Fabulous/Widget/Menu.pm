package Term::Fabulous::Widget::Menu;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

use Term::Fabulous::Widget::Input;

our $VERSION = '0.02';

class Term::Fabulous::Widget::Menu
	:isa(Term::Fabulous::Widget::Input)
	:strict(params)
{
	use Clay::UI::Enum::Result;
	use Clay::XS qw(CLAY_ATTACH_TO_ROOT);
	use List::Util qw(first max min);
	use Scalar::Util qw(blessed refaddr weaken);
	use Term::Fabulous::Check qw(describe non_negative_integer);
	use Term::Fabulous::Command;
	use Term::Fabulous::Event::Choose;
	use Term::Fabulous::Event::Close;
	use Term::Fabulous::Roving qw(roving_target);
	use Term::Fabulous::Termbox qw(TB_KEY_MOUSE_RELEASE);
	use Term::Fabulous::Unicode qw(string_columns);

	use constant SEPARATOR       => '-';
	use constant SEPARATOR_GLYPH => "\x{2500}";
	use constant CHECK_MARK      => "\x{2713}";
	use constant KEYS_GAP        => 3;    # columns between the longest label and the keys

	# The highest z_index Clay has (int16): an open menu belongs to the
	# focused widget, so it floats over everything, a dialog included.
	use constant Z_INDEX => 32767;

	# PageUp and PageDown go to the ends of a menu, as Home and End do.
	my %MOVE_KEY = ( PageUp => 'Home', PageDown => 'End' );

	field $commands :param = undef;

	field @_items;    # Term::Fabulous::Command objects, undef for a separator
	field $_highlight;    # the index of the highlighted item, or undef
	field $_armed = 0;    # whether a mouse release may choose: a press or a move inside came first
	field $_anchor;    # where the menu floats: { x, y } or { below, column }, or undef
	field $_is_open = 0;    # opened as a popup with open
	field $_focus_before;    # the widget the popup gives the focus back to

	ADJUST :params ( :$items = [] ) {
		die ref($self) . ": commands must be a Term::Fabulous::Commands, got " . describe($commands) if defined $commands && !( blessed $commands && $commands->isa('Term::Fabulous::Commands') );
		@_items     = $self->_parsed_items($items);
		$_highlight = $self->_first_enabled;
		weaken( my $weak_self = $self );
		$self->on(
			MouseMove => sub ($event) {
				$weak_self->_pointer_at($event) if refaddr( $event->target ) == refaddr($weak_self);
				return Clay::UI::Enum::Result->CONTINUE;
			}
		);
	}

	method theme_family :common () {
		return 'menu';
	}

	method themed_params :common () {
		return (
			$class->SUPER::themed_params,
			keys_color                 => [ 'keys',                 'normal', 'cell_color' ],
			separator_color            => [ 'separator',            'normal', 'cell_color' ],
			highlight_text_color       => [ 'highlight.text',       'normal', 'cell_color' ],
			highlight_background_color => [ 'highlight.background', 'normal', 'cell_color' ],
		);
	}

	# ---------------------------------------------------------------------
	# Items
	# ---------------------------------------------------------------------

	method _parsed_items ($items) {
		die ref($self) . ": items must be an array reference, got " . describe($items) unless ref $items eq 'ARRAY';
		return map { $self->_parsed_item($_) } @$items;
	}

	# An item is a separator, a command, the id of a command in the
	# commands table, or the hash reference of a command's parameters
	# (whose id defaults to its label).
	method _parsed_item ($item) {
		return undef if defined $item && !ref $item && $item eq SEPARATOR;
		return $item if blessed $item && $item->isa('Term::Fabulous::Command');
		if ( ref $item eq 'HASH' ) {
			die ref($self) . ": an item needs a label, got a hash reference without one" unless defined $item->{label};
			return Term::Fabulous::Command->new( id => $item->{label}, %$item );
		}
		die ref($self) . ": an item must be a Term::Fabulous::Command, the id of a command, a hash reference or '-', got " . describe($item) if ref $item || !defined $item;
		die ref($self) . ": the item '$item' is the id of a command, but the menu has no commands" unless defined $commands;
		return $commands->command($item);
	}

	method items (@new) {
		return map { $_ // SEPARATOR } @_items unless @new;
		@_items     = $self->_parsed_items( $new[0] );
		$_highlight = $self->_first_enabled;
		$self->mark_changed;
		return $self->items;
	}

	method _enabled_indexes () {
		return grep { defined $_items[$_] && $_items[$_]->is_enabled } 0 .. $#_items;
	}

	method _first_enabled () {
		my ($first) = $self->_enabled_indexes;
		return $first;
	}

	method highlighted () {
		return $_highlight;
	}

	# Highlights an enabled item; undef highlights none.
	method highlight ($index) {
		if ( defined $index ) {
			$index = non_negative_integer( $self, index => $index );
			die ref($self) . ": there is no item $index" if $index > $#_items;
			return $self unless defined $_items[$index] && $_items[$index]->is_enabled;
		}
		$_highlight = $index;
		$self->mark_changed;
		return $self;
	}

	# Chooses an item as the user does: a popup closes first, then Choose
	# fires, then the command runs. A separator or a disabled item does
	# nothing.
	method choose ($index) {
		$index = non_negative_integer( $self, index => $index );
		die ref($self) . ": there is no item $index" if $index > $#_items;
		my $command = $_items[$index];
		return $self unless defined $command && $command->is_enabled;
		$self->close if $_is_open;
		$self->fire_event( Term::Fabulous::Event::Choose->new( command => $command, index => $index ) );
		$self->_tell_owner;
		$command->run;
		return $self;
	}

	# ---------------------------------------------------------------------
	# Opening and closing
	# ---------------------------------------------------------------------

	method is_open () {
		return $_is_open;
	}

	method open ( $ui, %where ) {    ## no critic (InputOutput::RequireBriefOpen) a method named open, not a file
		die ref($self) . ": open needs the Term::Fabulous object, got " . describe($ui) unless blessed $ui && $ui->isa('Clay::UI');
		return $self if $_is_open;
		die ref($self) . ": a menu that is a child of another widget cannot open" if defined $self->parent;
		die ref($self) . ": a disabled menu cannot open" unless $self->is_enabled;
		my $anchor = $self->_parsed_anchor(%where);
		die ref($self) . ": below needs a widget that the last frame drew; a text has no box of its own, so open the menu below the box that holds it"
			if exists $anchor->{below} && !defined $ui->bounding_box( $anchor->{below} );

		my $focused = $ui->interaction->get_focused_widget;
		$_focus_before = $focused;
		weaken $_focus_before if defined $_focus_before;
		$self->_float_at($anchor);
		$_is_open = 1;
		$ui->root->add_child($self);
		$ui->interaction->set_focused_widget($self);
		return $self;
	}

	method _parsed_anchor (%where) {
		if ( exists $where{below} ) {
			my $widget = delete $where{below};
			die ref($self) . ": below must be a widget, got " . describe($widget) unless blessed $widget && $widget->can('parent');
			die ref($self) . ": open takes x and y, or below, got " . join( ', ', sort keys %where ) if %where;
			return { below => $widget, column => 0 };
		}
		my @given = sort keys %where;
		die ref($self) . ": open takes x and y, or below, got " . ( @given ? join( ', ', @given ) : 'neither' ) unless "@given" eq 'x y';
		return { x => non_negative_integer( $self, x => $where{x} ), y => non_negative_integer( $self, y => $where{y} ) };
	}

	# Shows the menu below a widget, starting a number of columns from its
	# left edge, as the list of a menu bar does. The menu does not take
	# the focus: its owner, the widget, hands it the keys and hears of a
	# choice through its menu_chosen method.
	method show_below ( $widget, $column = 0 ) {
		die ref($self) . ": show_below needs a widget, got " . describe($widget) unless blessed $widget && $widget->isa('Term::Fabulous::Widget');
		$self->_float_at( { below => $widget, column => non_negative_integer( $self, column => $column ) } );
		return $self;
	}

	# The owner closes before the command runs, even when a listener of
	# the menu kept Choose from bubbling up to it.
	method _tell_owner () {
		return if $_is_open;
		my $owner = defined $_anchor ? $_anchor->{below} : undef;
		$owner->menu_chosen($self) if defined $owner && $owner->can('menu_chosen');
		return;
	}

	method _float_at ($anchor) {
		$_anchor    = $anchor;
		$_armed     = 0;
		$_highlight = $self->_first_enabled;
		weaken $_anchor->{below} if defined $_anchor->{below};
		$self->floating( { attach_to => CLAY_ATTACH_TO_ROOT, offset => { x => 0, y => 0 }, z_index => Z_INDEX } );
		$self->mark_changed;
		return;
	}

	# Takes a popup off the screen and gives the focus back; Close fires.
	# A close because the focus went elsewhere leaves the focus there.
	method close () {
		return $self unless $_is_open;
		my $ui        = $self->ui;
		my $give_back = defined $ui && $self->is_focused ? $_focus_before : undef;
		$_is_open      = 0;
		$_focus_before = undef;
		my $holder = $self->parent;
		$holder->remove_child($self) if defined $holder;
		$self->floating(undef);
		$_anchor = undef;
		$ui->interaction->set_focused_widget($give_back) if defined $give_back && $ui->interaction->can_take_focus($give_back);
		$self->fire_event( Term::Fabulous::Event::Close->new );
		return $self;
	}

	method focus_changed :override ($is_focused) {
		$self->close if !$is_focused && $_is_open;
		return;
	}

	# A popup keeps Tab and Shift+Tab: they move the highlight.
	method captures_tab () {
		return $_is_open;
	}

	# The size the menu takes on the screen: its content and its border.
	method outer_size () {
		my ( $columns, $rows ) = $self->natural_size;
		my $sides = $self->bordered;
		return ( $columns + $sides->{left} + $sides->{right}, $rows + $sides->{top} + $sides->{bottom} );
	}

	# Where the menu floats in this frame: at its anchor, kept on the
	# screen. Below a widget it opens upwards when there is no room
	# below; at a point it moves up until its last row is on the screen.
	method contribute_floating :override ($config) {
		$self->SUPER::contribute_floating($config);
		return unless defined $_anchor && defined $config->{floating};
		my $ui = $self->ui // return;
		my ( $width, $height ) = $self->outer_size;
		my ( $x, $y );
		if ( exists $_anchor->{below} ) {
			my $box = defined $_anchor->{below} ? $ui->bounding_box( $_anchor->{below} ) : undef;
			$box //= { x => 0, y => 0, width => 0, height => 0 };
			$x = $box->{x} + $_anchor->{column};
			$y = $box->{y} + $box->{height};
			$y = $box->{y} - $height if $y + $height > $ui->height && $box->{y} >= $height;
		}
		else {
			( $x, $y ) = @{$_anchor}{qw(x y)};
		}
		$x                  = max( 0, min( $x, $ui->width - $width ) );
		$y                  = max( 0, min( $y, $ui->height - $height ) );
		$config->{floating} = { %{ $config->{floating} }, offset => { x => $x, y => $y } };
		return;
	}

	# ---------------------------------------------------------------------
	# Keys and the mouse
	# ---------------------------------------------------------------------

	method handle_key ($event) {
		my $name = $event->main_key_name // '';
		my $text = $event->text;
		return $self->_move( $MOVE_KEY{$name} // $name ) if $name =~ /\A(?:Up|Down|Home|End|PageUp|PageDown)\z/;
		if ( $name eq 'Enter' || $name eq 'Space' ) {
			$self->choose($_highlight) if defined $_highlight;
			return 1;
		}
		return $self->_find($text) || $_is_open if defined $text && $text =~ /\S/;

		# Inline or in a menu bar, the other keys belong to the owner; a
		# popup keeps every key while it is open.
		return 0 unless $_is_open;
		return $self->_move('Down') if $name eq 'Tab';
		return $self->_move('Up') if $name eq 'BackTab';
		$self->close if $name eq 'Escape';
		return 1;
	}

	method _move ($key) {
		my $target = roving_target( [ $self->_enabled_indexes ], $_highlight, $key, keys => 'vertical' );
		$self->highlight($target) if defined $target;
		return 1;
	}

	# A letter highlights the next enabled item whose label starts with
	# it; returns whether there was one.
	method _find ($letter) {
		my @enabled = $self->_enabled_indexes;
		my $start   = $_highlight // -1;
		my @order   = ( ( grep { $_ > $start } @enabled ), ( grep { $_ <= $start } @enabled ) );
		my $found   = first { lc( substr( $_items[$_]->label, 0, 1 ) ) eq lc $letter } @order;
		return 0 unless defined $found;
		$self->highlight($found);
		return 1;
	}

	# The mouse arms the menu by pressing or dragging inside it; a release
	# over an enabled item chooses it once armed.
	method handle_mouse ($event) {
		return 0 unless refaddr( $event->target ) == refaddr($self);
		my $row = $self->_item_at($event);
		if ( $event->key == TB_KEY_MOUSE_RELEASE ) {
			$self->choose($row) if $_armed && defined $row;
			return 1;
		}
		$_armed = 1;
		$self->highlight($row) if defined $row;
		return 1;
	}

	method _pointer_at ($event) {
		my $row = $self->_item_at($event) // return;
		$_armed = 1;
		$self->highlight($row) unless defined $_highlight && $_highlight == $row;
		return;
	}

	# The index of the item under the pointer, or undef: the menu may be
	# laid out taller than its items.
	method _item_at ($event) {
		my ( undef, $row ) = $self->cell_at($event);
		return defined $row && $row <= $#_items ? $row : undef;
	}

	# A click is handled by handle_mouse, on the release.
	method activate :override () {
		return;
	}

	# ---------------------------------------------------------------------
	# Painting
	# ---------------------------------------------------------------------

	method _gutter_columns () {
		return ( grep { defined && $_->is_toggle } @_items ) ? 2 : 0;
	}

	method _keys_columns () {
		return max( 0, map { string_columns( $_->keys_text ) } grep { defined } @_items );
	}

	method natural_size () {
		my $labels = max( 0, map { string_columns( $_->label ) } grep { defined } @_items );
		my $keys   = $self->_keys_columns;
		return ( 1 + $self->_gutter_columns + $labels + ( $keys ? KEYS_GAP + $keys : 0 ) + 1, scalar @_items );
	}

	method paint_key :override () {
		return ( $self->SUPER::paint_key, $_highlight // -1, map { defined $_ ? ( $_->is_enabled, $_->is_checked ) : '-' } @_items );
	}

	method paint () {
		my $text      = $self->color_attr( $self->text_color );
		my $disabled  = $self->color_attr( $self->disabled_color );
		my $keys      = $self->color_attr( $self->look_value('keys_color') );
		my $separator = $self->color_attr( $self->look_value('separator_color') );
		my @highlight = ( $self->color_attr( $self->look_value('highlight_text_color') ), $self->color_attr( $self->look_value('highlight_background_color') ) );
		my $gutter    = $self->_gutter_columns;
		foreach my $row ( 0 .. min( $#_items, $self->rows - 1 ) ) {
			my $item = $_items[$row];
			if ( !defined $item ) {
				$self->fill_attrs( 0, $row, $self->columns, SEPARATOR_GLYPH, $separator, undef );
				next;
			}
			my $is_highlighted = defined $_highlight && $_highlight == $row;
			my ( $fg, $bg ) = $is_highlighted ? @highlight : ( $item->is_enabled ? $text : $disabled, undef );
			$self->fill_attrs( 0, $row, $self->columns, ' ', $fg, $bg ) if defined $bg;
			$self->put_attrs( 1, $row, CHECK_MARK, $fg, $bg ) if $item->is_checked;
			$self->paint_text( 1 + $gutter, $row, $item->label, $fg, $bg );
			my $key_text = $item->keys_text;
			next unless length $key_text;
			$self->paint_text( $self->columns - 1 - string_columns($key_text), $row, $key_text, $is_highlighted ? $fg : $keys, $bg );
		}
		return;
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Widget::Menu - A list of commands, as a context menu,
in a menu bar or on its own

=head1 SYNOPSIS

	use Term::Fabulous::Widget::Menu;
	use Term::Fabulous::Termbox qw(TB_KEY_MOUSE_RIGHT TB_MOD_MOTION);

	# A context menu, opened at the pointer with a right click:
	my $menu = Term::Fabulous::Widget::Menu->new(
		items => [
			{ label => 'Open',   run => sub { open_row() } },
			{ label => 'Rename', run => sub { rename_row() } },
			'-',
			{ label => 'Delete', run => sub { delete_row() }, enabled => sub { $row_is_selected } },
		],
	);
	$list->on( Mouse => sub ($event) {
		return Clay::UI::Enum::Result->CONTINUE unless $event->key == TB_KEY_MOUSE_RIGHT && !( $event->modifiers & TB_MOD_MOTION );
		$menu->open( $ui, x => $event->x, y => $event->y );
		return;
	} );

	# The same menu from the keyboard, below the widget with the focus:
	$menu->open( $ui, below => $ui->interaction->get_focused_widget // $ui->root );

	# Items from a command table, by id:
	my $edit_menu = Term::Fabulous::Widget::Menu->new( commands => $commands, items => [qw(cut copy paste - select_all)] );

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.02/screenshots/widget-menu.svg" alt="A list of files with a context menu opened over budget.csv where it was right-clicked: Open with Enter, Rename... with F2, a line, Cut with Ctrl+X, a dimmed Paste with Ctrl+V, a line, and Show hidden files with a check mark and Alt+h. The pointer highlights Rename..."></p>

=end html

The program is F<examples/widgets/menu.pl>. Paste is dimmed because
nothing was cut yet, and Show hidden files has a check mark because the
hidden file F<.profile> is shown. The keys on the right work without
the menu, because the menu and the keys run the same
L<commands|Term::Fabulous::Commands>.

=head1 DESCRIPTION

A menu is a framed list of L<commands|Term::Fabulous::Command>, one per
row, with the keys that run them on the right. The user highlights an
item with the arrow keys, its first letter or the mouse, and chooses it
with C<Enter> or a click. Choosing an item fires
L<Choose|Term::Fabulous::Event::Choose> and runs the item's command.

A menu has three uses:

=over

=item As a context menu

L</open> shows the menu over everything else, at a point (usually where
the user clicked) or below a widget, and gives it the focus. It closes
when the user chooses an item, presses C<Escape> or clicks anywhere
else, and the focus goes back where it was. See L</POPUP MENUS>.

=item In a menu bar

A L<Term::Fabulous::Widget::MenuBar> makes one menu per title and shows
it below its title. You build those menus from the bar's C<menus>
parameter and do not handle them yourself.

=item On its own

Added to a box like any other widget, a menu stays on the screen: a
list of actions in a side panel, for example. It takes the focus with
Tab, and choosing an item runs it, as in a popup.

=back

=head2 Items

An item is one of:

=over

=item * a L<Term::Fabulous::Command>.

=item * the id of a command in the L</commands> table, such as C<'save'>.

=item * a hash reference of the parameters of
L<Term::Fabulous::Command/new>, for an item that is only in this menu.
Its C<id> may be left out, and is then its label. The keys of such an
item are only shown. To make them work, put the command in a
L<Term::Fabulous::Commands> table that listens for its keys, or handle
the keys yourself.

=item * C<'-'>, a separator: a line between groups of items.

=back

An item whose command is disabled is drawn dimmed and cannot be
highlighted or chosen. An item whose command is a toggle shows a check
mark (✓) in front of its label while it is on. A menu with
toggles leaves room for the mark in front of every label, so the labels
line up. The menu asks the commands every time it is drawn, so it
always shows the program's state.

=head2 Keys

=over

=item C<Up>, C<Down>

Highlight the item above or below, skipping separators and disabled
items, and going round at the ends.

=item C<Home>, C<PageUp>, C<End>, C<PageDown>

Highlight the first or the last item.

=item a letter or digit

Highlights the next enabled item whose label starts with it. The item
does not run until C<Enter> or a click chooses it.

=item C<Enter>, C<Space>

Choose the highlighted item.

=back

A popup menu also takes C<Tab> and C<Shift+Tab>, which work like
C<Down> and C<Up>, and C<Escape>, which closes it. It keeps every other
key for itself while it is open, as a dialog does, so the shortcuts of
the program wait until the menu is closed. C<Ctrl+C> still ends the
program (unless the UI was made with C<< stop_on_ctrl_c =E<gt> 0 >>).

=head2 The mouse

Moving the pointer over an item highlights it. Pressing a button on an
item highlights it, and releasing the button over an item chooses it,
so a click chooses, and so does pressing on a menu bar title, dragging
down and letting go over an item. A release only chooses after a press
or a move inside the menu since it opened: the release of the right
click that opened a context menu does not choose the item that happens
to be under the pointer.

=head1 POPUP MENUS

L</open> adds the menu to the root of the UI as a floating widget, over
everything else (dialogs included), and focuses it. At a point, the
menu's top left corner is at that point. Below a widget, the menu
starts at the widget's left edge, just below it, or just above it when
there is no room below. Either way, the menu moves left and up as far
as it must to stay on the screen. It finds its place again in every
frame, so a menu that is open while the terminal shrinks stays on the
screen. A menu does not scroll: one that is taller than the screen
starts at the top row, and its last items are cut off. Keep menus
shorter than the smallest screen the program expects, or split them.

The menu closes when:

=over

=item * the user chooses an item. The menu closes first, the focus goes
back, and then C<Choose> fires and the command runs. A command that
opens a dialog therefore works as it does from a key.

=item * the user presses C<Escape>, or the program calls L</close>. The
focus goes back to the widget that had it when the menu opened.

=item * the focus goes elsewhere, for example because the user clicked
outside the menu. The click reaches what is under the pointer, and the
focus stays where the click put it.

=back

Every time a popup closes, it fires C<Close>
(L<Term::Fabulous::Event::Close>) on itself. A closed menu can be
opened again, as often as needed.

=head1 CONSTRUCTOR

=head2 new

=for highlighter language=perl

	my $menu = Term::Fabulous::Widget::Menu->new(%parameters);

Accepts the parameters of L<Term::Fabulous::Widget::Input/new> (C<id>,
C<layout>, C<disabled>, C<text_color>, ...) and the ones below. All are
optional, and unknown parameters die.

=over

=item C<items>

An array reference of items, as described under L</Items>. Default:
C<[]>.

=item C<commands>

A L<Term::Fabulous::Commands> table, which items given as ids are
looked up in. Default: C<undef>. An id that the table does not have
dies, and so does an id without a table.

=item C<keys_color>

The color of the keys on the right, in any format
L<Term::Fabulous::Widget::Canvas/Colors> accepts. Default: the theme's
C<menu.keys>, the placeholder gray in the built-in themes.

=item C<separator_color>

The color of the separator lines. Default: the theme's
C<menu.separator>, the same gray.

=item C<highlight_text_color>, C<highlight_background_color>

The colors of the highlighted item. Default: the theme's
C<menu.highlight.text> and C<menu.highlight.background>, dark text on
the accent blue in the built-in dark theme.

=back

The text of the items is C<text_color>, and C<disabled_color> for a
disabled item (the theme's C<menu.text> and its C<disabled> state). The
background and the frame come from the theme's C<menu> family: a menu
has a border unless the theme's C<menu.border.enabled> is false or the
program passes C<< bordered =E<gt> 0 >>.

=head1 METHODS

A menu has the methods of L<Term::Fabulous::Widget::Input> plus these.

=head2 open

	$menu->open( $ui, x => 10, y => 4 );
	$menu->open( $ui, below => $button );

Opens the menu as a popup, as described under L</POPUP MENUS>: at the
cell C<x>, C<y> of the screen (both non-negative integers), or below a
widget. The widget must have been drawn in the last frame, so that its
place is known. A text widget has no box of its own, so open the menu
below the box that holds the text, or at the text's cell with C<x> and
C<y>. The first enabled item is highlighted. Opening an open menu does
nothing. Dies when C<$ui> is not a L<Term::Fabulous>, when the place is
not C<x> and C<y> or C<below> alone, for a widget the last frame did
not draw, for a disabled menu, and when the menu is a child of another
widget. Returns the menu.

=head2 close

	$menu->close;

Closes a popup menu: takes it off the screen, gives the focus back to
the widget that had it when the menu opened (if the menu still had the
focus and that widget can still take it) and fires C<Close>. Closing a
menu that is not open as a popup does nothing. Returns the menu.

=head2 is_open

1 while the menu is open as a popup, 0 otherwise.

=head2 items

	my @items = $menu->items;
	$menu->items( [ 'copy', 'paste' ] );

The items: the L<Term::Fabulous::Command> objects, and C<'-'> for each
separator. Writing them replaces every item, highlights the first
enabled one and returns the new items.

=head2 highlighted, highlight

	my $index = $menu->highlighted;
	$menu->highlight(2);

The index of the highlighted item (from 0, separators counted), or
C<undef>. C<highlight> highlights another one. It does nothing for a
separator or a disabled item, and dies for an index past the last item.
C<highlight(undef)> highlights none. Returns the menu.

=head2 choose

	$menu->choose(2);

Chooses an item as the user does: closes a popup, fires C<Choose> and
runs the command. Does nothing for a separator or a disabled item. Dies
for an index past the last item. Returns the menu.

=head2 show_below

	$menu->show_below( $bar, 6 );

Floats the menu below a widget, a number of columns from the widget's
left edge (default 0), kept on the screen like a popup, without opening
it. The menu does not take the focus, does not close by itself and
fires no C<Close>: the widget it is shown below hands it the keys with
L</handle_key> and takes it out of the tree again. When an item is
chosen, that widget hears of it, after C<Choose> and before the item's
command runs, through its C<menu_chosen> method (called with the menu)
if it has one. L<Term::Fabulous::Widget::MenuBar> shows its menus this
way. Programs use L</open>. Returns the menu.

=head2 handle_key

	return 1 if $menu->handle_key($event);

Handles a L<Term::Fabulous::Event::KeyPress> as described under
L</Keys>, and returns 1 when the menu used the key and 0 when not. A
menu calls it for the keys it receives while it has the focus. An owner
that keeps the focus itself, like a menu bar, passes its keys on with
it.

=head2 outer_size

	my ( $columns, $rows ) = $menu->outer_size;

The size of the menu on the screen: its items and its border.

=head2 keys_color, separator_color, highlight_text_color, highlight_background_color

Accessors for the themed colors, through
L<Term::Fabulous::Role::Themed/look_value> and
L<Term::Fabulous::Role::Themed/set_look>.

=head1 EVENTS

=over

=item C<Choose> (L<Term::Fabulous::Event::Choose>)

An item was chosen. Fired on the menu, after a popup closed and before
the item's command runs. It bubbles up from a menu in a menu bar or on
its own, and not from a popup, which has left the tree.

=item C<Close> (L<Term::Fabulous::Event::Close>)

A popup menu closed. Fired on the menu after it left the screen.

=back

=head1 KDL PROPERTIES

A menu is built in Perl only: its items run code, which a layout file
cannot express.

=head1 SEE ALSO

L<Term::Fabulous::Command>, L<Term::Fabulous::Commands>,
L<Term::Fabulous::Widget::MenuBar>, L<Term::Fabulous::Event::Choose>,
L<Term::Fabulous::Manual::Menus>,
L<Term::Fabulous::Cookbook::Menus/Open a menu with a right click or the Menu key (Menu)>.

=cut
