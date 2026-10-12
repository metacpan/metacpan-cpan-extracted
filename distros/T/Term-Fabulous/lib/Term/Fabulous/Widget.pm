package Term::Fabulous::Widget;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.02';

use Object::Pad 0.825;

class Term::Fabulous::Widget
	:isa(Term::Fabulous::Widget::Element)
	:does(Term::Fabulous::Role::HasBorderStyle)
	:does(Term::Fabulous::Role::Themed)
	:abstract
{
	use List::Util qw(first);
	use Term::Fabulous::Check qw(boolean class_names color);
	use Term::Fabulous::Theme;

	my @COLOR_PARAMS = qw(background_color border_color);

	# The sides of the theme's border.enabled, shared and never changed.
	my %EVERY_SIDE = map { $_ => 1 } qw(top right bottom left);
	my %NO_SIDE    = map { $_ => 0 } qw(top right bottom left);

	field $classes             :param = [];
	field $glyphs_show_through :param = 0;

	# Clay::UI validates the colors before any ADJUST of this class runs,
	# so they are converted while the arguments are still a plain list.
	# Clay::UI's border_width is replaced by bordered.
	sub BUILDARGS ( $class, %params ) {
		_no_border_width($class) if exists $params{border_width};
		$params{$_} = color( $class, $_ => $params{$_} ) foreach grep { defined $params{$_} } @COLOR_PARAMS;
		return %params;
	}

	sub _no_border_width ($owner) {
		die( ( ref $owner || $owner )
			. ": border_width is not a parameter of Term::Fabulous widgets; use bordered (true, or a hash of the sides top, right, bottom and left) and give the room inside the border as layout padding"
		);
	}

	ADJUST {
		$glyphs_show_through = boolean( $self, glyphs_show_through => $glyphs_show_through );
		$classes             = class_names( $self, classes => $classes );
	}

	# The readers return the color in use: the given one, or the theme's
	# for the widget's family (none for a plain box).
	method background_color :override (@new) {
		return $self->SUPER::background_color( defined $new[0] ? color( $self, background_color => $new[0] ) : @new ) if @new;
		return $self->SUPER::background_color // $self->look('background');
	}

	method border_color :override (@new) {
		return $self->SUPER::border_color( defined $new[0] ? color( $self, border_color => $new[0] ) : @new ) if @new;
		return $self->SUPER::border_color // $self->look('border.color');
	}

	method border_width :override (@) {
		_no_border_width($self);
	}

	# The sides the widget has a border on: the given ones, or every side
	# or none as the theme's border.enabled says. Returns a new hash.
	method bordered (@new) {
		return { %{ $self->_bordered_sides } } unless @new;
		$self->set_look( bordered => $new[0] );
		return { %{ $self->_bordered_sides } };
	}

	# The same, shared, for Term::Fabulous::Role::HasBorderStyle, which
	# reads it for every frame; it must not be changed.
	method _bordered_sides () {
		my $sides = $self->look_value('bordered');
		return ref $sides ? $sides : $sides ? \%EVERY_SIDE : \%NO_SIDE;
	}

	# The color this widget lies on: the background of the widget itself
	# or of its nearest ancestor that has one, else the screen background
	# of its UI, painted opaque, else undef. A background counts when it is
	# opaque; with translucent => 1 any background with an alpha above 0
	# counts, the one a painter blends the widget's own cells over.
	method background_below (%options) {
		my @unknown = grep { $_ ne 'translucent' } sort keys %options;
		die ref($self) . ": background_below does not take @unknown (known: translucent)" if @unknown;
		my $lowest_alpha = $options{translucent} ? 1 : 255;
		for ( my $node = $self; defined $node; $node = $node->parent ) {
			next unless $node->can('background_color');
			my $color = $node->background_color // next;
			return [@$color] if $color->[3] >= $lowest_alpha;
		}
		my $ui = $self->ui // return undef;
		return undef unless $ui->can('screen_background');
		my $screen = $ui->screen_background // return undef;
		return [ ( $screen->to_rgba )[ 0 .. 2 ], 255 ];
	}

	# ---------------------------------------------------------------------
	# The theme (Term::Fabulous::Role::Themed): a container is a box, whose
	# background and border the theme colors only when the program gave
	# none. Subclasses name their family and add their parameters.
	# ---------------------------------------------------------------------

	method theme_family :common () {
		return 'box';
	}

	# A family without border.enabled (box itself) leaves bordered to the
	# program.
	method themed_params :common () {
		my $border_slot = Term::Fabulous::Theme::has_slot( $class->theme_family, 'border.enabled' ) ? 'border.enabled' : undef;
		return (
			background_color => [ 'background',   'normal' ],
			border_color     => [ 'border.color', 'normal' ],
			bordered         => [ $border_slot,   'normal', 'border_sides' ],
		);
	}

	method look_state () {
		return 'normal';
	}

	# background_color and border_color live in the Clay::UI roles.
	method look_reset ($name) {
		$self->SUPER::background_color(undef) if $name eq 'background_color';
		$self->SUPER::border_color(undef) if $name eq 'border_color';
		return;
	}

	method classes (@new) {
		return [@$classes] unless @new;
		$classes = class_names( $self, classes => $new[0] );
		$self->forget_looks;
		$self->mark_changed;
		return [@$classes];
	}

	# A widget that joins or leaves a tree may be in another UI, with
	# another theme, from now on.
	method tree_changed :override () {
		$self->SUPER::tree_changed;
		$self->_forget_own_looks;
		return;
	}

	# Runs after contribute_background and contribute_border (Clay::UI
	# calls the contributors in alphabetical order) and before a subclass's
	# contribute_state_look: fills the background and the border color the
	# program left to the theme, for the state the widget is in. A border
	# is colored only where there is one.
	method contribute_look_theme ($config) {
		my $state      = $self->look_state;
		my $background = $self->themed_value( 'background', $state, $config->{background_color} // $self->look('background') );
		$config->{background_color} = $background if defined $background && ref $background;

		my $border = $config->{border} // return;
		my $color  = $self->themed_value( 'border.color', $state, $border->{color} // $self->look('border.color') );
		$config->{border} = { %$border, color => $color } if defined $color;
		return;
	}

	# The first widget at or below this one, in layout pre-order, whose id
	# is $id.
	method find_by_id ($id) {
		die "Term::Fabulous::Widget: find_by_id needs an id, got undef" unless defined $id;
		return first { _has_id( $_, $id ) } $self, $self->descendants;
	}

	# The inputs at or below this one, in layout pre-order, whose value is
	# not valid.
	method invalid_inputs () {
		return grep { $_->DOES('Term::Fabulous::Role::Validatable') && !$_->is_valid } $self, $self->descendants;
	}

	# Text leaves have an id too.
	sub _has_id ( $widget, $id ) {
		my $widget_id = $widget->can('id') ? $widget->id : undef;
		return defined $widget_id && $widget_id eq $id;
	}

	method get_classes () {
		return ( @$classes, map { 'state_' . lc($_) } $self->states );
	}

	method glyphs_show_through (@new) {
		return $glyphs_show_through unless @new;
		$glyphs_show_through = boolean( $self, glyphs_show_through => $new[0] );
		$self->mark_changed;
		return $glyphs_show_through;
	}

	# Whether the renderer swaps the foreground and background colors of
	# every cell the widget and its children paint. Button overrides it
	# while it is pressed.
	method reverse_video () {
		return 0;
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Widget - Abstract base class of the Term::Fabulous
container widgets

=head1 SYNOPSIS

	# Term::Fabulous::Widget is abstract; you use its subclasses:
	use Term::Fabulous::Widget::Box;
	use Term::Fabulous::Enum::BorderStyle;
	use Clay::XS qw(sizing_grow sizing_fit CLAY_TOP_TO_BOTTOM);

	my $panel = Term::Fabulous::Widget::Box->new(
		id               => 'panel',
		layout           => {
			layout_direction => CLAY_TOP_TO_BOTTOM,
			sizing           => { width => sizing_grow(), height => sizing_fit() },
			padding          => { left => 1, right => 1 },
			child_gap        => 1,
		},
		background_color => [ 30, 35, 50, 255 ],
		bordered         => 1,
		border_color     => [ 120, 160, 220, 255 ],
		border_style     => Term::Fabulous::Enum::BorderStyle->Round,
		classes          => ['sidebar'],
	);

	# Writing a widget class of your own:
	use Object::Pad;
	class My::Panel :isa(Term::Fabulous::Widget) :strict(params) { }

=head1 DESCRIPTION

C<Term::Fabulous::Widget> is the common base of every Term::Fabulous
widget that is a rectangle on the screen and can hold other widgets:
L<Term::Fabulous::Widget::Box> and everything built on it
(L<Term::Fabulous::Widget::Button>, L<Term::Fabulous::Widget::ScrollBox>,
L<Term::Fabulous::Widget::Canvas>, the input widgets, ...).
L<Term::Fabulous::Widget::Text> is not one of them: text is a leaf that
always lives inside such a widget.

The class is abstract: C<< Term::Fabulous::Widget->new >> dies. Create a
L<Term::Fabulous::Widget::Box> when you need a plain container, or
subclass this class (or Box) for a widget of your own.

This page is the reference for everything these widgets have in common:
the constructor parameters for layout, background, border and ids, and
the methods for children, events and states. Most of it comes from
L<Clay::UI>, the widget layer on top of the Clay layout engine, through
the roles this class inherits from L<Term::Fabulous::Widget::Element>
and the one it composes itself:

=over

=item * L<Clay::UI::Role::Core::Container>: children (C<add_child>, ...)

=item * L<Clay::UI::Role::Events::Listener> and L<Clay::UI::Role::Events::Emitter>: events (C<on>, C<fire_event>)

=item * L<Clay::UI::Role::Layout::HasFloating>: the C<floating> hash

=item * L<Clay::UI::Role::Layout::HasLayout>: the C<layout> hash

=item * L<Clay::UI::Role::Layout::HasParent>: C<parent>, C<root>, C<ui>

=item * L<Clay::UI::Role::Layout::HasSizingGroup>: C<width_group>, C<height_group>

=item * L<Clay::UI::Role::Style::HasBackground>: C<background_color>

=item * L<Clay::UI::Role::Style::HasBorder>: C<border_color> (its C<border_width> gives way to L</bordered>)

=item * L<Clay::UI::Role::Style::HasStates>: C<add_state>, C<states>, ...

=item * L<Term::Fabulous::Role::HasBorderStyle>: the border glyphs (C<border_style>, ...)

=item * L<Term::Fabulous::Role::Themed>: the colors, border styles and borders the theme supplies (C<look>, C<reset_look>, ...)

=back

The sections below summarize what you need for everyday use; the role
pages have the full details.

=head1 CONSTRUCTOR

=head2 new

	my $box = Term::Fabulous::Widget::Box->new(%parameters);

C<new> is called on a concrete subclass. All parameters are optional.
The concrete classes reject unknown parameters: a typo dies with
C<Unrecognised parameters for ... constructor>. Widgets are created
empty; add children afterwards with L</add_child>.

=over

=item C<id>

A non-empty string. Default: none. Names the widget:
L</remove_child_with_id> removes children by id, listeners can tell widgets apart with
C<< $event->target->id >>, and Clay keeps state (such as a scroll
position) for it between frames. L</find_by_id> finds a widget in a
tree by its id. Ids must be unique in a widget tree: two widgets with
the same id make drawing die with a C<Clay error>. Ids starting with
C<anon:> are reserved and die. Widgets without an id get one
generated from their position in the tree.
L<Term::Fabulous::Widget::ScrollBox> requires an id.

=item C<layout>

A hash reference of layout options. Default: C<{}>, which sizes the
widget to fit its content and stacks children from left to right. The
keys are:

=over

=item C<sizing>

C<< { width => $sizing, height => $sizing } >>, each built with a
function from L<Clay::XS>: C<sizing_fit($min, $max)> (as big as the
content, the default), C<sizing_grow($min, $max)> (take the space left
over in the parent), C<sizing_fixed($cells)> and
C<sizing_percent($fraction)> (a share of the parent, a number from 0 to
1; C<0.5> is half). A fraction above 1 is accepted by C<new> but makes
drawing die with a C<Clay error>. C<$min> and C<$max> are optional
limits in cells. Either axis may be
left out.

=item C<padding>

C<< { left => $n, right => $n, top => $n, bottom => $n } >>, any
subset, in cells; C<padding_all($n)> from L<Clay::XS> builds one with
all four sides. The padding lies inside the border (see
L<Term::Fabulous::Role::HasBorderStyle/Border space>).

=item C<child_gap>

The number of empty cells between two neighboring children.

=item C<layout_direction>

C<CLAY_LEFT_TO_RIGHT> (the default), C<CLAY_TOP_TO_BOTTOM>,
C<CLAY_LEFT_TO_RIGHT_WRAP> (left to right, wrapping onto new lines; see
L<Term::Fabulous::Manual::Layout/Flow layout>) or C<CLAY_BACK_TO_FRONT> (on top
of each other; see L<Term::Fabulous::Manual::Layout/Stack layout>), constants
exported by L<Clay::XS>.

=item C<line_gap>

The number of empty rows between two lines of a
C<CLAY_LEFT_TO_RIGHT_WRAP> layout. Default: 0.

=item C<line_sizing>

C<CLAY_LINE_SIZING_GROW> (the default) or C<CLAY_LINE_SIZING_FIT>,
constants exported by L<Clay::XS>: whether the lines of a
C<CLAY_LEFT_TO_RIGHT_WRAP> layout share the rows left over below them
or keep the height of their tallest child.

=item C<child_alignment>

C<< { x => $x, y => $y } >> with C<CLAY_ALIGN_X_LEFT>,
C<CLAY_ALIGN_X_CENTER> or C<CLAY_ALIGN_X_RIGHT> and C<CLAY_ALIGN_Y_TOP>,
C<CLAY_ALIGN_Y_CENTER> or C<CLAY_ALIGN_Y_BOTTOM>. Default: left and top.

=back

Any other key, or a value of the wrong shape, dies. See
L<Term::Fabulous::Manual::Layout/LAYOUT> for how these work together.

=item C<floating>

A hash reference that takes the widget out of its parent's layout and
draws it on top of the other widgets, positioned against its parent,
the root or another widget. It takes no space in its parent. Default:
C<undef>, the widget is laid out normally. The keys, all optional, take
constants exported by L<Clay::XS>:

=over

=item C<attach_to>

What the widget is positioned against: C<CLAY_ATTACH_TO_PARENT>,
C<CLAY_ATTACH_TO_ROOT> (the whole screen) or
C<CLAY_ATTACH_TO_ELEMENT_WITH_ID> (the widget named by C<parent_id>).
The default, C<CLAY_ATTACH_TO_NONE>, does not make the widget float.

=item C<parent_id>

With C<CLAY_ATTACH_TO_ELEMENT_WITH_ID>, the Clay element id number of
the widget to attach to: C<< Clay::XS::Clay_GetElementId($id)->{id} >>
for the widget with the id C<$id>. That widget does not have to be an
ancestor.

=item C<attach_points>

C<< { element => $point, parent => $point } >>: the point of this
widget that is placed on the point of the widget it is attached to,
each one of C<CLAY_ATTACH_POINT_LEFT_TOP>, C<..._LEFT_CENTER>,
C<..._LEFT_BOTTOM>, C<..._CENTER_TOP>, C<..._CENTER_CENTER>,
C<..._CENTER_BOTTOM>, C<..._RIGHT_TOP>, C<..._RIGHT_CENTER> and
C<..._RIGHT_BOTTOM>. Default: both C<CLAY_ATTACH_POINT_LEFT_TOP>.

=item C<offset>

C<< { x => $columns, y => $rows } >>, added to the position; negative
values move left and up.

=item C<expand>

C<< { width => $columns, height => $rows } >>, enlarges the widget's
area without changing the space its children get.

=item C<z_index>

An integer from -32768 to 32767. Floating widgets with a higher value
are drawn on top of those with a lower one.

=item C<pointer_capture_mode>

C<CLAY_POINTER_CAPTURE_MODE_CAPTURE> (the default) or
C<CLAY_POINTER_CAPTURE_MODE_PASSTHROUGH>, Clay's pointer setting for
the widget. Term::Fabulous delivers C<Mouse> events to the topmost
widget painted under the pointer either way.

=item C<clip_to>

C<CLAY_CLIP_TO_NONE> (the default) or C<CLAY_CLIP_TO_ATTACHED_PARENT>,
which cuts the widget off at the clipping area (such as a
L<Term::Fabulous::Widget::ScrollBox>) of the widget it is attached to.

=back

Any other key, or a value of the wrong shape, dies. See
L<Clay::UI::Role::Layout::HasFloating>.

=item C<background_color>

The color of the widget's area, in any format
L<Term::Fabulous::Color> accepts: an array reference C<[r, g, b, a]>
(or C<[r, g, b]>, alpha 255), a hash reference
C<{ r => ..., g => ..., b => ..., a => ... }>, a string such as
C<'#ff0000'> or C<'rgb(255, 0, 0)'>, or a Term::Fabulous::Color
object. The value is stored as C<[r, g, b, a]>, which is what the
reader returns. Default: none, so the widget's area shows what is
behind it. An alpha of 0 means no color, 255 is opaque, and 1 to 254 is
translucent: the color is blended with whatever is below the widget
(see C<glyphs_show_through>). See L<Term::Fabulous::Manual::Looks/COLORS>.

A widget with neither a background color nor a border paints nothing,
so it is also invisible to the mouse: clicks on it go to the widget
behind it. A widget with only a border receives clicks on its border
cells.

=item C<glyphs_show_through>

Only matters with a translucent C<background_color> (alpha 1 to 254).
False (the default): the widget's area is covered with spaces in the
blended color, so text and borders below it disappear. True: they stay
visible through the background, with their colors tinted by it, until
the widget paints its own content over them. Where the color below is
the terminal default, which cannot be blended, the background is drawn
opaque and a glyph's default foreground stays as it is. Any true or
false value; references die. See
L<Term::Fabulous::Manual::Looks/Alpha and the terminal default color>.

=item C<bordered>

Which sides have a border: one true or false value for all four sides,
or a hash reference with any of the keys C<top>, C<right>, C<bottom>
and C<left> and true or false values, where a side the hash leaves out
has no border (C<< { top => 1, bottom => 1 } >> draws a line above and
below the widget). Default: the theme's C<border.enabled> for the
widget's family, on all four sides. The C<box> family (plain boxes,
scroll boxes, canvases, charts and every widget that names no family
of its own) has no C<border.enabled>, so its widgets have no border
unless they are given one (see L<Term::Fabulous::Theme/Borders>). Stored as a hash of all four sides,
1 or 0. Another reference, an unknown side or a reference as a side's
value dies, and so does C<undef>: L</reset_look> returns the parameter
to the theme.

A border is one cell thick and takes that cell from the inside of the
widget: the C<padding> and the content start after it, and a widget
with C<fit> sizing grows by it. Room between the border and the content
is C<padding>. A side whose style is C<Hidden> draws nothing and takes
no space. See L<Term::Fabulous::Manual::Looks/BORDERS>.

Term::Fabulous widgets do not take the C<border_width> of
L<Clay::UI::Role::Style::HasBorder>: giving it to the constructor, or
calling C<border_width>, dies with a hint to use C<bordered>.

=item C<border_color>

The color of the border glyphs, in the same formats as
C<background_color>. Default: the terminal's default foreground color.

=item C<border_style>

A L<Term::Fabulous::Enum::BorderStyle> item, such as
C<< Term::Fabulous::Enum::BorderStyle->Round >>, or its name
(C<'Round'>), used for every side
that has no side parameter of its own. Default: the theme's
C<border.style> for the widget's family (C<Round> in the built-in
themes); a side with a border but no style from the program, the
widget or the theme is drawn with the C<Blank> style (spaces). See
L<Term::Fabulous::Role::HasBorderStyle>.

=item C<border_style_top>

=item C<border_style_right>

=item C<border_style_bottom>

=item C<border_style_left>

The style of one side, a L<Term::Fabulous::Enum::BorderStyle> item or
its name. It wins over C<border_style> for that side; see
L<Term::Fabulous::Role::HasBorderStyle>.

=item C<border_corners>

C<undef> (the default) or a hash reference with any of the keys
C<top_left>, C<top_right>, C<bottom_left> and C<bottom_right>, each a
glyph drawn at that corner instead of the style's corner glyph, for
example to join the box to lines around it. See
L<Term::Fabulous::Role::HasBorderStyle/border_corners>.

=item C<outer_border_sides>

An array reference of side names (C<top>, C<right>, C<bottom>,
C<left>) whose glyphs are drawn on the background outside the widget
instead of the widget's own. Default: C<[]>. See
L<Term::Fabulous::Role::HasBorderStyle/outer_border_sides>.

=item C<width_group>

=item C<height_group>

An integer from 0 to 1048575. Default: 0 (no group). Widgets anywhere
in the tree with the same non-zero group number get the same width (or
height): the largest content size among them. Useful to line up form
labels. Only C<fit> and C<grow> sizing take part. See
L<Clay::UI::Role::Layout::HasSizingGroup>.

=item C<classes>

An array reference of strings. Default: C<[]>. Names of your own,
returned by L</get_classes> and L</classes>. The theme reads them: a
widget whose classes name a variant of its family draws with that
variant (see L<Term::Fabulous::Manual::Looks/Variants and classes>).
The array is copied; anything but an array of defined, non-reference
names dies.

=back

The background, the border color, the border style and whether there
is a border at all come from the theme of the UI when they are not
given, where the theme has them for the widget's family (a plain Box
has no background in the built-in themes and never gets a border from
a theme; a Dialog or a Toast has both); see
L<Term::Fabulous::Manual::Looks/THEMES>. Subclasses document the
theme slot each of their colors reads.

=head1 METHODS

The methods fall into four groups: children (C<add_child> to C<ui>),
events (C<on>, C<fire_event>, C<handlers_for>), layout and style
accessors (C<layout> to C<height_group>) and states (C<add_state> to
C<get_classes>).

States: every widget has a set of state names. C<hovered>, C<pressed>,
C<focused> and C<disabled> are I<derived> states: they follow the
widget's interaction (for example on a L<Term::Fabulous::Widget::Button>)
or its C<disabled> flag and cannot be set by hand. You may add names of
your own, for example C<selected>. See
L<Clay::UI::Role::Style::HasStates>.

=head2 add_child

	$box->add_child($widget);
	$box->add_child( $header, $body, $footer );

Appends one or more widgets (or L<Term::Fabulous::Widget::Text>s) as
children, in order. Returns the widget, so calls chain:
C<< $root->add_child($a)->add_child($b) >>.

A widget has at most one parent at a time. Adding a widget that still
has a parent dies, and so does adding the root of a L<Term::Fabulous>
or a widget to itself or one of its descendants. To move a widget,
remove it from its parent first. See
L<Clay::UI::Role::Core::Container/add_child>.

=head2 remove_child

	$box->remove_child($status);
	$box->remove_child( $spinner, $label );

Removes each given widget that is a direct child of this one (the very
object; widgets without an id and Text widgets included). A widget that
is not a direct child is ignored. Dies, removing nothing, for anything
but a widget, an id included (use L</remove_child_with_id>). A removed
widget keeps its children and its state and can be added again. Returns
the widget.

Removing a subtree that holds the focused widget or a hovered widget
fires C<OnBlur> or C<OnHoverStopped> on it during the call; C<OnBlur>
still bubbles through the old parents. When an C<OnBlur> listener dies,
the removal is completed first and the error is rethrown afterwards.

=head2 remove_child_with_id

	$box->remove_child_with_id('status');

Removes every direct child whose C<id> equals the argument. Unknown ids
are ignored. Text widgets are never removed this way, even when they
have an C<id> (use L</remove_child> or L</remove_children_with>).
Returns the widget. Removal works as described in L</remove_child>.

=head2 remove_children_with

	$box->remove_children_with( sub { $_->isa('Term::Fabulous::Widget::Text') } );

Removes every direct child for which the code reference returns true.
The child is passed as the argument and in C<$_>. Returns the widget.
Removal works as described in L</remove_child>.

=head2 clear_children

	$box->clear_children;

Removes all children. Returns the widget. Removal works as described
in L</remove_child>.

=head2 id

	my $id = $widget->id;

The C<id> given to the constructor, or C<undef> when none was given
(the generated id is not returned). There is no writer.

=head2 invalid_inputs

	if ( my @invalid = $form->invalid_inputs ) {
		$message->text( $invalid[0]->error );
		$ui->interaction->set_focused_widget( $invalid[0] );
		return;
	}

The input widgets at or below this one, in the same order as
L</find_by_id> walks, whose value is not valid (see
L<Term::Fabulous::Widget::Input/is_valid>): empty while C<required>,
or rejected by their C<validator>. The widget itself is included when
it is such an input. Returns an empty list when every input is fine,
also when there is none. The tree is walked on every call.

=head2 find_by_id

	my $volume = $root->find_by_id('volume');

The first widget, in depth-first pre-order, whose C<id> equals the
argument: the widget itself, then its first child and that child's
descendants, then the second child, and so on, the order in which the
frame lays them out (L<Clay::UI::Role::Core::Element/descendants>).
Text widgets with an id are found too, and so are the widgets a widget
keeps below an internal child, such as the items of a
L<Term::Fabulous::Widget::VirtualList>. Returns C<undef> when there is
none. Dies when the argument is C<undef>. The tree is walked on every
call; keep the result instead of searching in every event.

=head2 children

	my @kids = @{ $box->children };

A new array reference with the direct children, in order. Changing the
array does not change the widget.

=head2 has_child

	$box->add_child($status) unless $box->has_child($status);

1 when the widget is a direct child of this one (the very object), else
0. Dies for anything but a widget.

=head2 get_children_with

	my @buttons = $box->get_children_with( sub { $_->isa('Term::Fabulous::Widget::Button') } );

The direct children for which the code reference returns true (as a
list). Does not look at grandchildren.

=head2 descendants

	my @fields = grep { $_->isa('Term::Fabulous::Widget::TextField') } $form->descendants;

Every widget below this one, not the widget itself, as a list in the
order the frame lays them out: each child followed by the widgets below
it, including those a widget keeps below an internal child (the items
of a L<Term::Fabulous::Widget::VirtualList>). See
L<Clay::UI::Role::Core::Element/descendants>.

=head2 parent

	my $owner = $widget->parent;

The widget that contains this one, or C<undef> for the root and for
widgets that were never added or were removed.

=head2 root

	my $top = $widget->root;

The topmost widget above this one (the widget itself when it has no
parent).

=head2 ui

	my $ui = $widget->ui;

The L<Term::Fabulous> (or L<Term::Fabulous::Static>) object whose tree
contains the widget, or C<undef> when it is not part of one. Useful in
listeners, for example C<< $widget->ui->interaction->set_focused_widget(...) >>.

=head2 contains

	return if $popup->contains( $event->target );

1 when the argument is this widget or a widget below it, else 0. Dies
for anything but a widget. To ask whether the focus is inside a
widget, use C<< $widget->ui->interaction->has_focus_within($widget) >>.
See L<Clay::UI::Role::Layout::HasParent/contains>.

=head2 on

	$widget->on( KeyPress => sub ($event) { ...; return } );

Registers a listener: a code reference called with the event object
whenever an event of that name is fired on this widget or bubbles up
to it from a descendant. Several listeners per name are allowed; they
run in the order they were added. Returns the widget. Dies when the
name is empty or the listener is not a code reference.

What the listener returns decides whether the event continues to the
parent: only C<< Clay::UI::Enum::Result->CONTINUE >> lets it go on, any
other value (including a plain C<return;>) stops it after this widget.
The other listeners on the same widget still run. A few event types
never bubble, whatever the listeners return.
See L<Term::Fabulous::Manual::Events/EVENTS> for the event names and the rules.

=head2 fire_event

	$widget->fire_event( Term::Fabulous::Event::Change->new( value => 42 ) );

Delivers an event object to this widget's listeners and then up the
parent chain as described in L</on>. An event object can be fired only
once. Term::Fabulous calls this for you; call it yourself for events of
your own or in tests. See L<Clay::UI::Role::Events::Emitter>.

=head2 handlers_for

	my $listeners = $widget->handlers_for('KeyPress');
	printf "%d KeyPress listeners\n", scalar @$listeners;

A new array reference with the listeners registered on this widget for
an event name, in the order they were added (an empty array reference
when there are none). Changing the array does not change the widget.
Mostly useful in tests.

=head2 layout

	my $layout = $box->layout;
	$box->layout( { %{ $box->layout }, child_gap => 2 } );

Accessor for the C<layout> hash (see L</new>). Without an argument it
returns a copy of the stored hash; with an argument it replaces the
whole hash and returns a copy of the new one. Changing the returned hash
does not change the widget; write it back. An invalid hash dies like the
constructor parameter. The change shows in the next frame. Copy the old
hash as above to change a single key.

=head2 floating

	my $floating = $popup->floating;
	$popup->floating( { %{ $popup->floating // {} }, offset => { x => 4, y => 2 } } );

Accessor for the C<floating> hash (see L</new>). Without an argument it
returns a copy of the stored hash (C<undef> when none is set); with an
argument it replaces the whole hash and returns a copy of the new one. C<undef>
makes the widget part of its parent's layout again. An invalid hash
dies like the constructor parameter. The change shows in the next
frame.

=head2 background_color

	$box->background_color( [ 60, 90, 140, 255 ] );
	$box->background_color('#3c5a8c');

Accessor. Without an argument it returns the color in use as
C<[r, g, b, a]>: the given one, or the theme's background for the
widget's family (C<undef> for a widget whose family has none, such as
a plain Box); with an argument it sets the value, in any format the
constructor parameter accepts, and returns the stored C<[r, g, b, a]>.
C<undef> removes the given background color (L</reset_look> does the
same). An invalid value dies like the constructor parameter of the
same name. The change shows in the next frame.

=head2 background_below

	my $rgba = $widget->background_below;                     # opaque backgrounds only
	my $seen = $widget->background_below( translucent => 1 );

The color the widget lies on, as a new C<[r, g, b, a]>: the
L</background_color> of the widget itself or of its nearest ancestor
that has an opaque one, else the screen background of the
L<Term::Fabulous> object the widget is shown in (the theme's
C<background> token, returned with alpha 255 because it is painted
opaque; see L<Term::Fabulous::Render/SCREEN BACKGROUND>), else
C<undef>: for a widget that is in no UI, in a
L<Term::Fabulous::Static> (which paints no screen) or under a
C<background> token with alpha 0. Widgets that draw on what lies below
them use it: a L<Term::Fabulous::Widget::Table> paints the cells that
have no color of their own in it, and a chart mixes its ink from it.

A translucent background (alpha from 1 to 254) lets the colors below
show through, so it is skipped. With C<< translucent => 1 >> it counts
as well: that is the color a painter blends a widget's own cells over,
which is how the unset cells of a L<Term::Fabulous::Widget::Canvas> are
painted. Other options die.

=head2 glyphs_show_through

	$box->glyphs_show_through(1);

Accessor for the constructor parameter of the same name (0 or 1).
Without an argument it returns the current value; with an argument it
sets the value and returns the new one. The change shows in the next
frame.

=head2 border_color

	$box->border_color( [ 97, 175, 239, 255 ] );
	$box->border_color( Term::Fabulous::Enum::WebColor->SteelBlue );

Accessor. Without an argument it returns the color in use as
C<[r, g, b, a]>: the given one, or the theme's border color for the
widget's family (C<undef> for the terminal's default color, as for a
plain Box); with an argument it sets the value, in any format the
constructor parameter accepts, and returns the stored C<[r, g, b, a]>.
C<undef> removes the given color (L</reset_look> does the same). An
invalid value dies like the constructor parameter of the same name.
The change shows in the next frame.

=head2 bordered

	$box->bordered(1);                                # every side
	$box->bordered( { top => 1, bottom => 1 } );      # two sides
	$box->bordered(0);                                # none, whatever the theme says
	my $sides = $box->bordered;                       # { top => 1, right => 0, ... }

Accessor for the C<bordered> parameter. The writer takes the same values
as the constructor and returns the sides; an invalid value dies like the
constructor parameter. The reader returns the sides the widget has a
border on, given or from the theme's C<border.enabled>, as a new hash
reference of all four sides, each 1 or 0; a side whose style is
C<Hidden> still counts
(L<Term::Fabulous::Role::HasBorderStyle/drawn_border_sides> leaves it
out). C<< reset_look('bordered') >> returns it to the theme (no border
in a family without C<border.enabled>). The change shows in the next
frame and changes the layout, because a border takes space.

=head2 border_width

Dies: Term::Fabulous widgets use L</bordered> instead.

=head2 border_style_top

	$box->border_style_top( Term::Fabulous::Enum::BorderStyle->Heavy );

Accessor for the style of the top side. The writer takes C<undef>
(no style of its own), a L<Term::Fabulous::Enum::BorderStyle> item or
its name, returns the new value, and anything else dies. The reader
returns the style the side is drawn in: its own, else the theme's (or
one the widget derives), else C<Blank>; see
L<Term::Fabulous::Role::HasBorderStyle/border_style_of>. The change
shows in the next frame.
There is no C<border_style> accessor; set the sides one by one. See
L<Term::Fabulous::Role::HasBorderStyle>.

=head2 border_style_right

	$box->border_style_right( Term::Fabulous::Enum::BorderStyle->Heavy );

Accessor for the style of the right side. The writer takes C<undef>
(no style of its own), a L<Term::Fabulous::Enum::BorderStyle> item or
its name, returns the new value, and anything else dies. The reader
returns the style the side is drawn in: its own, else the theme's (or
one the widget derives), else C<Blank>; see
L<Term::Fabulous::Role::HasBorderStyle/border_style_of>. The change
shows in the next frame.
There is no C<border_style> accessor; set the sides one by one. See
L<Term::Fabulous::Role::HasBorderStyle>.

