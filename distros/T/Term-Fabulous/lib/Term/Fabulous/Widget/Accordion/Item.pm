package Term::Fabulous::Widget::Accordion::Item;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Button;
use Term::Fabulous::Widget::Text;

our $VERSION = '0.02';

class Term::Fabulous::Widget::Accordion::Item
	:isa(Term::Fabulous::Widget::Box)
	:strict(params)
{
	use Clay::UI::Enum::Result;
	use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);
	use Scalar::Util qw(blessed weaken);
	use Term::Fabulous::Check qw(boolean optional string);
	use Term::Fabulous::Theme;

	# The settings an item shows while it has no accordion to take them
	# from; the colors come from the default theme's accordion family.
	my %DEFAULT_LOOK = (
		toggle_position => 'start',
		open_glyph      => "\x{25BE}",
		closed_glyph    => "\x{25B8}",
		title_bold      => 0,
		body_indent     => 2,
	);

	field $title :param = '';
	field $icon  :param = undef;

	# The header the user acts on, the body that holds the children, and
	# the texts of the header, which the look updates.
	field $_header;
	field $_body;
	field $_toggle_text;
	field $_icon_text;
	field $_title_text;
	field $_is_open = 0;
	field $_built   = 0;

	ADJUST :params ( :$open = 0, :$disabled = 0 ) {
		$title = string( $self, title => $title );
		$icon  = optional( \&string, $self, icon => $icon );
		$self->layout( { %{ $self->layout }, layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), %{ $self->layout->{sizing} // {} } } } );

		weaken( my $weak_self = $self );
		my $continue = Clay::UI::Enum::Result->CONTINUE;
		$_header = Term::Fabulous::Widget::Button->new( layout => { sizing => { width => sizing_grow() }, child_gap => 1 }, pressed_background_color => undef );
		$_header->on( Activate => sub ($event) { $weak_self->_activated if $weak_self;   return } );
		$_header->on( $_       => sub ($event) { $weak_self->refresh_look if $weak_self; return $continue } ) foreach qw(OnFocus OnBlur OnHoverStart OnHoverStopped);
		$_body        = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow() } } );
		$_toggle_text = Term::Fabulous::Widget::Text->new( text => '' );
		$_icon_text   = Term::Fabulous::Widget::Text->new( text => $icon // '' );
		$_title_text  = Term::Fabulous::Widget::Text->new( text => $title );

		$self->SUPER::add_child($_header);
		$_built = 1;
		$_header->disabled( boolean( $self, disabled => $disabled ) );
		$self->open( boolean( $self, open => $open ) );
		$self->refresh_look;
	}

	# The accordion the item belongs to, if any.
	method accordion () {
		my $parent = $self->parent;
		return blessed $parent && $parent->isa('Term::Fabulous::Widget::Accordion') ? $parent : undef;
	}

	# ---------------------------------------------------------------------
	# The parts
	# ---------------------------------------------------------------------

	method header () { return $_header }
	method body ()   { return $_body }

	# The item's children live in its body; the header is its own.
	method add_child :override (@kids) {
		return $self->SUPER::add_child(@kids) unless $_built;
		$_body->add_child(@kids);
		return $self;
	}

	method remove_child :override (@kids) {
		$_body->remove_child(@kids);
		return $self;
	}

	method remove_child_with_id :override ($target_id) {
		$_body->remove_child_with_id($target_id);
		return $self;
	}

	method remove_children_with :override ($predicate) {
		$_body->remove_children_with($predicate);
		return $self;
	}

	method clear_children :override () {
		$_body->clear_children;
		return $self;
	}

	# ---------------------------------------------------------------------
	# State
	# ---------------------------------------------------------------------

	method is_open () {
		return $_is_open;
	}

	# Opens or closes the item: the body is part of the tree only while
	# the item is open. Fires nothing.
	method open (@new) {
		return $_is_open unless @new;
		my $wanted = boolean( $self, open => $new[0] );
		return $_is_open if $wanted == $_is_open;
		$_is_open = $wanted;
		if ($wanted) {
			$self->SUPER::add_child($_body);
		}
		else {
			$self->SUPER::remove_child($_body);
		}
		$self->refresh_look;
		return $_is_open;
	}

	method disabled (@new) {
		return $_header->disabled unless @new;
		$_header->disabled( $new[0] );
		$self->refresh_look;
		return $_header->disabled;
	}

	method is_enabled () {
		return $_header->is_enabled;
	}

	method title (@new) {
		return $title unless @new;
		$title = string( $self, title => $new[0] );
		$_title_text->text($title);
		return $title;
	}

	method icon (@new) {
		return $icon unless @new;
		$icon = optional( \&string, $self, icon => $new[0] );
		$_icon_text->text( $icon // '' );
		$self->refresh_look;
		return $icon;
	}

	method focus () {
		my $ui = $self->ui // die ref($self) . ": the item is not part of a Term::Fabulous, so nothing can focus it";
		$ui->interaction->set_focused_widget($_header);
		return $self;
	}

	method is_focused () {
		return $_header->is_focused;
	}

	method layout_properties :common () {
		return ( $class->SUPER::layout_properties, title => 'scalar', icon => 'scalar', open => 'boolean', disabled => 'boolean' );
	}

	# The user toggled the item: the accordion decides what happens to the
	# others and fires Select; an item on its own just toggles. A header
	# without a background paints no cells of its own, so a click on its
	# text would not focus it by itself.
	method _activated () {
		my $ui = $self->ui;
		$ui->interaction->set_focused_widget($_header) if defined $ui && $ui->interaction->can_take_focus($_header) && !$_header->is_focused;
		my $accordion = $self->accordion;
		return $accordion->_item_activated($self) if defined $accordion;
		$self->open( !$_is_open );
		return;
	}

	# ---------------------------------------------------------------------
	# Look
	# ---------------------------------------------------------------------

	# One setting of the look: the accordion's; without one, the default
	# setting, or the default theme's accordion look.
	method _look ($name) {
		my $accordion = $self->accordion;
		return $accordion->$name if defined $accordion;
		return $DEFAULT_LOOK{$name} if exists $DEFAULT_LOOK{$name};
		require Term::Fabulous::Widget::Accordion;
		my %themed = Term::Fabulous::Widget::Accordion->themed_params;
		return Term::Fabulous::Theme->default->look( 'accordion', @{ $themed{$name} }[ 0, 1 ] );    # slot and state
	}

	# Updates the header's texts, order and colors from the state and the
	# accordion's settings. Called by the accordion when they change.
	method refresh_look () {
		my $enabled = $_header->is_enabled;
		my $at_end  = $self->_look('toggle_position') eq 'end';

		$_toggle_text->text( $_is_open      ? $self->_look('open_glyph')                                                 : $self->_look('closed_glyph') );
		$_toggle_text->text_color( $enabled ? ( $_is_open ? $self->_look('accent_color') : $self->_look('title_color') ) : $self->_look('disabled_color') );
		$_title_text->text_color( $self->_look('title_color') );
		$_title_text->bold( $self->_look('title_bold') );
		$_icon_text->text_color( $self->_look('title_color') );
		$_header->disabled_color( $self->_look('disabled_color') );

		my @parts = ( ( defined $icon ? $_icon_text : () ), $_title_text );
		my @order = $at_end ? ( @parts, Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow() } } ), $_toggle_text ) : ( $_toggle_text, @parts );
		$_header->clear_children;
		$_header->add_child(@order);

		my $background
			= !$enabled            ? $self->_look('header_background_color')
			: $_header->is_focused ? $self->_look('focus_background_color')
			: $_header->is_hovered ? $self->_look('hover_background_color')
			:                        $self->_look('header_background_color');
		$_header->background_color($background);

		my $indent = $self->_look('body_indent');
		$_body->layout( { %{ $_body->layout }, padding => { %{ $_body->layout->{padding} // {} }, left => $indent } } );
		return $self;
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Widget::Accordion::Item - One section of an accordion

=head1 SYNOPSIS

	use Term::Fabulous::Widget::Accordion;
	use Term::Fabulous::Widget::Accordion::Item;

	my $network = Term::Fabulous::Widget::Accordion::Item->new( title => 'Network', open => 1 );
	$network->add_child( $hostname_row, $port_row );    # the body
	$accordion->add_child($network);

	$network->open(0);           # close it from the program; fires nothing
	say $network->is_open;       # 0
	$network->disabled(1);       # the user cannot open it

=head1 DESCRIPTION

An item is one section of a L<Term::Fabulous::Widget::Accordion>: a
header line with a toggle glyph, an optional icon and a title, and a
body of any widgets below it that is shown while the item is open.
The header is a L<Term::Fabulous::Widget::Button>, so it takes the
focus, reacts to C<Enter>, C<Space> and clicks, and can be disabled;
the look of all headers (glyphs, colors, where the toggle sits) comes
from the accordion, see
L<Term::Fabulous::Widget::Accordion/CONSTRUCTOR>.

The children you add to an item go into its body, which is part of
the widget tree only while the item is open: a closed body takes no
space, and the widgets inside it cannot take the focus. The body is a
box laid out top to bottom, indented by the accordion's
C<body_indent>.

An item can also be used on its own, outside an accordion: it then
toggles itself and shows the default look.

=head1 CONSTRUCTOR

=head2 new

	my $item = Term::Fabulous::Widget::Accordion::Item->new(%parameters);

Accepts the parameters of L<Term::Fabulous::Widget::Box/CONSTRUCTOR>
(C<id>, C<layout>, C<background_color>, the border parameters, ...),
of which C<layout_direction> is always top to bottom and the width
grows unless the C<layout> says otherwise, and the ones below. Unknown
parameters die.

=over

=item C<title>

A character string. Default: C<''>. The text of the header.

=item C<icon>

A character string, or C<undef>. Default: C<undef>. A short text, for
example a symbol, shown before the title.

=item C<open>

A boolean. Default: 0. Whether the item starts open. In an accordion
that allows one open item, the last open item added wins.

=item C<disabled>

A boolean. Default: 0. A disabled item cannot be opened or closed by
the user, is skipped by Tab and drawn in the accordion's
C<disabled_color>; its body stays as it is.

=back

=head1 METHODS

The methods of L<Term::Fabulous::Widget>, of which C<add_child>,
C<remove_child>, C<remove_child_with_id>, C<remove_children_with> and
C<clear_children> act on the body (C<children> and C<has_child> see the
header and, while open, the body), plus:

=head2 open

	my $is_open = $item->open;
	$item->open(1);

Accessor. Writing opens or closes the item without an event and
without regard to the accordion's C<multiple>; the accordion's
L<Term::Fabulous::Widget::Accordion/open> keeps that rule. Returns 1 or
0.

=head2 is_open

	if ( $item->is_open ) { ... }

The same as reading L</open>.

=head2 disabled

	$item->disabled(1);

Accessor for the header's C<disabled> flag. Returns 1 or 0.

=head2 is_enabled

The opposite of L</disabled>.

=head2 title

	$item->title('Advanced');

Accessor for the title; the new text shows in the next frame.

=head2 icon

	$item->icon("\x{2699}");
	$item->icon(undef);

Accessor for the icon.

=head2 focus

	$item->focus;

Gives the keyboard focus to the item's header. Dies when the item is
not part of a L<Term::Fabulous>.

=head2 is_focused

True while the header has the focus.

=head2 header

	my $button = $item->header;

The header L<Term::Fabulous::Widget::Button>, to listen on it or to
style it further.

=head2 body

	my $box = $item->body;

The body L<Term::Fabulous::Widget::Box>, also while the item is closed.

=head2 accordion

	my $accordion = $item->accordion;

The L<Term::Fabulous::Widget::Accordion> the item is in, or C<undef>.

=head2 refresh_look

	$item->refresh_look;

Updates the header from the item's state and the accordion's settings.
The accordion calls it when its settings change; call it yourself
after changing the header's look behind its back. Returns the item.

=head1 EVENTS

An item fires no events of its own: the accordion fires
L<Term::Fabulous::Event::Select> when the user opens or closes an
item. The header fires the events of a Button (C<Activate>,
C<OnFocus>, C<OnBlur>, ...), which bubble through the item.

=head1 KDL PROPERTIES

The properties of L<Term::Fabulous::Widget::Box/KDL PROPERTIES>, plus
C<title> and C<icon> (strings) and C<open> and C<disabled> (C<#true> /
C<#false>). Child widget nodes go into the body:

=for highlighter language=kdl

	use Term::Fabulous::Widget::Accordion::Item as Item

	Item "network" {
		title "Network"
		open #true
		Text { text "Hostname: example.org"; }
	}

=head1 SEE ALSO

L<Term::Fabulous::Widget::Accordion>, L<Term::Fabulous::Event::Select>,
L<Term::Fabulous::Manual::Layout/ACCORDIONS>.

=cut
