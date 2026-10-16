package Term::Fabulous::Widget::Tabs::Page;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

use Term::Fabulous::Widget::Box;

our $VERSION = '0.03';

class Term::Fabulous::Widget::Tabs::Page
	:isa(Term::Fabulous::Widget::Box)
	:strict(params)
{
	use Clay::XS qw(sizing_grow padding_all CLAY_TOP_TO_BOTTOM);
	use Scalar::Util qw(refaddr weaken);
	use Term::Fabulous::Check qw(boolean optional string);
	use Term::Fabulous::Enum::BorderStyle;

	field $title    :param = '';
	field $icon     :param = undef;
	field $disabled :param = 0;

	# Whether the page asks to be the active one when it joins a Tabs.
	field $_wants_active = 0;

	# The Tabs the page belongs to, also while it is not shown and so has
	# no parent. Set by the Tabs.
	field $_tabs;

	ADJUST :params ( :$active = 0 ) {
		$title         = string( $self, title => $title );
		$icon          = optional( \&string, $self, icon => $icon );
		$disabled      = boolean( $self, disabled => $disabled );
		$_wants_active = boolean( $self, active   => $active );

		my $layout = $self->layout;
		$self->layout(
			{
				layout_direction => CLAY_TOP_TO_BOTTOM,
				padding          => padding_all(1),
				%$layout,
				sizing => { width => sizing_grow(), height => sizing_grow(), %{ $layout->{sizing} // {} } },
			}
		);
	}

	method tabs () {
		return $_tabs;
	}

	# Called by the Tabs when the page joins it or leaves it.
	method _set_tabs ($tabs) {
		$_tabs = $tabs;
		weaken $_tabs if defined $_tabs;
		return;
	}

	# Whether the page asked to start active; read by the Tabs when the
	# page joins it.
	method _wants_active () {
		return $_wants_active;
	}

	method _notify_tabs () {
		$_tabs->_page_changed($self) if defined $_tabs;
		return;
	}

	method title (@new) {
		return $title unless @new;
		$title = string( $self, title => $new[0] );
		$self->_notify_tabs;
		return $title;
	}

	method icon (@new) {
		return $icon unless @new;
		$icon = optional( \&string, $self, icon => $new[0] );
		$self->_notify_tabs;
		return $icon;
	}

	method disabled (@new) {
		return $disabled unless @new;
		$disabled = boolean( $self, disabled => $new[0] );
		$self->_notify_tabs;
		return $disabled;
	}

	method is_enabled () {
		return $disabled ? 0 : 1;
	}

	method is_active () {
		return 0 unless defined $_tabs;
		my $active = $_tabs->active;
		return defined $active && refaddr($active) == refaddr($self) ? 1 : 0;
	}

	# In a Tabs, the page is active when it is the shown one, and writing
	# selects it (or, with a false value, no page). On its own, the page
	# remembers the wish for the Tabs it joins.
	method active (@new) {
		unless (@new) {
			return defined $_tabs ? $self->is_active : $_wants_active;
		}
		my $wanted = boolean( $self, active => $new[0] );
		if ( defined $_tabs ) {
			$_tabs->select( $wanted ? $self : undef ) if $wanted != $self->is_active;
			return $self->is_active;
		}
		$_wants_active = $wanted;
		return $_wants_active;
	}

	method layout_properties :common () {
		return ( $class->SUPER::layout_properties, title => 'scalar', icon => 'scalar', disabled => 'boolean', active => 'boolean' );
	}

	# ---------------------------------------------------------------------
	# The border: in a Tabs with page_border, the line's style on the
	# three sides away from the bar and none on the bar's side, in the
	# line's color, read when the frame is built; a style or color the
	# page was given wins.
	# ---------------------------------------------------------------------

	method _bar_with_page_border () {
		my $bar = defined $_tabs ? $_tabs->bar : return undef;
		return $bar->page_border ? $bar : undef;
	}

	# The style of a side without one of its own
	# (Term::Fabulous::Role::HasBorderStyle).
	method derived_border_style ($side) {
		my $bar = $self->_bar_with_page_border // return undef;
		return $side eq $bar->side ? Term::Fabulous::Enum::BorderStyle->Hidden : $bar->line_style;
	}

	method contribute_look_theme :override ($config) {
		$self->SUPER::contribute_look_theme($config);
		my $border = $config->{border} // return;
		return if $self->has_look_override('border_color');
		my $bar = $self->_bar_with_page_border // return;
		$config->{border} = { %$border, color => $bar->line_color };
		return;
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Widget::Tabs::Page - One page of a Tabs widget

=head1 SYNOPSIS

	use Term::Fabulous::Widget::Tabs;
	use Term::Fabulous::Widget::Tabs::Page;

	my $network = Term::Fabulous::Widget::Tabs::Page->new( title => 'Network', icon => "\x{2601}" );
	$network->add_child( $hostname_row, $port_row );    # the content
	$tabs->add_child($network);

	$network->active(1);        # show it; fires nothing
	say $network->is_active;    # 1
	$network->disabled(1);      # the user cannot switch to it

=head1 DESCRIPTION

A page is one tab of a L<Term::Fabulous::Widget::Tabs>: a box of any
widgets that is shown while its tab is the active one, and a title
with an optional icon for the tab button that the Tabs makes for it.
Only the active page is part of the widget tree: the other pages take
no space, and the widgets inside them cannot take the focus.

A page is a L<Term::Fabulous::Widget::Box> that, unless its C<layout>
says otherwise, stacks its children top to bottom, grows to fill the
Tabs and keeps one cell of padding on every side. The Tabs draws a
border around it in its C<line_style> and C<line_color>, open on the
side of the tab bar, unless its C<page_border> is off (see
L<Term::Fabulous::Widget::Tabs/CONSTRUCTOR>); the page's own border
parameters are overwritten.

A page can also be used on its own, outside a Tabs: it is then a plain
box that remembers its title.

=head1 CONSTRUCTOR

=head2 new

	my $page = Term::Fabulous::Widget::Tabs::Page->new(%parameters);

Accepts the parameters of L<Term::Fabulous::Widget::Box/CONSTRUCTOR>
(C<id>, C<layout>, C<background_color>, ...) and the ones below.
Unknown parameters die.

=over

=item C<title>

A character string. Default: C<''>. The text of the tab.

=item C<icon>

A character string, or C<undef>. Default: C<undef>. A short text, for
example a symbol, shown before the title (above it in a tab with a
vertical label).

=item C<active>

A boolean. Default: 0. Whether the page becomes the active one when it
is added to a Tabs. Without it, the first enabled page added is the
active one.

=item C<disabled>

A boolean. Default: 0. A disabled page cannot be chosen by the user:
its tab is drawn in the Tabs' C<disabled_color>, skipped by the keys
and ignores clicks. A page that is disabled while it is active stays
shown.

=back

=head1 METHODS

The methods of L<Term::Fabulous::Widget> (C<add_child> and the other
children methods act on the content), plus:

=head2 title

	$page->title('Advanced');

Accessor for the title; the tab shows the new text in the next frame.

=head2 icon

	$page->icon("\x{2699}");
	$page->icon(undef);

Accessor for the icon.

=head2 disabled

	$page->disabled(1);

Accessor for the C<disabled> flag. Returns 1 or 0.

=head2 is_enabled

The opposite of L</disabled>.

=head2 active

	my $shown = $page->active;
	$page->active(1);

Accessor. In a Tabs, reading tells whether the page is the active one,
and writing a true value makes it active (a false value shows no page),
without an event, like L<Term::Fabulous::Widget::Tabs/select>. On its
own, the page remembers the value for the Tabs it joins. Returns 1 or
0.

=head2 is_active

	if ( $page->is_active ) { ... }

1 while the page is the active one of its Tabs, 0 otherwise (also
outside a Tabs).

=head2 tabs

	my $tabs = $page->tabs;

The L<Term::Fabulous::Widget::Tabs> the page belongs to, or C<undef>.
Unlike C<parent>, it is set also while the page is not shown.

=head1 EVENTS

A page fires no events of its own: the Tabs fires
L<Term::Fabulous::Event::Select> when the user chooses a tab. The
events of the widgets in the page bubble through it.

=head1 KDL PROPERTIES

The properties of L<Term::Fabulous::Widget::Box/KDL PROPERTIES>, plus
C<title> and C<icon> (strings) and C<active> and C<disabled>
(C<#true> / C<#false>). Child widget nodes are the content:

=for highlighter language=kdl

	use Term::Fabulous::Widget::Tabs::Page as Page

	Page "network" {
		title "Network"
		active #true
		Text { text "Hostname: example.org"; }
	}

=head1 SEE ALSO

L<Term::Fabulous::Widget::Tabs>, L<Term::Fabulous::Event::Select>,
L<Term::Fabulous::Manual::Layout/TABS>.

=cut