=head2 border_style_bottom

	$box->border_style_bottom( Term::Fabulous::Enum::BorderStyle->Heavy );

Accessor for the style of the bottom side. The writer takes C<undef>
(no style of its own), a L<Term::Fabulous::Enum::BorderStyle> item or
its name, returns the new value, and anything else dies. The reader
returns the style the side is drawn in: its own, else the theme's (or
one the widget derives), else C<Blank>; see
L<Term::Fabulous::Role::HasBorderStyle/border_style_of>. The change
shows in the next frame.
There is no C<border_style> accessor; set the sides one by one. See
L<Term::Fabulous::Role::HasBorderStyle>.

=head2 border_style_left

	$box->border_style_left( Term::Fabulous::Enum::BorderStyle->Heavy );

Accessor for the style of the left side. The writer takes C<undef>
(no style of its own), a L<Term::Fabulous::Enum::BorderStyle> item or
its name, returns the new value, and anything else dies. The reader
returns the style the side is drawn in: its own, else the theme's (or
one the widget derives), else C<Blank>; see
L<Term::Fabulous::Role::HasBorderStyle/border_style_of>. The change
shows in the next frame.
There is no C<border_style> accessor; set the sides one by one. See
L<Term::Fabulous::Role::HasBorderStyle>.

=head2 border_corners

	$box->border_corners( { top_left => "\x{251C}" } );

