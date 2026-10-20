package Term::Fabulous::ThemeEditor::SettingsList;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.05';

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
	use List::Util qw(max min);
	use Scalar::Util qw(weaken);
	use Term::Fabulous::Widget::Table::Model;
	use Term::Fabulous::Widget::VirtualList;
	use Term::Fabulous::Unicode qw(string_columns);

	use constant SWATCH_COLUMNS => 4;
	use constant ORIGIN_COLUMNS => 8;

	field $on_activate :param;    # code: Enter or a double click on a setting row ( $id )
	field $on_cursor   :param;    # code: the cursor moved ( $id )

	# The rows, their expansion, the search, the filters and the cursor
	# (on the line of a row). Sections pass only for a setting inside
	# them, and a search or a filter opens them without changing which
	# are open.
	field $model = Term::Fabulous::Widget::Table::Model->new( row_id => 'id', children_key => 'children', open_when_filtered => 1, only_leaves_match => 1 );
	field @shown;    # the lines the list shows, each { row, depth }; for the model revision below
	field %index_of;    # id => its index in @shown
	field $shown_revision = -1;
	field $hover;
	field $value_columns = 10;
	field $header;
	field $body;
	field $last_click;    # the index of the last single click, which a double click must repeat

	ADJUST {
		my $id = $self->id // die "Term::Fabulous::ThemeEditor::SettingsList: an id is required";
		$self->layout( { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() } } );
		weaken( my $weak_self = $self );    # for the rows the list builds, which it keeps
		$header = Term::Fabulous::ThemeEditor::SettingsList::Row->new( list => $self, index => -1, layout => { sizing => { width => sizing_grow(), height => sizing_fixed(1) } } );
		$body   = Term::Fabulous::Widget::VirtualList->new(
			id    => "$id/rows",
			build => sub ($index) {
				Term::Fabulous::ThemeEditor::SettingsList::Row->new( list => $weak_self, index => $index, layout => { sizing => { width => sizing_grow(), height => sizing_fixed(1) } } );
			},
			layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() } },
		);
		$self->add_child( $header, $body );
		$model->add_column( { key => $_ } ) foreach qw(setting value origin id);    # what the search reads
		$self->on( KeyPress => sub ( $self, $event ) { return $self->_key($event) ? Clay::UI::Enum::Result->HANDLED : Clay::UI::Enum::Result->CONTINUE }, owner => $self );
	}

	# ---------------------------------------------------------------------
	# Rows
	# ---------------------------------------------------------------------

	# Replaces every row: a list of hashes with an id, the shown texts
	# (setting, value, origin, swatch), a color, and for a section
	# `section => 1` and its rows under `children`. Every section starts
	# closed; the cursor stays on its row when the row is still there.
	method rows ($rows) {
		return $self->_change( sub { $model->set_rows($rows) } );
	}

	method has_row ($row_id) {
		return $model->has_row($row_id);
	}

	# A copy of the row's data, without its children.
	method row ($row_id) {
		return $model->has_row($row_id) ? $model->row($row_id) : undef;
	}

	method parent_of ($row_id) {
		return $model->has_row($row_id) ? $model->parent_of($row_id) : undef;
	}

	method children_of ($row_id) {
		return $model->has_row($row_id) ? $model->children_of($row_id) : ();
	}

	method row_ids () {
		return $model->row_ids;
	}

	# Changes texts of a row; the row paints again by itself.
	method update_row ( $row_id, $changes ) {
		die "Term::Fabulous::ThemeEditor::SettingsList: no row '$row_id'" unless $model->has_row($row_id);
		$model->update_row( $row_id, $changes );
		return $self;
	}

	# Shows the rows again after changes with update_row: a search or a
	# filter may take other rows now, and the values may be wider.
	method refresh () {
		return $self->_change( sub { } );
	}

	# ---------------------------------------------------------------------
	# Sections
	# ---------------------------------------------------------------------

	method _is_section ($row_id) {
		return $model->has_row($row_id) && $model->data_of($row_id)->{section} ? 1 : 0;
	}

	method is_expanded ($row_id) {
		return $model->has_row($row_id) ? $model->is_expanded($row_id) : 0;
	}

	method expand (@ids) {
		my @sections = grep { $self->_is_section($_) } @ids;
		return $self->_change( sub { $model->set_expanded( $_, 1 ) foreach @sections } );
	}

	method collapse (@ids) {
		my @known = grep { $model->has_row($_) } @ids;
		return $self->_change( sub { $model->set_expanded( $_, 0 ) foreach @known } );
	}

	method expand_all () {
		return $self->_change( sub { $model->set_all_expanded(1) } );
	}

	method collapse_all () {
		return $self->_change( sub { $model->set_all_expanded(0) } );
	}

	method toggle ($row_id) {
		return $self->is_expanded($row_id) ? $self->collapse($row_id) : $self->expand($row_id);
	}

	# ---------------------------------------------------------------------
	# Search and filters
	# ---------------------------------------------------------------------

	# Accessor for the search text: rows whose setting, value, origin or
	# id holds it (in any case) are shown with the sections above them.
	method search (@new) {
		return $model->search unless @new;
		my $text = $new[0] // '';
		return $self->_change( sub { $model->search($text) } );
	}

	# A named filter: code that gets a row and returns true to show it, or
	# undef to remove it.
	method filter ( $name, $code ) {
		return $self->_change( sub { $model->set_filter( $name, $code ) } );
	}

	# The ids of the rows the list shows, in order, sections included.
	method filtered_row_ids () {
		return map { $_->{row}{id} } $self->_shown;
	}

	# Every change of the model goes through here: afterwards the list
	# shows the model's lines, measures the values again and keeps the
	# cursor on the row it was on, or puts it on the first row shown when
	# that row went out of sight (the model's own stand-in is not used).
	method _change ($code) {
		my $before = $self->cursor;
		$code->();
		my @lines = $self->_shown;
		$body->count( scalar @lines );
		$self->_measure_values;
		my $target = defined $before && exists $index_of{$before} ? $before : @lines ? $lines[0]{row}{id} : undef;
		$self->_put_cursor_on( $target, $before );
		$self->mark_changed;
		return $self;
	}

	# The lines of the model as { row, depth }, again only after the
	# model changed.
	method _shown () {
		return @shown if $shown_revision == $model->revision;
		@shown          = map { +{ row => $model->data_of( $_->{id} ), depth => $_->{depth} } } $model->lines;
		%index_of       = map { $shown[$_]{row}{id} => $_ } 0 .. $#shown;
		$shown_revision = $model->revision;
		return @shown;
	}

	# The widest value of all rows, so that the columns stay where they are
	# whatever a search or a section shows.
	method _measure_values () {
		$value_columns = max( 5, min( 24, max( 0, map { string_columns( $model->data_of($_)->{value} // '' ) } $model->row_ids ) ) + 1 );
		return;
	}

	# ---------------------------------------------------------------------
	# The cursor
	# ---------------------------------------------------------------------

	method cursor (@new) {
		return $model->line_count ? Term::Fabulous::Widget::Table::Model::id_of_key( $model->cursor ) : undef unless @new;
		my $row_id = $new[0];
		die "Term::Fabulous::ThemeEditor::SettingsList: no row '$row_id'" unless $self->has_row($row_id);
		my @closed = grep { !$model->is_expanded($_) } $self->_sections_above($row_id);
		$self->expand(@closed) if @closed;
		$self->_shown;
		die "Term::Fabulous::ThemeEditor::SettingsList: the row '$row_id' is not shown (a search or filter hides it)" unless exists $index_of{$row_id};
		$self->_move_to( $index_of{$row_id} );
		return $self;
	}

	method _sections_above ($row_id) {
		my @above;
		for ( my $parent = $model->parent_of($row_id); defined $parent; $parent = $model->parent_of($parent) ) {
			push @above, $parent;
		}
		return @above;
	}

	method shown_count () {
		return scalar $self->_shown;
	}

	method shown_row ($index) {
		$self->_shown;
		return $index >= 0 && $index < @shown ? $shown[$index] : undef;
	}

	method cursor_index () {
		my $cursor = $self->cursor // return undef;
		$self->_shown;
		return $index_of{$cursor};
	}

	method hover_index () {
		return $hover;
	}

	method value_columns () {
		return $value_columns;
	}

	# The cursor goes to a row shown (or nowhere in an empty list); a row
	# other than the one before tells on_cursor.
	method _put_cursor_on ( $row_id, $before ) {
		return unless defined $row_id;
		$model->set_cursor( Term::Fabulous::Widget::Table::Model::row_key($row_id) );
		$on_cursor->($row_id) if $row_id ne ( $before // '' );
		return;
	}

	method _move_to ($index) {
		my @lines = $self->_shown;
		return unless @lines;
		$index = max( 0, min( $#lines, $index ) );
		$self->_put_cursor_on( $lines[$index]{row}{id}, $self->cursor );
		$self->_reveal($index);
		$self->mark_changed;
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
		my $last  = $self->shown_count - 1;
		my %move  = ( Up => $index - 1, Down => $index + 1, PageUp => $index - $page, PageDown => $index + $page, Home => 0, End => $last, 'Ctrl+Home' => 0, 'Ctrl+End' => $last );
		if ( exists $move{$name} ) {
			$self->_move_to( $move{$name} );
			return 1;
		}
		my $cursor = $self->cursor // return 0;
		my $item   = $model->data_of($cursor);
		my $text   = $event->text // '';
		my $folds  = $item->{section} && !$model->is_filtered;    # a search or a filter shows the sections open
		if ( $name eq 'Right' || $text eq '+' ) {
			return 1 unless $item->{section};
			if ( $folds && !$self->is_expanded($cursor) ) {
				$self->expand($cursor);
				return 1;
			}
			$self->_move_to( $index + 1 ) if $name eq 'Right';
			return 1;
		}
		if ( $name eq 'Left' || $text eq '-' ) {
			if ( $folds && $self->is_expanded($cursor) ) {
				$self->collapse($cursor);
				return 1;
			}
			my $parent = $model->parent_of($cursor);
			$self->_move_to( $index_of{$parent} ) if defined $parent && exists $index_of{$parent};
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
		return unless $model->has_row($row_id);
		return $self->toggle($row_id) if $self->_is_section($row_id);
		$on_activate->($row_id);
		return;
	}

	# A click puts the cursor on a row; on a section's marker it opens or
	# closes the section, and the second click of a double click on the
	# same row activates it. $click_count is the click's place in a run
	# of quick clicks (Term::Fabulous::Event::Mouse).
	method click ( $index, $column, $click_count = 1 ) {
		my $entry = $self->shown_row($index) // return;
		$self->_move_to($index);
		if ( $entry->{row}{section} && $column >= SWATCH_COLUMNS + 2 * $entry->{depth} && $column < SWATCH_COLUMNS + 2 * $entry->{depth} + 2 ) {
			$last_click = undef;
			$self->toggle( $entry->{row}{id} );
			return;
		}
		if ( $click_count >= 2 && defined $last_click && $last_click == $index ) {
			$last_click = undef;
			$self->activate( $entry->{row}{id} );
			return;
		}
		$last_click = $index;
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
	use Term::Fabulous::Unicode qw(fit_columns);

	use constant OPEN   => "\x{25BE} ";
	use constant CLOSED => "\x{25B8} ";
	use constant CUT    => '~';    # marks a cut setting or value

	field $list :param :weak;
	field $index :param;

	ADJUST {
		$self->on( Mouse          => sub ( $self, $event ) { $self->_mouse($event); return Clay::UI::Enum::Result->CONTINUE }, owner => $self );
		$self->on( MouseMove      => sub ( $self, $event ) { $self->_moved;         return Clay::UI::Enum::Result->CONTINUE }, owner => $self );
		$self->on( OnHoverStopped => sub ( $self, $event ) { $self->_left;          return Clay::UI::Enum::Result->CONTINUE }, owner => $self );
	}

	method natural_size () {
		return ( 0, 1 );
	}

	method _mouse ($event) {
		return if $index < 0 || !defined $list;
		return unless $event->key == TB_KEY_MOUSE_LEFT && !( $event->modifiers & TB_MOD_MOTION );
		my ($column) = $self->cell_at($event);
		$list->click( $index, $column // 0, $event->click_count );
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
		$self->paint_text( $swatch,          0, fit_columns( $indent . $marker . $row->{setting}, $label - 1, mark => CUT ), $fg, $bg );
		$self->paint_text( $swatch + $label, 0, fit_columns( $row->{value} // '', $values - 1, mark => CUT ), $row->{section} ? $self->_look('muted') : $fg, $bg );
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
so the list costs the same with every section open. The rows, which
sections are open, the search, the filters and the cursor are kept in a
L<Term::Fabulous::Widget::Table::Model> (with C<open_when_filtered> and
C<only_leaves_match>): a search or a filter shows the settings it lets
through with their sections open, and a section never matches by
itself. The rows are
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

Reading the rows (C<row> gives a copy of a row's data without its
children; C<parent_of>, C<children_of> and C<row> give nothing for an
unknown id), changing one's texts, and showing the rows again after
such changes (a search or a filter may take other rows then).

=head2 expand, collapse, toggle, expand_all, collapse_all, is_expanded

Opening and closing sections.

=head2 search, filter, filtered_row_ids

The search text (rows whose setting, value, origin or id hold it, in
any case, with their sections), named filters (code that gets a row),
and the ids of the rows shown.

=head2 cursor, cursor_index

The row under the cursor; setting it opens the sections above the row
and scrolls it into view, and dies for a row a search or a filter
hides. When a change hides the row under the cursor, the cursor goes to
the first row shown.

=head2 activate, click, hover

What C<Enter>, a click and the pointer do to a row.
C<< click( $index, $column, $click_count ) >> takes the click's place in
a run of quick clicks
(L<Term::Fabulous::Event::Mouse/click_count>, default 1); the second
click of a double click on the same row activates it.

=head2 shown_count, shown_row, hover_index, value_columns

What the rows paint from.

=head1 SEE ALSO

L<Term::Fabulous::ThemeEditor>, L<Term::Fabulous::ThemeEditor::Form>,
L<Term::Fabulous::Widget::VirtualList>.

=cut
