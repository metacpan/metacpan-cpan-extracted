package Term::Fabulous::ThemeEditor::SettingsList;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.02';

use Object::Pad 0.825;

use Clay::UI::Role::Interaction::Focusable;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Display;

# The table of the form mode: rows of settings in sections that open and
# close, with a swatch, the setting, its value and where the value comes
# from. Only the rows near the viewport are widgets (it is a
# Term::Fabulous::Widget::VirtualList inside), so it stays fast with
# every section open.
class Term::Fabulous::ThemeEditor::SettingsList
	:isa(Term::Fabulous::Widget::Box)
	:does(Clay::UI::Role::Interaction::Focusable)
	:strict(params)
{
	use Clay::UI::Enum::Result;
	use Clay::XS qw(sizing_fixed sizing_grow CLAY_TOP_TO_BOTTOM);
	use List::Util qw(any first max min);
	use Scalar::Util qw(weaken);
	use Term::Fabulous::Widget::VirtualList;
	use Term::Fabulous::Unicode qw(string_columns);
	use Time::HiRes ();

	use constant DOUBLE_CLICK_SECONDS => 0.4;
	use constant SWATCH_COLUMNS       => 4;
	use constant ORIGIN_COLUMNS       => 8;

	field $on_activate :param;    # code: Enter or a double click on a setting row ( $id )
	field $on_cursor   :param;    # code: the cursor moved ( $id )

	field @tree;    # the rows: hashes, sections with children
	field %row;    # id => row
	field %parent;    # id => the id of its section
	field %expanded;
	field @shown;    # the rows the list shows now, in order, each { row, depth }
	field %index_of;    # id => its index in @shown
	field $search = '';
	field %filter;
	field $cursor;
	field $hover;
	field $value_columns = 10;
	field $header;
	field $body;
	field @last_click;    # [ time, index ]

	ADJUST {
		my $id = $self->id // die "Term::Fabulous::ThemeEditor::SettingsList: an id is required";
		$self->layout( { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() } } );
		weaken( my $weak_self = $self );
		$header = Term::Fabulous::ThemeEditor::SettingsList::Row->new( list => $self, index => -1, layout => { sizing => { width => sizing_grow(), height => sizing_fixed(1) } } );
		$body   = Term::Fabulous::Widget::VirtualList->new(
			id    => "$id/rows",
			build => sub ($index) {
				Term::Fabulous::ThemeEditor::SettingsList::Row->new( list => $weak_self, index => $index, layout => { sizing => { width => sizing_grow(), height => sizing_fixed(1) } } );
			},
			layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() } },
		);
		$self->add_child( $header, $body );
		$self->on( KeyPress => sub ($event) { return $weak_self->_key($event) ? Clay::UI::Enum::Result->HANDLED : Clay::UI::Enum::Result->CONTINUE } );
	}

	# ---------------------------------------------------------------------
	# Rows
	# ---------------------------------------------------------------------

	# Replaces every row: a list of hashes with an id, the shown texts
	# (setting, value, origin, swatch), a color, and for a section
	# `section => 1` and its rows under `children`. Every section starts
	# closed; the cursor stays on its row when the row is still there.
	method rows ($rows) {
		@tree = @$rows;
		%row  = %parent = %expanded = ();
		my @queue = map { [ $_, undef ] } @tree;
		while ( my $entry = shift @queue ) {
			my ( $item, $above ) = @$entry;
			$row{ $item->{id} }    = $item;
			$parent{ $item->{id} } = $above;
			push @queue, map { [ $_, $item->{id} ] } @{ $item->{children} // [] };
		}
		$cursor = undef unless defined $cursor && exists $row{$cursor};
		$self->_reshape;
		return $self;
	}

	method has_row ($row_id) {
		return defined $row_id && exists $row{$row_id} ? 1 : 0;
	}

	method row ($row_id) {
		return $row{$row_id};
	}

	method parent_of ($row_id) {
		return $parent{$row_id};
	}

	method children_of ($row_id) {
		my $item = $row{$row_id} // return ();
		return map { $_->{id} } @{ $item->{children} // [] };
	}

	method row_ids () {
		return keys %row;
	}

	# Changes texts of a row; the row paints again by itself.
	method update_row ( $row_id, $changes ) {
		my $item = $row{$row_id} // die "Term::Fabulous::ThemeEditor::SettingsList: no row '$row_id'";
		@{$item}{ keys %$changes } = values %$changes;
		return $self;
	}

	# Shows the rows again after changes with update_row: a search or a
	# filter may take other rows now, and the values may be wider.
	method refresh () {
		$self->_reshape;
		return $self;
	}

	# ---------------------------------------------------------------------
	# Sections
	# ---------------------------------------------------------------------

	method is_expanded ($row_id) {
		return $expanded{$row_id} ? 1 : 0;
	}

	method expand (@ids) {
		$expanded{$_} = 1 foreach grep { $row{$_} && $row{$_}{section} } @ids;
		$self->_reshape;
		return $self;
	}

	method collapse (@ids) {
		delete @expanded{@ids};
		$self->_reshape;
		return $self;
	}

	method expand_all () {
		return $self->expand( grep { $row{$_}{section} } keys %row );
	}

	method collapse_all () {
		%expanded = ();
		$self->_reshape;
		return $self;
	}

	method toggle ($row_id) {
		return $self->is_expanded($row_id) ? $self->collapse($row_id) : $self->expand($row_id);
	}

	# ---------------------------------------------------------------------
	# Search and filters
	# ---------------------------------------------------------------------

	# Accessor for the search text: rows whose setting, value or origin
	# holds it (in any case) are shown with the sections above them.
	method search (@new) {
		return $search unless @new;
		$search = $new[0] // '';
		$self->_reshape;
		return $self;
	}

	# A named filter: code that gets a row and returns true to show it, or
	# undef to remove it.
	method filter ( $name, $code ) {
		defined $code ? ( $filter{$name} = $code ) : delete $filter{$name};
		$self->_reshape;
		return $self;
	}

	method _matches ($item) {
		return 0 if $item->{section};
		return 0 if any { !$_->($item) } values %filter;
		return 1 unless length $search;
		my $wanted = fc $search;
		return ( any { index( fc( $_ // '' ), $wanted ) >= 0 } @{$item}{qw(setting value origin)}, $item->{id} ) ? 1 : 0;
	}

	# The ids of the rows a search or a filter leaves, in order, sections
	# included; every row without either.
	method filtered_row_ids () {
		return map { $_->{row}{id} } @shown;
	}

	# Works out the rows shown: a section's rows while it is open; with a
	# search or a filter, the rows that match and their sections, open.
	method _reshape () {
		my $narrowed = length $search || %filter;
		@shown = ();
		my $walk;
		$walk = sub ( $items, $depth ) {
			my @out;
			foreach my $item (@$items) {
				if ( !$item->{section} ) {
					push @out, { row => $item, depth => $depth } if !$narrowed || $self->_matches($item);
					next;
				}
				my @inside = $walk->( $item->{children} // [], $depth + 1 );
				next if $narrowed && !@inside;
				push @out, { row => $item, depth => $depth };
				push @out, @inside if $narrowed || $expanded{ $item->{id} };
			}
			return @out;
		};
		@shown = $walk->( \@tree, 0 );
		undef $walk;
		%index_of = map { $shown[$_]{row}{id} => $_ } 0 .. $#shown;
		$body->count( scalar @shown );
		$self->_measure_values;
		my $before = $cursor // '';
		$cursor = @shown ? $shown[0]{row}{id} : undef if !defined $cursor || !exists $index_of{$cursor};
		$self->mark_changed;
		$on_cursor->($cursor) if defined $cursor && $cursor ne $before;
		return;
	}

	# The widest value of all rows, so that the columns stay where they are
	# whatever a search or a section shows.
	method _measure_values () {
		$value_columns = max( 5, min( 24, max( 0, map { string_columns( $_->{value} // '' ) } values %row ) ) + 1 );
		return;
	}

	# ---------------------------------------------------------------------
	# The cursor
	# ---------------------------------------------------------------------

	# Accessor for the row under the cursor; setting one that a closed
	# section hides opens it, one a search or filter hides dies.
	method cursor (@new) {
		return $cursor unless @new;
		my $row_id = $new[0];
		die "Term::Fabulous::ThemeEditor::SettingsList: no row '$row_id'" unless $self->has_row($row_id);
		my @closed;
		for ( my $above = $parent{$row_id}; defined $above; $above = $parent{$above} ) {
			push @closed, $above unless $expanded{$above};
		}
		$self->expand(@closed) if @closed;
		die "Term::Fabulous::ThemeEditor::SettingsList: the row '$row_id' is not shown (a search or filter hides it)" unless exists $index_of{$row_id};
		$self->_move_to( $index_of{$row_id} );
		return $self;
	}

	method shown_count () {
		return scalar @shown;
	}

	method shown_row ($index) {
		return $index >= 0 && $index < @shown ? $shown[$index] : undef;
	}

	method cursor_index () {
		return defined $cursor ? $index_of{$cursor} : undef;
	}

	method hover_index () {
		return $hover;
	}

	method value_columns () {
		return $value_columns;
	}

	method _move_to ($index) {
		return unless @shown;
		$index = max( 0, min( $#shown, $index ) );
		my $old = $cursor // '';
		$cursor = $shown[$index]{row}{id};
		$self->_reveal($index);
		$self->mark_changed;
		$on_cursor->($cursor) if $cursor ne $old;
		return;
	}

	# Scrolls so that the row at an index is inside the viewport.
	method _reveal ($index) {
		my $visible = $body->visible_items;
		my $rows    = $self->_viewport_rows;
		if ( !defined $visible ) {
			$body->scroll_to_item( max( 0, $index - $rows + 1 ) ) if $index >= $rows;
			return;
		}
		return $body->scroll_to_item($index) if $index < $visible->{first};
		return $body->scroll_to_item( max( 0, $index - $rows + 1 ) ) if $index > $visible->{first} + $rows - 1;
		return;
	}

	method _viewport_rows () {
		my $ui  = $self->ui                // return 10;
		my $box = $ui->bounding_box($body) // return 10;
		return max( 1, int( $box->{height} + 0.5 ) );
	}

	# ---------------------------------------------------------------------
	# Keys and mouse
	# ---------------------------------------------------------------------

	method _key ($event) {
		return 0 unless $self->is_focused;
		my $name  = $event->main_key_name // return 0;
		my $index = $self->cursor_index   // 0;
		my $page  = max( 1, $self->_viewport_rows - 1 );
		my %move  = ( Up => $index - 1, Down => $index + 1, PageUp => $index - $page, PageDown => $index + $page, Home => 0, End => $#shown, 'Ctrl+Home' => 0, 'Ctrl+End' => $#shown );
		if ( exists $move{$name} ) {
			$self->_move_to( $move{$name} );
			return 1;
		}
		my $item = defined $cursor ? $row{$cursor} : undef;
		return 0 unless defined $item;
		my $text = $event->text // '';
		if ( $name eq 'Right' || $text eq '+' ) {
			return 1 unless $item->{section};
			if ( !$self->is_expanded($cursor) && !length $search && !%filter ) {
				$self->expand($cursor);
				return 1;
			}
			$self->_move_to( $index + 1 ) if $name eq 'Right';
			return 1;
		}
		if ( $name eq 'Left' || $text eq '-' ) {
			if ( $item->{section} && $self->is_expanded($cursor) && !length $search && !%filter ) {
				$self->collapse($cursor);
				return 1;
			}
			$self->_move_to( $index_of{ $parent{$cursor} } ) if defined $parent{$cursor} && exists $index_of{ $parent{$cursor} };
			return 1;
		}
		if ( $name eq 'Enter' || $name eq 'Space' ) {
			$self->activate($cursor);
			return 1;
		}
		return 0;
	}

	# A section opens or closes; a setting is edited.
	method activate ($row_id) {
		my $item = $row{$row_id} // return;
		return $self->toggle($row_id) if $item->{section};
		$on_activate->($row_id);
		return;
	}

	# A click puts the cursor on a row; on a section's marker it opens or
	# closes the section, and a second click on the same row activates it.
	method click ( $index, $column ) {
		return unless defined $self->shown_row($index);
		my $entry = $self->shown_row($index);
		$self->_move_to($index);
		my $now = Time::HiRes::time();
		if ( $entry->{row}{section} && $column >= SWATCH_COLUMNS + 2 * $entry->{depth} && $column < SWATCH_COLUMNS + 2 * $entry->{depth} + 2 ) {
			@last_click = ();
			$self->toggle( $entry->{row}{id} );
			return;
		}
		if ( @last_click && $last_click[1] == $index && $now - $last_click[0] <= DOUBLE_CLICK_SECONDS ) {
			@last_click = ();
			$self->activate( $entry->{row}{id} );
			return;
		}
		@last_click = ( $now, $index );
		return;
	}

	method hover ($index) {
		return if ( $hover // -2 ) == ( $index // -2 );
		$hover = $index;
		$self->mark_changed;
		return;
	}
}

# One row of the list (index -1: the titles), painted from the list's
# data: the swatch, the setting with its indentation and marker, the
# value, where it comes from.
class Term::Fabulous::ThemeEditor::SettingsList::Row :isa(Term::Fabulous::Widget::Display) :strict(params) {
	use Clay::UI::Enum::Result;
	use List::Util qw(max min);
	use Scalar::Util qw(weaken);
	use Term::Fabulous::Termbox qw(TB_BOLD TB_KEY_MOUSE_LEFT TB_MOD_MOTION);
	use Term::Fabulous::Unicode qw(string_columns);

	use constant OPEN   => "\x{25BE} ";
	use constant CLOSED => "\x{25B8} ";

	field $list :param :weak;
	field $index :param;

	ADJUST {
		weaken( my $weak_self = $self );
		$self->on( Mouse          => sub ($event) { $weak_self->_mouse($event); return Clay::UI::Enum::Result->CONTINUE } );
		$self->on( MouseMove      => sub ($event) { $weak_self->_moved;         return Clay::UI::Enum::Result->CONTINUE } );
		$self->on( OnHoverStopped => sub ($event) { $weak_self->_left;          return Clay::UI::Enum::Result->CONTINUE } );
	}

	method natural_size () {
		return ( 0, 1 );
	}

	# A text cut to a number of columns, a ~ marking the cut.
	sub _fit ( $text, $columns ) {
		return $text if string_columns($text) <= $columns;
		return '' if $columns < 1;
		my $cut = $text;
		chop $cut while length $cut && string_columns($cut) > $columns - 1;
		return "$cut~";
	}

	method _mouse ($event) {
		return if $index < 0 || !defined $list;
		return unless $event->key == TB_KEY_MOUSE_LEFT && !( $event->modifiers & TB_MOD_MOTION );
		my ($column) = $self->cell_at($event);
		$list->click( $index, $column // 0 );
		return;
	}

	method _moved () {
		$list->hover( $index >= 0 ? $index : undef ) if defined $list;
		return;
	}

	method _left () {
		$list->hover(undef) if defined $list && ( $list->hover_index // -1 ) == $index;
		return;
	}

	method paint_key :override () {
		return $self->SUPER::paint_key unless defined $list;
		return ( $self->SUPER::paint_key, $list->value_columns, $list->is_focused ) if $index < 0;
		my $entry = $list->shown_row($index) // return ( $self->SUPER::paint_key, 'none' );
		my $row   = $entry->{row};
		return (
			$self->SUPER::paint_key, $list->value_columns, $entry->{depth}, $list->is_focused,
			( $list->cursor_index // -1 ) == $index, ( $list->hover_index // -1 ) == $index,
			$list->is_expanded( $row->{id} ),
			map { ref $_ ? join( ',', @$_ ) : $_ // '' } @{$row}{qw(setting value origin swatch color set section)}
		);
	}

	method _look ( $slot, $state = 'normal' ) {
		return $self->color_attr( $self->family_look( table => $slot, $state ) );
	}

	method paint () {
		return unless defined $list;
		my $width  = $self->columns;
		my $origin = Term::Fabulous::ThemeEditor::SettingsList::ORIGIN_COLUMNS;
		my $swatch = Term::Fabulous::ThemeEditor::SettingsList::SWATCH_COLUMNS;
		my $values = min( $list->value_columns, max( 6, int( ( $width - $swatch - $origin ) * 0.4 ) ) );
		my $label  = max( 1, $width - $swatch - $values - $origin );
		if ( $index < 0 ) {
			my ( $fg, $bg ) = ( $self->_look('header.text') | TB_BOLD, $self->_look('header.background') );
			$self->fill_attrs( 0, 0, $width, ' ', $fg, $bg );
			$self->paint_text( $swatch,                    0, 'Setting', $fg, $bg );
			$self->paint_text( $swatch + $label,           0, 'Value',   $fg, $bg );
			$self->paint_text( $swatch + $label + $values, 0, 'From',    $fg, $bg );
			return;
		}
		my $entry     = $list->shown_row($index) // return;
		my $row       = $entry->{row};
		my $is_cursor = ( $list->cursor_index // -1 ) == $index;
		my $bg
			= $is_cursor && $list->is_focused        ? $self->_look('cursor')
			: $is_cursor                             ? $self->_look('selected')
			: ( $list->hover_index // -1 ) == $index ? $self->_look('hover')
			: $row->{section}                        ? $self->_look('group.background')
			:                                          undef;
		my $fg = $row->{section} ? $self->_look('group.text') | TB_BOLD : $row->{set} ? $self->_look('text') | TB_BOLD : $self->_look('muted');
		$self->fill_attrs( 0, 0, $width, ' ', $fg, $bg );
		if ( defined $row->{color} ) {
			$self->fill_attrs( 0, 0, $swatch - 1, ' ', $fg, $self->color_attr( $row->{color} ) );
		}
		elsif ( length( $row->{swatch} // '' ) ) {
			$self->paint_text( 0, 0, $row->{swatch}, $self->_look('text'), $bg, $swatch - 1 );
		}
		my $indent = '  ' x $entry->{depth};
		my $marker = !$row->{section} ? '  ' : ( $list->is_expanded( $row->{id} ) || length $list->search ) ? OPEN : CLOSED;
		$self->paint_text( $swatch,          0, _fit( $indent . $marker . $row->{setting}, $label - 1 ), $fg, $bg );
		$self->paint_text( $swatch + $label, 0, _fit( $row->{value} // '', $values - 1 ), $row->{section} ? $self->_look('muted') : $fg, $bg );
		$self->paint_text( $swatch + $label + $values, 0, $row->{origin} // '', $row->{set} ? $self->_look('group.text') : $self->_look('muted'), $bg );
		return;
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::ThemeEditor::SettingsList - The table of settings in
the theme editor's form

=head1 DESCRIPTION

Part of L<Term::Fabulous::ThemeEditor>; not meant to be used on its
own. A tree of rows in sections, each row showing a swatch, the
setting (indented, sections with a marker), its value and where the
value comes from, under a row of titles. Only the rows near the
viewport are widgets, inside a L<Term::Fabulous::Widget::VirtualList>,
so the list costs the same with every section open. The rows are
painted in the colors of the theme's C<table> family: the cursor in
C<table.cursor> (C<table.selected> while the list does not have the
focus), the row under the pointer in C<table.hover>, sections in
C<table.group.text> on C<table.group.background>, settings the theme
does not set in C<table.muted>. A text too long for its column ends in
C<~>; the columns keep their places whatever the list shows.

Keys while the list has the focus: C<Up>, C<Down>, C<PageUp>,
C<PageDown>, C<Home>, C<End> move the cursor; C<Right> or C<+> opens a
section (on an open one, C<Right> goes to its first row); C<Left> or
C<-> closes a section, or goes to the section above a row; C<Enter> or
C<Space> opens or closes a section and edits a setting. A click puts
the cursor on a row, a click on a section's marker opens or closes it,
a double click activates a row, the wheel scrolls.

=head1 CONSTRUCTOR

=head2 new

	my $list = Term::Fabulous::ThemeEditor::SettingsList->new(
		id          => 'settings',
		on_activate => sub ($id) { ... },    # Enter or a double click on a setting
		on_cursor   => sub ($id) { ... },    # the cursor moved
	);

=head1 METHODS

=head2 rows

Replaces all rows: hashes with C<id>, C<setting>, C<value>, C<origin>,
C<swatch> (glyphs), C<color> (the swatch's color), C<set>, and for a
section C<< section => 1 >> with its rows under C<children>.

=head2 row, has_row, row_ids, parent_of, children_of, update_row, refresh

Reading the rows, changing one's texts, and showing the rows again
after such changes (a search or a filter may take other rows then).

=head2 expand, collapse, toggle, expand_all, collapse_all, is_expanded

Opening and closing sections.

=head2 search, filter, filtered_row_ids

The search text (rows whose texts hold it, in any case, with their
sections), named filters (code that gets a row), and the ids of the
rows shown.

=head2 cursor, cursor_index

The row under the cursor; setting it opens the sections above the row
and scrolls it into view, and dies for a row a search or a filter
hides.

=head2 activate, click, hover

What C<Enter>, a click and the pointer do to a row.

=head2 shown_count, shown_row, hover_index, value_columns

What the rows paint from.

=head1 SEE ALSO

L<Term::Fabulous::ThemeEditor>, L<Term::Fabulous::ThemeEditor::Form>,
L<Term::Fabulous::Widget::VirtualList>.

=cut