Accessor for the corner glyphs; the reader returns a new hash reference
or C<undef>. See L<Term::Fabulous::Role::HasBorderStyle/border_corners>.

=head2 outer_border_sides

	$box->outer_border_sides( [ 'left', 'right' ] );

Accessor for the sides drawn outside the widget; the reader returns a
new array reference. See
L<Term::Fabulous::Role::HasBorderStyle/outer_border_sides>.

=head2 width_group

	$label->width_group(1);

Accessor. Without an argument it returns the group number (0 when the
widget is in no group); with an argument it sets it and returns the new
value. An invalid value dies like the constructor parameter. The change
shows in the next frame.

=head2 height_group

	$row->height_group(2);

Accessor for the height group, used like L</width_group>.

=head2 add_state

	$row->add_state('selected');

Adds a state name of your own. Returns the widget. Dies for the
derived states C<hovered>, C<pressed>, C<focused> and C<disabled>.

=head2 remove_state

	$row->remove_state('selected');

Removes a state name of your own. Returns the widget. Dies for the
derived states C<hovered>, C<pressed>, C<focused> and C<disabled>.

=head2 toggle_state

	$row->toggle_state('selected');

Adds the name when it is missing, removes it otherwise. Returns the
widget. Dies for the derived states C<hovered>, C<pressed>, C<focused>
and C<disabled>.

