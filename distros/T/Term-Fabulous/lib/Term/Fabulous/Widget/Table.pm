package Term::Fabulous::Widget::Table;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.05';

use Object::Pad 0.825;

use Clay::UI::Role::Core::Preparable;
use Clay::UI::Role::Interaction::Focusable;
use Clay::UI::Role::Interaction::Hoverable;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::ScrollBox;
use Term::Fabulous::Widget::Text;
use Term::Fabulous::Widget::TextField;
use Term::Fabulous::Widget::Table::Cell;
use Term::Fabulous::Widget::Table::ColumnChooser;
use Term::Fabulous::Widget::Table::Grid;
use Term::Fabulous::Widget::Table::EdgeView;
use Term::Fabulous::Role::Searchable qw(searchables_in nested_search_texts nested_search_revision nested_highlight_text nested_clear_text_highlights nested_reveal_text);
use Term::Fabulous::Widget::Table::Model;
use Term::Fabulous::Widget::Table::Pager;
use Term::Fabulous::Widget::Scrollbar;
use Term::Fabulous::Widget::Table::Toggle;

class Term::Fabulous::Widget::Table
	:isa(Term::Fabulous::Widget::Box)
	:does(Clay::UI::Role::Interaction::Focusable)
	:does(Clay::UI::Role::Interaction::Hoverable)
	:does(Clay::UI::Role::Core::Preparable)
	:does(Term::Fabulous::Role::Searchable)
	:strict(params)
{
	use Clay::UI::Enum::Result;
	use Clay::UI::Role::Layout::HasParent qw(is_widget);
	use Feature::Compat::Try;
	use Clay::XS qw(
		sizing_fit sizing_fixed sizing_grow sizing_percent CLAY_LEFT_TO_RIGHT CLAY_TOP_TO_BOTTOM
		CLAY__SIZING_TYPE_GROW CLAY__SIZING_TYPE_PERCENT
		CLAY_ALIGN_X_LEFT CLAY_ALIGN_X_CENTER CLAY_ALIGN_X_RIGHT CLAY_ALIGN_Y_TOP
		CLAY_TEXT_WRAP_WORDS CLAY_TEXT_WRAP_NEWLINES CLAY_TEXT_WRAP_NONE
		CLAY_TEXT_ALIGN_LEFT CLAY_TEXT_ALIGN_CENTER CLAY_TEXT_ALIGN_RIGHT
	);
	use List::Util qw(all any first max min none);
	use Scalar::Util qw(blessed refaddr weaken);
	use Term::Fabulous::Check qw(boolean border_style describe non_negative_integer one_of optional string);
	use Term::Fabulous::Enum::BorderStyle;
	use Term::Fabulous::Event::CursorMove;
	use Term::Fabulous::Event::Collapse;
	use Term::Fabulous::Event::ColumnsChange;
	use Term::Fabulous::Event::Expand;
	use Term::Fabulous::Event::FilterChange;
	use Term::Fabulous::Event::PageChange;
	use Term::Fabulous::Event::RowActivate;
	use Term::Fabulous::Event::SelectionChange;
	use Term::Fabulous::Event::SortChange;
	use Term::Fabulous::Termbox qw(TB_KEY_MOUSE_LEFT TB_KEY_MOUSE_RIGHT TB_MOD_MOTION TB_MOD_SHIFT TB_MOD_CTRL TB_MOD_ALT);
	use Term::Fabulous::Text::Marks;
	use Term::Fabulous::Widget::Table::Borders qw(resolve_borders);
	use Term::Fabulous::Widget::Table::Filter;
	use Term::Fabulous::Widget::Table::Style qw(style_hash merge_styles);

	use constant {
		SELECT_COLUMN       => '',    # the column key of the selection column
		EMPTY_LINE          => "e\0",    # the key of the line an empty view shows
		MARK_CHECKED        => '[x]',
		MARK_UNCHECKED      => '[ ]',
		MARK_SOME           => '[-]',
		OPEN                => "\x{25BE} ",
		CLOSED              => "\x{25B8} ",
		LEAF                => '  ',
		SORT_UP             => "\x{25B4}",
		SORT_DOWN           => "\x{25BE}",
		INDENT              => 2,
		DEFAULT_PAGE_STEP   => 10,
		FALLBACK_BACKGROUND => [ 22, 25, 31, 255 ],    # cells on nothing (see _base_background)
	};

	my $CONTINUE = Clay::UI::Enum::Result->CONTINUE;
	my $HANDLED  = Clay::UI::Enum::Result->HANDLED;

	my @SELECTIONS     = qw(none single multiple);
	my %ALIGN_X        = ( left  => CLAY_ALIGN_X_LEFT,    center   => CLAY_ALIGN_X_CENTER,     right => CLAY_ALIGN_X_RIGHT );
	my %TEXT_ALIGN     = ( left  => CLAY_TEXT_ALIGN_LEFT, center   => CLAY_TEXT_ALIGN_CENTER,  right => CLAY_TEXT_ALIGN_RIGHT );
	my %WRAP           = ( words => CLAY_TEXT_WRAP_WORDS, newlines => CLAY_TEXT_WRAP_NEWLINES, none  => CLAY_TEXT_WRAP_NONE );
	my @LINE_PARAMS    = qw(border_top border_right border_bottom border_left column_lines row_lines header_line);
	my @NONE_IS_HIDDEN = ( none => Term::Fabulous::Enum::BorderStyle->Hidden );    # 'none' draws no line
	my %NO_BOX_BORDER  = map { $_ => 0 } qw(top right bottom left);
	my @COLOR_PARAMS   = qw(
		text_color header_text_color header_background_color group_text_color group_background_color
		cursor_color selected_color hover_color filter_background_color error_color muted_color line_color
	);
	my %COLOR_SLOT = (
		text_color              => 'text',
		header_text_color       => 'header.text',
		header_background_color => 'header.background',
		group_text_color        => 'group.text',
		group_background_color  => 'group.background',
		cursor_color            => 'cursor',
		selected_color          => 'selected',
		hover_color             => 'hover',
		filter_background_color => 'filter.background',
		error_color             => 'error',
		muted_color             => 'muted',
		line_color              => 'line.color',
	);

	# ---------------------------------------------------------------------
	# Parameters
	# ---------------------------------------------------------------------

	# What the model is made of; handed over in ADJUST and dropped there.
	field $initial_columns   :param(columns)   = [];
	field $initial_rows      :param(rows)      = [];
	field $initial_sort      :param(sort)      = [];
	field $initial_group     :param(group_by)  = undef;
	field $row_id            :param            = undef;
	field $children_key      :param            = undef;
	field $tree_expanded     :param            = 0;
	field $initial_page_size :param(page_size) = 0;

	field $selection        :param = 'none';
	field $selection_column :param = undef;
	field $_explicit_selection_column;    # selection_column as the user set it, else undef
	field $show_header   :param(header) = 1;
	field $filter_row    :param         = 0;
	field $page_sizes    :param         = [ 10, 25, 50, 100 ];
	field $show_pager    :param(pager)  = undef;
	field $scrollbar     :param         = 1;
	field $hover         :param         = 1;
	field $tree_column   :param         = undef;
	field $group_label   :param         = undef;
	field $row_style     :param         = undef;
	field $header_style  :param         = undef;
	field $group_style   :param         = undef;
	field $empty_text    :param         = 'No rows';
	field $no_match_text :param         = 'No rows match';
	field $cell_padding  :param         = 1;

	field $border        :param = 'Round';
	field $border_top    :param = undef;
	field $border_right  :param = undef;
	field $border_bottom :param = undef;
	field $border_left   :param = undef;
	field $column_lines  :param = 'Solid';
	field $row_lines     :param = undef;
	field $header_line   :param = 'Solid';

	# ---------------------------------------------------------------------
	# State
	# ---------------------------------------------------------------------

	field $model :reader;
	field %_line_style;    # table-wide lines: border_* , column_lines, row_lines, header_line

	# The widgets of the table: three rows, each a view of a grid (the
	# header, the scrolling body, the footer) and, while the rows scroll,
	# a strip of the scrollbar column beside it, which draws the frame's
	# right side there. The strips of the header and the footer hold a
	# blank column, the body's the scrollbar.
	field $_header_row;
	field $_header_view;
	field $_header_grid;
	field $_header_strip;
	field $_body_row;
	field $_body;
	field $_body_grid;
	field $_body_strip;
	field $_scrollbar;
	field $_footer_row;
	field $_footer_view;
	field $_footer_grid;
	field $_footer_strip;
	field $_pager;
	field $_chooser;

	# The header as built: a signature of what it was built from, and per
	# grid column { cell, title, marker, mark } and { cell, field }; or,
	# without header rows, the cells of the ledge that draws the frame's
	# top. The footer is the ledge that draws its bottom.
	field $_header_signature = '';
	field @_header_cells;
	field @_filter_cells;
	field @_top_ledge_cells;
	field %_filter_text;
	field %_filter_error;
	field $_footer_signature = '';
	field @_footer_cells;

	# Whether the scrollbar column is shown: wanted, and the rows did not
	# fit in the last frame. The strips as dressed, by part, and the
	# column inside the header strip that fills the header rows'
	# backgrounds, with what it was filled from.
	field $_gutter_shown = 0;
	field %_strip_dressed;
	field $_header_fills;
	field $_header_fills_signature = '';

	# The body as built: the signature of its columns, the lines by key
	# (see _build_line) and the order of the grid's rows.
	field $_body_signature = '';
	field %_built;
	field @_grid_keys;

	# What a search marked, by "id\0column": for a text cell the ranges
	# and the row revision they were set at, for a custom cell the
	# highlights of the widgets inside it, [ index, key, ranges ] by the
	# index and key.
	field %_text_highlights;
	field %_cell_highlights;

	# The grid lines as last worked out (per line, and the strips of the
	# scrollbar column), what they were worked out from, and a count that
	# tells the lines' looks they changed. Changes of styles count in
	# _style_revision.
	field $_borders_signature  = '';
	field $_borders            = [];
	field $_strip_borders      = undef;
	field $_borders_generation = 0;
	field $_style_revision     = 0;

	field %_row_style_of;    # row id => style hash
	field %_cell_style_of;    # "id\0key" => style hash
	field $_hover_key;
	field $_header_cursor;    # grid column index while the header has the keyboard, else undef
	field $_last_press_key;    # the line of the last single left press, which a double click must repeat
	field $_shown_page = 0;

	method theme_family :common () {
		return 'table';
	}

	# The colors come from the theme's table family unless given. The
	# table draws its frame itself, so it takes no bordered and has no
	# border.enabled from the theme.
	method themed_params :common () {
		my %box = $class->SUPER::themed_params;
		delete $box{bordered};
		return (
			%box,
			stripe_color => [ 'stripe', 'normal', 'optional_color' ],
			map { $_ => [ $COLOR_SLOT{$_}, 'normal', 'color' ] } @COLOR_PARAMS,
		);
	}

	sub BUILDARGS ( $class, %params ) {
		_no_bordered($class) if exists $params{bordered};
		return $class->SUPER::BUILDARGS(%params);
	}

	sub _no_bordered ($owner) {
		die( ( ref $owner || $owner )
			. ": a table takes no bordered; it draws its frame itself, in the style of border (or border_top, border_right, border_bottom and border_left), and 'none' leaves a side out" );
	}

	method bordered :override (@new) {
		_no_bordered($self) if @new;
		return $self->SUPER::bordered;
	}

	# No Box border around the table's own frame.
	method _bordered_sides :override () {
		return \%NO_BOX_BORDER;
	}

	# The cells, the pager and the scrollbar copy the colors
	# (Term::Fabulous::Role::Themed).
	method looks_changed (@names) {
		$self->_colors_changed(@names);
		return;
	}

	ADJUST {
		my $id = $self->id;
		die "Term::Fabulous::Widget::Table: a table needs an id (its body keeps its scroll position by it)" unless defined $id;

		$self->_check_parameters;
		$model = Term::Fabulous::Widget::Table::Model->new(
			row_id       => $row_id,
			children_key => $children_key,
			page_size    => $initial_page_size,
			expand_new   => $tree_expanded,
		);
		$model->add_column($_) foreach @$initial_columns;
		$model->set_rows($initial_rows);
		$model->set_sort( _sort_spec($initial_sort) );
		$model->group_by( ref $initial_group eq 'ARRAY' ? @$initial_group : $initial_group ) if defined $initial_group;
		( $initial_columns, $initial_rows, $initial_sort, $initial_group ) = ();

		$self->_build_frame;
		$self->_listen;
		$self->_watch_gutter;
		$self->request_prepare;
	}

	method _check_parameters () {
		one_of( $self, selection => $selection, @SELECTIONS );
		$_explicit_selection_column = boolean( $self, selection_column => $selection_column ) if defined $selection_column;
		$selection_column           = $_explicit_selection_column // ( $selection eq 'multiple' ? 1 : 0 );
		$show_header                = boolean( $self, header        => $show_header );
		$filter_row                 = boolean( $self, filter_row    => $filter_row );
		$scrollbar                  = boolean( $self, scrollbar     => $scrollbar );
		$hover                      = boolean( $self, hover         => $hover );
		$tree_expanded              = boolean( $self, tree_expanded => $tree_expanded );
		$show_pager                 = boolean( $self, pager         => $show_pager ) if defined $show_pager;
		die "Term::Fabulous::Widget::Table: page_sizes must be an array reference of positive integers, got " . describe($page_sizes)
			unless ref $page_sizes eq 'ARRAY' && @$page_sizes && !grep { !defined || ref || !/\A[1-9][0-9]*\z/ } @$page_sizes;
		$page_sizes = [ map { $_ + 0 } @$page_sizes ];

		foreach my $code ( [ group_label => $group_label ], [ row_style => $row_style ] ) {
			die "Term::Fabulous::Widget::Table: $code->[0] must be a code reference, got " . describe( $code->[1] )
				if defined $code->[1] && ref $code->[1] ne 'CODE';
		}
		$header_style  = style_hash( $self, 'header_style', row => $header_style );
		$group_style   = style_hash( $self, 'group_style',  row => $group_style );
		$empty_text    = string( $self, empty_text    => $empty_text );
		$no_match_text = string( $self, no_match_text => $no_match_text );
		$cell_padding  = $self->_padding($cell_padding);

		my $outer = optional( \&border_style, $self, border => $border, @NONE_IS_HIDDEN );
		my %line  = (
			border_top    => $border_top,
			border_right  => $border_right,
			border_bottom => $border_bottom,
			border_left   => $border_left,
			column_lines  => $column_lines,
			row_lines     => $row_lines,
			header_line   => $header_line,
		);
		foreach my $name (@LINE_PARAMS) {
			my $value = $line{$name} // ( $name =~ /\Aborder_/ ? $outer : undef );
			$_line_style{$name} = optional( \&border_style, $self, $name => $value, @NONE_IS_HIDDEN );
		}
		return;
	}

	sub _sort_spec ($spec) {
		die "Term::Fabulous::Widget::Table: sort must be an array reference of column keys or [ key, 'asc' or 'desc' ] pairs, got " . describe($spec)
			unless ref $spec eq 'ARRAY';
		return @$spec;
	}

	method _padding ($padding) {
		return { left => $padding, right => $padding, top => 0, bottom => 0 } if !ref $padding && defined $padding && $padding =~ /\A[0-9]+\z/;
		die "Term::Fabulous::Widget::Table: cell_padding must be a number of cells or a hash reference of left, right, top and bottom, got " . describe($padding)
			unless ref $padding eq 'HASH' && !grep { !/\A(?:left|right|top|bottom)\z/ } keys %$padding;
		return { map { $_ => non_negative_integer( $self, "cell_padding $_", $padding->{$_} // 0 ) } qw(left right top bottom) };
	}

	# ---------------------------------------------------------------------
	# The frame of widgets: header, body with scrollbar, pager
	# ---------------------------------------------------------------------

	method _build_frame () {
		my $layout = $self->layout;
		$self->layout(
			{
				%$layout,
				layout_direction => CLAY_TOP_TO_BOTTOM,
				sizing           => { width => sizing_fit(), height => sizing_fit(), %{ $layout->{sizing} // {} } },
			}
		);

		my $id = $self->id;
		$_body = Term::Fabulous::Widget::ScrollBox->new(
			id         => "$id/body",
			vertical   => 1,
			horizontal => 1,
			scrollbar  => 0,
			layout     => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_fit() } },
		);
		$_header_grid = Term::Fabulous::Widget::Table::Grid->new( layout => { sizing => { width => sizing_grow(), height => sizing_fit() } } );
		$_body_grid   = Term::Fabulous::Widget::Table::Grid->new( layout => { sizing => { width => sizing_grow(), height => sizing_fit() } }, share_columns_with => $_header_grid );
		$_body->add_child($_body_grid);

		$_footer_grid = Term::Fabulous::Widget::Table::Grid->new( layout => { sizing => { width => sizing_grow(), height => sizing_fit() } }, share_columns_with => $_header_grid );
		( $_header_view, $_footer_view ) = map { Term::Fabulous::Widget::Table::EdgeView->new( follows => $_body, layout => { sizing => { width => sizing_grow(), height => sizing_fit() } } ) } 1 .. 2;
		$_header_view->add_child($_header_grid);
		$_footer_view->add_child($_footer_grid);

		$_scrollbar = Term::Fabulous::Widget::Scrollbar->new(
			follows     => $_body,
			thumb_color => $self->text_color,
			track_color => $self->line_color,
			layout      => { sizing => { width => sizing_fixed(1), height => sizing_grow() } },
		);
		$_header_fills = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_fixed(1), height => sizing_grow() } } );
		$_header_strip = _new_strip($_header_fills);
		$_body_strip   = _new_strip($_scrollbar);
		$_footer_strip = _new_strip( Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_fixed(1), height => sizing_fit() } } ) );

		( $_header_row, $_body_row, $_footer_row ) = map { _new_row($_) } $_header_view, $_body, $_footer_view;
		$_pager = $self->_new_pager;
		$self->_wire_pager;
		$self->add_child( $_header_row, $_body_row, $_footer_row );
		return;
	}

	sub _new_row ($view) {
		my $row = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_LEFT_TO_RIGHT, sizing => { width => sizing_grow(), height => sizing_fit() } } );
		$row->add_child($view);
		return $row;
	}

	# A strip of the scrollbar column: its content (a blank column or the
	# scrollbar) and, once dressed, the frame's right side.
	sub _new_strip ($content) {
		my $strip = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_fit(), height => sizing_grow() } } );
		$strip->add_child($content);
		return $strip;
	}

	method _new_pager () {
		return Term::Fabulous::Widget::Table::Pager->new(
			page_sizes   => $page_sizes,
			text_color   => $self->text_color,
			muted_color  => $self->muted_color,
			button_color => $self->look('pager.button'),
		);
	}

	# A new pager, for new page sizes or colors; prepare_layout shows it.
	method _rebuild_pager () {
		my $old = $_pager;
		$_pager = $self->_new_pager;
		$self->_wire_pager;
		$self->remove_child($old);
		return;
	}

	method _wire_pager () {
		my %step = ( first => sub ($self) { 1 }, previous => sub ($self) { $self->page - 1 }, next => sub ($self) { $self->page + 1 }, last => sub ($self) { $self->page_count } );
		foreach my $name ( sort keys %step ) {
			$_pager->button($name)->on( Activate => sub ( $self, $event ) { $self->_turn_page( $step{$name}->($self) ); return }, owner => $self );
		}
		$_pager->size_list->on( Change => sub ( $self, $event ) { $self->_change_page_size( $event->value ); return }, owner => $self );
		return;
	}

	# The grid columns: the selection column, then the visible columns.
	method _grid_columns () {
		my @columns = map { { key => $_->key, column => $_ } } $model->visible_columns;
		unshift @columns, { key => SELECT_COLUMN, column => undef } if $selection_column && $selection ne 'none';
		return @columns;
	}

	# The column that shows the tree: tree_column, or the first visible one.
	method _tree_column_key () {
		return undef unless defined $model->children_key;
		return $tree_column if defined $tree_column && $model->has_column($tree_column) && $model->is_column_visible($tree_column);
		my ($first) = $model->visible_columns;
		return defined $first ? $first->key : undef;
	}

	# ---------------------------------------------------------------------
	# Preparing the widgets for a frame
	# ---------------------------------------------------------------------

	method _changed () {
		$self->request_prepare;
		return;
	}

	# A change of looks or lines every cell may show.
	method _restyle () {
		$_style_revision++;
		$self->request_prepare;
		return;
	}

	# A focused widget in a cell that is built again or removed hands the
	# focus to its focus heir, the table.
	method prepare_layout () {
		my @grid_columns = $self->_grid_columns;
		my @lines        = $self->_body_lines;
		$self->_prepare_width( \@grid_columns );
		$self->_prepare_gutter;
		$self->_prepare_header( \@grid_columns );
		$self->_prepare_footer( \@grid_columns );
		$self->_prepare_body( \@grid_columns, \@lines );
		$self->_dress( \@grid_columns, \@lines );
		$self->_prepare_pager;
		$self->_prepare_scrolling;
		return;
	}

	# The grids are as wide as their columns, unless a column grows (or is
	# a share of the width): then they take the width of the table, and the
	# body no longer scrolls sideways, since Clay squeezes the columns (and
	# wraps their text) only inside a box that does not clip them.
	method _prepare_width ($grid_columns) {
		my $stretch = any {
			my $type = defined $_->{column} ? $_->{column}->width->{type} : -1;
			$type == CLAY__SIZING_TYPE_GROW || $type == CLAY__SIZING_TYPE_PERCENT;
		} @$grid_columns;
		my $width = $stretch ? sizing_grow() : sizing_fit();
		foreach my $widget ( $_header_row, $_header_view, $_header_grid, $_body_row, $_body, $_body_grid, $_footer_row, $_footer_view, $_footer_grid ) {
			my $layout = $widget->layout;
			next if _same( $layout->{sizing}{width}, $width );
			$widget->layout( { %$layout, sizing => { %{ $layout->{sizing} // {} }, width => $width } } );
		}
		my $sideways = $stretch ? 0 : 1;
		$_body->horizontal($sideways) if $_body->horizontal != $sideways;
		return;
	}

	# The lines of the page, or the one line of an empty view.
	method _body_lines () {
		my @lines = $model->page_lines;
		return @lines if @lines;
		return { kind => 'empty', key => EMPTY_LINE };
	}

	method _prepare_header ($grid_columns) {
		my $signature = join "\0", $model->columns_revision, $show_header, $filter_row, $selection, map { $_->{key} } @$grid_columns;
		return if $signature eq $_header_signature;
		$_header_signature = $signature;
		$_header_grid->clear_rows;
		@_header_cells = @_filter_cells = ();
		if ($show_header) {
			@_header_cells = map { $self->_header_cell($_) } @$grid_columns;
			$_header_grid->append_row( [ map { $_->{cell} } @_header_cells ] ) if @_header_cells;
		}
		if ($filter_row) {
			@_filter_cells = map { $self->_filter_cell($_) } @$grid_columns;
			$_header_grid->append_row( [ map { $_->{cell} } @_filter_cells ] ) if @_filter_cells;
		}

		# Without header rows, the frame's top is a ledge, which also keeps
		# the header grid, and with it the body, as wide as the columns.
		@_top_ledge_cells = @_header_cells || @_filter_cells ? () : map { { cell => $self->_ledge_cell($_) } } @$grid_columns;
		$_header_grid->append_row( [ map { $_->{cell} } @_top_ledge_cells ] ) if @_top_ledge_cells;
		return;
	}

	# The footer: the ledge that draws the frame's bottom.
	method _prepare_footer ($grid_columns) {
		my $signature = join "\0", $model->columns_revision, $selection, map { $_->{key} } @$grid_columns;
		return if $signature eq $_footer_signature;
		$_footer_signature = $signature;
		$_footer_grid->clear_rows;
		@_footer_cells = map { { cell => $self->_ledge_cell($_) } } @$grid_columns;
		$_footer_grid->append_row( [ map { $_->{cell} } @_footer_cells ] );
		return;
	}

	# A cell of a ledge: a child of no height inside (Clay gives a childless
	# box no height, border or not), so it is as high as the one frame side
	# it draws.
	method _ledge_cell ($grid_column) {
		my $column = $grid_column->{column};
		my $cell   = Term::Fabulous::Widget::Table::Cell->new(
			part       => 'ledge',
			column_key => $grid_column->{key},
			layout     => { sizing => { width => defined $column ? $column->width : sizing_fit(), height => sizing_fit() } },
		);
		$cell->add_child( Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow(), height => sizing_fixed(0) } } ) );
		return $cell;
	}

	method _new_cell ( $part, $line_key, $column_key, $column ) {
		my $align = defined $column ? ( $part eq 'header' ? $column->header_align : $column->align ) : 'left';
		return Term::Fabulous::Widget::Table::Cell->new(
			part       => $part,
			line_key   => $line_key,
			column_key => $column_key,
			layout     => {
				sizing          => { width => defined $column ? $column->width : sizing_fit(), height => sizing_fit() },
				padding         => {%$cell_padding},
				child_alignment => { x => $ALIGN_X{$align}, y => CLAY_ALIGN_Y_TOP },
			},
		);
	}

	method _header_cell ($grid_column) {
		my $column = $grid_column->{column};
		my $cell   = $self->_new_cell( header => undef, $grid_column->{key}, $column );
		unless ( defined $column ) {
			my $mark = Term::Fabulous::Widget::Text->new( text => MARK_UNCHECKED );
			$cell->add_child($mark);
			return { cell => $cell, mark => $mark };
		}
		my $marker = Term::Fabulous::Widget::Text->new( text => '', wrap_mode => CLAY_TEXT_WRAP_NONE );
		my $title;
		my $content;
		if ( defined $column->header ) {
			$content = _widget_from( "column '" . $column->key . "' header", $column->header->($column) );
		}
		else {
			$content = $title = Term::Fabulous::Widget::Text->new( text => $column->title, wrap_mode => $WRAP{ $column->wrap }, text_alignment => $TEXT_ALIGN{ $column->header_align } );
		}
		my $row = Term::Fabulous::Widget::Box->new;
		$row->add_child( $content, $marker );
		$cell->add_child($row);
		return { cell => $cell, title => $title, marker => $marker };
	}

	method _filter_cell ($grid_column) {
		my $column = $grid_column->{column};
		my $cell   = $self->_new_cell( filter => undef, $grid_column->{key}, $column );
		return { cell => $cell } unless defined $column && $column->filterable;
		my $key   = $column->key;
		my $field = Term::Fabulous::Widget::TextField->new(
			value                  => $_filter_text{$key} // '',
			placeholder            => "\x{2026}",
			text_color             => $self->text_color,
			focus_background_color => $self->cursor_color,
			layout                 => { sizing => { width => sizing_grow(0) } },    # one row high, as wide as the column
		);
		$field->on( Change => sub ( $self, $event ) { $self->_filter_typed( $key, $event->value ); return }, owner => $self );
		$field->on( Submit => sub ( $self, $event ) { $self->_focus_self;                          return }, owner => $self );
		$cell->add_child($field);
		return { cell => $cell, field => $field };
	}

	sub _widget_from ( $what, $widget ) {
		die "Term::Fabulous::Widget::Table: $what must return a widget, got " . describe($widget)
			unless is_widget($widget);
		return $widget;
	}

	# ---------------------------------------------------------------------
	# The body: one grid row per line of the page
	# ---------------------------------------------------------------------

	method _prepare_body ( $grid_columns, $lines ) {
		my $signature = join "\0", $model->columns_revision, $selection, map { $_->{key} } @$grid_columns;
		if ( $signature ne $_body_signature ) {
			$_body_signature = $signature;
			$_body_grid->clear_rows;
			%_built     = ();
			@_grid_keys = ();
		}

		my ( %wanted, %rebuilt );
		foreach my $line (@$lines) {
			my $key   = $line->{key};
			my $built = $_built{$key};
			$wanted{$key} = 1;
			if ( !defined $built || !$self->_still_fits( $built, $line ) ) {
				$_built{$key}  = $self->_build_line( $line, $grid_columns );
				$rebuilt{$key} = 1 if defined $built;
				next;
			}
			$built->{line} = $line;
			$self->_refresh_row( $built, $grid_columns ) if $line->{kind} eq 'row' && $built->{revision} != $model->row_revision( $line->{id} );
		}

		my @gone = grep { !$wanted{ $_grid_keys[$_] } || $rebuilt{ $_grid_keys[$_] } } 0 .. $#_grid_keys;
		$_body_grid->remove_row($_) foreach reverse @gone;
		my %gone_index = map { $_ => 1 } @gone;
		@_grid_keys = map { $_grid_keys[$_] } grep { !$gone_index{$_} } 0 .. $#_grid_keys;
		delete @_built{ grep { !$wanted{$_} } keys %_built };

		my %placed = map { $_ => 1 } @_grid_keys;
		foreach my $line ( grep { !$placed{ $_->{key} } } @$lines ) {
			my $built = $_built{ $line->{key} };
			$built->{spanning} ? $_body_grid->append_spanning_row( $built->{cells}[0] ) : $_body_grid->append_row( $built->{cells} );
			push @_grid_keys, $line->{key};
		}

		my %index_of = map { $_grid_keys[$_] => $_ } 0 .. $#_grid_keys;
		my @order    = map { $index_of{ $_->{key} } } @$lines;
		$_body_grid->reorder_rows( \@order ) if join( ',', @order ) ne join( ',', 0 .. $#order );
		@_grid_keys = map { $_->{key} } @$lines;
		return;
	}

	# Whether a line built earlier can show the line now (its contents are
	# refreshed separately).
	method _still_fits ( $built, $line ) {
		return 0 if $built->{kind} ne $line->{kind};
		return 1 unless $line->{kind} eq 'row';
		return $built->{depth} == $line->{depth} ? 1 : 0;
	}

	method _build_line ( $line, $grid_columns ) {
		return $self->_build_row( $line, $grid_columns ) if $line->{kind} eq 'row';
		return $self->_build_group($line) if $line->{kind} eq 'group';
		my $cell = $self->_new_cell( body => $line->{key}, undef, undef );
		my $text = Term::Fabulous::Widget::Text->new( text => $model->is_filtered && $model->row_count ? $no_match_text : $empty_text );
		$cell->add_child($text);
		$cell->layout( { %{ $cell->layout }, sizing => { width => sizing_percent(1), height => sizing_fit() } } );
		return { kind => 'empty', line => $line, spanning => 1, cells => [$cell], label => $text };
	}

	# The hash a column's cell, update_cell and cell_style get.
	method _cell_context ( $id, $column ) {
		my $key = $column->key;
		return {
			value   => $model->value_of( $id, $key ),
			display => $model->display_of( $id, $key ),
			row     => $model->data_of($id),
			id      => $id,
			column  => $column,
			table   => $self,
		};
	}

	method _build_row ( $line, $grid_columns ) {
		my $id       = $line->{id};
		my $tree_key = $self->_tree_column_key;
		my %built    = ( kind => 'row', line => $line, id => $id, depth => $line->{depth}, revision => $model->row_revision($id), cells => [], content => {}, text => {}, holder => {} );
		foreach my $grid_column (@$grid_columns) {
			my ( $key, $column ) = @{$grid_column}{qw(key column)};
			my $cell = $self->_new_cell( body => $line->{key}, $key, $column );
			push @{ $built{cells} }, $cell;
			unless ( defined $column ) {
				$built{mark} = Term::Fabulous::Widget::Text->new( text => MARK_UNCHECKED );
				$cell->add_child( $built{mark} );
				next;
			}
			my $content = $self->_cell_content( \%built, $column );
			my $holder  = $cell;
			if ( defined $tree_key && $key eq $tree_key ) {
				$holder            = Term::Fabulous::Widget::Box->new( layout => { padding => { left => INDENT * $line->{depth} } } );
				$built{toggle_box} = Term::Fabulous::Widget::Table::Toggle->new( line_key => $line->{key} );
				$built{toggle}     = Term::Fabulous::Widget::Text->new( text => LEAF, wrap_mode => CLAY_TEXT_WRAP_NONE );
				$built{toggle_box}->add_child( $built{toggle} );
				$holder->add_child( $built{toggle_box} );
				$cell->add_child($holder);
			}
			$holder->add_child($content);
			$built{holder}{$key} = $holder;
		}
		return \%built;
	}

	# The widget showing a cell: the column's cell widget, or a Text. The
	# highlights a search left for the cell go onto the new widget.
	method _cell_content ( $built, $column ) {
		my $key  = $column->key;
		my $slot = "$built->{id}\0$key";
		if ( defined $column->cell ) {
			my $widget = _widget_from( "the cell of column '$key'", $column->cell->( $self->_cell_context( $built->{id}, $column ) ) );
			delete $built->{text}{$key};
			my @searchables = searchables_in($widget);
			nested_highlight_text( \@searchables, [ $_->[0], $_->[1] ], $_->[2] ) foreach values %{ $_cell_highlights{$slot} // {} };
			return $built->{content}{$key} = $widget;
		}
		my $text = Term::Fabulous::Widget::Text->new(
			text           => $model->display_of( $built->{id}, $key ),
			wrap_mode      => $WRAP{ $column->wrap },
			text_alignment => $TEXT_ALIGN{ $column->align },
		);
		my $kept = $_text_highlights{$slot};
		$text->highlights( $kept->{ranges} ) if defined $kept && $kept->{revision} == $model->row_revision( $built->{id} );
		$built->{text}{$key} = $text;
		return $built->{content}{$key} = $text;
	}

	# A row whose data changed: texts are updated, cell widgets brought up
	# to date by update_cell or built again. What a search marked in the
	# row pointed into the old data and goes.
	method _refresh_row ( $built, $grid_columns ) {
		$built->{revision} = $model->row_revision( $built->{id} );
		$self->_drop_row_highlights( $built->{id} );
		foreach my $column ( map { $_->{column} } grep { defined $_->{column} } @$grid_columns ) {
			my $key = $column->key;
			if ( my $text = $built->{text}{$key} ) {
				_set( $text, text => $model->display_of( $built->{id}, $key ) );
				next;
			}
			if ( defined $column->update_cell ) {
				$column->update_cell->( $built->{content}{$key}, $self->_cell_context( $built->{id}, $column ) );
				next;
			}
			my $holder = $built->{holder}{$key};
			my $old    = $built->{content}{$key};
			$holder->remove_child($old);
			$holder->add_child( $self->_cell_content( $built, $column ) );
		}
		return;
	}

	method _build_group ($line) {
		my $cell = $self->_new_cell( body => $line->{key}, undef, undef );
		$cell->layout( { %{ $cell->layout }, sizing => { width => sizing_percent(1), height => sizing_fit() } } );
		my $holder = Term::Fabulous::Widget::Box->new( layout => { padding => { left => INDENT * $line->{depth} } } );
		my $toggle = Term::Fabulous::Widget::Table::Toggle->new( line_key => $line->{key} );
		my $glyph  = Term::Fabulous::Widget::Text->new( text => OPEN, wrap_mode => CLAY_TEXT_WRAP_NONE );
		$toggle->add_child($glyph);
		$holder->add_child($toggle);
		$cell->add_child($holder);
		my %built = ( kind => 'group', line => $line, spanning => 1, cells => [$cell], holder => $holder, toggle => $glyph, toggle_box => $toggle, label_signature => '' );
		$self->_refresh_group_label( \%built );
		return \%built;
	}

	# The label of a group header: group_label's text or widget, or
	# "Title: value (count)".
	method _refresh_group_label ($built) {
		my $line      = $built->{line};
		my $signature = join "\0", $line->{display}, $line->{count};
		return if $signature eq $built->{label_signature};
		$built->{label_signature} = $signature;
		my $label = defined $group_label ? $group_label->( $self->_group_context($line) ) : $self->_default_group_label($line);
		if ( !ref $label && defined $built->{label} && $built->{label}->isa('Term::Fabulous::Widget::Text') ) {
			_set( $built->{label}, text => $label );
			return;
		}
		my $widget = ref $label ? _widget_from( 'group_label', $label ) : Term::Fabulous::Widget::Text->new( text => $label // '', bold => 1 );
		$built->{holder}->remove_child( $built->{label} ) if defined $built->{label};
		$built->{holder}->add_child($widget);
		$built->{label} = $widget;
		return;
	}

	method _group_context ($line) {
		return {
			column  => $model->column( $line->{column} ),
			value   => $line->{value},
			display => $line->{display},
			count   => $line->{count},
			path    => [ @{ $line->{path} } ],
			depth   => $line->{depth},
			ids     => [ @{ $line->{ids} } ],
			table   => $self,
		};
	}

	method _default_group_label ($line) {
		my $title = $model->column( $line->{column} )->title;
		my $shown = length $line->{display} ? $line->{display} : '(empty)';
		return "$title: $shown ($line->{count})";
	}

	# ---------------------------------------------------------------------
	# Dressing: colors, lines and markers of every cell
	# ---------------------------------------------------------------------

	# Sets a property only when it differs, so preparing a table that did
	# not change makes no further frame due.
	sub _set ( $widget, $property, $value ) {
		my $current = $widget->$property;
		return if _same( $current, $value );
		$widget->$property($value);
		return;
	}

	sub _same ( $left, $right ) {
		return !defined $right unless defined $left;
		return 0 unless defined $right;
		return _flat($left) eq _flat($right);
	}

	sub _flat ($value) {
		return "$value" unless ref $value;
		return 'S' . refaddr($value) if blessed $value;
		return 'A' . join( "\x{1F}", map { _flat($_) } @$value ) if ref $value eq 'ARRAY';
		return 'H' . join( "\x{1F}", map { "$_=" . _flat( $value->{$_} ) } sort keys %$value );
	}

	# Whether the keyboard is in the table: the table or a widget of its
	# body has the focus, not the header, the column chooser or the pager.
	method _has_focus_within () {
		my $ui          = $self->ui // return 0;
		my $interaction = $ui->interaction;
		return 0 unless $interaction->has_focus_within($self);
		return ( none { $interaction->has_focus_within($_) } grep { defined } $_header_view, $_chooser, $_pager ) ? 1 : 0;
	}

	method _row_style_for ($id) {
		my $dynamic = defined $row_style ? style_hash( $self, 'row_style result', row => $row_style->( $model->data_of($id), $id ) ) : {};
		return merge_styles( $_row_style_of{$id}, $dynamic );
	}

	method _cell_style_for ( $id, $column ) {
		my $static  = $_cell_style_of{ $id . "\0" . $column->key };
		my $dynamic = defined $column->cell_style ? style_hash( $self, "column '" . $column->key . "' cell_style result", cell => $column->cell_style->( $self->_cell_context( $id, $column ) ) ) : {};
		return merge_styles( $static, $dynamic );
	}

	# Whether styles depend on the data of rows (row_style, a column's
	# cell_style): then a change of a row may change its lines and looks.
	method _styles_follow_data ($grid_columns) {
		return 1 if defined $row_style;
		return ( any { defined $_->{column} && defined $_->{column}->cell_style } @$grid_columns ) ? 1 : 0;
	}

	# Colors, lines and marks of every cell. The grid lines are worked out
	# again only when something they depend on changed; a body line is
	# dressed again only when its look, the backgrounds of the lines next
	# to it (see _line_backdrops) or the lines changed, so moving the
	# cursor dresses the two lines and their neighbours.
	method _dress ( $grid_columns, $lines ) {
		my $follows_data = $self->_styles_follow_data($grid_columns);
		my @header_rows  = $self->_header_rows;
		my $signature    = join "\0", $model->columns_revision, $_style_revision, $_gutter_shown, scalar @header_rows, scalar @$grid_columns,
			map { $_->{key} . ( $follows_data && $_->{kind} eq 'row' ? ':' . $model->row_revision( $_->{id} ) : '' ) } @$lines;
		if ( $signature ne $_borders_signature ) {
			$_borders_signature = $signature;
			my $resolved = $self->_resolve_lines( $grid_columns, \@header_rows, $lines );
			( $_borders, $_strip_borders ) = @{$resolved}{qw(lines gutter)};
			$_borders_generation++;
		}

		my $column_count = scalar @$grid_columns;
		my $ledge_look   = $self->_ledge_look;
		my @header_looks = map {
			my ( $cells, $part ) = @$_;
			[ map { $part eq 'header' ? $self->_header_look( $_, $grid_columns->[$_] ) : $part eq 'filter' ? $self->_filter_look( $cells->[$_], $grid_columns->[$_] ) : $ledge_look } 0 .. $#$cells ]
		} @header_rows;
		my @footer_looks = ($ledge_look) x $column_count;

		my $focused    = $self->_has_focus_within;
		my $cursor     = $model->cursor;
		my $data_index = 0;
		foreach my $line (@$lines) {
			my $built = $_built{ $line->{key} };
			my $state
				= $focused               && !defined $_header_cursor && defined $cursor && $cursor eq $line->{key} ? 'cursor'
				: $line->{kind} eq 'row' && $model->is_selected( $line->{id} ) ? 'selected'
				: $hover                 && defined $_hover_key && $_hover_key eq $line->{key} ? 'hover'
				:                                                                                '';
			my $stripe   = $line->{kind} eq 'row' && defined $self->stripe_color && $data_index++ % 2 ? 1 : 0;
			my $look_key = join "\0", $_borders_generation, $state, $stripe, $self->_line_look_key($line);
			next if defined $built->{look_key} && $built->{look_key} eq $look_key;
			$built->{look_key}    = $look_key;
			$built->{looks}       = $self->_line_looks( $line, $grid_columns, $state, $stripe );
			$built->{backgrounds} = _backgrounds( $built->{looks}, $column_count );
		}

		my @backgrounds  = ( ( map { _backgrounds( $_, $column_count ) } @header_looks ), ( map { $_built{ $_->{key} }{backgrounds} } @$lines ), _backgrounds( \@footer_looks, $column_count ) );
		my $base         = $self->_base_background;
		my $backdrops_of = sub ($at) {
			my $borders = $_borders->[$at];
			my @spans   = @$borders == $column_count ? map { [ $_, $_ ] } 0 .. $column_count - 1 : ( [ 0, $column_count - 1 ] );
			return [ map { _line_backdrops( \@backgrounds, scalar @header_rows, $at, @{ $spans[$_] }, $borders->[$_], $base ) } 0 .. $#$borders ];
		};

		foreach my $index ( 0 .. $#header_rows ) {
			my $cells     = $header_rows[$index][0];
			my $backdrops = $backdrops_of->($index);
			foreach my $column ( 0 .. $#$cells ) {
				$self->_dress_cell( $cells->[$column]{cell}, $header_looks[$index][$column], $_borders->[$index][$column], $backdrops->[$column], \$cells->[$column]{dressed} );
			}
		}
		$self->_mark_header($grid_columns) if @_header_cells;

		my $footer_at        = @header_rows + @$lines;
		my $footer_backdrops = $backdrops_of->($footer_at);
		$self->_dress_cell( $_footer_cells[$_]{cell}, $footer_looks[$_], $_borders->[$footer_at][$_], $footer_backdrops->[$_], \$_footer_cells[$_]{dressed} ) foreach 0 .. $#_footer_cells;
		$self->_dress_strips( \@header_rows, $base ) if $_gutter_shown;

		my @background_keys = map { join "\x{1F}", @$_ } @backgrounds;
		my $base_key        = _flat($base);
		foreach my $index ( 0 .. $#$lines ) {
			my ( $line, $at ) = ( $lines->[$index], @header_rows + $index );
			my $built     = $_built{ $line->{key} };
			my $dress_key = join "\0", $built->{look_key}, $base_key, map { $background_keys[$_] // '' } grep { $_ >= 0 } $at - 1, $at + 1;
			next if defined $built->{dress_key} && $built->{dress_key} eq $dress_key;
			$built->{dress_key} = $dress_key;
			$self->_dress_line( $built, $line, $grid_columns, $built->{looks}, $_borders->[$at], $backdrops_of->($at) );
		}
		return;
	}

	# The rows of the header grid as built, [ cells, part ] each: the
	# column titles and the filter row, or the ledge instead of both.
	method _header_rows () {
		return ( ( @_header_cells ? [ \@_header_cells, 'header' ] : () ), ( @_filter_cells ? [ \@_filter_cells, 'filter' ] : () ), ( @_top_ledge_cells ? [ \@_top_ledge_cells, 'ledge' ] : () ) );
	}

	# The strips of the scrollbar column: the frame's right side and the
	# lines that run on beside the header and the footer, on the table's
	# background. Inside the header strip, a blank column in the background
	# of each header row, so that the rows reach the frame.
	method _dress_strips ( $header_rows, $base ) {
		my $look  = { background_color => $base, border_color => $self->line_color };
		my %strip = ( header => $_header_strip, body => $_body_strip, footer => $_footer_strip );
		$self->_dress_cell( $strip{$_}, $look, $_strip_borders->{$_}, undef, \$_strip_dressed{$_} ) foreach sort keys %strip;

		my $filter_height = 1 + $cell_padding->{top} + $cell_padding->{bottom};
		my @fills         = map {
			my $part = $_->[1];
				  $part eq 'header' ? [ $header_style->{background_color} // $self->header_background_color, sizing_grow() ]
				: $part eq 'filter' ? [ $self->filter_background_color, sizing_fixed($filter_height) ]
				: ()
		} @$header_rows;
		my $signature = join "\0", map { _flat($_) } @fills;
		return if $signature eq $_header_fills_signature;
		$_header_fills_signature = $signature;
		$_header_fills->clear_children;
		$_header_fills->add_child( Term::Fabulous::Widget::Box->new( background_color => $_->[0], layout => { sizing => { width => sizing_grow(), height => $_->[1] } } ) ) foreach @fills;
		return;
	}

	# The background of every grid column of a line, as comparable keys: a
	# line across the table has one look for all columns.
	sub _backgrounds ( $looks, $column_count ) {
		my @keys = map { _flat( $_->{background_color} ) } @$looks;
		return @keys == 1 ? [ ( $keys[0] ) x $column_count ] : \@keys;
	}

	# A line between two cells of different backgrounds takes neither: the
	# drawn sides and corners of a cell inside the frame whose cells around
	# them do not all share one background get the table's background
	# ($base). The line below the header rows always does, as the body
	# scrolls under it. Takes the background keys of every line (header
	# rows first) per grid column, the number of header rows, the cell (its
	# line and first and last grid column) and its lines (from
	# resolve_borders); returns a hash for border_background_colors, or
	# undef when every line keeps the cell's own background.
	sub _line_backdrops ( $backgrounds, $header_lines, $line, $first, $last, $border, $base ) {
		my $sides      = $border->{sides};
		my %inside     = ( top => $line > 0, bottom => $line < $#$backgrounds, left => $first > 0, right => $last < $#{ $backgrounds->[$line] } );
		my %lines_of   = ( top => [ $line - 1, $line ], bottom => [ $line, $line + 1 ] );
		my %columns_of = ( left => [ $first - 1, $first ], right => [ $last, $last + 1 ] );
		my %backdrops;
		foreach my $name (qw(top bottom left right top_left top_right bottom_left bottom_right)) {
			my @parts = split /_/, $name;
			next unless all { $sides->{$_} && $inside{$_} } @parts;
			my ($across) = grep { $lines_of{$_} } @parts;
			my ($along)  = grep { $columns_of{$_} } @parts;
			my @lines    = defined $across ? @{ $lines_of{$across} }  : ($line);
			my @columns  = defined $along  ? @{ $columns_of{$along} } : ( $first .. $last );
			my @around   = map { @{ $backgrounds->[$_] }[@columns] } @lines;
			my $scrolls  = defined $across && $lines[0] == $header_lines - 1;
			next if !$scrolls && all { $_ eq $around[0] } @around;
			$backdrops{$name} = $base;
		}
		return %backdrops ? \%backdrops : undef;
	}

	# What else a line's look depends on.
	method _line_look_key ($line) {
		return join "\0", $model->row_revision( $line->{id} ), $line->{has_children}, $line->{expanded}, $model->is_selected( $line->{id} ) if $line->{kind} eq 'row';
		return join "\0", $line->{expanded}, $line->{count}, $line->{display} if $line->{kind} eq 'group';
		return $model->is_filtered && $model->row_count ? 'no match' : 'empty';
	}

	method _state_color ($state) {
		return $state eq 'cursor' ? $self->cursor_color : $state eq 'selected' ? $self->selected_color : $state eq 'hover' ? $self->hover_color : undef;
	}

	# The grid lines of the header rows, the lines and the footer, and the
	# strips of the scrollbar column while it is shown.
	method _resolve_lines ( $grid_columns, $header_rows, $lines ) {
		my @no_styles    = map { {} } @$grid_columns;
		my @border_lines = map { $_->[1] eq 'ledge' ? { ledge => 1, cells => [@no_styles] } : { style => $header_style, cells => [@no_styles] } } @$header_rows;
		foreach my $line (@$lines) {
			if ( $line->{kind} eq 'row' ) {
				my $id = $line->{id};
				push @border_lines, {
					style => $self->_row_style_for($id),
					cells => [ map { defined $_->{column} ? $self->_cell_style_for( $id, $_->{column} ) : {} } @$grid_columns ],
				};
				next;
			}
			push @border_lines, { spanning => 1, style => $line->{kind} eq 'group' ? $group_style : {}, cells => [ {} ] };
		}
		push @border_lines, { ledge => 1, cells => [@no_styles] };
		return resolve_borders(
			columns       => scalar @$grid_columns,
			header        => scalar @$header_rows,
			gutter        => $_gutter_shown,
			table         => \%_line_style,
			column_styles => [ map { defined $_->{column} ? $_->{column}->style : {} } @$grid_columns ],
			lines         => \@border_lines,
		);
	}

	# The look of every cell of a line: one per grid column for a data
	# row, one for a line across the table.
	method _line_looks ( $line, $grid_columns, $state, $stripe ) {
		my $state_color = $self->_state_color($state);
		return [ $line->{kind} eq 'group' ? $self->_group_look($state_color) : $self->_empty_look ] unless $line->{kind} eq 'row';
		my $id  = $line->{id};
		my $row = $self->_row_style_for($id);
		return [
			map {
				my $cell = defined $grid_columns->[$_]{column} ? $self->_cell_style_for( $id, $grid_columns->[$_]{column} ) : {};
				$self->_body_look( $state_color // ( $stripe ? $self->stripe_color : undef ), $row, $cell, $grid_columns->[$_]{column}, defined $state_color );
			} 0 .. $#$grid_columns
		];
	}

	method _dress_line ( $built, $line, $grid_columns, $looks, $borders, $backdrops ) {
		if ( $line->{kind} eq 'row' ) {
			$built->{dressed} //= [];
			$self->_dress_cell( $built->{cells}[$_], $looks->[$_], $borders->[$_], $backdrops->[$_], \$built->{dressed}[$_] ) foreach 0 .. $#$looks;
			$self->_mark_row( $built, $line, $grid_columns, $looks );
			return;
		}
		my $look = $looks->[0];
		$self->_dress_cell( $built->{cells}[0], $look, $borders->[0], $backdrops->[0], \$built->{dressed} );
		if ( $line->{kind} eq 'group' ) {
			$self->_refresh_group_label($built);
			_set( $built->{toggle}, text => $line->{expanded} ? OPEN : CLOSED );
			$self->_dress_text( $built->{toggle}, $look );
			_set( $built->{toggle_box}, background_color => $look->{background_color} );
		}
		else {
			_set( $built->{label}, text => $model->is_filtered && $model->row_count ? $no_match_text : $empty_text );
		}
		$self->_dress_text( $built->{label}, $look ) if defined $built->{label} && $built->{label}->isa('Term::Fabulous::Widget::Text');
		return;
	}

	method _header_look ( $index, $grid_column ) {
		my $column = $grid_column->{column};
		my $style  = merge_styles( defined $column ? $column->header_style : {}, $header_style );
		my $active = defined $_header_cursor && $_header_cursor == $index && $self->_has_focus_within;
		return {
			background_color => $active ? $self->cursor_color : $style->{background_color} // $self->header_background_color,
			text_color       => $style->{text_color}                                       // $self->header_text_color,
			bold             => $style->{bold}                                             // 1,
			italic           => $style->{italic}                                           // 0,
			underline        => $style->{underline}                                        // 0,
			border_color     => $style->{border_color}                                     // $self->line_color,
		};
	}

	method _filter_look ( $cell, $grid_column ) {
		my $column = $grid_column->{column};
		if ( defined $cell->{field} ) {
			my $error = defined $_filter_error{ $column->key };
			_set( $cell->{field}, text_color => $error ? $self->error_color : $self->text_color );
		}
		return { background_color => $self->filter_background_color, border_color => $self->line_color };
	}

	method _group_look ($state_color) {
		my $style = $group_style;
		return {
			background_color => $state_color           // $style->{background_color} // $self->group_background_color,
			text_color       => $style->{text_color}   // $self->group_text_color,
			bold             => $style->{bold}         // 1,
			italic           => $style->{italic}       // 0,
			underline        => $style->{underline}    // 0,
			border_color     => $style->{border_color} // $self->line_color,
		};
	}

	method _body_look ( $base_color, $row, $cell, $column, $state_wins ) {
		my $column_style = defined $column ? $column->style : {};
		my $look         = merge_styles( $cell, $row, $column_style );
		my $background   = ( $state_wins ? $base_color : $look->{background_color} // $base_color ) // $self->_base_background;
		return {
			background_color => $background,
			text_color       => $look->{text_color}   // $self->text_color,
			bold             => $look->{bold}         // 0,
			italic           => $look->{italic}       // 0,
			underline        => $look->{underline}    // 0,
			border_color     => $look->{border_color} // $self->line_color,
		};
	}

	# Gives a cell its look and lines, and the background of the lines it
	# draws between itself and cells of other backgrounds ($backdrops, see
	# _line_backdrops); $memo holds what it was given last time, so an
	# unchanged cell costs one string comparison.
	method _dress_cell ( $cell, $look, $border, $backdrops, $memo ) {
		my $sides      = $border->{sides};
		my %properties = (
			background_color         => $look->{background_color},
			border_background_colors => $backdrops,
			border_color             => $look->{border_color},
			bordered                 => { map { $_ => $sides->{$_} ? 1 : 0 } qw(top right bottom left) },
			border_corners           => %{ $border->{corners} } ? $border->{corners} : undef,
			outer_border_sides       => $border->{outer},
			map { ( "border_style_$_" => $sides->{$_} ) } qw(top right bottom left),
		);
		my $signature = join "\x{1E}", map { "$_=" . ( defined $properties{$_} ? _flat( $properties{$_} ) : '' ) } sort keys %properties;
		return if defined $$memo && $$memo eq $signature;
		$$memo = $signature;
		$cell->$_( $properties{$_} ) foreach sort keys %properties;
		return;
	}

	method _dress_text ( $text, $look ) {
		_set( $text, text_color => $look->{text_color} );
		_set( $text, $_         => $look->{$_} // 0 ) foreach qw(bold italic underline);
		return;
	}

	# The marks of a data row - the selection mark, the tree marker - and
	# the look of its texts.
	method _mark_row ( $built, $line, $grid_columns, $looks ) {
		my $tree_key = $self->_tree_column_key // "\0";
		foreach my $index ( 0 .. $#$grid_columns ) {
			my ( $key, $look ) = ( $grid_columns->[$index]{key}, $looks->[$index] );
			if ( $key eq SELECT_COLUMN ) {
				_set( $built->{mark}, text => $model->is_selected( $line->{id} ) ? MARK_CHECKED : MARK_UNCHECKED );
				$self->_dress_text( $built->{mark}, $look );
				next;
			}
			$self->_dress_text( $built->{text}{$key}, $look ) if defined $built->{text}{$key};
			next unless $key eq $tree_key && defined $built->{toggle};
			_set( $built->{toggle}, text => !$line->{has_children} ? LEAF : $line->{expanded} ? OPEN : CLOSED );
			$self->_dress_text( $built->{toggle}, $look );
			_set( $built->{toggle_box}, background_color => $look->{background_color} );
		}
		return;
	}

	method _ledge_look () {
		return { background_color => $self->_base_background, border_color => $self->line_color };
	}

	method _empty_look () {
		return { background_color => $self->_base_background, text_color => $self->muted_color, border_color => $self->line_color, italic => 1 };
	}

	# The color of cells that have none of their own: what the table lies
	# on (background_below), so the cells blend in; a fixed dark color only
	# where there is none (Term::Fabulous::Static, no UI). Cells are always
	# painted: only painted cells receive the mouse.
	method _base_background () {
		return $self->background_below // FALLBACK_BACKGROUND;
	}

	method _mark_header ($grid_columns) {
		my @sort = @{ $model->sort_spec };
		foreach my $index ( 0 .. $#_header_cells ) {
			my $cell = $_header_cells[$index];
			my $look = $self->_header_look( $index, $grid_columns->[$index] );
			if ( defined $cell->{mark} ) {
				_set( $cell->{mark}, text => $self->_select_all_mark );
				$self->_dress_text( $cell->{mark}, $look );
				next;
			}
			my $key     = $grid_columns->[$index]{key};
			my ($place) = grep { $sort[$_][0] eq $key } 0 .. $#sort;
			my $marker  = !defined $place ? '' : ' ' . ( $sort[$place][1] eq 'asc' ? SORT_UP : SORT_DOWN ) . ( @sort > 1 ? $place + 1 : '' );
			_set( $cell->{marker}, text => $marker );
			$self->_dress_text( $cell->{marker}, $look );
			$self->_dress_text( $cell->{title},  $look ) if defined $cell->{title};
		}
		return;
	}

	method _select_all_mark () {
		my @ids      = $model->filtered_row_ids;
		my $selected = grep { $model->is_selected($_) } @ids;
		return !@ids || !$selected ? MARK_UNCHECKED : $selected == @ids ? MARK_CHECKED : MARK_SOME;
	}

	# ---------------------------------------------------------------------
	# Scrollbar, pager, scrolling
	# ---------------------------------------------------------------------

	# The scrollbar column, while the rows did not fit in the last frame:
	# the strips beside the header, the body and the footer.
	method _prepare_gutter () {
		$_gutter_shown = $self->_gutter_wanted;
		_show_child( $_header_row, $_header_strip, $_gutter_shown );
		_show_child( $_body_row,   $_body_strip,   $_gutter_shown );
		_show_child( $_footer_row, $_footer_strip, $_gutter_shown );
		return;
	}

	method _gutter_wanted () {
		return 0 unless $scrollbar;
		my $ui    = $self->ui                 // return 0;
		my $state = $ui->scroll_state($_body) // return 0;
		return $state->{content}{height} > $state->{viewport}{height} ? 1 : 0;
	}

	# Whether the rows fit is known after a frame; one that changes it
	# prepares the next.
	method _watch_gutter () {
		$self->each_frame(
			sub ($table) {
				$table->request_prepare if $table->_gutter_wanted != $_gutter_shown;
				return 0;
			},
			name => 'gutter'
		);
		return;
	}

	sub _show_child ( $parent, $child, $show ) {
		$parent->remove_child($child) unless $show;
		$parent->add_child($child) if $show && !$parent->has_child($child);
		return;
	}

	method _pager_shown () {
		return $show_pager // ( $model->page_size > 0 ? 1 : 0 );
	}

	method _prepare_pager () {
		if ( !$self->_pager_shown ) {
			$self->remove_child($_pager);
			return;
		}
		$self->add_child($_pager) unless $self->has_child($_pager);
		my $size  = $model->page_size;
		my $total = $model->line_count;
		my $first = $size ? ( $model->page - 1 ) * $size + 1  : 1;
		my $last  = $size ? min( $total, $first + $size - 1 ) : $total;
		$_pager->show( page => $model->page, page_count => $model->page_count, page_size => $size || $total || 1, first => $first, last => $last, total => $total );
		return;
	}

	# A new page starts at the top.
	method _prepare_scrolling () {
		my $ui = $self->ui // return;
		return if $model->page == $_shown_page;
		$_shown_page = $model->page;
		$ui->scroll_to( $_body, { x => 0, y => 0 } );
		return;
	}

	# A cursor that moved is scrolled into view once the frame that lays
	# its line out is drawn: the line's cells may be new, or the last
	# frame put them elsewhere (a sort, a new page). Before the table is
	# in a UI, that is the first frame.
	method _reveal_cursor_after_frame () {
		$self->each_frame( sub ($table) { $table->_reveal_cursor_line; return 1 }, name => 'cursor' );
		return;
	}

	# The body reveals the first cell of the cursor's line.
	method _reveal_cursor_line () {
		my $built = $_built{ $model->cursor // '' } // return;
		$_body->reveal( $built->{cells}[0] );
		return;
	}

	# How many lines of the page fit into the body's viewport, for PageUp
	# and PageDown.
	method _page_step () {
		my $ui      = $self->ui                 // return DEFAULT_PAGE_STEP;
		my $state   = $ui->scroll_state($_body) // return DEFAULT_PAGE_STEP;
		my @heights = grep { defined } map { my $built = $_built{$_}; defined $built ? ( $ui->bounding_box( $built->{cells}[0] ) // {} )->{height} : undef } @_grid_keys;
		return DEFAULT_PAGE_STEP unless @heights;
		my $average = ( List::Util::sum(@heights) / @heights ) || 1;
		return max( 1, int( $state->{viewport}{height} / $average ) - 1 );
	}

	# ---------------------------------------------------------------------
	# Input
	# ---------------------------------------------------------------------

	method _listen () {
		$self->on( KeyPress  => sub ( $self, $event ) { return $self->_on_key($event) },                   owner => $self );
		$self->on( Mouse     => sub ( $self, $event ) { return $self->_on_mouse($event) },                 owner => $self );
		$self->on( MouseMove => sub ( $self, $event ) { $self->_on_mouse_move($event); return $CONTINUE }, owner => $self );
		foreach my $name (qw(OnFocus OnBlur)) {
			$self->on( $name => sub ( $self, $event ) { $self->_changed; return $CONTINUE }, owner => $self );
		}
		$self->on( OnHoverStopped => sub ( $self, $event ) { $self->_hover_line(undef) if refaddr( $event->target ) == refaddr($self); return $CONTINUE }, owner => $self );
		return;
	}

	# Which part of the table a widget belongs to.
	method _region_of ($widget) {
		my %region = ( refaddr($_body_row) => 'body', refaddr($_header_view) => 'header', refaddr($_pager) => 'pager', refaddr($self) => 'table' );
		$region{ refaddr $_chooser } = 'chooser' if defined $_chooser;
		my $part = $widget->closest( sub ($node) { exists $region{ refaddr $node } } ) // return 'table';
		return $region{ refaddr $part };
	}

	# Whether a widget between $widget and the table takes input of its own
	# (a button or a field in a cell).
	# A widget without a background of its own is not hit by the mouse: a
	# click on such a button makes its cell the target, so the widgets of
	# the cell under the pointer count, too.
	method _inside_input ($event) {
		my $target = $event->target;
		foreach my $node ( $target, $target->ancestors ) {
			last if refaddr($node) == refaddr($self);
			return 1 if _takes_input($node);
			return $self->_input_under_pointer( $node, $event->x, $event->y ) if $node->isa('Term::Fabulous::Widget::Table::Cell');
		}
		return 0;
	}

	sub _takes_input ($widget) {
		return $widget->DOES('Clay::UI::Role::Interaction::Pressable') || ( $widget->DOES('Clay::UI::Role::Interaction::Focusable') && $widget->can_focus ) ? 1 : 0;
	}

	method _input_under_pointer ( $widget, $x, $y ) {
		my $ui = $self->ui // return 0;
		return 0 unless $widget->can('children');
		foreach my $child ( @{ $widget->children } ) {
			my $box = $ui->bounding_box($child) // next;
			next unless $x >= $box->{x} && $x < $box->{x} + $box->{width} && $y >= $box->{y} && $y < $box->{y} + $box->{height};
			return 1 if _takes_input($child) || $self->_input_under_pointer( $child, $x, $y );
		}
		return 0;
	}

	method _on_key ($event) {
		my $name   = $event->key_name // return $CONTINUE;
		my $region = $self->_region_of( $event->target );
		if ( $region eq 'header' ) {
			return $self->_on_filter_key( $event, $name );
		}
		return $CONTINUE unless $region eq 'table' || $region eq 'body';
		return $self->_on_header_key($name) if defined $_header_cursor;
		my $from_cell = $region eq 'body' && refaddr( $event->target ) != refaddr($self);
		return $CONTINUE unless $self->_on_body_key( $name, $from_cell );
		$self->_focus_self if $from_cell;    # the keyboard follows the cursor out of the cell
		return $HANDLED;
	}

	method _on_filter_key ( $event, $name ) {
		if ( $name eq 'Down' ) {
			$self->_focus_self;
			return $HANDLED;
		}
		if ( $name eq 'Escape' ) {
			my ($cell) = grep { defined $_->{field} && refaddr( $_->{field} ) == refaddr( $event->target ) } @_filter_cells;
			return $CONTINUE unless defined $cell && length $cell->{field}->value;
			$cell->{field}->value('');
			$self->_filter_typed( $cell->{cell}->column_key, '' );
			return $HANDLED;
		}
		return $CONTINUE;
	}

	method _focus_self () {
		my $ui = $self->ui // return;
		$ui->interaction->set_focused_widget($self) if $self->can_focus;
		return;
	}

	# Keys on the rows. Returns whether the key was used. $from_cell: the
	# key comes from a widget inside a cell, which has used the keys it
	# wants; Space and Enter are left to it.
	method _on_body_key ( $name, $from_cell ) {
		my $cursor = $model->cursor;
		my $line   = defined $cursor ? $model->line($cursor) : undef;
		my %move   = (
			Up       => -1,
			Down     =>  1,
			PageUp   => -$self->_page_step,
			PageDown => $self->_page_step,
		);
		my $base   = $name =~ s/\AShift\+//r;
		my $extend = $base ne $name && $selection eq 'multiple';
		if ( exists $move{$base} && ( $base eq $name || $extend ) ) {
			return $self->_enter_header if $base eq 'Up' && defined $line && $self->_is_first_on_page($cursor) && !$extend && $self->_header_usable;
			$self->_move_within_page( $move{$base}, $extend );
			return 1;
		}
		if ( ( $base eq 'Home' || $base eq 'End' ) && ( $base eq $name || $extend ) ) {
			my @lines = $model->page_lines;
			return 1 unless @lines;
			$self->_move_cursor( ( $base eq 'Home' ? $lines[0] : $lines[-1] )->{key}, extend => $extend );
			return 1;
		}
		my %jump = (
			'Ctrl+Home'     => sub { $self->_move_cursor( $model->first_line_key ) },
			'Ctrl+End'      => sub { $self->_move_cursor( $model->last_line_key ) },
			'Ctrl+PageUp'   => sub { $self->_turn_page( $model->page - 1 ) },
			'Ctrl+PageDown' => sub { $self->_turn_page( $model->page + 1 ) },
		);
		if ( exists $jump{$name} ) {
			$jump{$name}->();
			return 1;
		}
		return $self->_select_all_by_user if $name eq 'Ctrl+A' && $selection eq 'multiple';
		return 0 unless defined $line;

		if ( $line->{kind} eq 'group' ) {
			return $self->_toggle_line( $line, !$line->{expanded} ) if $name eq 'Enter' || $name eq 'Space';
			return $self->_toggle_line( $line, 1 ) if $name eq '+' || ( $name eq 'Right' && !$line->{expanded} );
			return $self->_toggle_line( $line, 0 ) if $name eq '-' || ( $name eq 'Left'  && $line->{expanded} );
			if ( $name eq 'Right' ) {
				$self->_move_cursor( $self->_line_after($cursor) );
				return 1;
			}
			return $self->_move_to_parent_group($line) if $name eq 'Left';
			return 0;
		}
		return 0 unless $line->{kind} eq 'row';
		if ( $name eq 'Enter' && !$from_cell ) {
			$self->fire_event( Term::Fabulous::Event::RowActivate->new( row_id => $line->{id}, row => $model->row( $line->{id} ) ) );
			return 1;
		}
		if ( $name eq 'Space' && !$from_cell ) {
			return $self->_toggle_selection_by_user( $line->{id} ) if $selection eq 'multiple';
			return $self->_select_by_user( $line->{id} ) if $selection eq 'single';
			return 0;
		}
		return $self->_toggle_line( $line, 1 ) if ( $name eq '+' || $name eq 'Right' ) && $line->{has_children} && !$line->{expanded};
		return $self->_toggle_line( $line, 0 ) if ( $name eq '-' || $name eq 'Left' )  && $line->{has_children} && $line->{expanded};
		if ( $name eq 'Right' && $line->{has_children} ) {
			$self->_move_cursor( $self->_line_after($cursor) );
			return 1;
		}
		return $self->_move_to_parent($line) if $name eq 'Left' && ( defined $model->parent_of( $line->{id} ) || $model->group_by );
		return 0;
	}

	method _header_usable () {
		return $show_header && @_header_cells ? 1 : 0;
	}

	method _is_first_on_page ($key) {
		my ($first) = $model->page_lines;
		return defined $first && $first->{key} eq $key ? 1 : 0;
	}

	method _line_after ($key) {
		my @lines = $model->page_lines;
		my $index = first { $lines[$_]{key} eq $key } 0 .. $#lines;
		return defined $index && $index < $#lines ? $lines[ $index + 1 ]{key} : $key;
	}

	method _move_within_page ( $steps, $extend ) {
		my @lines = $model->page_lines;
		return unless @lines;
		my $cursor = $model->cursor;
		my $index  = first { $lines[$_]{key} eq $cursor } 0 .. $#lines;
		$index = max( 0, min( $#lines, ( $index // 0 ) + $steps ) );
		$self->_move_cursor( $lines[$index]{key}, extend => $extend );
		return;
	}

	method _move_to_parent ($line) {
		my $parent = $model->parent_of( $line->{id} );
		my $key    = defined $parent ? Term::Fabulous::Widget::Table::Model::row_key($parent) : undef;
		if ( defined $key && defined $model->line_index($key) ) {
			$self->_move_cursor($key);
			return 1;
		}
		return $self->_move_to_parent_group($line);
	}

	# The nearest group header above the line, of a lower level for a group.
	method _move_to_parent_group ($line) {
		my @lines = $model->lines;
		my $index = $model->line_index( $line->{key} ) // return 1;
		my $limit = $line->{kind} eq 'group' ? $line->{depth} : 9**9;
		for ( my $at = $index - 1; $at >= 0; $at-- ) {
			next unless $lines[$at]{kind} eq 'group' && $lines[$at]{depth} < $limit;
			$self->_move_cursor( $lines[$at]{key} );
			return 1;
		}
		return 1;
	}

	# Moves the cursor as the user does: fires CursorMove, selects in
	# single mode, extends the selection with extend, turns the page.
	method _move_cursor ( $key, %options ) {
		return 0 unless defined $key;
		my $page_before = $model->page;
		my $anchor      = $model->anchor // $model->cursor;
		my $moved       = $model->set_cursor($key);
		$self->_after_cursor_moved( $moved, $page_before );
		my $id = Term::Fabulous::Widget::Table::Model::id_of_key($key);
		if ( $options{extend} && defined $anchor && defined $model->line_index($anchor) ) {
			$model->set_anchor($anchor);
			my @ids = grep { defined } map { Term::Fabulous::Widget::Table::Model::id_of_key($_) } $model->line_keys_between( $anchor, $key );
			$self->_select_by_user( $options{add} ? ( $model->selected_ids, @ids ) : @ids );
		}
		else {
			$model->set_anchor($key);
			$self->_select_by_user($id) if $selection eq 'single' && defined $id && $moved;
		}
		return $moved;
	}

	method _after_cursor_moved ( $moved, $page_before ) {
		return unless $moved || $model->page != $page_before;
		$self->_reveal_cursor_after_frame;
		$self->_changed;
		if ($moved) {
			my $line = $model->line( $model->cursor );
			$self->fire_event(
				Term::Fabulous::Event::CursorMove->new(
					row_id     => $line->{kind} eq 'row'   ? $line->{id}   : undef,
					group_path => $line->{kind} eq 'group' ? $line->{path} : undef,
				)
			);
		}
		$self->_fire_page_change if $model->page != $page_before;
		return;
	}

	method _fire_page_change () {
		$self->fire_event( Term::Fabulous::Event::PageChange->new( page => $model->page, page_size => $model->page_size ) );
		return;
	}

	# Turns the page as the user does. The cursor goes to the page's first
	# line, as for any other move by the user: CursorMove and PageChange
	# fire, a range starts there, and in single mode the row is selected.
	method _turn_page ($page) {
		$page = max( 1, min( $page, $model->page_count ) );
		my ( $page_before, $cursor_before ) = ( $model->page, $model->cursor );
		return 0 unless $model->set_page($page);
		my $key   = $model->cursor;
		my $moved = _same( $cursor_before, $key ) ? 0 : 1;
		$self->_after_cursor_moved( $moved, $page_before );
		$model->set_anchor($key);
		my $id = Term::Fabulous::Widget::Table::Model::id_of_key($key);
		$self->_select_by_user($id) if $selection eq 'single' && defined $id && $moved;
		return 1;
	}

	method _change_page_size ($size) {
		return unless $model->set_page_size($size);
		$self->_reveal_cursor_after_frame;
		$self->_changed;
		$self->_fire_page_change;
		return;
	}

	# Selection changes the user makes fire SelectionChange.
	method _select_by_user (@ids) {
		return $self->_selection_event( $model->set_selection(@ids) );
	}

	method _toggle_selection_by_user ($id) {
		return $self->_selection_event( $model->toggle_selected($id) );
	}

	method _select_all_by_user () {
		my @ids = $model->filtered_row_ids;
		my $all = @ids && !grep { !$model->is_selected($_) } @ids;
		return $self->_selection_event( $all ? $model->deselect(@ids) : $model->select(@ids) );
	}

	method _selection_event ( $added, $removed ) {
		return 1 unless @$added || @$removed;
		$self->_changed;
		$self->fire_event( Term::Fabulous::Event::SelectionChange->new( selected_ids => [ $model->selected_ids ], added_ids => $added, removed_ids => $removed ) );
		return 1;
	}

	# Opens or closes a group or tree row as the user does.
	method _toggle_line ( $line, $open ) {
		my $changed
			= $line->{kind} eq 'group'
			? $model->set_group_collapsed( $line->{path}, $open ? 0 : 1 )
			: $model->set_expanded( $line->{id}, $open );
		return 1 unless $changed;
		$self->_changed;
		my $class = $open ? 'Term::Fabulous::Event::Expand' : 'Term::Fabulous::Event::Collapse';
		$self->fire_event(
			$class->new(
				row_id     => $line->{kind} eq 'row'   ? $line->{id}   : undef,
				group_path => $line->{kind} eq 'group' ? $line->{path} : undef,
			)
		);
		return 1;
	}

	# The header has the keyboard: the header cursor picks a column.
	method _enter_header () {
		$_header_cursor = first { defined $_header_cells[$_]{marker} || defined $_header_cells[$_]{mark} } 0 .. $#_header_cells;
		$_header_cursor //= 0;
		$self->_changed;
		return 1;
	}

	method _leave_header () {
		$_header_cursor = undef;
		$self->_reveal_cursor_after_frame;
		$self->_changed;
		return $HANDLED;
	}

	method _on_header_key ($name) {
		my $last = $#_header_cells;
		return $self->_leave_header if $name eq 'Down' || $name eq 'Escape' || $last < 0;
		my %target = ( Left => $_header_cursor - 1, Right => $_header_cursor + 1, Home => 0, End => $last );
		if ( exists $target{$name} ) {
			$_header_cursor = max( 0, min( $last, $target{$name} ) );
			$self->_changed;
			return $HANDLED;
		}
		my @grid_columns = $self->_grid_columns;
		my $key          = $grid_columns[$_header_cursor]{key} // return $CONTINUE;
		if ( $name eq 'Enter' || $name eq 'Space' ) {
			if ( $key eq SELECT_COLUMN ) {
				$self->_select_all_by_user;
				return $HANDLED;
			}
			$self->_sort_by_user( $key, $name eq 'Space' );
			return $HANDLED;
		}
		if ( $name eq 'c' ) {
			$self->open_column_chooser;
			return $HANDLED;
		}
		return $CONTINUE;
	}

	method _sort_by_user ( $key, $add ) {
		return unless $model->column($key)->sortable;
		return unless $model->cycle_sort( $key, $add );
		$self->_reveal_cursor_after_frame;
		$self->_changed;
		$self->fire_event( Term::Fabulous::Event::SortChange->new( sort => $model->sort_spec ) );
		return;
	}

	# ---------------------------------------------------------------------
	# Mouse
	# ---------------------------------------------------------------------

	# The table widget a mouse event is about: a toggle or a cell, and the
	# widget it hit. The scrollbar handles its own clicks.
	method _hit ($target) {
		foreach my $node ( $target, $target->ancestors ) {
			last if refaddr($node) == refaddr($self);
			return ( toggle => $node ) if $node->isa('Term::Fabulous::Widget::Table::Toggle');
			return ( cell   => $node ) if $node->isa('Term::Fabulous::Widget::Table::Cell');
		}
		return ();
	}

	method _on_mouse ($event) {
		my ( $kind, $widget ) = $self->_hit( $event->target );
		return $CONTINUE unless defined $kind;
		my $key    = $event->key;
		my $motion = $event->modifiers & TB_MOD_MOTION;
		return $CONTINUE if $motion;
		if ( $key == TB_KEY_MOUSE_RIGHT ) {
			return $CONTINUE unless $kind eq 'cell' && $widget->part eq 'header';
			$self->open_column_chooser;
			return $HANDLED;
		}
		return $CONTINUE unless $key == TB_KEY_MOUSE_LEFT;

		if ( $kind eq 'toggle' ) {
			my $line = $model->line( $widget->line_key ) // return $HANDLED;
			$self->_move_cursor( $line->{key} );
			$self->_toggle_line( $line, !$line->{expanded} ) if $line->{kind} eq 'group' || $line->{has_children};
			return $HANDLED;
		}
		return $self->_click_header( $widget, $event ) if $widget->part eq 'header';
		return $CONTINUE unless $widget->part eq 'body';
		return $self->_click_line( $widget, $event );
	}

	method _click_header ( $cell, $event ) {
		$_header_cursor = undef;
		my $key = $cell->column_key // return $HANDLED;
		if ( $key eq SELECT_COLUMN ) {
			$self->_select_all_by_user;
			return $HANDLED;
		}
		my $add = $event->modifiers & ( TB_MOD_SHIFT | TB_MOD_CTRL | TB_MOD_ALT ) ? 1 : 0;
		$self->_sort_by_user( $key, $add );
		return $HANDLED;
	}

	method _click_line ( $cell, $event ) {
		my $line   = $model->line( $cell->line_key // '' ) // return $HANDLED;
		my $double = $event->click_count >= 2 && defined $_last_press_key && $_last_press_key eq $line->{key};
		$_last_press_key = $double ? undef : $line->{key};
		$_header_cursor  = undef;

		if ( $line->{kind} eq 'group' ) {
			$self->_move_cursor( $line->{key} );
			$self->_toggle_line( $line, !$line->{expanded} );
			return $HANDLED;
		}
		my $in_input = $self->_inside_input($event);
		my $mods     = $event->modifiers;
		my $id       = $line->{id};
		if ( $in_input || $selection ne 'multiple' ) {
			$self->_move_cursor( $line->{key} );
		}
		elsif ( defined $cell->column_key && $cell->column_key eq SELECT_COLUMN || $mods & ( TB_MOD_CTRL | TB_MOD_ALT ) ) {
			$self->_move_cursor( $line->{key} );
			$self->_toggle_selection_by_user($id);
		}
		elsif ( $mods & TB_MOD_SHIFT ) {
			$self->_move_cursor( $line->{key}, extend => 1 );
		}
		else {
			$self->_move_cursor( $line->{key} );
			$self->_select_by_user($id);
		}
		$self->_select_by_user($id) if $selection eq 'single' && !$in_input;
		$self->fire_event( Term::Fabulous::Event::RowActivate->new( row_id => $id, row => $model->row($id) ) ) if $double && !$in_input;
		return $HANDLED;
	}

	method _on_mouse_move ($event) {
		return unless $hover;
		my ( $kind, $widget ) = $self->_hit( $event->target );
		my $key = defined $kind && $kind eq 'cell' && $widget->part eq 'body' ? $widget->line_key : undef;
		$self->_hover_line($key);
		return;
	}

	method _hover_line ($key) {
		return if _same( $key, $_hover_key );
		$_hover_key = $key;
		$self->_changed;
		return;
	}

	# ---------------------------------------------------------------------
	# The filter row
	# ---------------------------------------------------------------------

	method _filter_typed ( $key, $text ) {
		my $error = $self->_apply_filter_text( $key, $text );
		$self->fire_event( Term::Fabulous::Event::FilterChange->new( column => $key, text => $text, error => $error ) );
		return;
	}

	# Applies the expression of a filter field; returns the error message,
	# or undef.
	method _apply_filter_text ( $key, $text ) {
		my $column = $model->column($key);
		$_filter_text{$key} = $text;
		delete $_filter_error{$key};
		my $filter;
		try {
			$filter = Term::Fabulous::Widget::Table::Filter->parse( $text, column => $key, type => $column->type, on => $column->filter_on );
		}
		catch ($error) {
			$_filter_error{$key} = $error =~ s/\ATerm::Fabulous::Widget::Table::Filter: //r =~ s/\s+\z//r;
		}
		$model->set_filter( "column:$key" => $filter );
		$model->expand_to_matches;
		$self->_reveal_cursor_after_frame;
		$self->_changed;
		return $_filter_error{$key};
	}

	# =====================================================================
	# Public methods
	# =====================================================================

	# --- Rows ------------------------------------------------------------

	method rows (@new) {
		return $model->rows unless @new;
		$model->set_rows( $new[0] );
		$self->_rows_changed;
		return $self;
	}

	method _rows_changed () {
		%_row_style_of  = map { $_ => $_row_style_of{$_} } grep  { $model->has_row($_) } keys %_row_style_of;
		%_cell_style_of = map { $_ => $_cell_style_of{$_} } grep { $model->has_row( ( split /\0/, $_, 2 )[0] ) } keys %_cell_style_of;
		$model->expand_to_matches;
		$self->_changed;
		return;
	}

	method add_row ( $row, %options ) {
		my ($id) = $model->add_rows( [$row], %options );
		$self->_rows_changed;
		return $id;
	}

	method add_rows ( $rows, %options ) {
		my @ids = $model->add_rows( $rows, %options );
		$self->_rows_changed;
		return @ids;
	}

	method update_row ( $id, $changes ) {
		$model->update_row( $id, $changes );
		$self->_data_changed;
		return $self;
	}

	method replace_row ( $id, $row ) {
		$model->replace_row( $id, $row );
		$self->_data_changed;
		return $self;
	}

	method set_value ( $id, $key, $value ) {
		$model->column($key);
		$model->set_value( $id, $key, $value );
		$self->_data_changed;
		return $self;
	}

	# A row's data changed: in a filtered tree, a row that matches now is
	# shown, like after any change of the filters.
	method _data_changed () {
		$model->expand_to_matches;
		$self->_changed;
		return;
	}

	method value ( $id, $key ) {
		return $model->value_of( $self->_check_row($id), $key );
	}

	method display_value ( $id, $key ) {
		return $model->display_of( $self->_check_row($id), $key );
	}

	method _check_row ($id) {
		die "Term::Fabulous::Widget::Table: there is no row with the id " . describe($id) unless $model->has_row($id);
		return $id;
	}

	method remove_rows (@ids) {
		$model->remove_rows(@ids);
		$self->_rows_changed;
		return $self;
	}

	method remove_row ($id) {
		return $self->remove_rows($id);
	}

	method clear_rows () {
		$model->clear_rows;
		$self->_rows_changed;
		return $self;
	}

	method row     ($id) { return $model->row($id) }
	method has_row ($id) { return $model->has_row($id) }
	method row_ids ()   { return $model->row_ids }
	method row_count () { return $model->row_count }
	method parent_of   ($id) { return $model->parent_of($id) }
	method children_of ($id) { return $model->children_of($id) }
	method filtered_row_ids () { return $model->filtered_row_ids }

	method page_row_ids () {
		return map { $_->{id} } grep { $_->{kind} eq 'row' } $model->page_lines;
	}

	# --- Columns ---------------------------------------------------------

	method columns ()     { return $model->columns }
	method column ($key)  { return $model->column($key) }
	method column_keys () { return $model->column_keys }

	method add_column ( $spec, %options ) {
		my @unknown = grep { $_ ne 'index' } sort keys %options;
		die "Term::Fabulous::Widget::Table: add_column does not accept @unknown (known: index)" if @unknown;
		my $column = $model->add_column( $spec, $options{index} );
		$self->_changed;
		return $column;
	}

	method remove_column ($key) {
		delete $_filter_text{$key};
		delete $_filter_error{$key};
		delete $_cell_style_of{$_} foreach grep { ( split /\0/, $_, 2 )[1] eq $key } keys %_cell_style_of;
		$model->remove_column($key);
		$self->_changed;
		return $self;
	}

	method move_column ( $key, $index ) {
		$model->move_column( $key, $index );
		$self->_changed;
		return $self;
	}

	method update_column ( $key, %changes ) {
		die "Term::Fabulous::Widget::Table: update_column cannot change the key of a column" if exists $changes{key};
		my $column = $model->replace_column( $model->column($key)->with(%changes) );
		$self->_changed;
		return $column;
	}

	method visible_columns () {
		return map { $_->key } $model->visible_columns;
	}

	method is_column_visible ($key) {
		return $model->is_column_visible($key);
	}

	method show_columns (@keys) {
		$model->set_column_visible( $_, 1 ) foreach @keys;
		$self->_changed;
		return $self;
	}

	method hide_columns (@keys) {
		$model->set_column_visible( $_, 0 ) foreach @keys;
		$self->_changed;
		return $self;
	}

	method set_visible_columns (@keys) {
		$model->set_visible_columns(@keys);
		$self->_changed;
		return $self;
	}

	method open_column_chooser () {
		return $self if defined $_chooser;
		weaken( my $weak = $self );
		$_chooser = Term::Fabulous::Widget::Table::ColumnChooser->new(
			columns          => [ map { [ $_->key, length $_->title ? $_->title : $_->key, $model->is_column_visible( $_->key ) ] } $model->columns ],
			text_color       => $self->text_color,
			muted_color      => $self->muted_color,
			background_color => $self->group_background_color,
			bordered         => 1,
			border_color     => $self->text_color,
			border_style     => Term::Fabulous::Enum::BorderStyle->Round,
			on_toggle        => sub ( $key, $visible ) { $weak->_chooser_toggled( $key, $visible ) if $weak },
			on_close         => sub () { $weak->close_column_chooser if $weak },
		);
		$self->add_child($_chooser);
		$_chooser->focus_first;
		return $self;
	}

	method close_column_chooser () {
		return $self unless defined $_chooser;
		my $closing = $_chooser;
		undef $_chooser;
		$self->remove_child($closing);    # a focus inside goes to its heir, the table
		return $self;
	}

	method is_column_chooser_open () {
		return defined $_chooser ? 1 : 0;
	}

	method _chooser_toggled ( $key, $visible ) {
		$model->set_column_visible( $key, $visible );
		$self->_changed;
		$self->fire_event( Term::Fabulous::Event::ColumnsChange->new( visible => [ $self->visible_columns ] ) );
		return;
	}

	# --- Sorting ---------------------------------------------------------

	method sort_spec () {
		return $model->sort_spec;
	}

	method sort_by (@spec) {
		$self->_reveal_cursor_after_frame if $model->set_sort(@spec);
		$self->_changed;
		return $self;
	}

	method clear_sort () {
		return $self->sort_by;
	}

	# --- Filtering -------------------------------------------------------

	method filter ( $name, $filter ) {
		die "Term::Fabulous::Widget::Table: filter names starting with 'column:' belong to the filter row; use filter_text"
			if defined $name && !ref $name && $name =~ /\Acolumn:/;
		$model->set_filter( $name, $filter );
		$model->expand_to_matches;
		$self->_reveal_cursor_after_frame;
		$self->_changed;
		return $self;
	}

	method remove_filter ($name) {
		$model->remove_filter($name);
		$model->expand_to_matches;
		$self->_changed;
		return $self;
	}

	method filter_names () {
		return grep { !/\Acolumn:/ } $model->filter_names;
	}

	method clear_filters () {
		%_filter_text = %_filter_error = ();
		_set( $_->{field}, value => '' ) foreach grep { defined $_->{field} } @_filter_cells;
		$model->clear_filters;
		$self->_changed;
		return $self;
	}

	method search (@new) {
		return $model->search unless @new;
		$model->search( $new[0] );
		$model->expand_to_matches;
		$self->_reveal_cursor_after_frame;
		$self->_changed;
		return $self;
	}

	method filter_text ( $key, @new ) {
		$model->column($key);
		return $_filter_text{$key} // '' unless @new;
		my $text = string( $self, filter_text => $new[0] // '' );
		my ($cell) = grep { defined $_->{field} && $_->{cell}->column_key eq $key } @_filter_cells;
		_set( $cell->{field}, value => $text ) if defined $cell;
		$self->_apply_filter_text( $key, $text );
		return $self;
	}

	method filter_error ($key) {
		$model->column($key);
		return $_filter_error{$key};
	}

	method filter_row (@new) {
		return $filter_row unless @new;
		$filter_row = boolean( $self, filter_row => $new[0] );
		$self->_changed;
		return $filter_row;
	}

	# --- Grouping --------------------------------------------------------

	method group_by (@keys) {
		return $model->group_by unless @keys;
		$model->group_by(@keys);
		$self->_changed;
		return $self;
	}

	method ungroup () {
		$model->group_by(undef);
		$self->_changed;
		return $self;
	}

	method is_group_expanded (@path) {
		return $model->is_group_collapsed(@path) ? 0 : 1;
	}

	method expand_group (@path) {
		$model->set_group_collapsed( \@path, 0 );
		$self->_changed;
		return $self;
	}

	method collapse_group (@path) {
		$model->set_group_collapsed( \@path, 1 );
		$self->_changed;
		return $self;
	}

	method expand_all_groups () {
		$model->set_all_groups_collapsed(0);
		$self->_changed;
		return $self;
	}

	method collapse_all_groups () {
		$model->set_all_groups_collapsed(1);
		$self->_changed;
		return $self;
	}

	# --- Tree ------------------------------------------------------------

	method is_expanded ($id) { return $model->is_expanded($id) }

	method expand (@ids) {
		$model->set_expanded( $_, 1 ) foreach @ids;
		$self->_changed;
		return $self;
	}

	method collapse (@ids) {
		$model->set_expanded( $_, 0 ) foreach @ids;
		$self->_changed;
		return $self;
	}

	method expand_all () {
		$model->set_all_expanded(1);
		$self->_changed;
		return $self;
	}

	method collapse_all () {
		$model->set_all_expanded(0);
		$self->_changed;
		return $self;
	}

	# --- Pages -----------------------------------------------------------

	method page (@new) {
		return $model->page unless @new;
		$model->set_page( $new[0] );
		$self->_changed;
		return $self;
	}

	method page_count () { return $model->page_count }

	# The rows the table takes before it is laid out: the header rows, the
	# lines of the current page (or the one line that says there are
	# none), the lines of the frame around them (the top, the line under
	# the header rows and the bottom ledge, each when its style draws a
	# line) and the pager when it shows. The lines between rows are not
	# counted.
	method estimated_content_rows :override ($columns) {
		my $header_rows = ( $show_header ? 1 : 0 ) + ( $filter_row ? 1 : 0 );
		my $rows        = $header_rows + max( 1, scalar $model->page_lines );
		$rows++ if _draws_line( $_line_style{border_top} );
		$rows++ if $header_rows && _draws_line( $_line_style{header_line} // $_line_style{row_lines} );
		$rows++ if _draws_line( $_line_style{border_bottom} );
		$rows += $_pager->estimated_rows($columns) if $self->_pager_shown;
		return $rows;
	}

	sub _draws_line ($style) {
		return defined $style && $style->name ne 'Hidden' ? 1 : 0;
	}

	method page_size (@new) {
		return $model->page_size unless @new;
		$model->set_page_size( $new[0] );
		$self->_changed;
		return $self;
	}

	method next_page ()     { return $self->page( min( $model->page + 1, $model->page_count ) ) }
	method previous_page () { return $self->page( max( $model->page - 1, 1 ) ) }

	# --- Selection -------------------------------------------------------

	# Changing the mode keeps what the new mode allows of the selection:
	# none of it for 'none', the first selected row for 'single'.
	method selection (@new) {
		return $selection unless @new;
		my $mode = one_of( $self, selection => $new[0], @SELECTIONS );
		$selection = $mode;
		my @kept = $mode eq 'none' ? () : $model->selected_ids;
		@kept = @kept[ 0 .. 0 ] if $mode eq 'single' && @kept > 1;
		$model->set_selection(@kept);
		$selection_column = $_explicit_selection_column // ( $mode eq 'multiple' ? 1 : 0 );
		$self->_changed;
		return $selection;
	}

	method selection_column (@new) {
		return $selection_column unless @new;
		$_explicit_selection_column = $selection_column = boolean( $self, selection_column => $new[0] );
		$self->_changed;
		return $selection_column;
	}

	method row_id (@new) {
		return $model->row_id unless @new;
		return $model->set_row_id( $new[0] );
	}

	method children_key (@new) {
		return $model->children_key unless @new;
		$model->set_children_key( $new[0] );
		$_body_signature = '';
		$self->_changed;
		return $model->children_key;
	}

	method tree_expanded (@new) {
		return $model->expand_new unless @new;
		return $model->expand_new( boolean( $self, tree_expanded => $new[0] ) );
	}

	method _selectable (@ids) {
		die "Term::Fabulous::Widget::Table: the table has selection => 'none'; nothing can be selected" if @ids && $selection eq 'none';
		die "Term::Fabulous::Widget::Table: a table with selection => 'single' selects one row at most" if @ids > 1 && $selection eq 'single';
		$self->_check_row($_) foreach @ids;
		return @ids;
	}

	method selected_ids () { return $model->selected_ids }

	method selected_rows () {
		return map { $model->row($_) } $model->selected_ids;
	}
	method is_selected ($id) { return $model->is_selected($id) }

	method set_selection (@ids) {
		$model->set_selection( $self->_selectable(@ids) );
		$self->_changed;
		return $self;
	}

	method select (@ids) {
		return $self->set_selection(@ids) if $selection eq 'single';
		$model->select( $self->_selectable(@ids) );
		$self->_changed;
		return $self;
	}

	method deselect (@ids) {
		$model->deselect( map { $self->_check_row($_) } @ids );
		$self->_changed;
		return $self;
	}

	method select_all () {
		die "Term::Fabulous::Widget::Table: select_all needs selection => 'multiple'" unless $selection eq 'multiple';
		$model->select( $model->filtered_row_ids );
		$self->_changed;
		return $self;
	}

	method clear_selection () {
		$model->set_selection;
		$self->_changed;
		return $self;
	}

	# --- Cursor ----------------------------------------------------------

	method cursor (@new) {
		unless (@new) {
			return Term::Fabulous::Widget::Table::Model::id_of_key( $model->cursor );
		}
		my $key = Term::Fabulous::Widget::Table::Model::row_key( $self->_check_row( $new[0] ) );
		die "Term::Fabulous::Widget::Table: row '$new[0]' is not shown (filtered out, or below a collapsed row or group)" unless defined $model->line_index($key);
		$model->set_cursor($key);
		$model->set_anchor($key);
		$self->_reveal_cursor_after_frame;
		$self->_changed;
		return $self;
	}

	method cursor_group () {
		my $line = $model->line( $model->cursor // return undef ) // return undef;
		return $line->{kind} eq 'group' ? [ @{ $line->{path} } ] : undef;
	}

	method scroll_to_row ($id) {
		return $self->cursor($id);
	}

	# --- Styles ----------------------------------------------------------

	method set_row_style ( $id, $style ) {
		$self->_check_row($id);
		my $checked = style_hash( $self, 'row style', row => $style );
		%$checked ? ( $_row_style_of{$id} = $checked ) : delete $_row_style_of{$id};
		$self->_restyle;
		return $self;
	}

	method row_style_of ($id) {
		return { %{ $_row_style_of{ $self->_check_row($id) } // {} } };
	}

	method set_cell_style ( $id, $key, $style ) {
		$self->_check_row($id);
		$model->column($key);
		my $checked = style_hash( $self, 'cell style', cell => $style );
		%$checked ? ( $_cell_style_of{ $id . "\0" . $key } = $checked ) : delete $_cell_style_of{ $id . "\0" . $key };
		$self->_restyle;
		return $self;
	}

	method cell_style_of ( $id, $key ) {
		$self->_check_row($id);
		$model->column($key);
		return { %{ $_cell_style_of{ $id . "\0" . $key } // {} } };
	}

	# --- Appearance ------------------------------------------------------

	method _color_property ( $name, @new ) {
		return @new ? $self->set_look( $name => $new[0] ) : $self->look_value($name);
	}

	# The parts that copy the table's colors take them again.
	method _colors_changed (@names) {
		my %changed = map { $_ => 1 } @names;
		$_scrollbar->thumb_color( $self->text_color ) if $changed{text_color};
		$_scrollbar->track_color( $self->line_color ) if $changed{line_color};
		$self->_rebuild_pager if $changed{text_color}   || $changed{muted_color};
		$_header_signature = '' if $changed{text_color} || $changed{cursor_color};    # the filter fields take them when built
		$self->_restyle;
		return;
	}

	method text_color              (@new) { return $self->_color_property( text_color              => @new ) }
	method header_text_color       (@new) { return $self->_color_property( header_text_color       => @new ) }
	method header_background_color (@new) { return $self->_color_property( header_background_color => @new ) }
	method group_text_color        (@new) { return $self->_color_property( group_text_color        => @new ) }
	method group_background_color  (@new) { return $self->_color_property( group_background_color  => @new ) }
	method cursor_color            (@new) { return $self->_color_property( cursor_color            => @new ) }
	method selected_color          (@new) { return $self->_color_property( selected_color          => @new ) }
	method hover_color             (@new) { return $self->_color_property( hover_color             => @new ) }
	method filter_background_color (@new) { return $self->_color_property( filter_background_color => @new ) }
	method error_color             (@new) { return $self->_color_property( error_color             => @new ) }
	method muted_color             (@new) { return $self->_color_property( muted_color             => @new ) }
	method line_color              (@new) { return $self->_color_property( line_color              => @new ) }

	method stripe_color (@new) {
		return @new ? $self->set_look( stripe_color => $new[0] ) : $self->look_value('stripe_color');
	}

	# The table's own background is the color of its cells (see
	# _base_background).
	method background_color :override (@new) {
		my $color = $self->SUPER::background_color(@new);
		$self->_restyle if @new;
		return $color;
	}

	method _line_property ( $name, @new ) {
		return $_line_style{$name} unless @new;
		$_line_style{$name} = optional( \&border_style, $self, $name => $new[0], @NONE_IS_HIDDEN );
		$self->_restyle;
		return $_line_style{$name};
	}

	method border_top    (@new) { return $self->_line_property( border_top    => @new ) }
	method border_right  (@new) { return $self->_line_property( border_right  => @new ) }
	method border_bottom (@new) { return $self->_line_property( border_bottom => @new ) }
	method border_left   (@new) { return $self->_line_property( border_left   => @new ) }
	method column_lines  (@new) { return $self->_line_property( column_lines  => @new ) }
	method row_lines     (@new) { return $self->_line_property( row_lines     => @new ) }
	method header_line   (@new) { return $self->_line_property( header_line   => @new ) }

	# Sets the four sides of the frame; reads the style they share, or
	# undef when they differ.
	method border (@new) {
		if (@new) {
			$self->_line_property( $_ => $new[0] ) foreach qw(border_top border_right border_bottom border_left);
			return $_line_style{border_top};
		}
		my %names = map { ( defined $_ ? $_->name : '' ) => 1 } @_line_style{qw(border_top border_right border_bottom border_left)};
		return keys %names == 1 ? $_line_style{border_top} : undef;
	}

	method header (@new) {
		return $show_header unless @new;
		$show_header = boolean( $self, header => $new[0] );
		$self->_changed;
		return $show_header;
	}

	method scrollbar (@new) {
		return $scrollbar unless @new;
		$scrollbar = boolean( $self, scrollbar => $new[0] );
		$self->_changed;
		return $scrollbar;
	}

	method hover (@new) {
		return $hover unless @new;
		$hover      = boolean( $self, hover => $new[0] );
		$_hover_key = undef unless $hover;
		$self->_restyle;
		return $hover;
	}

	method pager (@new) {
		return $show_pager unless @new;
		$show_pager = defined $new[0] ? boolean( $self, pager => $new[0] ) : undef;
		$self->_changed;
		return $show_pager;
	}

	method empty_text (@new) {
		return $empty_text unless @new;
		$empty_text = string( $self, empty_text => $new[0] );
		$self->_restyle;
		return $empty_text;
	}

	method no_match_text (@new) {
		return $no_match_text unless @new;
		$no_match_text = string( $self, no_match_text => $new[0] );
		$self->_restyle;
		return $no_match_text;
	}

	method _callback_property ( $name, $field_ref, @new ) {
		return $$field_ref unless @new;
		die "Term::Fabulous::Widget::Table: $name must be a code reference or undef, got " . describe( $new[0] )
			if defined $new[0] && ref $new[0] ne 'CODE';
		$$field_ref = $new[0];
		$_->{label_signature} = '' foreach grep { $_->{kind} eq 'group' } values %_built;    # labels are made again
		$self->_restyle;
		return $$field_ref;
	}

	method row_style   (@new) { return $self->_callback_property( row_style   => \$row_style,   @new ) }
	method group_label (@new) { return $self->_callback_property( group_label => \$group_label, @new ) }

	method header_style (@new) {
		return {%$header_style} unless @new;
		$header_style = style_hash( $self, 'header_style', row => $new[0] );
		$self->_restyle;
		return {%$header_style};
	}

	method group_style (@new) {
		return {%$group_style} unless @new;
		$group_style = style_hash( $self, 'group_style', row => $new[0] );
		$self->_restyle;
		return {%$group_style};
	}

	method cell_padding (@new) {
		return {%$cell_padding} unless @new;
		$cell_padding      = $self->_padding( $new[0] );
		$_header_signature = $_body_signature = '';    # every cell is built again
		$self->_changed;
		return {%$cell_padding};
	}

	method tree_column (@new) {
		return $tree_column unless @new;
		die "Term::Fabulous::Widget::Table: tree_column must be a column key or undef, got " . describe( $new[0] ) if ref $new[0];
		$model->column( $new[0] ) if defined $new[0];
		$tree_column     = $new[0];
		$_body_signature = '';
		$self->_changed;
		return $tree_column;
	}

	method page_sizes (@new) {
		return [@$page_sizes] unless @new;
		die "Term::Fabulous::Widget::Table: page_sizes must be an array reference of positive integers, got " . describe( $new[0] )
			unless ref $new[0] eq 'ARRAY' && @{ $new[0] } && !grep { !defined || ref || !/\A[1-9][0-9]*\z/ } @{ $new[0] };
		$page_sizes = [ map { $_ + 0 } @{ $new[0] } ];
		$self->_rebuild_pager;
		$self->_changed;
		return [@$page_sizes];
	}

	# --- KDL -------------------------------------------------------------

	method layout_properties :common () {
		return (
			$class->SUPER::layout_properties,
			selection        => 'scalar',
			selection_column => 'boolean',
			page_size        => 'scalar',
			pager            => 'boolean',
			filter_row       => 'boolean',
			header           => 'boolean',
			scrollbar        => 'boolean',
			hover            => 'boolean',
			row_id           => 'scalar',
			children_key     => 'scalar',
			tree_expanded    => 'boolean',
			tree_column      => 'scalar',
			empty_text       => 'scalar',
			no_match_text    => 'scalar',
			column           => \&_parse_column,
			sort             => \&_parse_sort,
			group_by         => \&_parse_group_by,
			lines            => \&_parse_lines,
			cell_padding     => \&_parse_cell_padding,
			page_sizes       => \&_parse_page_sizes,
		);
	}

	# A table's cells come from its columns, not from child widgets.
	method apply_layout_node :override ($node) {
		my @widgets = grep { Term::Fabulous::Role::CanParseLayout::is_widget_node_name( $_->name ) } $node->children->@*;
		die "Term::Fabulous::Widget::Table: a table takes no child widgets (found '" . $widgets[0]->name . "'); its cells come from its columns and rows" if @widgets;
		return $self->SUPER::apply_layout_node($node);
	}

	# How rows are read comes first, then the columns, so every other
	# property can name them.
	method apply_layout_settings :override (@settings) {
		my %rank    = ( row_id => 0, children_key => 0, column => 1, sort => 3, group_by => 3 );
		my @ordered = map { $_->[1] } sort { $a->[0] <=> $b->[0] } map { [ $rank{ $_->[0] } // 2, $_ ] } @settings;
		return $self->SUPER::apply_layout_settings(@ordered);
	}

	my @COLUMN_PROPERTIES = qw(title type width align header_align wrap sortable filterable filter_on compare visible);
	my @STYLE_PROPERTIES  = qw(text_color background_color bold italic underline border_color border_left border_right row_lines);

	method _parse_column ($kid) {
		my @args = map { $_->as_perl } $kid->args->@*;
		die "Term::Fabulous::Widget::Table: layout property 'column' needs the column key as its one argument" unless @args == 1 && defined $args[0] && !ref $args[0];
		my %props   = map  { $_->[0] => $_->[1]->as_perl } $kid->props->@*;
		my %allowed = map  { $_      => 1 } @COLUMN_PROPERTIES;
		my @unknown = grep { !$allowed{$_} } sort keys %props;
		die "Term::Fabulous::Widget::Table: layout property 'column' does not accept @unknown (allowed: @COLUMN_PROPERTIES)" if @unknown;
		my %styles;
		foreach my $child ( $kid->children->@* ) {
			my $name = $child->name;
			die "Term::Fabulous::Widget::Table: a column node holds only 'style' and 'header_style' nodes, got '$name'"
				unless $name eq 'style' || $name eq 'header_style';
			$styles{$name} = $self->kdl_properties( $child, @STYLE_PROPERTIES );
		}
		$self->add_column( { key => $args[0], %props, %styles } );
		return;
	}

	method _parse_sort ($kid) {
		my @args = map { $_->as_perl } $kid->args->@*;
		die "Term::Fabulous::Widget::Table: layout property 'sort' takes a column key and optionally asc or desc"
			unless ( @args == 1 || @args == 2 ) && !$kid->props->@* && !$kid->children->@*;
		$self->sort_by( @{ $model->sort_spec }, [ $args[0], $args[1] // 'asc' ] );
		return;
	}

	method _parse_group_by ($kid) {
		my @keys = map { $_->as_perl } $kid->args->@*;
		die "Term::Fabulous::Widget::Table: layout property 'group_by' takes one or more column keys" unless @keys && !$kid->props->@* && !$kid->children->@*;
		$self->group_by(@keys);
		return;
	}

	method _parse_lines ($kid) {
		my %line_of = ( top => 'border_top', right => 'border_right', bottom => 'border_bottom', left => 'border_left', columns => 'column_lines', rows => 'row_lines', header => 'header_line' );
		my $props   = $self->kdl_properties( $kid, 'frame', ( sort keys %line_of ), 'color' );
		$self->border( $props->{frame} ) if exists $props->{frame};
		$self->_line_property( $line_of{$_} => $props->{$_} ) foreach grep { exists $props->{$_} } sort keys %line_of;
		$self->line_color( $props->{color} ) if exists $props->{color};
		return;
	}

	method _parse_cell_padding ($kid) {
		my @args = $kid->args->@*;
		$self->cell_padding( @args ? $self->kdl_argument($kid)->as_perl : $self->kdl_properties( $kid, qw(left right top bottom) ) );
		return;
	}

	method _parse_page_sizes ($kid) {
		my @sizes = map { $_->as_perl } $kid->args->@*;
		die "Term::Fabulous::Widget::Table: layout property 'page_sizes' takes one or more numbers" unless @sizes && !$kid->props->@* && !$kid->children->@*;
		$self->page_sizes( \@sizes );
		return;
	}

	# --- Widgets ---------------------------------------------------------

	# ---------------------------------------------------------------------
	# Searching (Term::Fabulous::Role::Searchable): every filtered row,
	# on any page, shown or collapsed
	# ---------------------------------------------------------------------

	# The texts of the plain columns come from the model, so a search
	# reaches rows the table never built; the widgets of a custom cell
	# answer only while the row is built.
	method search_texts () {
		my @columns = $model->visible_columns;
		my @entries;
		foreach my $id ( $model->filtered_row_ids ) {
			my $built = $_built{ Term::Fabulous::Widget::Table::Model::row_key($id) };
			foreach my $column (@columns) {
				my $key = $column->key;
				if ( !defined $column->cell ) {
					push @entries, [ [ $id, $key ], $model->display_of( $id, $key ) ];
					next;
				}
				my $content = defined $built ? $built->{content}{$key} : undef;
				next unless defined $content;
				push @entries, map { [ [ $id, $key, @{ $_->[0] } ], $_->[1] ] } nested_search_texts( [ searchables_in($content) ] );
			}
		}
		return @entries;
	}

	# A key: [ row id, column key ] for a text cell, with the index and the
	# key of the widget inside for a custom cell.
	method _search_target ( $what, $key ) {
		die ref($self) . ": $what needs a key of [ row id, column key ] (and the index and key of a widget in a custom cell), got " . describe($key)
			unless ref $key eq 'ARRAY' && ( @$key == 2 || @$key == 4 ) && defined $key->[0] && !ref $key->[0] && defined $key->[1] && !ref $key->[1];
		my ( $id, $column, @nested ) = @$key;
		return ( $id, $column, @nested ? [@nested] : undef );
	}

	method search_revision ($key) {
		my ( $id, $column, $nested ) = $self->_search_target( search_revision => $key );
		return 'gone' unless $model->has_row($id) && $model->has_column($column);
		my $revision = join ':', $model->row_revision($id), $model->columns_revision;
		return $revision unless defined $nested;
		my $content = $self->cell_widget( $id, $column ) // return 'gone';
		return join ':', $revision, nested_search_revision( [ searchables_in($content) ], $nested );
	}

	method highlight_text ( $key, $ranges ) {
		my ( $id, $column, $nested ) = $self->_search_target( highlight_text => $key );
		return unless $model->has_row($id);
		my $slot  = "$id\0$column";
		my $built = $_built{ Term::Fabulous::Widget::Table::Model::row_key($id) };
		if ( defined $nested ) {
			$_cell_highlights{$slot}{ join "\0", map { $_ // '' } @$nested } = [ @$nested, $ranges ];
			my $content = defined $built ? $built->{content}{$column} : undef;
			nested_highlight_text( [ searchables_in($content) ], $nested, $ranges ) if defined $content;
			return;
		}

		# The ranges are checked against the cell's text now, whether or
		# not the row is built: the text the cell shows is the model's.
		Term::Fabulous::Text::Marks->new( owner => ref($self), text => $model->display_of( $id, $column ) )->check_spans( highlight => $ranges );
		$_text_highlights{$slot} = { ranges => $ranges, revision => $model->row_revision($id) };
		my $text = defined $built ? $built->{text}{$column} : undef;
		$text->highlights($ranges) if defined $text;
		return;
	}

	method clear_text_highlights () {
		%_text_highlights = ();
		%_cell_highlights = ();
		foreach my $built ( grep { $_->{kind} eq 'row' } values %_built ) {
			$_->clear_highlights foreach values %{ $built->{text} };
			nested_clear_text_highlights( [ map { searchables_in($_) } grep { !$_->isa('Term::Fabulous::Widget::Text') } values %{ $built->{content} } ] );
		}
		return;
	}

	method _drop_row_highlights ($id) {
		delete @_text_highlights{ grep { index( $_, "$id\0" ) == 0 } keys %_text_highlights };
		delete @_cell_highlights{ grep { index( $_, "$id\0" ) == 0 } keys %_cell_highlights };
		return;
	}

	# Shows the row: the rows and groups above it are expanded, the cursor
	# goes to it, which turns to its page and scrolls the body. The cell's
	# widget is there once the table was prepared again.
	method reveal_text ( $key, $offset ) {
		my ( $id, $column, $nested ) = $self->_search_target( reveal_text => $key );
		return [ undef, undef ] unless $model->has_row($id);
		for ( my $parent = $model->parent_of($id); defined $parent; $parent = $model->parent_of($parent) ) {
			$model->set_expanded( $parent, 1 );
		}
		my @path;
		foreach my $group_key ( $model->group_by ) {
			push @path, $model->value_of( $id, $group_key );
			$model->set_group_collapsed( [@path], 0 );
		}
		return [ undef, undef ] unless defined $model->line_index( Term::Fabulous::Widget::Table::Model::row_key($id) );
		$self->cursor($id);
		my $built = $_built{ Term::Fabulous::Widget::Table::Model::row_key($id) } // return [ undef, undef ];
		return [ $built->{text}{$column}, undef ] unless defined $nested;
		my $content = $built->{content}{$column} // return [ undef, undef ];
		return nested_reveal_text( [ searchables_in($content) ], $nested, $offset );
	}

	# The widget a cell shows (its column's cell widget or a Text), once
	# the row is on the page and the table was prepared.
	method cell_widget ( $id, $key ) {
		my $built = $_built{ Term::Fabulous::Widget::Table::Model::row_key($id) } // return undef;
		return $built->{content}{$key};
	}

	method body ()         { return $_body }
	method pager_widget () { return $_pager }
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Widget::Table - Rows and columns with sorting, filtering,
grouping, trees, pages and selection

=head1 SYNOPSIS

	use Term::Fabulous::Widget::Table;
	use Term::Fabulous::Widget::Table::Mutator qw(date number);

	my $table = Term::Fabulous::Widget::Table->new(
		id        => 'staff',
		row_id    => 'id',              # the rows' 'id' entry names each row
		selection => 'multiple',        # check boxes, Space, Shift+arrows, Ctrl+A
		columns   => [
			{ key => 'name',    title => 'Name' },
			{ key => 'team',    title => 'Team' },
			{ key => 'started', title => 'Started', type => 'date',   mutator => date('%d %b %Y') },
			{ key => 'salary',  title => 'Salary',  type => 'number', mutator => number( decimals => 0 ) },
		],
		rows => [
			{ id => 1, name => 'Ada',   team => 'Core', started => '2019-03-04', salary => 81000 },
			{ id => 2, name => 'Grace', team => 'Web',  started => '2021-11-15', salary => 76500 },
			{ id => 3, name => 'Linus', team => 'Core', started => '2017-06-01', salary => 90000 },
		],
		sort       => [ [ started => 'desc' ] ],
		filter_row => 1,                # a filter field under every column title
		page_size  => 25,               # pages of 25 lines, with a pager below
	);

	$table->on( RowActivate => sub ($event) {       # Enter or a double click
		say 'open ', $event->row->{name};
		return;
	} );
	$table->on( SelectionChange => sub ($event) {
		say scalar @{ $event->selected_ids }, ' selected';
		return;
	} );

	$table->add_row( { id => 4, name => 'Ken', team => 'Web', started => '2023-01-09', salary => 70000 } );
	$table->set_value( 2, salary => 79000 );
	$table->group_by('team');
	my @chosen = $table->selected_rows;              # copies of the selected rows' data

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.05/screenshots/widget-table.svg" alt="A table of staff with a filter row, sorted by the start date, two rows selected with check boxes and a pager below"></p>

=end html

The program is F<examples/widgets/table.pl>.

=head1 DESCRIPTION

A table shows a list of Perl hashes as rows and columns. You describe
the columns once; the table takes care of everything the user does with
the rows: moving through them with the keyboard and the mouse, sorting
by a click on a column title, filtering, opening and closing groups and
tree rows, turning pages and selecting rows. Your program reads and
changes the data at any time through the table's methods, and learns
about the user's actions through events.

This page is the reference: the exact contract of every parameter,
method, key, mouse action, event and KDL property (what it takes,
returns and when it dies), in L</CONSTRUCTOR>, L</METHODS>, L</KEYS>,
L</MOUSE>, L</EVENTS> and L</KDL PROPERTIES>. To find a name in a
terminal, run C<perldoc Term::Fabulous::Widget::Table> and search with
C</>, for example C</filter_row>.

The table guide explains every feature with examples, organized by
feature, on three pages of the manual:

=over

=item L<Term::Fabulous::Manual::Tables>

How a table works, the terms used, rows, columns, display text and
mutators, and widgets in cells. Its
L<FEATURE INDEX|Term::Fabulous::Manual::Tables/FEATURE INDEX> lists
every feature with the section that explains it.

=item L<Term::Fabulous::Manual::TableRows>

Sorting, filtering, grouping, trees, pages, the cursor and the
selection.

=item L<Term::Fabulous::Manual::TableStyles>

Colors, styles, lines between and around the cells, padding, size,
scrolling and printing.

=back

Complete programs that use tables are in L<Term::Fabulous::Cookbook::Tables>,
L<Term::Fabulous::Cookbook::TableRows>,
L<Term::Fabulous::Cookbook::TableStyles> and L<Term::Fabulous::Examples>.

=head2 Features

=over

=item *

Any number of columns, each with its own width (fit, fixed, grow,
percent, with limits), alignment and text wrapping; rows are as high as
their tallest cell. See L<Term::Fabulous::Manual::Tables/COLUMNS>.

=item *

I<Mutators> turn raw values into display text, for example epoch
seconds into a date, while sorting and filtering keep using the raw
value. See L<Term::Fabulous::Manual::Tables/DISPLAY TEXT AND MUTATORS>.

=item *

Any widget as a cell: buttons, check boxes, text fields, canvases. See
L<Term::Fabulous::Manual::Tables/CELL WIDGETS>.

=item *

Sorting by one or several columns, by the user or from Perl, with
built-in comparisons for text, natural text, numbers and dates, or your
own function. See L<Term::Fabulous::Manual::TableRows/SORTING>.

=item *

Filtering: a filter row where the user types expressions such as
C<< >=100 >> or C<2024-05>, named filters from Perl (text, number and
date comparisons, on the raw value or the display text, combined with
and, or, not), and a search over all columns. See L<Term::Fabulous::Manual::TableRows/FILTERING>.

=item *

Grouping rows by the values of one or more columns, under group
headers that open and close. See L<Term::Fabulous::Manual::TableRows/GROUPING>.

=item *

Trees: rows with child rows, opened and closed with a marker. See
L<Term::Fabulous::Manual::TableRows/TREES>.

=item *

Pages with a pager and a choice of page sizes. See L<Term::Fabulous::Manual::TableRows/PAGES>.

=item *

A cursor and no, single or multiple selection, with check boxes. See
L<Term::Fabulous::Manual::TableRows/SELECTION AND CURSOR>.

=item *

Choosing the visible columns, also by the user in a column chooser.
See L<Term::Fabulous::Manual::Tables/Choosing the visible columns>.

=item *

Colors, striped rows, and lines (borders) per table, column, row and
cell, joined into a clean grid. See L<Term::Fabulous::Manual::TableStyles/STYLES AND BORDERS>.

=item *

Changing the data at any time: cells, whole rows, adding and removing
rows and columns. See L<Term::Fabulous::Manual::Tables/Changing the data>.

=item *

Full keyboard and mouse use (see L</KEYS> and L</MOUSE>), events for
every user action (see L</EVENTS>), and tables in KDL layout files (see
L</KDL PROPERTIES>).

=back

=head1 CONSTRUCTOR

=head2 new

	my $table = Term::Fabulous::Widget::Table->new( id => 'orders', %parameters );

Makes a table. C<id> is required. Unknown parameters and invalid values
die, naming the parameter. The
L<parameters of a Box|Term::Fabulous::Widget::Box/CONSTRUCTOR> work
too; the useful ones are C<layout> (only its C<sizing>; see
L<Term::Fabulous::Manual::TableStyles/SIZE AND SCROLLING>) and
C<background_color> (see L<Term::Fabulous::Manual::TableStyles/Colors>). Most parameters have an accessor
of the same name, described under L</METHODS>.

=head3 Data

=over

=item C<id>

Required. A string, unique among the widgets of the program, as for
every widget. The table also uses the id C<"$id/body"> for its
scrolling body, so that one must not be used either.

=item C<columns>

An array reference of column definitions, hash references (see
L<Term::Fabulous::Manual::Tables/COLUMNS> and L<Term::Fabulous::Widget::Table::Column/PARAMETERS>) or
L<Term::Fabulous::Widget::Table::Column> objects. Default: no columns.
Two columns with the same key die.

=item C<rows>

An array reference of hash references, the rows (see L<Term::Fabulous::Manual::Tables/ROWS>). They
are copied. Default: no rows.

=item C<row_id>

Where row ids come from: a key of the rows, a code reference
C<< sub ($row) { ... } >>, or C<undef> (the default) for ids the table
counts up from 1. See L<Term::Fabulous::Manual::Tables/Row ids>.

=item C<children_key>

The key under which a row holds its child rows, as an array reference
of rows; this makes the table a tree (see L<Term::Fabulous::Manual::TableRows/TREES>). Default: C<undef>,
no tree.

=item C<tree_expanded>

A boolean. Default: 0. When true, rows with children start open.

=item C<tree_column>

The key of the column that shows the tree's indentation and markers.
Default: C<undef>, the first visible column.

=back

=head3 Sorting, filtering, grouping, pages

=over

=item C<sort>

An array reference of column keys (ascending) and C<[ $key, 'asc' ]> or
C<[ $key, 'desc' ]> pairs; the first one decides first. Default: C<[]>,
unsorted. See L<Term::Fabulous::Manual::TableRows/SORTING>.

=item C<filter_row>

A boolean. Default: 0. When true, a row of filter fields shows below
the column titles. See L<Term::Fabulous::Manual::TableRows/The filter row>.

=item C<group_by>

A column key, or an array reference of column keys (outermost first).
Default: no groups. See L<Term::Fabulous::Manual::TableRows/GROUPING>.

=item C<group_label>

A code reference that gets a hash about a group and returns the text or
the widget of its header. Default: C<undef>, C<Title: value (count)>.
See L<Term::Fabulous::Manual::TableRows/Group headers>.

=item C<page_size>

A non-negative integer, the number of lines per page. Default: 0, no
pages. See L<Term::Fabulous::Manual::TableRows/PAGES>.

=item C<page_sizes>

A non-empty array reference of positive integers, the page sizes the
pager offers. Default: C<[10, 25, 50, 100]>.

=item C<pager>

C<undef> (the default): show the pager while C<page_size> is above 0.
1: always show it. 0: never.

=back

=head3 Selection and input

=over

=item C<selection>

C<'none'> (the default), C<'single'> or C<'multiple'>. With
C<'single'>, the selection follows the cursor: every move onto a data
row selects that row. See L<Term::Fabulous::Manual::TableRows/Selection>.

=item C<selection_column>

A boolean: whether the selection column with check boxes is shown.
Default: C<undef>, which means 1 for C<'multiple'> and 0 otherwise.
Never shown with C<'none'>.

=item C<hover>

A boolean. Default: 1. Whether the line under the mouse pointer is
highlighted with the C<hover_color>.

=back

=head3 Parts shown

=over

=item C<header>

A boolean. Default: 1. Whether the column titles are shown. Without
them, the user cannot sort by clicking, and C<Up> does not lead into the
header.

=item C<scrollbar>

A boolean. Default: 1. Whether the scrollbar column is shown inside
the frame, right of the rows, while they do not fit.

=item C<empty_text>

A string. Default: C<'No rows'>. Shown, in the C<muted_color> and
italic, when the table has no rows.

=item C<no_match_text>

A string. Default: C<'No rows match'>. Shown instead when the table has
rows but none passes the filters.

=back

=head3 Lines and spacing

=over

=item C<border>

The line style of all four sides of the frame. Default: C<'Round'>. The
values of this and the following parameters are described in
L<Term::Fabulous::Manual::TableStyles/Lines between and around the cells>.
The table draws its frame itself: it takes no C<bordered> (giving it
dies), and the C<table> family has no C<border.enabled>, so no theme
frames it (see L<Term::Fabulous::Theme/Borders>); C<'none'> leaves the
frame out.

=item C<border_top>, C<border_right>, C<border_bottom>, C<border_left>

One side of the frame. Default: C<undef>, the style of C<border>.

=item C<column_lines>

The lines between the columns. Default: C<'Solid'>.

=item C<row_lines>

The lines between the rows. Default: C<undef>, none.

=item C<header_line>

The line below the column titles and the filter row. Default:
C<'Solid'>. C<undef> takes the style of C<row_lines>.

=item C<cell_padding>

A non-negative integer (the left and right padding) or a hash reference
with any of C<left>, C<right>, C<top> and C<bottom>. Default: 1. See
L<Term::Fabulous::Manual::TableStyles/Cell padding>.

=back

=head3 Styles and colors

=over

=item C<row_style>

A code reference C<< sub ( $row, $id ) { ... } >> that returns a style
hash of the I<row> kind, or C<undef>. Default: none. See L<Term::Fabulous::Manual::TableStyles/Styles of
rows and cells>.

=item C<header_style>

A style hash of the I<row> kind for the column titles. Default: none.

=item C<group_style>

A style hash of the I<row> kind for group headers. Default: none.

=item C<stripe_color>

A color, or C<undef> (the default) for no stripes. See L<Term::Fabulous::Manual::TableStyles/Striped
rows>.

=item C<text_color>, C<header_text_color>, C<header_background_color>, C<group_text_color>, C<group_background_color>, C<cursor_color>, C<selected_color>, C<hover_color>, C<filter_background_color>, C<error_color>, C<muted_color>, C<line_color>

Colors in any format of L<Term::Fabulous::Color>. What each one colors,
and its default, is described in
L<Term::Fabulous::Manual::TableStyles/Colors>.

=back

=head1 METHODS

The methods are listed by topic. Unless a method says otherwise:

=over

=item *

A method that changes the table fires B<no> event. The change shows in
the next frame.

=item *

A method that is not an accessor and changes the table returns the
table, so calls can be chained.

=item *

Accessors return the value when called without an argument, and set it
with one. Setting returns the new value, except for C<rows>, C<search>,
C<filter_text>, C<group_by>, C<page>, C<page_size> and C<cursor>, which
return the table.

=item *

Methods that take a row id die when no row has that id; methods that
take a column key die when there is no such column.

=back

=head2 Methods for rows

=head3 rows

	my $rows = $table->rows;
	$table->rows( \@rows );

Without an argument: copies of all rows as an array reference, in data
order, in the form you gave them (in a tree, with the child rows nested
under C<children_key>). With an array reference of hash references:
replaces all rows. Rows whose id stays keep their selection; all tree
rows are closed again (or open, with C<tree_expanded>). Returns the
table.

=head3 add_row

	my $id = $table->add_row( \%row );
	my $id = $table->add_row( \%row, index => 0 );
	my $id = $table->add_row( \%row, parent => $parent_id, index => 2 );

Adds one row and returns its id. C<index> is the position among its
siblings in data order (0 is the first; default: after the last);
C<parent> makes it a child row of that row, which needs a tree. Dies
for an index out of range, an id in use, or other options.

=head3 add_rows

	my @ids = $table->add_rows( \@rows, %options );

Adds several rows, at one position, with the same options as
C<add_row>. Returns their ids. If one row is invalid, none is added.

=head3 update_row

	$table->update_row( $id, { name => 'Ada L.', team => 'Web' } );

Merges the hash of changes into the row's data. The keys need not be
column keys. Dies when the changes would give the row another id, or
contain C<children_key>. Returns the table.

=head3 replace_row

	$table->replace_row( $id, \%data );

Replaces the row's data with a copy of C<\%data> (an entry under
C<children_key> is ignored; the child rows stay). Dies when the data
would give the row another id. Returns the table.

=head3 set_value

	$table->set_value( $id, $key, $value );

Sets one entry of the row's data. C<$key> must be a column key; use
C<update_row> for other entries. Returns the table.

=head3 remove_row

	$table->remove_row($id);

Removes a row and all its child rows. They leave the selection, and
their styles from C<set_row_style> and C<set_cell_style> are forgotten.
Returns the table.

=head3 remove_rows

	$table->remove_rows(@ids);

Like C<remove_row>, for several rows. Dies before removing anything
when one of the ids is unknown.

=head3 clear_rows

	$table->clear_rows;

Removes all rows. Returns the table.

=head3 row

	my $data = $table->row($id);

A copy of the row's data (without its child rows).

=head3 value

	my $raw = $table->value( $id, $key );

The raw value of a cell: what the column reads or computes from the
row.

=head3 display_value

	my $text = $table->display_value( $id, $key );

The display text of a cell: the raw value after the column's mutators,
as a string (C<''> for C<undef>).

=head3 has_row

	if ( $table->has_row($id) ) { ... }

1 when a row has the id, 0 otherwise. Never dies.

=head3 row_ids

	my @ids = $table->row_ids;

The ids of all rows, in data order (in a tree: each row, then its
children).

=head3 row_count

	my $count = $table->row_count;

The number of rows, child rows included, filtered or not.

=head3 filtered_row_ids

	my @ids = $table->filtered_row_ids;

The ids of the rows that pass the filters and the search, in view order
(sorted and grouped), including rows inside closed groups and tree
rows.

=head3 page_row_ids

	my @ids = $table->page_row_ids;

The ids of the data rows on the current page, in the order they are
shown.

=head3 parent_of

	my $parent = $table->parent_of($id);

The id of the row's parent row, or C<undef> for a top-level row.

=head3 children_of

	my @ids = $table->children_of($id);

The ids of the row's child rows, in data order (all of them, filtered
or not).

=head2 Methods for columns

=head3 columns

	my @columns = $table->columns;

The L<Term::Fabulous::Widget::Table::Column> objects, in order, hidden
ones included.

=head3 column

	my $column = $table->column('salary');

One column object. Dies for an unknown key.

=head3 column_keys

	my @keys = $table->column_keys;

The keys of all columns, in order, hidden ones included.

=head3 add_column

	my $column = $table->add_column( \%definition );
	my $column = $table->add_column( \%definition, index => 0 );

Adds a column at the end, or at C<index> (0 is the first). Returns the
new column object. Dies when a column has the key already, for an index
out of range, or other options.

=head3 remove_column

	$table->remove_column('email');

Removes a column, also from the sort and the grouping, with every filter
that compares it and its filter field text. Returns the table.

=head3 move_column

	$table->move_column( email => 0 );

Moves a column to an index (0 is the first, the highest is the number of
columns minus 1). Returns the table.

=head3 update_column

	my $column = $table->update_column( salary => title => 'Pay', align => 'center' );

Replaces a column with a new one made from its parameters and the
changes, and returns the new column object. The column keeps its place
and whether it is visible: C<visible> in the changes has no effect (use
L</show_columns> and L</hide_columns>). The C<key> cannot be changed
(that dies).

=head3 visible_columns

	my @keys = $table->visible_columns;

The keys of the visible columns, in order.

=head3 is_column_visible

	if ( $table->is_column_visible('email') ) { ... }

1 or 0.

=head3 show_columns

	$table->show_columns(qw(email phone));

Shows the named columns, each at its place in the order of the columns.
Returns the table.

=head3 hide_columns

	$table->hide_columns('note');

Hides the named columns. Returns the table.

=head3 set_visible_columns

	$table->set_visible_columns(qw(name team));

Shows exactly the named columns and hides all others. The order of the
columns does not change. Returns the table.

=head3 open_column_chooser

	$table->open_column_chooser;

Opens the column chooser (see L<Term::Fabulous::Manual::Tables/Choosing the visible columns>) and
gives it the focus. Does nothing when it is open. Returns the table.
Changes the user makes in it fire C<ColumnsChange>.

=head3 close_column_chooser

	$table->close_column_chooser;

Closes the column chooser; when it had the focus, the table gets the
focus. Does nothing when it is closed. Returns the table.

=head3 is_column_chooser_open

1 while the column chooser is open, 0 otherwise.

=head2 Methods for sorting

=head3 sort_by

	$table->sort_by( 'team', [ salary => 'desc' ] );
	$table->sort_by;    # no sort

Sorts by the columns given, replacing the sort (see L<Term::Fabulous::Manual::TableRows/Sorting from
Perl>). Without arguments, the table is unsorted. Dies for an unknown
column, a direction other than C<'asc'> or C<'desc'>, or a column named
twice. Returns the table.

=head3 clear_sort

	$table->clear_sort;

The same as C<sort_by> without arguments.

=head3 sort_spec

	my $spec = $table->sort_spec;    # [ [ 'team', 'asc' ], [ 'salary', 'desc' ] ]

The sort, as an array reference of C<[ $key, $direction ]> pairs (a
copy). C<[]> when unsorted.

=head2 Methods for filtering

=head3 filter

	$table->filter( $name => $filter );
	$table->filter( $name => sub ($row) { ... } );
	$table->filter( $name => undef );    # remove it

Sets the filter of a name: a L<Term::Fabulous::Widget::Table::Filter>,
a code reference (called with a copy of each row's data; true keeps the
row), or C<undef> to remove it. A filter under the same name is
replaced. Dies for a name that is not a non-empty string or that starts
with C<column:> (those belong to the filter row), for a filter of
another kind, and for a filter that names an unknown column or compares
with a value its column's type cannot read. In a tree, opens the rows
that lead to matching rows. Returns the table.

=head3 remove_filter

	$table->remove_filter('adults');

Removes the filter of that name; does nothing when there is none.
Returns the table.

=head3 filter_names

	my @names = $table->filter_names;

The names of the filters set with C<filter>, in the order they were
first set. The filter row's filters are not listed.

=head3 clear_filters

	$table->clear_filters;

Removes all filters: those set with C<filter>, the search, and the text
of every filter field. Returns the table.

=head3 search

	$table->search('ada');
	my $text = $table->search;

Accessor for the search text (see L<Term::Fabulous::Manual::TableRows/Searching all columns>). C<''>
or C<undef> ends the search. Setting it returns the table. In a tree,
opens the rows that lead to matching rows.

=head3 filter_text

	$table->filter_text( size => '>=1000' );
	my $text = $table->filter_text('size');

Accessor for the filter expression of a column's filter field (see
L<Term::Fabulous::Manual::TableRows/The filter row>), also while the filter row is hidden. C<''> or
C<undef> removes the column's filter. An invalid expression does not
die: the column is then unfiltered, and C<filter_error> says why.
Setting it returns the table and fires no C<FilterChange>.

=head3 filter_error

	my $message = $table->filter_error('size');

Why the column's filter expression is invalid, or C<undef> when it is
valid or empty.

=head3 filter_row

	$table->filter_row(1);
	my $shown = $table->filter_row;

Accessor for the C<filter_row> parameter. Hiding the filter row keeps
the filters of its fields; use C<clear_filters> or C<filter_text> to
remove them. Setting it returns the new value.

=head2 Methods for groups

=head3 group_by

	$table->group_by( 'team', 'city' );
	$table->group_by(undef);           # no groups
	my @keys = $table->group_by;

Groups by the columns given, outermost first (see L<Term::Fabulous::Manual::TableRows/GROUPING>), and
returns the table. Without arguments, returns the keys of the group
columns (an empty list when not grouped). Dies for an unknown column or
a column named twice.

=head3 ungroup

	$table->ungroup;

Ends the grouping. Returns the table.

=head3 is_group_expanded

	if ( $table->is_group_expanded( 'Sales', 'Berlin' ) ) { ... }

1 when the group with that path is open, 0 when it is closed. Also 1
for a path that names no group.

=head3 expand_group

	$table->expand_group('Sales');
	$table->expand_group( 'Sales', 'Berlin' );

Opens the group with that path (the raw values of the group and the
groups around it, outermost first). Returns the table.

=head3 collapse_group

	$table->collapse_group( 'Sales', 'Berlin' );

Closes the group with that path. Returns the table.

=head3 expand_all_groups

	$table->expand_all_groups;

Opens every group, nested groups included. Returns the table.

=head3 collapse_all_groups

	$table->collapse_all_groups;

Closes every group there is now (with the current filters), nested
groups included. Groups that appear later start open. Returns the
table.

=head3 cursor_group

	my $path = $table->cursor_group;

The path of the group header the cursor is on (an array reference), or
C<undef> when the cursor is on a data row or there is no cursor.

=head2 Methods for trees

=head3 is_expanded

	if ( $table->is_expanded($id) ) { ... }

1 when the row is open, 0 otherwise.

=head3 expand

	$table->expand( '/src', '/src/lib' );

Opens the rows with these ids. Returns the table.

=head3 collapse

	$table->collapse('/src');

Closes the rows with these ids; their child rows keep their own state.
Returns the table.

=head3 expand_all

	$table->expand_all;

Opens every row that has child rows. Returns the table.

=head3 collapse_all

	$table->collapse_all;

Closes every row that has child rows. Returns the table.

=head3 children_key

	$table->children_key('children');

Accessor for the C<children_key> parameter. Setting it dies while the
table has rows; set it before adding rows. Setting returns the new
value.

=head3 tree_expanded

	$table->tree_expanded(1);

Accessor for the C<tree_expanded> parameter. Setting it affects rows
added afterwards, not the rows the table has. Setting returns the new
value.

=head3 tree_column

	$table->tree_column('name');
	$table->tree_column(undef);    # the first visible column

Accessor for the C<tree_column> parameter. Dies for an unknown column.
Setting returns the new value.

=head2 Methods for pages

=head3 page

	$table->page(3);
	my $page = $table->page;    # from 1

Accessor for the current page, counted from 1. Setting turns to that
page (a number above the last page turns to the last page) and, when the
page changes, puts the cursor on its first line; it dies for a number that is not a whole
number from 1. Setting returns the table. Without pages, the page is
always 1.

=head3 page_count

	my $pages = $table->page_count;

The number of pages, at least 1.

=head3 page_size

	$table->page_size(50);
	my $size = $table->page_size;

Accessor for the number of lines per page, 0 for no pages. Setting
keeps the cursor on its line and shows that line's page; it returns the
table. Dies for a value that is not a non-negative integer.

=head3 next_page

	$table->next_page;

Turns one page forward; on the last page, nothing happens. Returns the
table.

=head3 previous_page

	$table->previous_page;

Turns one page back; on the first page, nothing happens. Returns the
table.

=head3 page_sizes

	$table->page_sizes( [ 20, 50 ] );

Accessor for the C<page_sizes> parameter. Setting returns a copy of the
new list.

=head3 pager

	$table->pager(0);

Accessor for the C<pager> parameter (C<undef>, 1 or 0). Setting returns
the new value.

=head2 Methods for selection and cursor

=head3 selection

	$table->selection('multiple');
	my $mode = $table->selection;

Accessor for the selection mode. Setting keeps the part of the
selection the new mode allows (see L<Term::Fabulous::Manual::TableRows/Selection>), shows or hides the
selection column as C<selection_column> says, and returns the new mode.

=head3 selection_column

	$table->selection_column(0);

Accessor for the C<selection_column> parameter. Once set (by parameter
or accessor), it no longer follows the selection mode. Setting returns
the new value.

=head3 selected_ids

	my @ids = $table->selected_ids;

The ids of the selected rows, in data order.

=head3 selected_rows

	my @rows = $table->selected_rows;

Copies of the data of the selected rows, in data order.

=head3 is_selected

	if ( $table->is_selected($id) ) { ... }

1 or 0. Never dies.

=head3 set_selection

	$table->set_selection(@ids);
	$table->set_selection;    # nothing selected

Selects exactly these rows. Dies with C<< selection => 'none' >> when
ids are given, and for more than one id with C<'single'>. Returns the
table.

=head3 select

	$table->select(@ids);

Adds rows to the selection; with C<'single'>, selects the row instead
of the one selected before. Dies like C<set_selection>. Returns the
table.

=head3 deselect

	$table->deselect(@ids);

Removes rows from the selection. Returns the table.

=head3 select_all

	$table->select_all;

Adds every row that passes the filters to the selection. Dies unless
the mode is C<'multiple'>. Returns the table.

=head3 clear_selection

	$table->clear_selection;

Selects nothing. Returns the table.

=head3 cursor

	my $id = $table->cursor;
	$table->cursor($id);

Without an argument: the id of the row the cursor is on, or C<undef>
when it is on a group header or the view is empty. With a row id: puts
the cursor on that row, turns to its page, scrolls it into view and
returns the table. Dies when the row is not shown (filtered out, or
inside a closed group or tree row). Does not change the selection. See
L<Term::Fabulous::Manual::TableRows/The cursor>.

=head3 scroll_to_row

	$table->scroll_to_row($id);

The same as C<< $table->cursor($id) >>.

=head2 Methods for styles

=head3 set_row_style

	$table->set_row_style( $id, { background_color => '#3b3222', border_top => 'Double' } );

Sets the style hash (I<row> kind) of a row, replacing what was set for
it before; C<{}> or C<undef> removes it. Dies for unknown keys or
invalid values. Returns the table.

=head3 row_style_of

	my $style = $table->row_style_of($id);

A copy of what C<set_row_style> set for the row (colors as
C<[ $r, $g, $b, $a ]>, lines as L<Term::Fabulous::Enum::BorderStyle>
objects), C<{}> when nothing.

=head3 set_cell_style

	$table->set_cell_style( $id, 'amount', { text_color => '#e06c75' } );

Sets the style hash (I<cell> kind) of one cell, like C<set_row_style>.

=head3 cell_style_of

	my $style = $table->cell_style_of( $id, 'amount' );

A copy of what C<set_cell_style> set for the cell, C<{}> when nothing.

=head3 row_style

	$table->row_style( sub ( $row, $id ) { ... } );
	$table->row_style(undef);

Accessor for the C<row_style> code reference; C<undef> removes it.
Setting returns the new value.

=head3 group_label

	$table->group_label( sub ($group) { ... } );

Accessor for the C<group_label> code reference; C<undef> brings back
the default label. Setting returns the new value.

=head3 header_style

	$table->header_style( { background_color => '#2c313c' } );

Accessor for the C<header_style> style hash. Returns a copy; setting
returns a copy of the checked style.

=head3 group_style

	$table->group_style( { text_color => '#e5c07b' } );

Accessor for the C<group_style> style hash, like C<header_style>.

=head2 Methods for lines and spacing

The line accessors below take a line style name, a
L<Term::Fabulous::Enum::BorderStyle> object, C<'none'> or C<undef> (see
L<Term::Fabulous::Manual::TableStyles/Lines between and around the cells>).
They return the style as an object (the C<Hidden> style for C<'none'>),
or C<undef> for no line. L<Term::Fabulous::Widget::Table::Borders>
explains how the lines are worked out, who draws which side, and the
scrollbar column.

=head3 border

	$table->border('Double');
	my $style = $table->border;

Sets all four sides of the frame and returns the style of the top side.
Reading returns the style the four sides share, or C<undef> when they
differ or none has a style.

=head3 border_top

	$table->border_top('Heavy');

Accessor for the top side of the frame.

=head3 border_right

Accessor for the right side of the frame.

=head3 border_bottom

Accessor for the bottom side of the frame.

=head3 border_left

Accessor for the left side of the frame.

=head3 column_lines

	$table->column_lines('none');

Accessor for the lines between the columns.

=head3 row_lines

	$table->row_lines('Dashed');

Accessor for the lines between the rows.

=head3 header_line

	$table->header_line('Heavy');

Accessor for the line below the column titles. C<undef> takes the style
of C<row_lines>, as in the constructor.

=head3 cell_padding

	$table->cell_padding( { left => 2, right => 2 } );
	my $padding = $table->cell_padding;    # { left => 2, right => 2, top => 0, bottom => 0 }

Accessor for the C<cell_padding> parameter; returns a hash with all four
sides. Setting rebuilds every cell.

=head2 Methods for colors

	$table->cursor_color('#3e4451');
	my $rgba = $table->cursor_color;    # [ 62, 68, 81, 255 ]

Every color has an accessor of its name. It takes any format of
L<Term::Fabulous::Color> and returns C<[ $r, $g, $b, $a ]>; an invalid
color dies and keeps the old one.
L<The colors section of the table styles guide|Term::Fabulous::Manual::TableStyles/Colors>
describes what each color colors.

=head3 text_color

The text of the data cells and the filter fields, the pager's buttons
and page number, the text and frame of the column chooser, and the
scrollbar's thumb.

=head3 header_text_color

The text of the column titles.

=head3 header_background_color

The background of the column titles.

=head3 group_text_color

The text of group headers.

=head3 group_background_color

The background of group headers and of the column chooser.

=head3 cursor_color

The background of the cursor's line while the table has the focus, of
the column title the keyboard is on, and of a focused filter field.

=head3 selected_color

The background of selected rows.

=head3 hover_color

The background of the line under the mouse pointer.

=head3 filter_background_color

The background of the filter row.

=head3 error_color

The text of a filter field with an invalid expression.

=head3 muted_color

The text shown in an empty table, and the pager's count.

=head3 line_color

Every line that no style gives a C<border_color>, and the scrollbar's
track; while the scrollbar column is shown, also the right side of the
frame.

=head3 stripe_color

The background of every second data row; C<undef> for no stripes.

=head3 background_color

The background of cells that have no other; C<undef> for the background
of the nearest opaque ancestor.

=head2 Other accessors

Accessors for parameters with a single value. Setting returns the new
value.

=head3 header

	$table->header(0);

Whether the column titles are shown.

=head3 scrollbar

	$table->scrollbar(0);

Whether the scrollbar column is shown while the rows do not fit.

=head3 hover

	$table->hover(0);

Whether the line under the mouse pointer is highlighted.

=head3 empty_text

	$table->empty_text('Nothing here yet');

The text of a table without rows.

=head3 no_match_text

	$table->no_match_text('Nothing found');

The text of a table whose rows all are filtered out.

=head3 row_id

	$table->row_id('sku');

Where row ids come from (see L<Term::Fabulous::Manual::Tables/Row ids>). Setting it dies while the
table has rows.

=head3 estimated_rows

	my $rows = $table->estimated_rows($columns);

The rows the table will take before it is laid out (see
L<Term::Fabulous::Widget/estimated_rows>): the header, the rows of
the current page and the pager when there are pages, inside the
border. The lines between the rows are not counted.

=head2 Methods for searching

The table does L<Term::Fabulous::Role::Searchable>, so a widget that
searches its contents, such as L<Term::Fabulous::Widget::DocumentView>,
reaches every row of the table: the rows on other pages, and the rows
below collapsed rows and groups.

=head3 search_texts

	my @entries = $table->search_texts;    # ( [ [ $id, $key ], $text ], ... )
	                                       # [ $id, $key, $index, $inner ] in a custom cell

The text of every visible column of every row the filters let through,
in the order of the rows and the columns, as the cells show it
(L<Term::Fabulous::Widget::Table::Column/display_of>): the key is the
row id and the column key. A column with a C<cell> widget has no text
of its own; the texts of the searchable widgets inside the cell follow
instead, with the index and the key of the widget added, and only
while the row is built (on the current page, after a frame). Group
labels and column titles are not searched.

=head3 search_revision

	my $revision = $table->search_revision( [ $id, $key ] );

Changes when the row or the columns change; C<'gone'> for a row or a
column that no longer exists, and for a widget in a custom cell that is
not built.

=head3 highlight_text

	$table->highlight_text( [ $id, $key ], [ [ $start, $end, 'on selection' ] ] );

Marks ranges of a cell's text, now and whenever the cell is built again
(on another page, after sorting), until the row's data change or
L</clear_text_highlights> is called. Offsets past the cell's text die
at the call, also for a row that is not built. For a widget in a custom
cell the highlights go to that widget whenever the cell is built, and
the widget checks them then: its text exists only while the row is
built.

=head3 clear_text_highlights

	$table->clear_text_highlights;

Removes every highlight of every cell.

=head3 reveal_text

	my ( $text, $row ) = @{ $table->reveal_text( [ $id, $key ], $offset ) };

Shows the row: expands the rows and the groups above it, and moves the
cursor to it, which turns to its page and scrolls the body to it; it
fires no event and the selection does not change. Returns the cell's
L<Text|Term::Fabulous::Widget::Text> once the row is built, which is
after the next frame when the page turned, else C<undef>; the second
value (the row of the offset, see
L<Term::Fabulous::Role::Searchable/reveal_text>) is C<undef> for a text
cell. For a key into a custom cell, both values are those the widget
inside returns, once the row is built. A row the filters keep out cannot
be shown and gives C<undef> too.

=head2 Widgets of the table

The table builds its widgets itself; these methods give access to them
for reading and testing. Do not add, remove or rearrange their
children.

=head3 cell_widget

	my $widget = $table->cell_widget( $id, $key );

The widget a cell shows: the widget of the column's C<cell> code, or a
L<Term::Fabulous::Widget::Text>. C<undef> when the row is not on the
current page, the column is hidden, or the table has not been drawn
since the row was added.

=head3 body

The L<Term::Fabulous::Widget::ScrollBox> that holds the rows, with the
id C<"$id/body">.

=head3 pager_widget

The L<Term::Fabulous::Widget::Table::Pager>, also while it is not
shown.

=head3 model

The L<Term::Fabulous::Widget::Table::Model> that holds the data and the
view. Read from it as you like, for example the lines of the view;
change the table only through the table's methods.

=head3 prepare_layout

Called by L<Clay::UI> once per frame, before the layout, when the table
changed (see L<Clay::UI::Role::Core::Preparable>); it brings the
widgets up to date. You do not call it.

=head3 layout_properties

The table of the KDL properties (see L</KDL PROPERTIES> and
L<Term::Fabulous::Role::CanParseLayout/layout_properties>).

=head3 apply_layout_node

Called by L<Term::Fabulous::Layout> when it builds a table from a KDL
node (see L<Term::Fabulous::Role::CanParseLayout>). Dies for child
widget nodes. You do not call it.

=head3 apply_layout_settings

Called by L</apply_layout_node> with the properties of the node. Applies
C<row_id> and C<children_key> first, then the columns, then the other
properties, and C<sort> and C<group_by> last. You do not call it.

=head1 KEYS

The table uses these keys while it has the focus. Keys it does not use
bubble to its ancestors (see L<Term::Fabulous::Manual::Events/KEYBOARD>), among
them C<Tab>, which moves the focus on.

=head2 On the rows

=for highlighter language=text

	Up, Down                 the previous or next line of the page
	PageUp, PageDown         as many lines back or forward as the rows show, minus one,
	                         so that one line stays in view (within the page)
	Home, End                the first or last line of the page
	Ctrl+Home, Ctrl+End      the first or last line of all pages
	Ctrl+PageUp              the previous page (the cursor goes to its first line)
	Ctrl+PageDown            the next page
	Up on the first line     into the header (see below), when titles are shown

	Enter                    on a data row: fire RowActivate
	                         on a group header: open or close the group
	Space                    selection 'multiple': select or deselect the row
	                         selection 'single': select the row
	                         on a group header: open or close the group
	Shift+Up, Shift+Down,    selection 'multiple': select the range from the line where the
	Shift+PageUp/PageDown,   range started to the new cursor line
	Shift+Home, Shift+End
	Ctrl+A                   selection 'multiple': select every row that passes the filters,
	                         or deselect them all when all of them are selected already
	                         (selected rows hidden by a filter stay selected)

	Right, +                 open the tree row or group; on an open one, Right goes to the
	                         first line inside it
	Left, -                  close the tree row or group; on a closed one (or a row without
	                         children), Left goes to the parent row or the group header above

With selection C<'single'>, every move of the cursor onto a data row
also selects that row. A moving key fires C<CursorMove> when the cursor
moves, then C<PageChange> when the page changes, then
C<SelectionChange> when the selection changes.

=head2 In the header

C<Up> on the first line of the page moves the keyboard into the row of
column titles; the title it is on is drawn in the C<cursor_color>.

	Left, Right              the previous or next column title
	Home, End                the first or last column title
	Enter                    sort by this column alone: ascending, descending, unsorted
	Space                    add this column to the sort, or cycle its direction
	                         (Enter and Space do nothing on a column with sortable => 0)
	Enter or Space on [ ]    the same as Ctrl+A on the rows
	c                        open the column chooser
	Down, Escape             back to the rows

=head2 In the filter row

	Enter, Down              back to the rows
	Escape                   empty the field (when it has text)

All other keys edit the text as in any L<Term::Fabulous::Widget::TextField>.
C<Tab> and C<Shift+Tab> move between the fields.

=head2 In the column chooser

	Tab, Shift+Tab           the next or previous check box; Tab after the last one
	                         leaves the chooser, which closes it
	Space, Enter             show or hide the column
	Escape                   close the chooser; the table gets the focus

=head2 In a widget inside a cell

The widget gets the keys first. Movement keys it does not use move the
table's cursor and give the focus back to the table; C<Enter> and
C<Space> are left to the widget. See L<Term::Fabulous::Manual::Tables/Keys and clicks in cell
widgets>.

=head1 MOUSE

=over

=item *

B<Click on a row>: moves the cursor there (C<CursorMove>). With
C<< selection => 'single' >>, selects the row. With C<'multiple'>, a
plain click selects only that row; C<Ctrl>+click or C<Alt>+click
selects or deselects it and keeps the others; C<Shift>+click selects
the range from where the range started to that row; a click into the
selection column selects or deselects that row and keeps the others.

=item *

B<Double click on a row> (two presses of the left button on the same
character of a line, without moving the pointer, a
L<click_count|Term::Fabulous::Event::Mouse/click_count> of 2 within the
UI's L<double_click_seconds|Term::Fabulous/double_click_seconds>): each
click does what a click does (moves the cursor, selects), then the
second one fires C<RowActivate>. A third quick click is a single click
again, a fourth a double click.

=item *

B<Click on a group header> or on the marker of a tree row: opens or
closes it (C<Expand> or C<Collapse>) and moves the cursor there.

=item *

B<Click on a column title>: sorts by it alone (ascending, descending,
unsorted). With C<Shift>, C<Ctrl> or C<Alt>: adds it to the sort, or
cycles it within the sort. A click on the title of the selection column
does what C<Ctrl+A> does on the rows (see L<Term::Fabulous::Manual::TableRows/Selection>).

=item *

B<Right click on a column title>: opens the column chooser.

=item *

B<Click or drag on the scrollbar>: scrolls so that the thumb is
centered where the pointer is.

=item *

B<Wheel>: scrolls the rows up and down; a horizontal wheel scrolls them
sideways, and the titles and the bottom of the frame follow (not while
a column is C<grow> or C<percent>: such a table wraps the text of its
columns instead).

=item *

B<Pointer over a row>: with C<< hover => 1 >>, the line under the
pointer is drawn in the C<hover_color>.

=item *

B<Click on an input in a cell>: goes to the input; the table moves its
cursor to the row (with C<< selection => 'single' >>, that selects it).
See L<Term::Fabulous::Manual::Tables/Keys and clicks in cell widgets>.

=back

=head1 EVENTS

The table fires these events on itself when the user acts; changes from
your program fire none. Listen with C<< $table->on( Name => sub ($event) { ... } ) >>.
Every event bubbles to the table's ancestors like all events (see
L<Term::Fabulous::Manual::Events/Return values and bubbling>), and
C<< $event->target >> is the table. Each event's page describes it in
full.

=over

=item C<CursorMove>

L<Term::Fabulous::Event::CursorMove>: the user moved the cursor.
C<< $event->row_id >> is the row it is on now, or C<undef> on a group
header, where C<< $event->group_path >> is the group's path.

=item C<SelectionChange>

L<Term::Fabulous::Event::SelectionChange>: the user changed the
selection. C<< $event->selected_ids >>, C<< $event->added_ids >> and
C<< $event->removed_ids >> are array references of row ids.

=item C<RowActivate>

L<Term::Fabulous::Event::RowActivate>: C<Enter> on a data row or a
double click on it. C<< $event->row_id >> and C<< $event->row >> (a
copy of its data).

=item C<SortChange>

L<Term::Fabulous::Event::SortChange>: the user changed the sort with a
click or a key in the header. C<< $event->sort >> is the new sort, like
C<sort_spec>.

=item C<FilterChange>

L<Term::Fabulous::Event::FilterChange>: the user changed the text of a
filter field. C<< $event->column >>, C<< $event->text >>, and
C<< $event->error >> (the reason the text is not a valid expression,
else C<undef>).

=item C<PageChange>

L<Term::Fabulous::Event::PageChange>: the user turned the page or
changed the page size. C<< $event->page >> and
C<< $event->page_size >>.

=item C<Expand>, C<Collapse>

L<Term::Fabulous::Event::Expand> and
L<Term::Fabulous::Event::Collapse>: the user opened or closed a tree
row (C<< $event->row_id >>) or a group (C<< $event->group_path >>; the
other one is C<undef>).

=item C<ColumnsChange>

L<Term::Fabulous::Event::ColumnsChange>: the user showed or hid a
column in the column chooser. C<< $event->visible >> is the keys of the
visible columns.

=back

When one key or click causes several events, they come in this order:
C<CursorMove>, C<PageChange>, C<SelectionChange>, then C<RowActivate>,
C<Expand> or C<Collapse>.

To add keys of your own, listen for C<KeyPress> (see
L<Term::Fabulous::Manual::Events/KEYBOARD>). A listener on the table itself
gets every key the table gets, also the ones the table uses (C<Up>,
C<Enter>, ...); it must return C<< Clay::UI::Enum::Result->CONTINUE >>
for keys it does not use, or they stop at the table (C<Tab> too, see
L<Term::Fabulous::Manual::Events/Return values and bubbling>). A listener on an
ancestor of the table gets only the keys the table does not use,
because the table stops the others from bubbling further.

=head1 KDL PROPERTIES

A table can be part of a KDL layout (see
L<Term::Fabulous::Manual::KDL/KDL LAYOUT FILES>). The layout describes the
table: its columns, sort, grouping, lines, colors and options. The rows,
everything that is a code reference (mutators, cell widgets,
callbacks) and the style hashes C<header_style> and C<group_style> of
the table come from Perl.

=for highlighter language=kdl

	use Term::Fabulous::Widget::Table as Table

	Table "inventory" {
		sizing width=grow height=grow
		selection multiple
		row_id "sku"
		page_size 25
		page_sizes 25 50 100
		filter_row #true
		stripe_color "#1c2029"
		lines frame=Round columns=Solid rows=none header=Heavy color="#5c6370"
		cell_padding left=1 right=1

		column "sku" title="SKU" width="fixed(10)"
		column "name" title="Name" width=grow compare=natural
		column "qty" title="Qty" type=number {
			style text_color="#e5c07b" border_left=Heavy
			header_style text_color="#e5c07b"
		}
		column "updated" title="Updated" type=date visible=#false
		column "category" title="Category"

		sort "qty" "desc"
		sort "name"
		group_by "category"
	}

	use Term::Fabulous::Layout;
	use Term::Fabulous::Widget::Table::Mutator qw(date);

	my $root  = Term::Fabulous::Layout->new( file => 'inventory.kdl' )->build;
	my $table = $root->find_by_id('inventory');    # here the root itself
	$table->rows( \@items );
	$table->update_column( updated => mutator => date() );

The properties:

=over

=item C<column "key" ...>

A column, with the key as its argument. Properties: C<title>, C<type>,
C<width>, C<align>, C<header_align>, C<wrap>, C<sortable>,
C<filterable>, C<filter_on>, C<compare> (not a code reference) and
C<visible>, with the values of the column parameters. Inside its block,
an optional C<style> node with the keys of a style hash of the
I<column> kind (C<text_color>, C<background_color>, C<bold>, C<italic>,
C<underline>, C<border_color>, C<border_left>, C<border_right>,
C<row_lines>), and an optional C<header_style> node with the keys of
the I<header> kind (the first six of these); see
L<Term::Fabulous::Manual::TableStyles/Style keys>. Repeat C<column> for
every column, in order. The other column parameters (C<value>,
C<mutator>, C<cell>, ...) are code references; add them from Perl with
L</update_column>, as below.

=item C<sort "key" ["asc" or "desc"]>

Adds a column to the sort; the direction defaults to C<asc>. Repeat it
for a sort by several columns, the first one first.

=item C<group_by "key" ...>

The group columns, outermost first.

=item C<lines frame=... top=... right=... bottom=... left=... columns=... rows=... header=... color=...>

The lines: C<frame> is the parameter C<border>, C<top> to C<left> are
C<border_top> to C<border_left>, C<columns> is C<column_lines>, C<rows>
is C<row_lines>, C<header> is C<header_line>, C<color> is
C<line_color>. Each takes a line style name or C<none>. Every key is
optional.

=item C<cell_padding N>, C<cell_padding left=... right=... top=... bottom=...>

The C<cell_padding> parameter.

=item C<page_sizes N N ...>

The C<page_sizes> parameter.

=item C<selection>, C<selection_column>, C<page_size>, C<pager>, C<filter_row>, C<header>, C<scrollbar>, C<hover>, C<row_id>, C<children_key>, C<tree_expanded>, C<tree_column>, C<empty_text>, C<no_match_text>

The parameters of the same names, with one value each (booleans as
C<#true> and C<#false>; C<row_id> only as a key).

=item C<text_color>, C<header_text_color>, C<header_background_color>, C<group_text_color>, C<group_background_color>, C<cursor_color>, C<selected_color>, C<hover_color>, C<filter_background_color>, C<error_color>, C<muted_color>, C<line_color>, C<stripe_color>

The colors of the parameters of the same names, in any of the
L<color forms of a layout file|Term::Fabulous::Manual::KDL/Colors>.

=item the properties of a Box

C<sizing>, C<background_color> and the other
L<KDL properties of a Box|Term::Fabulous::Widget::Box/KDL PROPERTIES>. Note that a Box's
C<border> property is the Box border around the whole widget, not the
table's frame; the frame is C<lines frame=...>.

=back

C<row_id> and C<children_key> are applied first, then the columns, then
the other properties, and C<sort> and C<group_by> last, wherever they
stand in the block. A table takes no child widget nodes; one dies.

=head1 PERFORMANCE

L<Term::Fabulous> lays out every widget of the screen in every frame
that changed, and a table makes about two widgets per cell. What costs
time is therefore the number of cells B<shown>, not the number of rows:

=over

=item *

Up to a few hundred rows, a table without pages responds at once.

=item *

For more rows, use C<page_size>. With pages, only the cells of one page
are widgets, and a table of 10,000 rows with pages of 50 lines answers a
key press in a few hundredths of a second. Sorting or filtering 10,000
rows takes a few tenths of a second the first time; the table keeps the
display texts, so later searches are fast.

=item *

A table without pages builds widgets for all its rows, about two per
cell. A L<Term::Fabulous> program fits about 8,190 widgets on the
screen by default (C<max_element_count> 8192), so a table of 5 columns
without pages reaches the limit at about 750 rows and then dies when it
is drawn. Raise C<max_element_count> (see L<Term::Fabulous/new>) or,
better, use pages: with a limit high enough, 1,000 rows of 5 columns
without pages take about half a second per key press. The same limit
applies to a large page of many columns.

=item *

Custom C<compare> functions are called for every comparison of a sort;
named comparisons compute one key per row. Mutators and C<value> code
run once per cell and row change.

=back

=head1 CAVEATS

=over

=item *

A table needs an C<id>, and uses C<"$id/body"> as the id of its body.

=item *

A table takes no child widgets: its cells come from its columns and
rows. Do not call C<add_child> on it, and do not change its C<layout>
other than its C<sizing>.

=item *

Cell widgets can be replaced by new ones at any time (see L<Term::Fabulous::Manual::Tables/When cell
widgets are built>). Keep state in the row data.

=item *

The cursor is drawn only while the table has the focus.

=item *

Changes from your program fire no events. If a listener also has to
run for them, call it yourself.

=item *

Many terminals keep C<Shift>+click for selecting text on the screen and
do not report it to programs; C<Ctrl>+click and the keyboard work
there.

=back

=head1 SEE ALSO

L<Term::Fabulous::Widget::Table::Column>, L<Term::Fabulous::Widget::Table::Mutator>,
L<Term::Fabulous::Widget::Table::Filter>, L<Term::Fabulous::Widget::Table::Value>,
L<Term::Fabulous::Widget::Table::Model>, L<Term::Fabulous::Widget::Table::Style>,
L<Term::Fabulous::Widget::Table::Borders>, L<Term::Fabulous::Widget::Table::Pager>,
L<Term::Fabulous::Widget::Table::ColumnChooser>,
L<Term::Fabulous::Widget::Table::EdgeView>,
L<Term::Fabulous::Widget::Table::Cell>,
L<Term::Fabulous::Manual::Tables>, L<Term::Fabulous::Manual::TableRows>,
L<Term::Fabulous::Manual::TableStyles>, L<Term::Fabulous::Cookbook::Tables>,
L<Term::Fabulous::Cookbook::TableRows>, L<Term::Fabulous::Cookbook::TableStyles>,
L<Term::Fabulous::Examples>.

=cut
