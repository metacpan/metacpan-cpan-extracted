package Term::Fabulous::Widget::Accordion;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Accordion::Item;

our $VERSION = '0.02';

class Term::Fabulous::Widget::Accordion
	:isa(Term::Fabulous::Widget::Box)
	:strict(params)
{
	use Clay::UI::Enum::Result;
	use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);
	use List::Util qw(first);
	use Scalar::Util qw(blessed refaddr weaken);
	use Term::Fabulous::Check qw(boolean describe non_negative_integer one_of string);
	use Term::Fabulous::Roving qw(roving_target);
	use Term::Fabulous::Event::Select;

	use constant ITEM_CLASS => 'Term::Fabulous::Widget::Accordion::Item';

	my @TOGGLE_POSITIONS = qw(start end);

	field $multiple        :param = 0;
	field $item_borders    :param = 0;
	field $toggle_position :param = 'start';
	field $open_glyph      :param = "\x{25BE}";
	field $closed_glyph    :param = "\x{25B8}";
	field $title_bold      :param = 0;
	field $body_indent     :param = 2;

	ADJUST {
		$multiple        = boolean( $self, multiple     => $multiple );
		$item_borders    = boolean( $self, item_borders => $item_borders );
		$toggle_position = one_of( $self, toggle_position => $toggle_position, @TOGGLE_POSITIONS );
		$open_glyph      = string( $self, open_glyph   => $open_glyph );
		$closed_glyph    = string( $self, closed_glyph => $closed_glyph );
		$title_bold      = boolean( $self, title_bold => $title_bold );
		$body_indent     = non_negative_integer( $self, body_indent => $body_indent );

		my $layout = $self->layout;
		$self->layout( { %$layout, layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), %{ $layout->{sizing} // {} } } } );

		weaken( my $weak_self = $self );
		$self->on( KeyPress => sub ($event) { return $weak_self && $weak_self->_handle_key($event) ? Clay::UI::Enum::Result->HANDLED : Clay::UI::Enum::Result->CONTINUE } );
	}

	# ---------------------------------------------------------------------
	# Items
	# ---------------------------------------------------------------------

	method add_child :override (@kids) {
		foreach my $kid (@kids) {
			die ref($self) . ": an accordion holds only Term::Fabulous::Widget::Accordion::Item widgets, got " . ( blessed $kid ? ref $kid : describe($kid) )
				unless blessed $kid && $kid->isa(ITEM_CLASS);
		}
		$self->SUPER::add_child(@kids);
		foreach my $kid (@kids) {
			$self->_style_item($kid);
			$self->_close_others($kid) if $kid->is_open && !$multiple;
		}
		return $self;
	}

	method items () {
		return @{ $self->children };
	}

	method item ($index) {
		my @items = $self->items;
		die ref($self) . ": item needs an index in 0.." . $#items . ", got " . describe($index) unless defined $index && !ref $index && $index =~ /\A[0-9]+\z/ && $index < @items;
		return $items[$index];
	}

	# An item or its index: the item.
	method _item_of ($which) {
		return $self->item($which) unless blessed $which;
		die ref($self) . ": not an item of this accordion" unless first { refaddr($_) == refaddr($which) } $self->items;
		return $which;
	}

	method index_of ($item) {
		my @items = $self->items;
		return first { refaddr( $items[$_] ) == refaddr($item) } 0 .. $#items;
	}

	method open_items () {
		return grep { $_->is_open } $self->items;
	}

	# The open item of an accordion that allows one; the first open one
	# otherwise.
	method selected () {
		my @open = $self->open_items;
		return $open[0];
	}

	method _close_others ($kept) {
		$_->open(0) foreach grep { refaddr($_) != refaddr($kept) } $self->open_items;
		return;
	}

	# Opens an item from the program: closes the others unless multiple
	# are allowed. Fires nothing.
	method open ($which) {
		my $item = $self->_item_of($which);
		$self->_close_others($item) unless $multiple;
		$item->open(1);
		return $self;
	}

	method close ($which) {
		$self->_item_of($which)->open(0);
		return $self;
	}

	method open_all () {
		die ref($self) . ": open_all needs multiple => 1" unless $multiple;
		$_->open(1) foreach $self->items;
		return $self;
	}

	method close_all () {
		$_->open(0) foreach $self->items;
		return $self;
	}

	# Toggles an item as the user does: fires Select. A disabled item
	# changes nothing.
	method choose ($which) {
		my $item = $self->_item_of($which);
		return $self unless $item->is_enabled;
		$self->_item_activated($item);
		return $self;
	}

	method _item_activated ($item) {
		my $opens = !$item->is_open;
		$self->_close_others($item) if $opens && !$multiple;
		$item->open($opens);
		$self->fire_event( Term::Fabulous::Event::Select->new( item => $item, index => $self->index_of($item), open => $opens ) );
		return;
	}

	# ---------------------------------------------------------------------
	# Look
	# ---------------------------------------------------------------------

	# With item_borders, an item takes the theme's accordion border;
	# without, it has none.
	method _style_item ($item) {
		if ($item_borders) {
			my $style = $self->look('border.style');
			$item->bordered(1);
			$item->$_($style) foreach qw(border_style_top border_style_right border_style_bottom border_style_left);
			$item->border_color( $self->look('border.color') );
		}
		else {
			$item->bordered(0);
		}
		$item->refresh_look;
		return;
	}

	method theme_family :common () {
		return 'accordion';
	}

	method themed_params :common () {
		return (
			$class->SUPER::themed_params,
			title_color             => [ 'title',             'normal',  'color' ],
			accent_color            => [ 'accent',            'normal',  'color' ],
			header_background_color => [ 'header.background', 'normal',  'optional_color' ],
			focus_background_color  => [ 'header.background', 'focused', 'color' ],
			hover_background_color  => [ 'header.background', 'hovered', 'color' ],
			disabled_color          => [ 'disabled',          'normal',  'color' ],
		);
	}

	# The items copy the looks (Term::Fabulous::Role::Themed).
	method looks_changed (@names) {
		$self->_restyle;
		return;
	}

	method _restyle () {
		$self->_style_item($_) foreach $self->items;
		$self->mark_changed;
		return;
	}

	method _set ( $field_ref, $value ) {
		$$field_ref = $value;
		$self->_restyle;
		return $$field_ref;
	}

	method multiple (@new) {
		return $multiple unless @new;
		$multiple = boolean( $self, multiple => $new[0] );
		$self->_close_others( $self->selected ) if !$multiple && defined $self->selected;
		return $multiple;
	}

	method item_borders    (@new) { return @new ? $self->_set( \$item_borders, boolean( $self, item_borders => $new[0] ) )                         : $item_borders }
	method toggle_position (@new) { return @new ? $self->_set( \$toggle_position, one_of( $self, toggle_position => $new[0], @TOGGLE_POSITIONS ) ) : $toggle_position }
	method open_glyph      (@new) { return @new ? $self->_set( \$open_glyph, string( $self, open_glyph => $new[0] ) )                              : $open_glyph }
	method closed_glyph    (@new) { return @new ? $self->_set( \$closed_glyph, string( $self, closed_glyph => $new[0] ) )                          : $closed_glyph }
	method title_bold      (@new) { return @new ? $self->_set( \$title_bold, boolean( $self, title_bold => $new[0] ) )                             : $title_bold }
	method body_indent     (@new) { return @new ? $self->_set( \$body_indent, non_negative_integer( $self, body_indent => $new[0] ) )              : $body_indent }
	method title_color     (@new) { return @new ? $self->set_look( title_color => $new[0] )                                                        : $self->look_value('title_color') }
	method accent_color    (@new) { return @new ? $self->set_look( accent_color => $new[0] )                                                       : $self->look_value('accent_color') }

	method header_background_color (@new) {
		return @new ? $self->set_look( header_background_color => $new[0] ) : $self->look_value('header_background_color');
	}
	method focus_background_color (@new) { return @new ? $self->set_look( focus_background_color => $new[0] ) : $self->look_value('focus_background_color') }
	method hover_background_color (@new) { return @new ? $self->set_look( hover_background_color => $new[0] ) : $self->look_value('hover_background_color') }
	method disabled_color         (@new) { return @new ? $self->set_look( disabled_color         => $new[0] ) : $self->look_value('disabled_color') }

	method layout_properties :common () {
		return (
			$class->SUPER::layout_properties,
			( map { $_ => 'boolean' } qw(multiple item_borders title_bold) ),
			( map { $_ => 'scalar' } qw(toggle_position open_glyph closed_glyph body_indent) ),
		);
	}

	# ---------------------------------------------------------------------
	# Keys: Up, Down, Home and End move the focus between the headers.
	# ---------------------------------------------------------------------

	method _handle_key ($event) {
		my @items   = $self->items;
		my @enabled = grep { $items[$_]->is_enabled } 0 .. $#items;
		my $focused = first { $items[$_]->is_focused } @enabled;
		return 0 unless defined $focused;
		my $target = roving_target( \@enabled, $focused, $event->main_key_name, keys => 'vertical' ) // return 0;
		$items[$target]->focus;
		return 1;
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Widget::Accordion - Sections that open and close under
their headers

=head1 SYNOPSIS

	use Term::Fabulous::Widget::Accordion;
	use Term::Fabulous::Widget::Accordion::Item;
	use Term::Fabulous::Widget::Text;

	my $settings = Term::Fabulous::Widget::Accordion->new( id => 'settings' );
	foreach my $section ( [ General => 'Language, time zone' ], [ Network => 'Hostname, ports' ], [ Users => 'Accounts and groups' ] ) {
		my $item = Term::Fabulous::Widget::Accordion::Item->new( title => $section->[0] );
		$item->add_child( Term::Fabulous::Widget::Text->new( text => $section->[1], text_color => '#c8cdd7' ) );
		$settings->add_child($item);
	}
	$settings->open(0);    # the first item

	$settings->on( Select => sub ($event) {
		$status->text( ( $event->open ? 'Opened ' : 'Closed ' ) . $event->item->title );
		return;
	} );

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.02/screenshots/widget-accordion.svg" alt="Two accordions: one with the Network section open under General and a disabled Licenses section, one with borders, the toggles at the end and two sections open at once"></p>

=end html

=head1 DESCRIPTION

The picture shows two accordions: one with its second section open and
its last section disabled, and one with a border around every item and
the toggles at the end of the headers and two sections open at once. The
program is F<examples/widgets/accordion.pl>.

An accordion stacks sections, its I<items>, each with a header line
and a body that shows while the item is open:

=for highlighter language=text

	▸ General
	▾ Network
	    Hostname  example.org
	    Port      443
	▸ Users

One item is open at a time: opening another closes it, and the open
item can be closed, so that all are closed. With
C<< multiple => 1 >>, any number of items can be open. The user opens
and closes an item with a click on its header, or with C<Enter> or
C<Space> while the header has the focus; C<Tab> moves the focus from
header to header and through the widgets of the open bodies, and
C<Up>, C<Down>, C<Home> and C<End> on a header move it to the other
headers. An item can be disabled, and the accordion fires
L<Term::Fabulous::Event::Select> for every change the user makes.

Each item is a L<Term::Fabulous::Widget::Accordion::Item>: its header
holds a toggle glyph, an optional icon and the title; its body holds
the widgets you add to the item and is part of the widget tree only
while the item is open, so a closed body takes no space. The look of
the headers (the glyphs, their colors, where the toggle sits, borders
around the items) is set once, on the accordion. By default the
toggle sits at the start of the header, as in a tree; C<item_borders> and
C<< toggle_position => 'end' >> give the look of a web page's
accordion.

An accordion is a L<Term::Fabulous::Widget::Box> laid out top to
bottom whose width grows unless the C<layout> says otherwise; its
children are its items, and C<add_child> accepts nothing else.

=head1 CONSTRUCTOR

=head2 new

=for highlighter language=perl

	my $accordion = Term::Fabulous::Widget::Accordion->new(%parameters);

Accepts the parameters of L<Term::Fabulous::Widget::Box/CONSTRUCTOR>
(C<id>, C<layout>, C<background_color>, the border parameters, ...)
and the ones below. All are optional; unknown parameters die.

=over

=item C<multiple>

A boolean. Default: 0, one open item at a time. True lets any number
of items be open. Stored as 1 or 0; a reference dies.

=item C<item_borders>

A boolean. Default: 0. True draws a border around every item, in the
theme's C<accordion.border.style> and C<accordion.border.color>: a
C<Round> border in the C<disabled> token's gray in the built-in
themes. Stored as 1 or 0. Not to be confused with C<bordered>, which
frames the whole accordion, as it frames any box (see
L<Term::Fabulous::Widget/bordered>).

=item C<toggle_position>

C<start> (the default) or C<end>: whether the toggle glyph sits before
the title or at the right end of the header. Anything else dies.

=item C<open_glyph>

=item C<closed_glyph>

Character strings. Default: C<"\x{25BE}"> (a small down triangle) and
C<"\x{25B8}"> (a small right triangle). The toggle of an open and of a
closed item; C<'-'> and C<'+'> give a plus toggle.

=item C<title_color>

The color of the titles, in any format L<Term::Fabulous::Color>
accepts. Default: the theme's C<accordion.title>,
C<[220, 223, 228, 255]> in the dark theme.

=item C<title_bold>

A boolean. Default: 0. Whether the titles are bold.

=item C<accent_color>

The color of an open item's toggle. Default: the theme's
C<accordion.accent>, C<[97, 175, 239, 255]> in the dark theme, a blue.

=item C<header_background_color>

The background of the headers, or C<undef> for none. Default: the
theme's C<accordion.header.background>, none in the built-in themes.

=item C<focus_background_color>

The background of the header that has the focus. Default: the theme's
C<accordion.header.background> in the C<focused> state,
C<[52, 58, 72, 255]> in the dark theme.

=item C<hover_background_color>

The background of the header under the pointer. Default: the theme's
C<accordion.header.background> in the C<hovered> state,
C<[40, 45, 58, 255]> in the dark theme.

=item C<disabled_color>

The color of a disabled item's header. Default: the theme's
C<accordion.disabled>, C<[108, 112, 120, 255]> in the dark theme, a
gray. The borders of the items (C<item_borders>) take the theme's
C<accordion.border.color> and C<accordion.border.style>; the six
colors return to the theme with L<Term::Fabulous::Widget/reset_look>.

=item C<body_indent>

A non-negative integer. Default: 2. The columns the bodies are
indented by.

=back

=head1 METHODS

The methods of L<Term::Fabulous::Widget>, plus:

=head2 add_child

	$accordion->add_child( $item, $other_item );

Appends items. Dies for anything but a
L<Term::Fabulous::Widget::Accordion::Item>. When the accordion allows
one open item and an added item is open, the items open before it are
closed. Returns the accordion.

=head2 items

	my @items = $accordion->items;

The items, in order.

=head2 item

	my $item = $accordion->item(2);

The item at an index, from 0. Dies for an index outside the items.

=head2 index_of

	my $index = $accordion->index_of($item);

The index of an item, or C<undef>.

=head2 open_items

	my @open = $accordion->open_items;

The open items, in order.

=head2 selected

	my $item = $accordion->selected;    # or undef

The open item, or the first open one with C<multiple>; C<undef> when
all are closed.

=head2 open

	$accordion->open(1);        # by index
	$accordion->open($item);    # or the item

Opens an item from the program, closing the others unless C<multiple>
allows them. Fires nothing. Dies for an index outside the items or an
item of another accordion. Returns the accordion.

=head2 close

	$accordion->close($item);

Closes an item. Fires nothing. Returns the accordion.

=head2 open_all

	$accordion->open_all;

Opens every item. Dies unless C<multiple> is set. Returns the accordion.

=head2 close_all

	$accordion->close_all;

Closes every item. Returns the accordion.

=head2 choose

	$accordion->choose($index);

Toggles an item as the user does: opens a closed item (closing the
others unless C<multiple>), closes an open one, and fires C<Select>. A
disabled item changes nothing. Returns the accordion.

=head2 multiple

	$accordion->multiple(1);

Accessor for the C<multiple> parameter. Writing 0 while several items
are open closes all but the first. Returns 1 or 0.

=head2 item_borders

	$accordion->item_borders(1);

Accessor for the C<item_borders> parameter. Returns 1 or 0.

=head2 toggle_position

	$accordion->toggle_position('end');

Accessor for the C<toggle_position> parameter: C<start> or C<end>.

=head2 open_glyph

	$accordion->open_glyph('-');

Accessor for the C<open_glyph> parameter.

=head2 closed_glyph

	$accordion->closed_glyph('+');

Accessor for the C<closed_glyph> parameter.

=head2 title_color

	$accordion->title_color('#ffffff');

Accessor for the C<title_color> parameter. The reader returns
C<[r, g, b, a]>. An invalid color dies and leaves the old one.

=head2 title_bold

	$accordion->title_bold(1);

Accessor for the C<title_bold> parameter. Returns 1 or 0.

=head2 accent_color

	$accordion->accent_color('#98c379');

Accessor for the C<accent_color> parameter; works like L</title_color>.

=head2 header_background_color

	$accordion->header_background_color( [ 28, 33, 45 ] );
	$accordion->header_background_color(undef);

Accessor for the C<header_background_color> parameter; C<undef>
removes the background.

=head2 focus_background_color

	$accordion->focus_background_color('#343a48');

Accessor for the C<focus_background_color> parameter; works like
L</title_color>.

=head2 hover_background_color

	$accordion->hover_background_color('#282d3a');

Accessor for the C<hover_background_color> parameter; works like
L</title_color>.

=head2 disabled_color

	$accordion->disabled_color('#6c7078');

Accessor for the C<disabled_color> parameter; works like
L</title_color>.

=head2 body_indent

	$accordion->body_indent(4);

Accessor for the C<body_indent> parameter.

Every writer restyles the items, so the next frame shows the new look.

=head1 KEYS

While the header of an item has the focus:

=over

=item C<Enter>, C<Space>

Open or close the item (the header is a
L<Term::Fabulous::Widget::Button>).

=item C<Up>, C<Down>

Move the focus to the previous or the next enabled header, wrapping
around.

=item C<Home>, C<End>

Move the focus to the first or the last enabled header.

=back

C<Tab> and C<Shift+Tab> move through the headers and the widgets of
the open bodies in order, as everywhere. All other keys bubble to the
ancestors.

=head1 MOUSE

A click on a header opens or closes its item and focuses the header.
The header under the pointer is painted on C<hover_background_color>.

=head1 EVENTS

=over

=item C<Select>

L<Term::Fabulous::Event::Select> when the user opens or closes an
item (or L</choose> is called); C<< $event->item >> is the item,
C<< $event->index >> its position and C<< $event->open >> 1 or 0.
Only the item the user acted on fires, not the one that closes to
make room for it. Programmatic changes fire nothing.

=back

The C<Activate> of the headers and the events of the widgets in the
bodies bubble through the accordion as well.

=head1 KDL PROPERTIES

The properties of L<Term::Fabulous::Widget::Box/KDL PROPERTIES>, plus
C<multiple>, C<item_borders> and C<title_bold> (C<#true> / C<#false>),
C<toggle_position>, C<open_glyph>, C<closed_glyph> and C<body_indent>
(strings and numbers), and the colors C<title_color>, C<accent_color>,
C<header_background_color>, C<focus_background_color>,
C<hover_background_color> and C<disabled_color>. The items are C<Item>
child nodes (see L<Term::Fabulous::Widget::Accordion::Item/KDL PROPERTIES>):

=for highlighter language=kdl

	use Term::Fabulous::Widget::Accordion as Accordion
	use Term::Fabulous::Widget::Accordion::Item as Item
	use Term::Fabulous::Widget::Text as Text

	Accordion "settings" {
		item_borders #true
		toggle_position "end"
		Item "general" {
			title "General"
			open #true
			Text { text "Language, time zone"; }
		}
		Item "network" {
			title "Network"
			Text { text "Hostname, ports"; }
		}
	}

=head1 EXAMPLES

=head2 A plus toggle

=for highlighter language=perl

	my $faq = Term::Fabulous::Widget::Accordion->new( open_glyph => '-', closed_glyph => '+', title_bold => 1 );

=head2 Remember the open section

	$settings->on( Select => sub ($event) {
		$config->{section} = $event->open ? $event->item->id : undef;
		return;
	} );

=head1 SEE ALSO

L<Term::Fabulous::Widget::Accordion::Item>, L<Term::Fabulous::Event::Select>,
L<Term::Fabulous::Widget::Button>,
L<Term::Fabulous::Manual::Layout/ACCORDIONS>.

=cut