=head2 clear_states

	$row->clear_states;

Removes all state names of your own. The derived states
(C<hovered>, C<pressed>, C<focused>, C<disabled>) are not affected. Returns the
widget.

=head2 has_state

	if ( $row->has_state('selected') ) { ... }

True when the state is active, including the derived ones.

=head2 states

	my @active = $row->states;

The active state names, in no particular order.

=head2 classes

	my $names = $widget->classes;    # ['sidebar']
	$widget->classes( [ 'sidebar', 'primary' ] );

Accessor for the C<classes> parameter. Without an argument it returns
a copy of the names; with an array reference it replaces them, makes
the widget read its theme looks again and returns a copy of the new
names. An invalid value dies like the constructor parameter. The
change shows in the next frame.

=head2 get_classes

	my @classes = $widget->get_classes;    # ('sidebar', 'state_focused')

The names from the C<classes> parameter, followed by C<state_NAME> for
every active state (C<state_hovered>, C<state_selected>, ...). The
theme reads the classes only, not the state names.

=head2 reset_look

	$button->reset_look('border_color');
	$button->reset_look( 'background_color', 'focus_border_color' );

Drops the colors, border styles or borders the program gave for the
named parameters, so the theme supplies them again. Takes the names of
the widget's themed parameters (C<background_color>, C<border_color>,
C<bordered> and the ones a subclass lists), including the looks a widget
keeps on its parts (the colors of a L<Term::Fabulous::Widget::Tabs> live
on its bar, the scrollbar colors of a
L<Term::Fabulous::Widget::ScrollBox> on both scrollbars); an unknown
name dies naming the known ones. Returns the widget. The change shows in
the next frame. From L<Term::Fabulous::Role::Themed>, which also has
L<look|Term::Fabulous::Role::Themed/look> and
L<look_value|Term::Fabulous::Role::Themed/look_value> for widget
authors.

