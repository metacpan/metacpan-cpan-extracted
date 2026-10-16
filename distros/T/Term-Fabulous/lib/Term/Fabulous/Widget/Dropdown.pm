package Term::Fabulous::Widget::Dropdown;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

use Term::Fabulous::Role::HasOptions;
use Term::Fabulous::Widget::Dropdown::List;
use Term::Fabulous::Widget::Input;

our $VERSION = '0.03';

class Term::Fabulous::Widget::Dropdown
	:isa(Term::Fabulous::Widget::Input)
	:does(Term::Fabulous::Role::HasOptions)
	:strict(params)
{
	use Clay::XS qw(sizing_fixed CLAY_ATTACH_TO_PARENT CLAY_ATTACH_POINT_LEFT_TOP CLAY_ATTACH_POINT_LEFT_BOTTOM);
	use List::Util qw(max min);
	use Scalar::Util qw(refaddr);
	use Term::Fabulous::Check qw(positive_integer string);
	use Term::Fabulous::OptionList;
	use Term::Fabulous::Roving qw(roving_target);
	use Term::Fabulous::Termbox qw(TB_KEY_MOUSE_LEFT TB_MOD_MOTION);
	use Time::HiRes qw(time);
	use Term::Fabulous::Unicode qw(string_columns);

	use constant ARROW_DOWN        => "\x{25BE}";
	use constant ARROW_UP          => "\x{25B4}";
	use constant TYPEAHEAD_SECONDS => 1;

	# The highest z_index Clay has (int16): an open list belongs to the
	# focused widget, so it floats over everything, a dialog it is in
	# included.
	use constant LIST_Z_INDEX => 32767;

	field $option_list = Term::Fabulous::OptionList->new( owner => __CLASS__ );

	field $placeholder         :param = '';
	field $max_visible_options :param = 8;

	# The open list, the option it highlights and whether it opened upwards.
	field $list;
	field $highlighted;
	field $opens_upwards = 0;

	# Typed characters that search the labels, and when the last one came.
	field $typed    = '';
	field $typed_at = 0;

	ADJUST :params ( :$options = undef, :$value = undef, :$selected_index = undef ) {
		die "Term::Fabulous::Widget::Dropdown: give 'value' or 'selected_index', not both"
			if defined $value && defined $selected_index;
		$placeholder         = string( $self, placeholder => $placeholder );
		$max_visible_options = positive_integer( $self, max_visible_options => $max_visible_options );

		$self->options($options) if defined $options;
		$self->value($value) if defined $value;
		$self->selected_index($selected_index) if defined $selected_index;
	}

	# ---------------------------------------------------------------------
	# Options and value (Term::Fabulous::OptionList)
	# ---------------------------------------------------------------------

	method options (@new) {
		return $option_list->options unless @new;
		$option_list->set_options( $new[0] );
		$self->close;
		$self->mark_changed;
		return $option_list->options;
	}

	method value (@new) {
		return $option_list->value unless @new;
		$option_list->set_value( $new[0] );
		$self->mark_changed;
		return $option_list->value;
	}

	method selected_index (@new) {
		return $option_list->selected_index unless @new;
		$option_list->set_selected_index( $new[0] );
		$self->mark_changed;
		return $option_list->selected_index;
	}

	method selected_label () {
		return $option_list->selected_label;
	}

	method placeholder (@new) {
		return $placeholder unless @new;
		$placeholder = string( $self, placeholder => $new[0] );
		$self->mark_changed;
		return $placeholder;
	}

	method max_visible_options (@new) {
		return $max_visible_options unless @new;
		return $max_visible_options = positive_integer( $self, max_visible_options => $new[0] );
	}

	method theme_family :common () {
		return 'dropdown';
	}

	method themed_params :common () {
		return (
			$class->SUPER::themed_params,
			placeholder_color     => [ 'placeholder',     'normal', 'cell_color' ],
			list_background_color => [ 'list.background', 'normal', 'cell_color' ],
			highlight_text_color  => [ 'highlight.text',  'normal', 'cell_color' ],
		);
	}

	method placeholder_color (@new) {
		return @new ? $self->set_look( placeholder_color => $new[0] ) : $self->look_value('placeholder_color');
	}

	method list_background_color (@new) {
		return @new ? $self->set_look( list_background_color => $new[0] ) : $self->look_value('list_background_color');
	}

	method highlight_text_color (@new) {
		return @new ? $self->set_look( highlight_text_color => $new[0] ) : $self->look_value('highlight_text_color');
	}

	method disabled :override (@new) {
		$self->close if @new && $new[0];
		return $self->SUPER::disabled(@new);
	}

	method layout_properties :common () {
		return (
			$class->SUPER::layout_properties,
			value               => 'scalar',
			selected_index      => 'scalar',
			placeholder         => 'scalar',
			max_visible_options => 'scalar',
			options             => \&add_layout_options,
			option              => \&add_layout_options,
		);
	}

	# ---------------------------------------------------------------------
	# The list
	# ---------------------------------------------------------------------

	method is_open () {
		return defined $list ? 1 : 0;
	}

	method highlighted_index () {
		return $highlighted;
	}

	# The list opens with the selected option highlighted, or the first
	# one that is enabled.
	method open () {
		return $self if defined $list || !$option_list->count || !$self->is_enabled;
		my $selected = $option_list->selected_index;
		$highlighted = defined $selected && !$option_list->is_disabled($selected) ? $selected : ( $option_list->enabled_indexes )[0];

		my ( $visible, $upwards ) = $self->_list_rows;
		my $scrolls = $visible < $option_list->count;
		my $width   = max( $self->_box_width, 2 + ( max map { string_columns( $_->{label} ) } $option_list->options ) + 2 + ( $scrolls ? 1 : 0 ) );
		$opens_upwards = $upwards;

		my ( $element, $parent ) = $upwards ? ( CLAY_ATTACH_POINT_LEFT_BOTTOM, CLAY_ATTACH_POINT_LEFT_TOP ) : ( CLAY_ATTACH_POINT_LEFT_TOP, CLAY_ATTACH_POINT_LEFT_BOTTOM );
		$list = Term::Fabulous::Widget::Dropdown::List->new(
			dropdown     => $self,
			visible_rows => $visible,
			bordered     => 1,
			layout       => { sizing => { width => sizing_fixed($width), height => sizing_fixed( $visible + 2 ) } },
			floating     => {
				attach_to     => CLAY_ATTACH_TO_PARENT,
				attach_points => { element => $element, parent => $parent },
				z_index       => LIST_Z_INDEX,
			},
		);
		$self->add_child($list);
		$list->show_highlight;
		return $self->mark_changed;
	}

	method close () {
		return $self unless defined $list;
		my $closing = $list;
		undef $list;
		undef $highlighted;
		$self->remove_child($closing);
		return $self->mark_changed;
	}

	# The width of the whole widget in the last frame (its natural width
	# before the first one).
	method _box_width () {
		my ( $left, undef, $right ) = $self->content_insets;
		return $left + ( $self->columns || ( $self->natural_size )[0] ) + $right;
	}

	# How many options the list shows, and whether it opens upwards: below
	# the widget when they fit there or there is at least as much room
	# below as above.
	method _list_rows () {
		my $wanted = min( $option_list->count, $max_visible_options );
		my $ui     = $self->ui;
		my @origin = $self->content_origin;
		return ( $wanted, 0 ) unless defined $ui && @origin;

		my ( undef, $top, undef, $bottom ) = $self->content_insets;
		my $room_above = $origin[1] - $top;
		my $room_below = $ui->height - ( $origin[1] + $self->rows + $bottom );
		my $upwards    = $room_below < $wanted + 2 && $room_above > $room_below;
		my $room       = $upwards ? $room_above : $room_below;
		return ( max( 1, min( $wanted, $room - 2 ) ), $upwards ? 1 : 0 );
	}

	# Chooses an option as the user does; a disabled option cannot be
	# chosen, and the list stays open then.
	method choose ($index) {
		my $changed = $option_list->choose($index);
		return $self if $option_list->is_disabled($index);
		$self->close;
		return $self unless $changed;
		$self->mark_changed;
		$self->fire_change( $option_list->value );
		return $self;
	}

	# A disabled option is never highlighted.
	method highlight ($index) {
		return $self unless defined $list;
		$index = min( max( $index, 0 ), $option_list->count - 1 );
		return $self if $option_list->is_disabled($index);
		$highlighted = $index;
		$list->show_highlight;
		return $self;
	}

	# ---------------------------------------------------------------------
	# Input
	# ---------------------------------------------------------------------

	method focus_changed :override ($is_focused) {
		$self->close unless $is_focused;
		return;
	}

	method handle_mouse ($event) {
		return 0 unless refaddr( $event->target ) == refaddr($self);
		return 0 unless $event->key == TB_KEY_MOUSE_LEFT && !( $event->modifiers & TB_MOD_MOTION );
		$self->is_open ? $self->close : $self->open;
		return 1;
	}

	method handle_key ($event) {
		my $text = $event->text;
		return $self->_type_ahead($text) if defined $text && $text ne ' ';

		my $name = $event->main_key_name // return 0;
		return $self->_handle_key_while_open($name) if $self->is_open;

		if ( $name eq 'Enter' || $name eq 'Space' || $name eq 'Alt+Down' || $name eq 'F4' ) {
			$self->open;
			return 1;
		}
		my $target = roving_target( [ $option_list->enabled_indexes ], $option_list->selected_index, $name, keys => 'vertical', policy => 'clamp' ) // return 0;
		$self->_choose_closed($target);
		return 1;
	}

	method _choose_closed ($index) {
		return unless $option_list->choose($index);
		$self->mark_changed;
		$self->fire_change( $option_list->value );
		return;
	}

	method _handle_key_while_open ($name) {
		if ( $name eq 'Escape' ) {
			$self->close;
			return 1;
		}
		if ( $name eq 'Enter' || $name eq 'Space' ) {
			defined $highlighted ? $self->choose($highlighted) : $self->close;
			return 1;
		}
		my $target = roving_target( [ $option_list->enabled_indexes ], $highlighted, $name, keys => 'list', policy => 'clamp', page => $list->visible_rows ) // return 0;
		$self->highlight($target);
		return 1;
	}

	# Typing finds the next option whose label starts with the typed text;
	# characters typed within a second of each other form one search.
	# Disabled options are skipped.
	method _type_ahead ($character) {
		my @options = $option_list->options;
		return 0 unless @options;
		my $now = time;
		$typed    = $now - $typed_at <= TYPEAHEAD_SECONDS ? $typed . $character : $character;
		$typed_at = $now;

		my $current = $self->is_open    ? $highlighted // -1 : $option_list->selected_index // -1;
		my $start   = length $typed > 1 ? $current           : $current + 1;
		my $wanted  = fc $typed;
		my ($match) = grep { !$options[$_]{disabled} && fc( substr( $options[$_]{label}, 0, length $typed ) ) eq $wanted } map { ( $start + $_ ) % @options } 0 .. $#options;
		return 1 unless defined $match;

		$self->is_open ? $self->highlight($match) : $self->_choose_closed($match);
		return 1;
	}

	# ---------------------------------------------------------------------
	# Painting
	# ---------------------------------------------------------------------

	method natural_size () {
		my $widest = max 0, map { string_columns( $_->{label} ) } $option_list->options;
		return ( max( $widest, string_columns($placeholder) ) + 2, 1 );
	}

	method paint () {
		my $bg    = $self->paint_focus_background;
		my $label = $self->selected_label;
		my $fg    = defined $label ? $self->foreground_attr : $self->color_attr( $self->placeholder_color );
		$self->paint_text( 0, 0, $label // $placeholder, $fg, $bg, max( 0, $self->columns - 2 ) );
		$self->put_attrs( $self->columns - 1, 0, $opens_upwards && $self->is_open ? ARROW_UP : ARROW_DOWN, $self->accent_attr, $bg );
		return;
	}

	# The attributes of an option's row in the list:
	# ( $fg, $bg ) for the highlighted, the selected and the other options.
	# The highlighted option sits on the theme's dropdown.highlight.background,
	# or on the accent the program gave.
	method _highlight_background_attr () {
		return $self->accent_attr if $self->has_look_override('accent_color');
		return $self->color_attr( $self->look('highlight.background') );
	}

	method option_attrs ($index) {
		my $selected = $option_list->selected_index;
		return ( $self->color_attr( $self->highlight_text_color ), $self->_highlight_background_attr ) if defined $highlighted && $index == $highlighted;
		return ( $self->color_attr( $self->disabled_color ),       undef ) if $option_list->is_disabled($index);
		return ( $self->accent_attr,                               undef ) if defined $selected && $index == $selected;
		return ( $self->foreground_attr,                           undef );
	}

	method option_label ($index) {
		return $option_list->label($index);
	}

	method option_count () {
		return $option_list->count;
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Widget::Dropdown - Choose one of several options from a
list that opens

=head1 SYNOPSIS

	use Clay::UI::Enum::Result;
	use Term::Fabulous::Widget::Dropdown;

	my $color = Term::Fabulous::Widget::Dropdown->new(
		id          => 'color',
		options     => [ 'Red', [ 'Dark green' => 'green' ], { label => 'Blue', value => 'blue' } ],
		placeholder => 'Pick a color',
	);
	$color->on( Change => sub ($event) {
		say 'color: ', $event->value;    # 'Red', 'green' or 'blue'
		return Clay::UI::Enum::Result->CONTINUE;
	} );

	$color->value('green');              # programmatic: fires no Change
	say $color->selected_label;          # 'Dark green'

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.03/screenshots/widget-dropdown.svg" alt="Three dropdowns: a placeholder, France selected, and an open list of colors with Blue highlighted"></p>

=end html

=head1 DESCRIPTION

The picture shows three dropdowns: one without a selection, showing its
placeholder; one with France selected; and a focused one whose list is
open, with the selected option Green in the C<accent_color> and the
highlighted option Blue on the C<accent_color>. The program is
F<examples/widgets/dropdown.pl>.

A dropdown shows the label of the selected option (or a placeholder)
and a small arrow. When the user opens it, the options appear in a list
that floats over all other widgets, also over a
L<Term::Fabulous::Widget::Dialog> the dropdown is in. It opens below
the dropdown, unless
it does not fit there and there is more room above the dropdown; then it
opens above. The list shows up to C<max_visible_options> options at a
time; when the terminal has less room on the chosen side, it shrinks to
that room, but always shows at least one option. It scrolls through the
rest and has a scrollbar when it scrolls, drawn like every scrollbar
(L<Term::Fabulous::Widget::Scrollbar>) in the theme's
C<scrollbar.track> and C<scrollbar.thumb> colors. Choosing an option
closes the list.

Every option has a label (the text shown) and a value (what C<value>
and the C<Change> event return). The value defaults to the label.

The list is a child widget of the dropdown, created when the list opens
and removed when it closes (see L<Term::Fabulous::Widget::Dropdown::List>).
The dropdown keeps the focus and handles the keys while the list is
open. The list closes when the dropdown loses the focus, for example
through C<Tab> or a click elsewhere.

Disabling, colors, focus and sizing are described in
L<Term::Fabulous::Widget::Input>. Unless the C<layout> sizes it, the
dropdown is one row high and as wide as its longest label (or the
placeholder, if that is longer) plus two columns for the arrow.

=head1 CONSTRUCTOR

=head2 new

	my $dropdown = Term::Fabulous::Widget::Dropdown->new(%parameters);

Accepts the parameters of L<Term::Fabulous::Widget::Input/CONSTRUCTOR>
(C<id>, C<layout>, the border parameters, C<disabled>, C<can_focus>,
C<text_color>, C<disabled_color>, C<accent_color>,
C<focus_background_color>, the other Box parameters) and the ones below.
Unknown parameters die.

=over

=item C<options>

An array reference of options. Default: no options. Each option is one
of:

=over

=item *

a string, which is both the label and the value: C<'Red'>;

=item *

an array reference C<[ $label, $value ]>: C<[ 'Dark green' => 'green' ]>;

=item *

a hash reference with the key C<label> and optionally C<value> and
C<disabled>: C<< { label => 'Blue', value => 'blue', disabled => 1 } >>.

=back

A missing or C<undef> value is the label. Labels are character strings;
values are strings or numbers. Any other shape dies. These are the
options of a L<Term::Fabulous::Widget::SegmentedControl> as well (see
L<Term::Fabulous::OptionList/Options>).

A disabled option is shown in the open list in the C<disabled_color>,
but the user cannot choose it: the keys and typing skip it, it is never
highlighted, and pressing or releasing the mouse on it does nothing (the
list stays open). The program may still select it with C<value> or
C<selected_index>; the list then opens on the first enabled option.

=item C<value>

The value of the option to select at the start. Default: none selected.
Dies if no option has this value. Give either C<value> or
C<selected_index>, not both (giving both dies).

=item C<selected_index>

The index (from 0) of the option to select at the start. Default: none
selected. Dies if out of range.

=item C<placeholder>

A character string. Default: C<''> (none). Shown in
C<placeholder_color> while no option is selected.

=item C<max_visible_options>

A positive integer. Default: 8. The most options the open list shows at
once. The list is also made smaller when the terminal has less room
above and below the dropdown.

=item C<placeholder_color>

A color, in any format L<Term::Fabulous::Widget::Input> accepts.
Default: the theme's C<dropdown.placeholder>, C<[120, 126, 138, 255]>
in the dark theme, a gray.

=item C<list_background_color>

A color, as above. The background of the open list. Default: the
theme's C<dropdown.list.background>, C<[30, 33, 40, 255]> in the dark
theme, a very dark gray.

=item C<highlight_text_color>

A color, as above. The text color of the highlighted option in the open
list, which is painted on the theme's C<dropdown.highlight.background>
(the accent). Default: the theme's C<dropdown.highlight.text>,
C<[16, 18, 22, 255]> in the dark theme, nearly black.

=item C<background_color>

Any L<Term::Fabulous::Color> format, stored as C<[r, g, b, a]>.
Default: the theme's C<dropdown.background>, C<[36, 40, 48, 255]> in
the dark theme, a dark gray, like the text inputs.

=back

The open list's border has the C<accent_color>, and so does the label of
the selected option in the list.

=head1 METHODS

The methods of L<Term::Fabulous::Widget::Input/METHODS> (C<is_enabled>,
the color accessors, C<mark_changed>), plus:

=head2 value

	my $value = $dropdown->value;
	$dropdown->value('green');
	$dropdown->value(undef);    # select nothing

Accessor. Returns the value of the selected option, or C<undef> when
none is selected. Writing selects the first option with that value
(compared as strings), or clears the selection for C<undef>, marks the input changed,
and returns the new value. Dies if no option has the value. Writing
fires no C<Change> event.

=head2 selected_index

	my $index = $dropdown->selected_index;
	$dropdown->selected_index(0);
	$dropdown->selected_index(undef);

Accessor for the index of the selected option (from 0), C<undef> for
none. Writing returns the new index and fires no C<Change> event. Dies
if the index is not an integer in range; the selection then stays.

=head2 selected_label

	my $label = $dropdown->selected_label;

The label of the selected option, or C<undef> when none is selected.

=head2 options

	my @options = $dropdown->options;    # ( { label => ..., value => ..., disabled => 0 }, ... )
	$dropdown->options( [ 'One', 'Two', [ Three => 3 ] ] );

Accessor. Returns the options as a list of hash references with the keys
C<label>, C<value> and C<disabled> (copies; changing them does not
change the dropdown). Writing replaces all options (in the formats of the
C<options> parameter), closes the list, and keeps the selection when an
option with the selected value still exists; otherwise nothing is
selected afterwards. Writing fires no C<Change> event. Returns the new
options.

=head2 placeholder

	my $text = $dropdown->placeholder;
	$dropdown->placeholder('Choose one');

Accessor for the placeholder. Writing marks the input changed and returns the new
placeholder. A value that is not a string dies and leaves the
placeholder unchanged.

=head2 max_visible_options

	my $count = $dropdown->max_visible_options;
	$dropdown->max_visible_options(12);

Accessor for the C<max_visible_options> parameter. Writing returns the
new value, which takes effect the next time the list opens. A value that
is not a positive integer dies and leaves the old value.

=head2 placeholder_color

	$dropdown->placeholder_color('#888888');

Accessor for the C<placeholder_color> parameter. Writing marks the
dropdown changed and returns the new color as C<[r, g, b, a]>. An invalid color dies
and leaves the old one.

=head2 list_background_color

	$dropdown->list_background_color([ 20, 20, 30, 255 ]);

Accessor for the C<list_background_color> parameter. Writing returns the
new color as C<[r, g, b, a]>; it takes effect the next time the list opens. An
invalid color dies and leaves the old one.

=head2 highlight_text_color

	$dropdown->highlight_text_color('#000000');

Accessor for the C<highlight_text_color> parameter. Writing marks the
dropdown changed and returns the new color as C<[r, g, b, a]>; an open
list shows it in the next frame. An invalid color dies and leaves the
old one.

=head2 disabled

	$dropdown->disabled(1);

As described in L<Term::Fabulous::Widget::Input/disabled>; disabling
also closes the list.

=head2 open

	$dropdown->open;

Opens the list as the user does, with the selected option (or, when it
is disabled or there is none, the first enabled one) highlighted. Does nothing when the list is already open, when there
are no options, or while the dropdown is disabled. Returns the dropdown.

=head2 close

	$dropdown->close;

Closes the list without changing the selection. Does nothing when it is
closed. Returns the dropdown.

=head2 is_open

	if ( $dropdown->is_open ) { ... }

1 while the list is open, 0 otherwise.

=head2 choose

	$dropdown->choose(2);

Selects the option at an index (from 0) as the user does: closes the
list and, when the selection changes, fires a C<Change> event. A
disabled option is not chosen and the list stays as it is. Dies if the
index is not an integer in range. Returns the dropdown.

=head2 highlight

	$dropdown->highlight(3);

Moves the highlight of the open list to an index (clamped to the
options) and scrolls it into view. Does nothing while the list is
closed, or for a disabled option. Returns the dropdown.

=head2 highlighted_index

	my $index = $dropdown->highlighted_index;

The index of the highlighted option in the open list, C<undef> while the
list is closed.

=head1 KEYS

The dropdown uses the keys below while it has the focus and is enabled.
All of them skip disabled options, as the other widgets with entries do
(see L<Term::Fabulous::Roving>).

When the list is closed:

=over

=item C<Enter>, C<Space>, C<Alt+Down>, C<F4>

Open the list.

=item C<Up>, C<Down>

Select the previous or next option directly, without opening the list
(this fires C<Change>). They stop at the first and last option. With
nothing selected, C<Up> selects the last option and C<Down> the first.

=item C<Home>, C<End>

Select the first or last option.

=back

When the list is open:

=over

=item C<Up>, C<Down>

Move the highlight one option up or down.

=item C<PageUp>, C<PageDown>

Move the highlight by as many options as the list shows.

=item C<Home>, C<End>

Move the highlight to the first or last option.

=item C<Enter>, C<Space>

Select the highlighted option and close the list.

=item C<Escape>

Close the list without changing the selection.

=back

In both states, typing a printable character other than the space
(without C<Ctrl> or C<Alt>) jumps to the next option whose label starts
with it, ignoring case: it selects that option while the list is closed
(firing C<Change>) and highlights it while the list is open. The
current option is the selected one while the list is closed and the
highlighted one while it is open. Characters typed at most one second
apart form one search string, so typing C<d>, C<a> quickly finds "Dark
green" rather than the next option starting with C<a>. A search for a
single character starts after the current option, so pressing C<d>
again moves on to the next label starting with C<d>; a longer search
string starts at the current option, so it stays there while the label
still matches. Both wrap around from the last option to the first. The
space is not part of a search: it opens the list, or chooses the
highlighted option.

The keys above are used and do not bubble, and so is every printable
character, even one that matches no label. Only a dropdown without any
options lets printable characters bubble. All other keys bubble to the
ancestors, among them C<Tab> (which then moves the focus and closes the
list) and, while the list is closed, C<Escape>.

=head1 MOUSE

=over

=item *

Pressing the left button on the dropdown opens the list, or closes it
when it is open; the list reacts to the press, not to the release.

=item *

Pressing the left button on an option of the open list highlights it;
releasing the button over an option selects it and closes the list. So
both a click on an option and a single gesture work: press on the
dropdown, drag to an option and release there.

=item *

The mouse wheel over the open list scrolls it by one option per notch.

=back

=head1 EVENTS

=over

=item C<Change>

L<Term::Fabulous::Event::Change> when the user selects another option,
with the option's value as C<< $event->value >>. Selecting the option
that is already selected fires nothing. Programmatic writes to
C<value>, C<selected_index> and C<options> fire nothing.

=back

=head1 KDL PROPERTIES

The properties of L<Term::Fabulous::Widget::Input/KDL PROPERTIES>, plus
C<value>, C<selected_index>, C<placeholder>, C<max_visible_options>,
C<placeholder_color>, C<list_background_color> and
C<highlight_text_color>. Options are added with two kinds of nodes,
which may be repeated and mixed; each adds to the options given before:

=over

=item C<options "Label 1" "Label 2" ...>

One or more options whose value is their label.

=item C<option "Label" value="v" disabled=#true>

One option; C<value=> defaults to the label, C<disabled=> to C<#false>.

=back

=for highlighter language=kdl

	use Term::Fabulous::Widget::Dropdown as Dropdown

	Dropdown "color" {
		placeholder "Pick a color"
		options "Red" "Green"
		option "Dark blue" value="navy"
		value "navy"
	}

The options of a layout are added before its C<value> and
C<selected_index> are set, wherever they stand in the block, so
C<value "navy"> may also come first. A C<value> that no option has
dies.

=head1 EXAMPLES

=head2 Options with numeric values

=for highlighter language=perl

	my $priority = Term::Fabulous::Widget::Dropdown->new(
		options => [ [ Low => 1 ], [ Normal => 2 ], [ High => 3 ] ],
		value   => 2,
	);
	my $level = $priority->value;    # 2

=head2 Options that depend on another dropdown

	my $country = Term::Fabulous::Widget::Dropdown->new( options => [ 'Germany', 'France' ] );
	my $city    = Term::Fabulous::Widget::Dropdown->new( placeholder => 'City' );
	my %cities  = ( Germany => [qw(Berlin Hamburg)], France => [qw(Paris Lyon)] );

	$country->on( Change => sub ($event) {
		$city->options( $cities{ $event->value } );    # clears the city selection
		return;
	} );

=head1 SUBCLASS INTERFACE

The open list (L<Term::Fabulous::Widget::Dropdown::List>) paints the
options through these methods; override them in a subclass to change how
options look.

=head2 option_attrs

	my ( $fg, $bg ) = $self->option_attrs($index);

The termbox2 attributes of an option's row in the list: the
C<highlight_text_color> on the C<accent_color> for the highlighted
option, the C<accent_color> for the selected one, the C<text_color> for
the others (C<undef> background: the list background shows).

=head2 option_label

	my $label = $self->option_label($index);

The label of the option at an index.

=head2 option_count

	my $count = $self->option_count;

The number of options.

=head2 layout_properties

The KDL table (see L<Term::Fabulous::Widget::Box/layout_properties>):
the colors as colors, the other properties as scalars, and C<options>
and C<option> as structured properties. The options of a layout are
applied before C<value> and C<selected_index>, wherever they stand.

=head1 CAVEATS

Inside a L<Term::Fabulous::Widget::ScrollBox>, the mouse wheel over the
open list scrolls the list; a list that shows all options, or is at its
end, leaves the notch to the scroll box, which then moves the dropdown
and its list.

=head1 SEE ALSO

L<Term::Fabulous::Widget::Input>, L<Term::Fabulous::Widget::Dropdown::List>,
L<Term::Fabulous::Event::Change>,
L<the dropdown section of the forms guide|Term::Fabulous::Manual::Forms/Dropdowns>,
L<Term::Fabulous::Cookbook::Forms/Choose from options in Perl (Dropdown, RadioGroup, Slider)>.

=cut
