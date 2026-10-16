package Term::Fabulous::Widget::DocumentTabs;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

use Term::Fabulous::Widget::Display;

our $VERSION = '0.03';

class Term::Fabulous::Widget::DocumentTabs
	:isa(Term::Fabulous::Widget::Display)
	:strict(params)
{
	use Clay::UI::Enum::Result;
	use Clay::XS qw(sizing_grow);
	use List::Util qw(sum0);
	use Scalar::Util qw(weaken);
	use Term::Fabulous::Check qw(boolean describe non_negative_integer optional string);
	use Term::Fabulous::Event::Select;
	use Term::Fabulous::Event::TabAdd;
	use Term::Fabulous::Event::TabClose;
	use Term::Fabulous::Termbox qw(TB_BOLD TB_KEY_MOUSE_LEFT TB_KEY_MOUSE_MIDDLE TB_MOD_MOTION);
	use Term::Fabulous::Unicode qw(cluster_columns grapheme_clusters string_columns);

	use constant MODIFIED   => "\x{25CF}";    # a dot: unsaved changes
	use constant ERROR      => '!';
	use constant CLOSE      => "\x{00D7}";
	use constant NEW        => ' + ';
	use constant MORE_LEFT  => "\x{25C2}";
	use constant MORE_RIGHT => "\x{25B8}";
	use constant ELLIPSIS   => "\x{2026}";

	# The columns of a tab besides its title: " title mark " and, when it
	# can be closed, "x ".
	use constant FIXED_COLUMNS => 4;
	use constant CLOSE_COLUMNS => 2;

	my $CONTINUE = Clay::UI::Enum::Result->CONTINUE;
	my $HANDLED  = Clay::UI::Enum::Result->HANDLED;

	field $active     :param = undef;
	field $new_button :param = 1;

	field $_tabs;    # [ checked tab, ... ], or a code reference that returns tabs
	field @_shown_tabs;    # the tabs the next paint draws, read by paint_key
	field @_regions;    # what the last paint put where: [ from, to, action, index ]

	ADJUST :params ( :$tabs = [] ) {
		$_tabs      = $self->_checked_tabs($tabs);
		$active     = $self->_checked_active($active);
		$new_button = boolean( $self, new_button => $new_button );
		weaken( my $weak_self = $self );
		$self->on( Mouse => sub ($event) { return $weak_self ? $weak_self->_on_mouse($event) : $CONTINUE } );
	}

	method theme_family :common () {
		return 'document_tabs';
	}

	method themed_params :common () {
		return (
			$class->SUPER::themed_params,
			active_background_color => [ 'background', 'active', 'cell_color' ],
			text_color              => [ 'text',       'normal', 'cell_color' ],
			active_text_color       => [ 'text',       'active', 'cell_color' ],
			modified_color          => [ 'modified',   'normal', 'cell_color' ],
			error_color             => [ 'error',      'normal', 'cell_color' ],
			button_color            => [ 'button',     'normal', 'cell_color' ],
		);
	}

	# ---------------------------------------------------------------------
	# The tabs
	# ---------------------------------------------------------------------

	# The tabs as given to new or tabs: an array reference of tabs, or a
	# code reference that returns them whenever a frame is drawn.
	method _checked_tabs ($tabs) {
		return $tabs if ref $tabs eq 'CODE';
		die ref($self) . ": tabs must be an array reference or a code reference, got " . describe($tabs) unless ref $tabs eq 'ARRAY';
		return [ map { $self->_checked_tab($_) } @$tabs ];
	}

	# A tab is a hash with a title; its flags become 0 or 1, and keys of
	# the program's own stay.
	method _checked_tab ($tab) {
		die ref($self) . ": a tab must be a hash reference with a title, got " . describe($tab) unless ref $tab eq 'HASH';
		return {
			%$tab,
			title    => _one_row( string( $self, 'the title of a tab' => $tab->{title} ) ),
			modified => boolean( $self, 'modified' => $tab->{modified} ),
			error    => boolean( $self, 'error'    => $tab->{error} ),
			closable => boolean( $self, 'closable' => $tab->{closable} // 1 ),
		};
	}

	method _checked_active ($index) {
		return optional( \&non_negative_integer, $self, active => $index );
	}

	# A tab is one row: line breaks and runs of white space become one
	# space, and white space at the ends goes.
	sub _one_row ($text) {
		return $text =~ s/\s+/ /gr =~ s/\A | \z//gr;
	}

	method tabs (@new) {
		return ref $_tabs eq 'CODE' ? $_tabs : [
			map {
				{ %$_ }
			} @$_tabs
			]
			unless @new;
		$_tabs = $self->_checked_tabs( $new[0] );
		$self->mark_changed;
		return $self->tabs;
	}

	# The tabs to draw now, checked: a code reference is called.
	method _current_tabs () {
		return map {
			{ %$_ }
		} @$_tabs unless ref $_tabs eq 'CODE';
		return map { $self->_checked_tab($_) } $_tabs->();
	}

	method tab ($index) {
		$index = non_negative_integer( $self, index => $index );
		my @tabs = $self->_current_tabs;
		return $tabs[$index];
	}

	method count () {
		return scalar( my @tabs = $self->_current_tabs );
	}

	method active (@new) {
		return $active unless @new;
		$active = $self->_checked_active( $new[0] );
		$self->mark_changed;
		return $active;
	}

	method new_button (@new) {
		return $new_button unless @new;
		$new_button = boolean( $self, new_button => $new[0] );
		$self->mark_changed;
		return $new_button;
	}

	# ---------------------------------------------------------------------
	# Colors
	# ---------------------------------------------------------------------

	method active_background_color (@new) { return @new ? $self->set_look( active_background_color => $new[0] ) : $self->look_value('active_background_color') }
	method text_color              (@new) { return @new ? $self->set_look( text_color              => $new[0] ) : $self->look_value('text_color') }
	method active_text_color       (@new) { return @new ? $self->set_look( active_text_color       => $new[0] ) : $self->look_value('active_text_color') }
	method modified_color          (@new) { return @new ? $self->set_look( modified_color          => $new[0] ) : $self->look_value('modified_color') }
	method error_color             (@new) { return @new ? $self->set_look( error_color             => $new[0] ) : $self->look_value('error_color') }
	method button_color            (@new) { return @new ? $self->set_look( button_color            => $new[0] ) : $self->look_value('button_color') }

	# The termbox2 attributes paint draws with.
	method _attrs () {
		return {
			background        => $self->color_attr( $self->background_color ),
			active_background => $self->color_attr( $self->active_background_color ),
			text              => $self->color_attr( $self->text_color ),
			active_text       => $self->color_attr( $self->active_text_color ) | TB_BOLD,
			modified          => $self->color_attr( $self->modified_color ),
			error             => $self->color_attr( $self->error_color ),
			button            => $self->color_attr( $self->button_color ),
		};
	}

	# ---------------------------------------------------------------------
	# Painting
	# ---------------------------------------------------------------------

	method natural_size () {
		return ( sizing_grow(), 1 );
	}

	# The tabs are read here, once per frame, and painted from what was
	# read.
	method paint_key :override () {
		@_shown_tabs = $self->_current_tabs;
		return ( $self->SUPER::paint_key, $active, $new_button, map { @{$_}{qw(title modified error closable)} } @_shown_tabs );
	}

	# The tab paint shows as active: none when active is undef or past the
	# end.
	method _shown_active () {
		return defined $active && $active <= $#_shown_tabs ? $active : undef;
	}

	# The tabs from the left, scrolled so that the active one fits, with an
	# arrow at an end that has hidden tabs and the + button after them.
	# Every tab ends a column before the + button, which leaves room for
	# the arrow.
	method paint () {
		my $width        = $self->columns;
		my $attrs        = $self->_attrs;
		my $tabs_end     = $width - 1 - ( $new_button ? length NEW : 0 );
		my $room         = $tabs_end - 1;
		my @titles       = map { _cut( $_->{title}, $room - _columns_besides_title($_) ) } @_shown_tabs;
		my @labels       = map { _label( $_shown_tabs[$_], $titles[$_] ) } 0 .. $#_shown_tabs;
		my @widths       = map { string_columns($_) } @labels;
		my $shown_active = $self->_shown_active;
		my $first        = _first_shown( \@widths, $shown_active // 0, $room );
		@_regions = ();
		$self->fill_attrs( 0, 0, $width, ' ', $attrs->{text}, $attrs->{background} );

		my $x = 0;
		if ( $first > 0 ) {
			$self->put_attrs( 0, 0, MORE_LEFT, $attrs->{button}, $attrs->{background} );
			push @_regions, [ 0, 0, 'arrow', $first - 1 ];
			$x = 1;
		}
		foreach my $index ( $first .. $#_shown_tabs ) {
			last if $x + $widths[$index] > $tabs_end;
			my $is_active = defined $shown_active && $index == $shown_active;
			$x = $self->_paint_tab( $x, $index, $titles[$index], $labels[$index], $is_active, $attrs );
			next unless $index < $#_shown_tabs && $x + $widths[ $index + 1 ] > $tabs_end;
			$self->put_attrs( $x, 0, MORE_RIGHT, $attrs->{button}, $attrs->{background} );
			push @_regions, [ $x, $x, 'arrow', $index + 1 ];
			$x++;
			last;
		}
		return unless $new_button;
		$self->paint_text( $x, 0, NEW, $attrs->{button}, $attrs->{background} );
		push @_regions, [ $x, $x + length(NEW) - 1, 'new', undef ];
		return;
	}

	# Paints one tab from column $x and records its regions; returns the
	# column after it.
	method _paint_tab ( $x, $index, $title, $label, $is_active, $attrs ) {
		my $tab = $_shown_tabs[$index];
		my ( $fg, $bg ) = $is_active ? @{$attrs}{qw(active_text active_background)} : @{$attrs}{qw(text background)};
		$self->paint_text( $x, 0, $label, $fg, $bg );
		my $mark_x = $x + 1 + string_columns($title) + 1;
		$self->put_attrs( $mark_x, 0, _mark($tab), $tab->{error} ? $attrs->{error} : $attrs->{modified}, $bg ) if $tab->{error} || $tab->{modified};
		my $end = $x + string_columns($label) - 1;
		push @_regions, $tab->{closable} ? ( [ $x, $mark_x + 1, 'tab', $index ], [ $mark_x + 2, $mark_x + 2, 'close', $index ], [ $mark_x + 3, $end, 'tab', $index ] ) : [ $x, $end, 'tab', $index ];
		return $end + 1;
	}

	# The mark after the title: an error wins over unsaved changes.
	sub _mark ($tab) {
		return $tab->{error} ? ERROR : $tab->{modified} ? MODIFIED : ' ';
	}

	sub _label ( $tab, $title ) {
		return " $title " . _mark($tab) . ' ' . ( $tab->{closable} ? CLOSE . ' ' : '' );
	}

	sub _columns_besides_title ($tab) {
		return FIXED_COLUMNS + ( $tab->{closable} ? CLOSE_COLUMNS : 0 );
	}

	# The first tab shown: the strip scrolls so that the tab at $target
	# fits, the arrow on the left counted.
	sub _first_shown ( $widths, $target, $room ) {
		my $first = 0;
		$first++ while $first < $target && sum0( @{$widths}[ $first .. $target ] ) + ( $first > 0 ? 1 : 0 ) > $room;
		return $first;
	}

	# A text cut to a number of columns, ending in an ellipsis when cut.
	sub _cut ( $text, $room ) {
		return '' if $room <= 0;
		return $text if string_columns($text) <= $room;
		my ( $kept, $width ) = ( '', 0 );
		foreach my $cluster ( grapheme_clusters($text) ) {
			my $columns = cluster_columns($cluster);
			last if $width + $columns > $room - 1;
			( $kept, $width ) = ( $kept . $cluster, $width + $columns );
		}
		return $kept . ELLIPSIS;
	}

	# ---------------------------------------------------------------------
	# The mouse
	# ---------------------------------------------------------------------

	method _on_mouse ($event) {
		return $CONTINUE if $event->modifiers & TB_MOD_MOTION;
		my $key = $event->key;
		return $CONTINUE unless $key == TB_KEY_MOUSE_LEFT || $key == TB_KEY_MOUSE_MIDDLE;
		my ($column) = $self->cell_at($event);
		return $CONTINUE unless defined $column;
		my ($region) = grep { $column >= $_->[0] && $column <= $_->[1] } @_regions;
		return $HANDLED unless defined $region;

		my ( undef, undef, $action, $index ) = @$region;
		return $self->_middle_click( $action, $index ) if $key == TB_KEY_MOUSE_MIDDLE;
		return $self->_fire_close($index) if $action eq 'close';
		return $self->_fire_add if $action eq 'new';
		return $self->_fire_select($index);
	}

	# A middle click closes a tab that can be closed.
	method _middle_click ( $action, $index ) {
		return $HANDLED unless ( $action eq 'tab' || $action eq 'close' ) && $_shown_tabs[$index]{closable};
		return $self->_fire_close($index);
	}

	method _fire_select ($index) {
		$self->fire_event( Term::Fabulous::Event::Select->new( item => { %{ $_shown_tabs[$index] } }, index => $index ) );
		return $HANDLED;
	}

	method _fire_close ($index) {
		$self->fire_event( Term::Fabulous::Event::TabClose->new( item => { %{ $_shown_tabs[$index] } }, index => $index ) );
		return $HANDLED;
	}

	method _fire_add () {
		$self->fire_event( Term::Fabulous::Event::TabAdd->new );
		return $HANDLED;
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Widget::DocumentTabs - A row of tabs for the open
documents of a program

=head1 SYNOPSIS

	use Term::Fabulous::Widget::DocumentTabs;

	my $tabs = Term::Fabulous::Widget::DocumentTabs->new(
		tabs   => sub { map { { title => $_->name, modified => $_->is_modified, error => $_->has_errors } } @documents },
		active => 0,
	);
	$root->add_child( $tabs, $editor );

	$tabs->on( Select   => sub ($event) { show_document( $event->index ); return } );
	$tabs->on( TabClose => sub ($event) { close_document( $event->index ); return } );
	$tabs->on( TabAdd   => sub ($event) { new_document(); return } );

	# show_document, close_document and new_document change the list and
	# then tell the tabs which one is shown:
	$tabs->active($index);

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.03/screenshots/widget-document-tabs.svg" alt="A row of document tabs at the top: notes.txt with a blue dot for unsaved changes, config.kdl with a red exclamation mark for errors, todo.md, and the active tab budget.csv in bold on a lighter background with a blue dot, each with a close mark, then an arrow to a hidden tab and a plus button. Below, the text of budget.csv, a dim line with the keys that switch, close and add tabs, and a status bar with the message Closed README.md."></p>

=end html

The program is F<examples/widgets/document-tabs.pl>. A click on a tab
shows its document below, a click on a close mark closes it, and the
C<+> button adds a new one. The program gives the same actions keys of
its own, as commands: C<Alt+PageUp> and C<Alt+PageDown> switch,
C<Alt+w> closes and C<Ctrl+N> adds. In the screenshot, README.md was
closed and budget.csv chosen; the arrow leads to letter.md, which does
not fit.

=head1 DESCRIPTION

Document tabs are the row of tabs an editor shows above its text: one
tab per open document, with the document's title, a dot when it has
unsaved changes, an exclamation mark when it has errors, and a close
mark. A C<+> button after the last tab asks for a new document. When
the tabs do not fit, the row scrolls so that the active tab is shown,
and an arrow at each end that has hidden tabs leads to the next one.

Unlike L<Term::Fabulous::Widget::Tabs>, document tabs hold no pages
and no widgets. They show a list of plain hashes that the program
gives them, or a code reference that returns the list whenever a frame
is drawn, so the tabs always show the program's documents as they are
now. The program also decides which tab is the I<active> one, the
document it shows.

The tabs never change anything themselves. A click fires an event
(see L</EVENTS>), and the program answers it: it shows the chosen
document and sets L</active>, closes a document (perhaps after asking
whether to save it first) and removes its tab, or makes a new
document. Setting C<active> fires nothing.

Document tabs take no keyboard input and never take the focus: the
program offers its own keys for them, such as C<Alt+PageDown> for the
next document. They react to the mouse only. They grow to the width of
their parent and are one row high (see
L<Term::Fabulous::Widget::Display/Size>).

A title that is wider than the row is cut and ends in an ellipsis
(E<hellip>). Line breaks and runs of white space in a title become a
single space.

=head1 CONSTRUCTOR

=head2 new

=for highlighter language=perl

	my $tabs = Term::Fabulous::Widget::DocumentTabs->new(%parameters);

Accepts the parameters of L<Term::Fabulous::Widget::Box/CONSTRUCTOR>
(C<id>, C<layout>, C<background_color>, ...) and the ones below. All
are optional, and unknown parameters die.

=over

=item C<tabs>

The tabs: an array reference of tabs, or a code reference that
returns a list of tabs. Default: C<[]>, no tabs.

A tab is a hash reference with these keys:

=over

=item C<title>

Required. The text of the tab, a character string.

=item C<modified>

True when the document has unsaved changes: the tab shows a dot after
its title. Default: false.

=item C<error>

True when the document has errors: the tab shows an exclamation mark
after its title, in place of the dot. Default: false.

=item C<closable>

False for a tab the user cannot close: it has no close mark, and a
middle click on it does nothing. Default: true.

=back

Other keys are the program's own: the tabs keep them and give them
back in the events, so a tab can carry, for example, the path of its
file. A tab that is not a hash reference or has no title dies, when it
is given and, for a code reference, when the tabs it returned are
drawn.

=item C<active>

The position of the active tab, from 0, or C<undef> (the default) for
none. The active tab is drawn in bold on a background of its own. A
position past the last tab is allowed and shows no active tab, so the
program may remove tabs and set C<active> afterwards.

=item C<new_button>

A boolean. Default: 1, the tabs end in a C<+> button. With 0, there is
no button.

=item C<text_color>, C<active_text_color>, C<active_background_color>

The colors of the tabs, in any format
L<Term::Fabulous::Widget::Canvas/Colors> accepts: the text of a tab
(its title and close mark) and, for the active tab, its text and its
background. Default: the theme's C<document_tabs.text>, the same in
the C<active> state, and C<document_tabs.background> in the C<active>
state; in the built-in themes these are the C<text_dim>, C<text> and
C<focus_background> colors.

=item C<modified_color>, C<error_color>

The colors of the dot for unsaved changes and of the exclamation mark
for errors. Default: the theme's C<document_tabs.modified> and
C<document_tabs.error>, the C<accent> and C<danger> colors in the
built-in themes.

=item C<button_color>

The color of the C<+> button and of the arrows. Default: the theme's
C<document_tabs.button>, the C<accent> color in the built-in themes.

=item C<background_color>

As for every widget: the background of the row and of the tabs that
are not active. Default: the theme's C<document_tabs.background>,
C<surface_low> in the built-in themes.

=back

=head1 METHODS

The methods of L<Term::Fabulous::Widget::Display> (C<mark_changed>, the
Box and Canvas methods), plus these. The accessors work like those of
the other widgets. Without an argument they return the current value.
With one they set the value, checked as C<new> checks it, mark the
tabs changed, so the next frame paints them, and return the new value.
An invalid value dies and leaves the old one.

=head2 tabs

	$tabs->tabs( [ { title => 'notes.txt' }, { title => 'todo.md', modified => 1 } ] );
	$tabs->tabs( sub { map { { title => $_->name } } @documents } );

The tabs, as described under L</new>. Reading it returns the code
reference, or copies of the tabs, with C<modified>, C<error> and
C<closable> as 0 or 1.

=head2 tab

	my $title = $tabs->tab(2)->{title};

The tab at a position, from 0, as the tabs show it now (for a code
reference, it calls it), or C<undef> past the last tab. A position
that is not a non-negative integer dies.

=head2 count

	my $open = $tabs->count;

The number of tabs now. For a code reference, it calls it.

=head2 active

	$tabs->active(0);
	$tabs->active(undef);    # no active tab

The position of the active tab, or C<undef>. Setting it fires nothing.

=head2 new_button

	$tabs->new_button(0);

Whether the tabs end in a C<+> button.

=head2 text_color, active_text_color, active_background_color, modified_color, error_color, button_color

	$tabs->modified_color('#e5c07b');
	$tabs->reset_look('modified_color');    # back to the theme

The readers return C<[r, g, b, a]>.

=head1 EVENTS

Each event is fired on the tabs and bubbles to their ancestors. The
tab in an event is a copy of the tab as it was drawn, the program's
own keys included.

=over

=item C<Select>

L<Term::Fabulous::Event::Select> when the user clicks a tab, the
active one included; C<< $event->item >> is the tab and
C<< $event->index >> its position. A click on an arrow at an end fires
it for the next hidden tab on that side.

=item C<TabClose>

L<Term::Fabulous::Event::TabClose> when the user clicks the close mark
of a tab, or clicks a tab with the middle button. A tab whose
C<closable> is false fires nothing.

=item C<TabAdd>

L<Term::Fabulous::Event::TabAdd> when the user clicks the C<+> button.

=back

=head1 KDL PROPERTIES

Document tabs are built in Perl only: their tabs come from the
program's documents and they work through events, which a layout file
cannot express.

=head1 SEE ALSO

L<Term::Fabulous::Widget::Tabs> for pages with tabs,
L<Term::Fabulous::Event::Select>, L<Term::Fabulous::Event::TabClose>,
L<Term::Fabulous::Event::TabAdd>, L<Term::Fabulous::Widget::Display>.

=cut