=head2 mark_changed

	$widget->mark_changed;

For widget authors: tells Term::Fabulous that the widget has changed in
a way its accessors do not know about (state of your own that the
widget draws), so that the next frame is drawn. The built-in accessors
call it themselves. Returns the widget. See
L<Clay::UI::Role::Core::Element/mark_changed> and
L<Term::Fabulous::Manual::CustomWidgets>.

=head2 tree_changed

	class My::Counter :isa(Term::Fabulous::Widget::Box) {
		field $clicks = 0;

		method tree_changed :override () {
			$self->SUPER::tree_changed;
			$clicks = 0;    # counts again from its new place
			return;
		}
	}

For widget authors: Clay::UI calls it on every widget of a subtree
that joined a tree, left one or became the root of a UI, once the
change is complete (see
L<Clay::UI::Role::Layout::HasParent/tree_changed>). Here the widget
forgets the looks it fetched, since its new place may be in a UI with
another theme, and when that place is in a UI, calls
L<looks_changed|Term::Fabulous::Role::Themed/looks_changed> with all
its looks. An override calls C<< $self->SUPER::tree_changed >> first,
as L<Term::Fabulous::Widget::VirtualList> does to rebuild its items for
the new place.

=head2 reverse_video

	my $swapped = $widget->reverse_video;    # 0

