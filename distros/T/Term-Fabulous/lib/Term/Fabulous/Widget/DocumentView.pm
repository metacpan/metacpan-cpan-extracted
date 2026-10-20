package Term::Fabulous::Widget::DocumentView;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

use Clay::UI::Role::Interaction::Focusable;
use Clay::UI::Role::Interaction::HasFocusOrder;
use Term::Fabulous::Widget::VirtualList;

our $VERSION = '0.05';

class Term::Fabulous::Widget::DocumentView
	:isa(Term::Fabulous::Widget::VirtualList)
	:does(Clay::UI::Role::Interaction::Focusable)
	:does(Clay::UI::Role::Interaction::HasFocusOrder)
	:strict(params)
{
	use Clay::UI::Enum::Result;
	use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);
	use List::Util qw(any first max min);
	use Scalar::Util qw(blessed refaddr weaken);
	use Term::Fabulous::Check qw(describe non_negative_integer);
	use Term::Fabulous::Document;
	use Term::Fabulous::Document::Look;
	use Term::Fabulous::Event::LinkActivate;
	use Term::Fabulous::Event::ViewChange;
	use Term::Fabulous::Scrolling qw(inner_rows reveal_rows scroll_by_key scroll_by_pages scroll_by_rows scrolled_percent);
	use Term::Fabulous::Termbox qw(TF_KEY_MOUSE_WHEEL_LEFT TF_KEY_MOUSE_WHEEL_RIGHT);
	use Term::Fabulous::Widget::Box;

	use constant {
		CODE_STEP          => 8,    # columns the code moves per Left or Right
		CODE_WHEEL_COLUMNS => 3,    # and per notch of the horizontal wheel
		REVEAL_FRAMES      => 8,    # frames a reveal may take until its line is in view
		FOCUS_FRAMES       => 4,    # frames a widget far away may take to be built for the focus
		QUOTE_COLUMNS      => 2,    # the bar of a quote and the space after it
	};

	my $CONTINUE = Clay::UI::Enum::Result->CONTINUE;

	field $document    :param = undef;
	field $highlighter :param = undef;
	field $indent      :param = 2;

	# The slots built for items, by index: { slot => what the list shows,
	# holder => the box the item is the child of, item, quotes => the
	# boxes whose left border is a quote bar }.
	field %slot_of;

	# How far the code blocks are scrolled sideways, together.
	field $code_offset = 0;

	# The search: { query, matches => [ [ item index, widget, key, start,
	# end, revision ] ], current, groups => { id => { widget, key,
	# members } }, group_of => [ id per match ], painted => { refaddr =>
	# widget } }; undef without one.
	field $search;

	# The selected link: { index, text, link, revision }, or undef.
	field $selected;

	# What the last ViewChange said; the line of an item being brought
	# into view ({ index, widget, key, offset }) and the widget to focus
	# once its item is built ({ widget }). The frame work that follows a
	# request holds it; these weak copies only tell which request is the
	# current one, so setting one to undef cancels it, and it is undef
	# again once its frame work ended.
	field $reported = '';
	field $pending_reveal;
	field $pending_focus;

	# The list's build, estimate and count are the document's: a
	# placeholder satisfies VirtualList's constructor until ADJUST, where
	# $self exists, installs the real ones.
	sub BUILDARGS ( $class, %params ) {
		foreach my $name (qw(build estimate count)) {
			die "$class: $name cannot be given; the view builds its items from its document" if exists $params{$name};
		}
		return $class->SUPER::BUILDARGS( %params, build => sub ($index) { die "$class: the builder is installed in ADJUST" } );
	}

	ADJUST {
		$highlighter = _checked_highlighter( $self, $highlighter );
		$indent      = non_negative_integer( $self, indent => $indent );
		$document    = $self->_checked_document($document);
		$document->_attach_view($self) if defined $document;

		weaken( my $weak_self = $self );    # for the build and estimate code, which the list keeps
		$self->SUPER::build( sub ($index) { return $weak_self->_build_slot($index) } );
		$self->SUPER::estimate( sub ( $index, $columns ) { return $weak_self->_item_rows( $index, $columns ) } );
		$self->on( KeyPress     => sub ( $self, $event ) { return $self->_key($event) },                                owner => $self );
		$self->on( Mouse        => sub ( $self, $event ) { return $self->_wheel($event) },                              owner => $self );
		$self->on( LinkActivate => sub ( $self, $event ) { return $self->_link_clicked($event) },                       owner => $self );
		$self->on( OnFocus      => sub ( $self, $event ) { $self->_focus_arrived( $event->target ); return $CONTINUE }, owner => $self );
		$self->_show_document;
	}

	method _checked_document ($value) {
		return undef unless defined $value;
		die ref($self) . ": document must be a Term::Fabulous::Document or undef, got " . describe($value) unless blessed $value && $value->isa('Term::Fabulous::Document');
		return $value;
	}

	sub _checked_highlighter ( $owner, $value ) {
		die ref($owner) . ": highlighter must be a code reference or undef, got " . describe($value) if defined $value && ref $value ne 'CODE';
		return $value;
	}

	# The look of the document, in the theme the view draws with.
	method document_look () {
		return $self->_look_class->of($self);
	}

	method _look_class () {
		return defined $document ? $document->look : 'Term::Fabulous::Document::Look';
	}

	# ---------------------------------------------------------------------
	# Parameters
	# ---------------------------------------------------------------------

	method document (@new) {
		return $document unless @new;
		my $new = $self->_checked_document( $new[0] );
		$new->_attach_view($self) if defined $new;
		$self->_forget_marks;
		$document->_detach_view($self) if defined $document && !( defined $new && refaddr($new) == refaddr($document) );
		$document = $new;
		$self->_show_document;
		return $document;
	}

	method highlighter (@new) {
		return $highlighter unless @new;
		$highlighter = _checked_highlighter( $self, $new[0] );
		$_->highlighter($highlighter) foreach $self->_document_code;
		return $highlighter;
	}

	method indent (@new) {
		return $indent unless @new;
		$indent = non_negative_integer( $self, indent => $new[0] );
		$self->rebuild;
		return $indent;
	}

	# The list's own parameters are the document's business.
	method build :override (@new) {
		die ref($self) . ": build cannot be set; the view builds its items from its document" if @new;
		return $self->SUPER::build;
	}

	method estimate :override (@new) {
		die ref($self) . ": estimate cannot be set; the view estimates its items from its document" if @new;
		return $self->SUPER::estimate;
	}

	method count :override (@new) {
		die ref($self) . ": count cannot be set; it is the number of items of the document" if @new;
		$self->_adopt_new_items;
		return $self->SUPER::count;
	}

	# Items added to the document since the view last looked join the
	# list: before a frame, and before anything that needs their indexes.
	method _adopt_new_items () {
		return unless defined $document;
		my $count = $document->count;
		$self->SUPER::count($count) if $count != $self->SUPER::count;
		return;
	}

	# The items leave their slots, so that they can be shown again, in new
	# slots or by another view.
	method rebuild :override () {
		foreach my $built ( values %slot_of ) {
			my ( $item, $holder ) = @{$built}{qw(item holder)};
			my $parent = $item->parent;
			$holder->remove_child($item) if defined $parent && refaddr($parent) == refaddr($holder);
		}
		%slot_of = ();
		return $self->SUPER::rebuild;
	}

	# A new document starts at its top, with no marks, its code not
	# scrolled sideways, and a ViewChange for its first frame.
	method _show_document () {
		( $pending_reveal, $pending_focus ) = ();
		( $code_offset,    $reported )      = ( 0, '' );
		$self->rebuild;
		$self->SUPER::count( defined $document ? $document->count : 0 );
		foreach my $code ( $self->_document_code ) {
			$code->highlighter($highlighter) if defined $highlighter;
			$code->offset(0);
		}
		$self->scroll_to_item(0) if $self->SUPER::count;
		return;
	}

	method _document_code () {
		return defined $document ? $document->code_blocks : ();
	}

	# ---------------------------------------------------------------------
	# The slots of the items
	# ---------------------------------------------------------------------

	# Columns before an item: the view's indent, unless the item is flush,
	# and its own.
	method _left_of ($option) {
		return ( $option->{flush} ? 0 : $indent ) + $option->{indent};
	}

	# The item in a box that gives it its indent and the blank rows above
	# it, inside a bar for each quote it is in. The blank rows stay inside
	# the innermost bar, so the bars of one quote join.
	method _build_slot ($index) {
		my $item   = $document->item($index);
		my $option = $document->options_of($index);
		my $holder = Term::Fabulous::Widget::Box->new(
			layout => {
				layout_direction => CLAY_TOP_TO_BOTTOM,
				sizing           => { width => sizing_grow() },
				padding          => { left  => $self->_left_of($option), top => $index ? $option->{gap} : 0 },
			}
		);
		$holder->add_child($item);
		my ( $slot, @quotes ) = ($holder);
		foreach ( 1 .. $option->{quote} ) {
			my $quote = Term::Fabulous::Widget::Box->new(
				bordered => { left             => 1 },
				layout   => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow() }, padding => { left => QUOTE_COLUMNS - 1 } },
			);
			$quote->add_child($slot);
			push @quotes, $quote;
			$slot = $quote;
		}
		$slot_of{$index} = { slot => $slot, holder => $holder, item => $item, quotes => \@quotes };
		$self->_color_quotes( $slot_of{$index} );
		$self->_settle_code($index);
		return $slot;
	}

	# The code blocks of an item built after the document was shown take
	# what the others got then: the view's highlighter, for a code block
	# of the document, and the offset the code is scrolled to.
	method _settle_code ($index) {
		my $item = $slot_of{$index}{item};
		$item->highlighter($highlighter) if defined $highlighter && any { refaddr($_) == refaddr($item) } $self->_document_code;
		$_->offset($code_offset) foreach $self->_built_code($index);
		return;
	}

	method _color_quotes ($built) {
		return unless @{ $built->{quotes} };
		my $color = $self->document_look->style('quote')->{color};
		$_->border_color($color) foreach @{ $built->{quotes} };
		return;
	}

	# The rows of an item before it was laid out: the blank rows above it,
	# and what the item says it takes in the columns left for it (see
	# Term::Fabulous::Widget::estimated_rows), or what the document says.
	method _item_rows ( $index, $columns ) {
		my $option = $document->options_of($index);
		my $top    = $index ? $option->{gap} : 0;
		return $top + $option->{rows} if defined $option->{rows};
		my $item  = $document->item($index);
		my $inner = max( 1, $columns - $self->_left_of($option) - QUOTE_COLUMNS * $option->{quote} );
		return $top + ( $item->can('estimated_rows') ? $item->estimated_rows($inner) : 1 );
	}

	# A theme switch recolors the quote bars; everything else draws with
	# palette tokens and follows by itself. The ScrollBox pads its gutter
	# for the border first.
	method looks_changed :override (@names) {
		$self->SUPER::looks_changed(@names);
		$self->_color_quotes($_) foreach values %slot_of;
		return;
	}

	# The item a widget belongs to: its index, or undef for a widget that
	# is in none (the view, its scrollbars).
	method _item_index_of ($widget) {
		return undef unless defined $document;
		foreach my $node ( $widget, $widget->ancestors ) {
			last if refaddr($node) == refaddr($self);
			my $index = $document->index_of($node);
			return $index if defined $index;
		}
		return undef;
	}

	# ---------------------------------------------------------------------
	# Scrolling
	# ---------------------------------------------------------------------

	method scroll_lines ($lines) {
		my $ui = $self->ui // return 0;
		return scroll_by_rows( $ui, $self, $lines );
	}

	# A page is the rows the content shows less one (see
	# Term::Fabulous::Scrolling).
	method scroll_pages ($pages) {
		my $ui = $self->ui // return 0;
		return scroll_by_pages( $ui, $self, $pages );
	}

	method scroll_to_top () {
		return 0 unless $self->count;
		$self->scroll_to_item(0);
		return 1;
	}

	method scroll_to_bottom () {
		my $count = $self->count or return 0;
		$self->scroll_to_item( $count - 1 );
		return 1;
	}

	method show_item ($index) {
		$self->_adopt_new_items;
		$self->scroll_to_item($index);
		return $self;
	}

	method top_item () {
		my $visible = $self->visible_items // return undef;
		return $visible->{first};
	}

	# Brings the line that holds a character of a text into view, with as
	# little movement as possible. An item that is not laid out goes to
	# the top first, and its line follows once it is. The list may move
	# the item to the top once more in the next frame (it repeats
	# scroll_to_item until it has measured the item), and a widget may
	# build the text only in the next frame (a table turns to a page), so
	# the reveal is checked again after each of a few frames, until the
	# line is in view. A new reveal replaces one still waiting.
	method _reveal ( $index, $widget, $key, $offset ) {
		my $request = { index => $index, widget => $widget, key => $key, offset => $offset };
		$pending_reveal = undef;
		return 1 unless $self->_reveal_line_now($request);
		weaken( $pending_reveal = $request );
		$self->_follow_frames( 'reveal line', sub ($view) { return $view->_continue_reveal($request) }, REVEAL_FRAMES );
		return 1;
	}

	# True when the reveal is done: cancelled, replaced or in view.
	method _continue_reveal ($request) {
		return 1 unless _is_current( $pending_reveal, $request );
		return $self->_reveal_line_now($request) ? 0 : 1;
	}

	sub _is_current ( $pending, $request ) {
		return defined $pending && refaddr($pending) == refaddr($request) ? 1 : 0;
	}

	# One attempt: 1 when the view had to move or could not tell yet, 0
	# when the line is in view.
	method _reveal_line_now ($request) {
		my ( $index, $widget, $key, $offset ) = @{$request}{qw(index widget key offset)};
		my $ui    = $self->ui;
		my $built = $slot_of{$index};
		my $box   = defined $ui && defined $built ? $ui->bounding_box( $built->{slot} ) : undef;
		my ( $top, $bottom ) = defined $box ? inner_rows( $ui, $self ) : ();
		unless ( defined $top ) {
			$self->show_item($index);
			return 1;
		}
		my $row = $self->_row_of( $ui, $widget, $key, $offset );
		unless ( defined $row ) {
			reveal_rows( $ui, $self, $box->{y}, $box->{y} + 1 );
			return 1;
		}
		return 0 if $row >= $top && $row < $bottom;
		reveal_rows( $ui, $self, $row, $row + 1 );
		return 1;
	}

	# The screen row of a character in the last frame: a widget that knows
	# the row (a code block, by its line) tells it; a text is looked up in
	# its painted lines. Clay leaves out the lines of a text below the
	# window, so for a character past the last line painted the text
	# works the row out from its wrapping. undef while the widget shows
	# no text for the key yet.
	method _row_of ( $ui, $widget, $key, $offset ) {
		my ( $text, $row ) = @{ $widget->reveal_text( $key, $offset ) };
		if ( defined $row ) {
			my $box = $ui->bounding_box($widget) // return undef;
			return $box->{y} + $row;
		}
		return undef unless defined $text;
		my $box   = $ui->bounding_box($text) // return undef;
		my $frame = $ui->can('last_frame') ? $ui->last_frame          : undef;
		my @lines = defined $frame         ? $frame->text_rows($text) : ();
		my $line  = ( grep { $_->[1] <= $offset } @lines )[-1];
		my $cut   = !defined $line || ( refaddr($line) == refaddr( $lines[-1] ) && $box->{y} + $box->{height} > $line->[0] + 1 );
		return $line->[0] unless $cut;
		return $box->{y} + ( $text->can('row_of_offset') ? $text->row_of_offset( $offset, max( 1, int( $box->{width} + 0.5 ) ) ) : 0 );
	}

	method code_offset () {
		return $code_offset;
	}

	# The code blocks of the items with these indexes that are built.
	method _built_code (@indexes) {
		return grep { $_->isa('Term::Fabulous::Widget::CodeBlock') } map { $_->{item}->subtree } grep { defined } @slot_of{@indexes};
	}

	# Scrolls every code block sideways, as far as the widest one in view
	# allows; blocks out of view move along, so that they match when they
	# come back. Only blocks in view that were painted know how much of
	# them shows.
	method scroll_code ($columns) {
		my $visible = $self->visible_items;
		my @in_view = defined $visible ? grep { $_->columns > 0 } $self->_built_code( $visible->{first} .. $visible->{last} ) : ();
		my $limit   = max 0, map { $_->max_offset } @in_view;
		my $from    = min( $code_offset,               $limit );
		my $wanted  = min( max( 0, $from + $columns ), $limit );
		return 0 if $wanted == $from;
		$code_offset = $wanted;
		my %seen;
		$_->offset($code_offset) foreach grep { !$seen{ refaddr $_ }++ } $self->_document_code, $self->_built_code( keys %slot_of );
		return 1;
	}

	# A notch of the horizontal wheel over a code block scrolls the code,
	# while it can move; at the end, the notch goes on. Texts and blank
	# rows take no mouse events, so a notch over them reaches the view
	# only when the view is the root widget.
	method _wheel ($event) {
		my $key       = $event->key;
		my $direction = $key == TF_KEY_MOUSE_WHEEL_LEFT ? -1 : $key == TF_KEY_MOUSE_WHEEL_RIGHT ? 1 : 0;
		return $CONTINUE unless $direction && $self->scroll_code( $direction * CODE_WHEEL_COLUMNS );
		$event->use_wheel;
		return;
	}

	# ---------------------------------------------------------------------
	# Links: one selection over the links of every text of every item
	# ---------------------------------------------------------------------

	# The links of an item in tree order, as [ text, link index ].
	method _links_of ($index) {
		return map {
			my $text = $_;
			map { [ $text, $_ ] } 0 .. $#{ $text->links }
		} $document->texts($index);
	}

	# A selection whose text changed points into nothing.
	method _selection_holds () {
		return 0 unless defined $selected;
		my $text = $selected->{text};
		return $text->content_revision == $selected->{revision} && $selected->{link} <= $#{ $text->links } ? 1 : 0;
	}

	# Shows the selection on the text that has it, and on no other.
	method _select ( $index = undef, $text = undef, $link = undef ) {
		$selected->{text}->select_link(undef) if defined $selected && !( defined $text && refaddr( $selected->{text} ) == refaddr($text) );
		$selected = defined $text ? { index => $index, text => $text, link => $link, revision => $text->content_revision } : undef;
		$text->select_link($link) if defined $text;
		return;
	}

	method selected_link () {
		return undef unless $self->_selection_holds;
		return $selected->{text}->links->[ $selected->{link} ][2];
	}

	method select_next_link () {
		return $self->_select_link(1);
	}

	method select_previous_link () {
		return $self->_select_link(-1);
	}

	# From the selected link while its item is in view, else from the
	# first (last) item in view; the selection stops at the first and the
	# last link of the document.
	method _select_link ($direction) {
		return 0 unless defined $document && $document->count;
		my $visible = $self->visible_items;
		my $target;
		if ( $self->_selection_holds && ( !defined $visible || ( $selected->{index} >= $visible->{first} && $selected->{index} <= $visible->{last} ) ) ) {
			my @links = $self->_links_of( $selected->{index} );
			my ($at)  = grep { refaddr( $links[$_][0] ) == refaddr( $selected->{text} ) && $links[$_][1] == $selected->{link} } 0 .. $#links;
			my $next  = defined $at ? $at + $direction : -1;
			$target = $next >= 0 && $next <= $#links ? [ $selected->{index}, @{ $links[$next] } ] : $self->_link_from( $selected->{index} + $direction, $direction );
		}
		else {
			my $start = $direction > 0 ? ( defined $visible ? $visible->{first} : 0 ) : ( defined $visible ? $visible->{last} : $document->count - 1 );
			$target = $self->_link_from( $start, $direction );
		}
		return 0 unless defined $target;
		$self->_select(@$target);
		my ( $index, $text, $link ) = @$target;
		$self->_reveal( $index, $text, undef, $text->links->[$link][0] );
		return 1;
	}

	# The first link (the last, going back) of the items from $start on.
	method _link_from ( $start, $direction ) {
		for ( my $index = $start; $index >= 0 && $index < $document->count; $index += $direction ) {
			my @links = $self->_links_of($index) or next;
			return [ $index, @{ $direction > 0 ? $links[0] : $links[-1] } ];
		}
		return undef;
	}

	# The text of the link fires LinkActivate, which bubbles through the
	# view to the program; a text that is not in the view at the moment
	# (its item left the window) cannot, and the view fires it instead.
	method follow_link () {
		return 0 unless $self->_selection_holds;
		my ( $text, $link ) = @{$selected}{qw(text link)};
		return $text->activate_link($link) if $self->contains($text);
		my ( $start, $end, $target ) = @{ $text->links->[$link] };
		$self->fire_event( Term::Fabulous::Event::LinkActivate->new( link => $target, index => $link, start => $start, end => $end ) );
		return 1;
	}

	# A link clicked or followed in a text of an item becomes the selected
	# link, and the event goes on to the program.
	method _link_clicked ($event) {
		my $text = $event->target;
		return $CONTINUE unless blessed $text && $text->isa('Term::Fabulous::Widget::Text');
		my $index = $self->_item_index_of($text) // return $CONTINUE;
		$self->_select( $index, $text, $event->index );
		return $CONTINUE;
	}

	# A text inside an item that took the focus (a click on a text with
	# links does) gives it to the view, which keeps one selection for all
	# links; the text's first link becomes the selected one, until a
	# click selects another.
	method _focus_arrived ($target) {
		return unless blessed $target && refaddr($target) != refaddr($self) && $target->DOES('Clay::UI::Role::Core::TextNode');
		my $index       = $self->_item_index_of($target) // return;
		my $ui          = $self->ui                      // return;
		my $interaction = $ui->interaction;
		return unless $interaction->can_take_focus($self);
		$interaction->set_focused_widget($self);
		$self->_select( $index, $target, 0 ) if $target->isa('Term::Fabulous::Widget::Text') && @{ $target->links };
		return;
	}

	# ---------------------------------------------------------------------
	# Searching: the texts of every searchable widget of every item
	# ---------------------------------------------------------------------

	method query () {
		return defined $search ? $search->{query} : undef;
	}

	method match_count () {
		return defined $search ? scalar @{ $search->{matches} } : 0;
	}

	method current_match () {
		return defined $search && defined $search->{current} ? $search->{current} + 1 : undef;
	}

	# Marks every occurrence and moves to the first one at or after the
	# top of the view. Returns the number of matches.
	method search ($text) {
		die ref($self) . ": search needs a string, got " . describe($text) unless defined $text && !ref $text;
		$self->_run_search( $text, $self->top_item // 0 );
		$self->_reveal_match;
		return $self->match_count;
	}

	method _run_search ( $query, $top ) {
		$self->_unpaint;
		$search = undef;
		return unless length $query && defined $document;
		my @matches = map { [ @$_, $_->[1]->search_revision( $_->[2] ) ] } $document->find_text($query);
		my $current = first { $matches[$_][0] >= $top } 0 .. $#matches;
		$current //= 0 if @matches;

		my ( %groups, @group_of );
		foreach my $index ( 0 .. $#matches ) {
			my ( undef, $widget, $key ) = @{ $matches[$index] };
			my $id = refaddr($widget) . "\0" . _key_string($key);
			push @{ ( $groups{$id} //= { widget => $widget, key => $key, members => [] } )->{members} }, $index;
			$group_of[$index] = $id;
		}
		$search = { query => $query, matches => \@matches, current => $current, groups => \%groups, group_of => \@group_of, painted => {} };
		$self->_paint_group($_) foreach keys %groups;
		return;
	}

	sub _key_string ($key) {
		return 'u' unless defined $key;
		return ref $key eq 'ARRAY' ? '[' . join( ',', map { _key_string($_) } @$key ) . ']' : "d$key";
	}

	# The matches in one text: the current one in the match_current style,
	# the others in the match style.
	method _paint_group ($id) {
		my $group   = $search->{groups}{$id};
		my $look    = $self->_look_class;
		my @style   = map { $look->token_style($_) } qw(match match_current);
		my $current = $search->{current} // -1;
		my @ranges  = map {
			my $match = $search->{matches}[$_];
			[ $match->[3], $match->[4], $style[ $_ == $current ? 1 : 0 ] ]
		} @{ $group->{members} };
		$group->{widget}->highlight_text( $group->{key}, \@ranges );
		$search->{painted}{ refaddr $group->{widget} } = $group->{widget};
		return;
	}

	method _unpaint () {
		return unless defined $search;
		$_->clear_text_highlights foreach values %{ $search->{painted} };
		return;
	}

	method next_match () {
		return $self->_step_match(1);
	}

	method previous_match () {
		return $self->_step_match(-1);
	}

	# Steps through the matches, around from the last to the first. When a
	# text changed since the search, the search runs again first, from
	# the item of the current match.
	method _step_match ($direction) {
		return 0 unless defined $search && @{ $search->{matches} };
		my $stale = first { $_->[1]->search_revision( $_->[2] ) ne $_->[5] } @{ $search->{matches} };
		if ( defined $stale ) {
			$self->_run_search( $search->{query}, $search->{matches}[ $search->{current} ][0] );
			return 0 unless defined $search && @{ $search->{matches} };
		}
		my $before = $search->{current};
		$search->{current} = ( $before + $direction ) % @{ $search->{matches} };
		my %seen;
		$self->_paint_group($_) foreach grep { !$seen{$_}++ } @{ $search->{group_of} }[ $before, $search->{current} ];
		$self->_reveal_match;
		return 1;
	}

	method _reveal_match () {
		return unless defined $search && defined $search->{current};
		my ( $index, $widget, $key, $start ) = @{ $search->{matches}[ $search->{current} ] };
		$self->_reveal( $index, $widget, $key, $start );
		return;
	}

	# Drops the search and the selected link. Returns 1 when there was
	# anything to drop: a search without matches ends too.
	method clear_marks () {
		return 0 unless defined $search || defined $selected;
		$pending_reveal = undef;
		$self->_forget_marks;
		return 1;
	}

	method _forget_marks () {
		$self->_unpaint;
		$search = undef;
		$self->_select;
		return;
	}

	# ---------------------------------------------------------------------
	# The focus: the view, then the interactive widgets of the items
	# ---------------------------------------------------------------------

	# Tab and Shift+Tab that come from outside stop at the view
	# (Clay::UI::Role::Interaction::HasFocusOrder).
	method get_entry_focus ($direction) {
		my $ui = $self->ui // return undef;
		return $ui->interaction->can_take_focus($self) ? $self : undef;
	}

	# From the view to the first interactive widget at or below the top
	# of the view, from a widget to the next one; past the last, out of
	# the view.
	method get_next_focus () {
		my $interaction = $self->ui->interaction;
		my $focused     = $interaction->get_focused_widget;
		my $from        = $self->_focused_item($focused);
		my $target      = defined $from ? $self->_interactive_after( $from, $focused, 1 ) : $self->_interactive_from( $self->top_item // 0, 1 );
		return $interaction->focus_after( $self, 'next' ) unless defined $target;
		return $self->_focus_target(@$target);
	}

	# From a widget to the one before it, from the first to the view, from
	# the view out of it.
	method get_previous_focus () {
		my $interaction = $self->ui->interaction;
		my $focused     = $interaction->get_focused_widget;
		my $from        = $self->_focused_item($focused)                   // return $interaction->focus_after( $self, 'previous' );
		my $target      = $self->_interactive_after( $from, $focused, -1 ) // return $self;
		return $self->_focus_target(@$target);
	}

	method _focused_item ($focused) {
		return undef unless defined $focused && refaddr($focused) != refaddr($self) && $self->contains($focused);
		return $self->_item_index_of($focused);
	}

	# The widgets of an item that take the focus with Tab: not its texts,
	# whose links the view selects.
	method _interactive_of ($index) {
		return grep { $_->DOES('Clay::UI::Role::Interaction::Focusable') && !$_->DOES('Clay::UI::Role::Core::TextNode') && $_->can_focus } $document->item($index)->subtree;
	}

	method _interactive_after ( $index, $focused, $direction ) {
		my @here = $self->_interactive_of($index);
		my ($at) = grep { refaddr( $here[$_] ) == refaddr($focused) } 0 .. $#here;
		if ( defined $at ) {
			my $next = $at + $direction;
			return [ $index, $here[$next] ] if $next >= 0 && $next <= $#here;
		}
		return $self->_interactive_from( $index + $direction, $direction );
	}

	method _interactive_from ( $start, $direction ) {
		return undef unless defined $document;
		for ( my $index = $start; $index >= 0 && $index < $document->count; $index += $direction ) {
			my @widgets = $self->_interactive_of($index) or next;
			return [ $index, $direction > 0 ? $widgets[0] : $widgets[-1] ];
		}
		return undef;
	}

	# A widget whose item is not built cannot take the focus yet: the view
	# scrolls to the item and focuses the widget once it is there.
	method _focus_target ( $index, $widget ) {
		my $interaction = $self->ui->interaction;
		return $widget if $interaction->can_take_focus($widget);
		my $request = { widget => $widget };
		weaken $request->{widget};
		weaken( $pending_focus = $request );
		$self->_follow_frames( focus => sub ($view) { return $view->_continue_focus($request) }, FOCUS_FRAMES );
		$self->show_item($index);
		return undef;
	}

	# True when the focus request is done: cancelled, replaced, its widget
	# gone, or focused.
	method _continue_focus ($request) {
		return 1 unless _is_current( $pending_focus, $request );
		my $widget      = $request->{widget} // return 1;
		my $interaction = $self->ui->interaction;
		return 0 unless $interaction->can_take_focus($widget);
		$interaction->set_focused_widget($widget);
		return 1;
	}

	# ---------------------------------------------------------------------
	# Keys
	# ---------------------------------------------------------------------

	# The keys of less scroll (Term::Fabulous::Scrolling's scroll_by_key);
	# these are the others.
	my %ACTION_OF_KEY = (
		Left   => sub ($self) { $self->scroll_code( -CODE_STEP ) },
		Right  => sub ($self) { $self->scroll_code(CODE_STEP) },
		l      => sub ($self) { $self->select_next_link },
		L      => sub ($self) { $self->select_previous_link },
		Enter  => sub ($self) { $self->follow_link },
		n      => sub ($self) { $self->next_match },
		N      => sub ($self) { $self->previous_match },
		Escape => sub ($self) { $self->clear_marks },
	);

	# A key with an action is used, whether or not the action could move
	# anything (at the end of the document, Down still belongs to the
	# document); Enter without a selected link and Escape without marks
	# go on to the widgets around. Keys a focused widget inside an item
	# did not use reach the view too: Escape gives the focus back to the
	# view, Enter goes on.
	my %PASSES_WHEN_IDLE = map { $_ => 1 } qw(Enter Escape);

	method _key ($event) {
		my $name = $event->main_key_name // return $CONTINUE;
		my $ui   = $self->ui;
		return if defined $ui && defined scroll_by_key( $ui, $self, $name, keys => 'less' );
		my $action  = $ACTION_OF_KEY{$name} // return $CONTINUE;
		my $focused = defined $ui ? $ui->interaction->get_focused_widget : undef;
		if ( defined $focused && refaddr($focused) != refaddr($self) ) {
			return $CONTINUE if $name eq 'Enter';
			if ( $name eq 'Escape' ) {
				$ui->interaction->set_focused_widget($self);
				return;
			}
		}
		my $acted = $action->($self);
		return $CONTINUE if !$acted && $PASSES_WHEN_IDLE{$name};
		return;
	}

	# ---------------------------------------------------------------------
	# Frames: what the view shows is reported, reveals and the focus go on
	# ---------------------------------------------------------------------

	method prepare_layout :override () {
		$self->_adopt_new_items;
		$self->SUPER::prepare_layout;
		$self->_watch_report;
		return;
	}

	# Work after the next frames (each_frame), for at most $frames frames;
	# the report comes after it, so that it tells what that work did.
	method _follow_frames ( $name, $code, $frames ) {
		$self->each_frame( $code, name => $name, frames => $frames );
		$self->_watch_report;
		return;
	}

	# After every frame the view reports what it shows.
	method _watch_report () {
		$self->each_frame( sub ($view) { $view->_report; return 0 }, name => 'report' );
		return;
	}

	method view_state () {
		my $visible = defined $document ? $self->visible_items : undef;
		my $ui      = $self->ui;
		my $section = defined $visible ? $document->section_at( $visible->{first} ) : undef;
		return {
			top           => defined $visible ? $visible->{first} : undef,
			bottom        => defined $visible ? $visible->{last}  : undef,
			section       => $section,
			section_title => defined $section ? $document->title_of_section($section) : undef,
			percent       => ( defined $ui ? scrolled_percent( $ui, $self ) : undef ) // 100,
			link          => $self->selected_link,
			query         => $self->query,
			match         => $self->current_match,
			matches       => $self->match_count,
		};
	}

	# A frame is reported when anything of the state differs from the last
	# report; a link that is a reference counts by its identity.
	method _report () {
		my $state = $self->view_state;
		my $key   = join "\x1F", map { my $value = $state->{$_}; !defined $value ? '' : ref $value ? refaddr($value) : $value } sort keys %$state;
		return if $key eq $reported;
		$reported = $key;
		$self->fire_event( Term::Fabulous::Event::ViewChange->new(%$state) );
		return;
	}

	# ---------------------------------------------------------------------
	# KDL
	# ---------------------------------------------------------------------

	method layout_properties :common () {
		return ( $class->SUPER::layout_properties, indent => 'scalar' );
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Widget::DocumentView - A scrollable, searchable view of a document of any widgets

=head1 SYNOPSIS

	use Clay::XS qw(sizing_grow);
	use Term::Fabulous::Widget::DocumentView;

	my $view = Term::Fabulous::Widget::DocumentView->new(
		id       => 'document',
		document => $document,    # a Term::Fabulous::Document, usually from a parser
		layout   => { sizing => { width => sizing_grow(), height => sizing_grow() } },
	);

	# Follow links, and keep a status line up to date.
	$view->on( LinkActivate => sub ($event) { open_page( $event->link ); return } );
	$view->on( ViewChange   => sub ($event) { show_position( $event->percent ); return } );

	# Search the text, and jump to a section.
	$view->search('frobnicate');
	my $methods = $view->document->find_section('METHODS');
	$view->show_item($methods) if defined $methods;

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.05/screenshots/widget-document-view.svg" alt="A framed document view scrolled to its Code section: a code block on a darker background, a paragraph with a selected link in inverse colors, a table of factories under the heading Any widget, every match of the word block highlighted, and a status line that names the selected link"></p>

=end html

The program is F<examples/widgets/document-view.pl>.

=head1 DESCRIPTION

A document view is the main pane of a document reader. It shows a
L<Term::Fabulous::Document>, a list of I<items>, each a widget, as a
parser made them: headings, paragraphs, list items and code, but also
tables, pictures, forms or anything else. The view lets the user read
it: it scrolls with the keyboard, the mouse wheel and the scrollbar,
selects and follows the links of every text, searches the text of
every item, and lets Tab reach the interactive widgets inside.

The view does not know the format the document was made from.
L<Pod::Fabulous> uses it to show POD; worked examples for showing
documents, following links, searching, building a table of contents
and putting any widget into a document are in
L<Term::Fabulous::Cookbook::Documents> and
L<Term::Fabulous::Cookbook::DocumentTechniques>; the manual introduces
documents in L<Term::Fabulous::Manual::Layout/Documents>.

The view is a L<Term::Fabulous::Widget::VirtualList>: it attaches only
the items near the visible area. A document with thousands of items
(L<perlfunc> has about 2000) therefore scrolls as fast as a short one,
and every frame stays within Clay's limits on elements and words (see
L<Term::Fabulous/LIMITATIONS>). The view composes
L<Clay::UI::Role::Interaction::Focusable>, so it takes the keyboard
focus, and L<Clay::UI::Role::Interaction::HasFocusOrder>, so it decides
where Tab goes inside it (see L</FOCUS>).

A border of the view's own (C<< bordered => 1 >>) is drawn over its
content, as the border of every scroll container is: a row scrolled
half under it shows its background in the border cells. A bordered Box
around the view avoids that; F<examples/widgets/document-view.pl>
gives the view a border of its own anyway, to stay short.

=head2 How items are shown

Each item is shown in a I<slot>: a box of the view's width that gives
the item

=over

=item *

the blank rows above it, its C<gap> option (none above the first item);
do not give the view's layout a C<child_gap>, which would add rows
between all items;

=item *

its indent: the view's L</indent> plus the item's C<indent> option, or
only the latter for a C<flush> item, such as a heading;

=item *

a vertical bar on its left for each block quote it is in (its C<quote>
option), drawn in the C<quote> style of the document's look and
followed by one column of space. The blank rows above a quoted item lie
inside its bars, so the bars of the items of one quote join up.

=back

See L<Term::Fabulous::Document/Item options>. The item itself is shown
as it is; the slot is its parent while the view shows the document,
which is why a document is shown by one view at a time. The styles of
the texts the factories of the document make are palette tokens, so a
theme switch restyles every item without the view doing anything; the
view recolors only its quote bars.

Before an item was laid out, the view needs its height to size the
scrollbar: it asks the item (L<Term::Fabulous::Widget/estimated_rows>,
which a box composes from its children) unless the item's C<rows>
option says it. Once Clay has laid the item out, its real height
replaces the estimate.

=head2 Marks

Two kinds of highlighting, the I<marks>, are drawn over the items'
own styles without rebuilding any widget:

=over

=item *

The I<selected link> is the link that C<Enter> follows: one link of one
L<Term::Fabulous::Widget::Text> anywhere in the document. The view
keeps one selection for the whole document and shows it through that
text's L<select_link|Term::Fabulous::Widget::Text/select_link>.

=item *

The I<search matches> are the occurrences of the text of the last
L</search> in the texts of every widget that does
L<Term::Fabulous::Role::Searchable>: every Text, every code block, and
the cells of a table on any page, the pages of a Tabs and the bodies of
accordion items, shown or not. They are drawn in the C<match> style,
as highlights that leave the texts' own styles alone; the I<current
match> is drawn in the C<match_current> style instead.
L<next_match and previous_match|/"next_match, previous_match"> move it.

=back

A text whose content changes after the search (a table row updated,
say) makes the search run again, from the current match, the next time
it steps; a selected link whose text changed is no longer selected.

=head1 CONSTRUCTOR

=head2 new

	my $view = Term::Fabulous::Widget::DocumentView->new( id => 'document', %parameters );

Creates a document view. It takes all parameters of
L<Term::Fabulous::Widget::VirtualList> except C<build>, C<estimate> and
C<count>, which the view derives from its document; passing any of them
dies. As for every scroll container, an C<id> is required. Unknown
parameters and invalid values die. The additional parameters are:

=over

=item C<document>

The L<Term::Fabulous::Document> to show, or C<undef> (the default) for
an empty view. Setting a document that another view shows dies.

=item C<highlighter>

C<undef> (the default), or a code reference that the code blocks the
document's L<code|Term::Fabulous::Document/code> factory made use to
highlight their code, called with the code and the language; see
L<Term::Fabulous::Widget::CodeBlock/highlighter>.

=item C<indent>

A non-negative integer, default 2: the columns by which every item that
is not C<flush> is indented.

=back

=head1 METHODS

The view has all methods of L<Term::Fabulous::Widget::VirtualList>,
plus the following. Unless stated otherwise, the methods that scroll,
select or search return 1 when they changed something and 0 when there
was nothing to change, so a key binding can tell whether the key had an
effect. C<Left>, C<Right>, C<l>, C<L>, C<Enter>, C<n>, C<N> and
C<Escape> are bound to these methods; the scrolling keys go through
L<Term::Fabulous::Scrolling/scroll_by_key>.

=head2 document

	my $document = $view->document;
	$view->document($new_document);

Gets or sets the document. A new document starts at its top, without a
search or a selected link, its code not scrolled sideways, and a
L<ViewChange|/EVENTS> follows its first frame. The items of the old
document leave their slots, so another view can show it. Setting a
document that another view shows dies.

=head2 highlighter

	$view->highlighter( sub ( $code, $language ) { ... } );

Gets or sets the C<highlighter>, which goes to the code blocks of the
document at once, and to a code block added later when the view builds
it.

=head2 indent

	$view->indent(4);

Gets or sets the C<indent>; the slots are built again.

=head2 document_look

	my $style = $view->document_look->style('quote');

The L<Term::Fabulous::Document::Look> of the document's C<look> class
in the theme the view draws with.

=head2 scroll_lines

	$view->scroll_lines(3);     # down
	$view->scroll_lines(-1);    # up

=head2 scroll_pages

	$view->scroll_pages(1);

Scroll by rows, or by pages of the rows the view shows less one, as
L<Term::Fabulous::Scrolling> does.

=head2 scroll_to_top, scroll_to_bottom

Show the first or the last item. Return 1 whenever the document has
items, even when the view is there already, and 0 for an empty
document.

=head2 show_item

	my $index = $document->find_section('SEE ALSO');
	$view->show_item($index) if defined $index;

Scrolls the item with that index to the top of the view, in the next
frame. Returns the view. An index outside the document dies.

=head2 top_item

	my $index = $view->top_item;    # or undef

The index of the item at the top of the view, or C<undef> before the
first frame and for an empty document.

=head2 scroll_code

	$view->scroll_code(8);    # shows the code 8 columns further right

Scrolls every code block sideways by that many columns, together, as
far as the widest code block in view allows. Code blocks out of view
move along, so that they match when they come back.

=head2 code_offset

	my $columns = $view->code_offset;

How far the code blocks are scrolled sideways.

=head2 select_next_link, select_previous_link

Select the link after (before) the selected one, from the texts of the
items in tree order. Without a selected link in view, the first link at
or after the top item in view (the last link at or before the bottom
item) is selected, scrolling to it when it lies outside the view. The
selection stops at the first
and the last link of the document. The line of the link is scrolled
into view. A link in content a widget builds later (a table cell on
another page) becomes selectable once it is built.

=head2 selected_link

	my $target = $view->selected_link;    # or undef

The target of the selected link, as the text holds it.

=head2 follow_link

Fires L<LinkActivate|/EVENTS> for the selected link. Returns 0 when no
link is selected.

=head2 search

	my $count = $view->search('needle');

Marks every occurrence of the text and makes the first one at or below
the top of the view the current match, scrolled into view: its line,
inside a text, a code block, or a table cell on another page, which the
table turns to (see L<Term::Fabulous::Role::Searchable/reveal_text>). A
query without capital letters ignores case (see
L<Term::Fabulous::Document/find_text>). An empty query ends the search.
Returns the number of matches.

=head2 next_match, previous_match

Make the next (previous) match the current one, around from the last to
the first, and scroll it into view.

=head2 query, match_count, current_match

The text searched for (or C<undef>), the number of matches, and the
number of the current match from 1 (or C<undef>).

=head2 clear_marks

Ends the search and drops the selected link. Returns 0 when there was
neither.

=head2 view_state

	my $state = $view->view_state;

What the view shows, as the hash of the fields of
L<Term::Fabulous::Event::ViewChange>: C<top> and C<bottom> (the items
in view), C<section> and C<section_title> (from the document's
sections), C<percent>, C<link>, C<query>, C<match> and C<matches>.

=head2 get_entry_focus, get_next_focus, get_previous_focus

The methods of L<Clay::UI::Role::Interaction::HasFocusOrder>; see
L</FOCUS>.

=head2 build, estimate, count

Without an argument, the methods of
L<Term::Fabulous::Widget::VirtualList> return the values the view
installed: its builder, its estimate, and the number of items. Setting
any of them dies.

=head1 KEYS

While the view or a widget inside it has the focus, the view handles
these keys, when the focused widget does not use them first. The
scrolling keys are the C<less> set of
L<Term::Fabulous::Scrolling/scroll_by_key>, which
L<Term::Fabulous::Cookbook::DocumentTechniques/Scroll any scroll box like a pager (Term::Fabulous::Scrolling)>
gives to a plain ScrollBox:

=for highlighter language=text

	Down, j            scroll down one row
	Up, k              scroll up one row
	PageDown, Space    scroll down one page
	PageUp, b          scroll up one page
	Home, g            go to the top of the document
	End, G             go to the end of the document
	Left, Right        scroll the code blocks eight columns sideways
	l, L               select the next or the previous link
	Enter              follow the selected link
	n, N               go to the next or the previous search match
	Escape             end the search and drop the selected link

The view consumes every key in this table, even when the key has
nothing to do: at the end of the document, C<Down> still belongs to the
view and does not reach the enclosing widgets. There are two
exceptions. When no link is selected, the view does not consume
C<Enter>; the same applies to C<Escape> when there is neither a search
nor a selected link. While a widget inside an item has the focus,
C<Enter> always goes on, and C<Escape> gives the focus back to the view
instead, keeping the marks. All other keys bubble up as well (see
L<Term::Fabulous::Manual::Events/KEYBOARD>).

=head1 FOCUS

The view is a Tab stop. Tab and Shift+Tab that come from outside land
on the view itself, whichever widget of the document is near. From the
view, Tab goes to the first interactive widget of the items at or below
the top of the view, then from widget to widget in the order of the
document, and past the last one out of the view; Shift+Tab goes back,
to the view from the first widget, and out of the view from the view.
An interactive widget is a focusable widget other than a text: buttons,
text fields, tables. A widget whose item is far from the view and not
built yet is brought into view and gets the focus once its item is
there, a frame or two later; a focused widget is kept in view as in
every L<ScrollBox|Term::Fabulous::Widget::ScrollBox/FOCUS>. Inside a
dialog, the order stays in the dialog (see
L<Clay::UI::Interaction/focus_after>).

Texts with links are no Tab stops inside the view: C<l> and C<L> select
the links of all texts. When a text takes the focus anyway, from a
click on it, the view takes the focus back, and the text's first link,
or the link clicked, becomes the selected link.
L<Term::Fabulous::Cookbook::DocumentTechniques/Put any widget into a document (a table and a picture)> shows
Tab reaching a table inside a document.

=head1 MOUSE

The mouse wheel and the scrollbar scroll the view vertically, as in
every L<Term::Fabulous::Widget::ScrollBox>. The horizontal wheel (or
tilting the wheel sideways) scrolls the code blocks three columns per
notch, as L</scroll_code> does, while the pointer is over a code block.
Texts and blank rows do not receive mouse events, so a notch over them
goes to the widget the view is in, not to the view; only when the view
is the root widget of the UI does a notch anywhere over it scroll the
code. Once the code cannot scroll further in that direction, the event
is passed on to the enclosing widgets. A click on a text or on a code
block focuses the view; a click on an interactive widget focuses that
widget.

A left click on a link selects the link and follows it: the text fires
L<LinkActivate|Term::Fabulous::Event::LinkActivate> with the link's
target as its C<link>. As the event bubbles up through the view, the
view makes the clicked link its selected link and lets the event
continue, so listeners on the view and on the widgets around it receive
it. The link under the mouse pointer is drawn as hovered.

=head1 EVENTS

=over

=item C<LinkActivate> (L<Term::Fabulous::Event::LinkActivate>)

Fired when the user presses C<Enter> while a link is selected, when
the program calls L</follow_link>, and when the user clicks a link. The
text of the link fires it, and it bubbles up through the view; when
that text is not in the view at the moment (its item scrolled out of
the window), the view fires it itself. C<< $event->link >> is the
target of the link, exactly as the document holds it.
L<Term::Fabulous::Cookbook::Documents/Follow links: jump to sections, open other pages, go back (LinkActivate)>
builds a help browser on it.

=item C<ViewChange> (L<Term::Fabulous::Event::ViewChange>)

Fired on the view after a frame in which the summary that
L</view_state> returns differs from the one the view reported last, for
example because the user scrolled, selected a link or searched. It also
fires after the first frame of a new document. A link target that is a
reference counts as changed only when it is a different reference.
L<Term::Fabulous::Cookbook::Documents/Search a document and show the reader's position (search, ViewChange)>
shows a status line fed by it.

=item The events of L<Term::Fabulous::Widget::VirtualList>

C<OnScroll> and C<Mouse>, as well as C<OnFocus> and C<OnBlur> from
L<Clay::UI::Role::Interaction::Focusable>.

=back

=head1 KDL PROPERTIES

The properties of L<Term::Fabulous::Widget::VirtualList>, plus
C<indent>:

=for highlighter language=kdl

	use Term::Fabulous::Widget::DocumentView as Document

	Document "document" {
		indent 2
	}

The document is given in Perl, with L</document>.

=head1 SEE ALSO

L<Term::Fabulous::Document>, L<Term::Fabulous::Document::Look>,
L<Term::Fabulous::Role::Searchable>, L<Term::Fabulous::Event::ViewChange>,
L<Term::Fabulous::Cookbook::Documents>, L<Term::Fabulous::Cookbook::DocumentTechniques>,
L<Term::Fabulous::Widget::VirtualList>, L<Pod::Fabulous>.

=cut