For widget authors: whether the renderer swaps the foreground and
background colors of every cell the widget and its children paint.
Always 0 here; L<Term::Fabulous::Widget::Button> returns 1 while it is
pressed with C<< pressed_background_color => 'reverse' >>. Override it in
a widget class of your own for the same effect.

=head1 EVENTS

The class fires no events of its own. Every widget receives the events
fired on its descendants, because events bubble up the tree (see
L</on>), and L<Term::Fabulous> fires these on any widget:

=over

=item C<Mouse> (L<Term::Fabulous::Event::Mouse>)

On the topmost widget painted under the pointer, for clicks and wheel
notches. A widget paints its whole area when it has a background color
and only its border cells when it has a border but no background; a
widget with neither is transparent to the mouse.

=item C<KeyPress> (L<Term::Fabulous::Event::KeyPress>)

On the root widget when no widget has the focus.

=back

Subclasses add their own events, such as C<Activate> on a
L<Term::Fabulous::Widget::Button> and C<OnScroll> on a
L<Term::Fabulous::Widget::ScrollBox>.
L<The event reference of the events guide|Term::Fabulous::Manual::Events/Event reference>
lists them all.

=head1 SEE ALSO

L<Term::Fabulous::Widget::Box>,
L<Term::Fabulous::Manual::Layout/LAYOUT> (the layout options with
pictures), L<Term::Fabulous::Manual::Events/EVENTS>,
L<Term::Fabulous::Role::HasBorderStyle>, L<Clay::UI>,
L<Term::Fabulous::Cookbook::Layout/Line up labels with equal widths (width_group)>,
L<Term::Fabulous::Cookbook::Layout/Use a different border style on each side>,
L<Term::Fabulous::Cookbook::Layout/Mark widgets with states and classes>.

=cut
