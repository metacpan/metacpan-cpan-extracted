package Term::Fabulous::Widget::Tabs;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Tabs::Bar;
use Term::Fabulous::Widget::Tabs::Button;
use Term::Fabulous::Widget::Tabs::Page;

our $VERSION = '0.03';

class Term::Fabulous::Widget::Tabs
	:isa(Term::Fabulous::Widget::Box)
	:strict(params)
{
	use Clay::UI::Enum::Result;
	use Clay::XS qw(sizing_grow CLAY_LEFT_TO_RIGHT CLAY_TOP_TO_BOTTOM);
	use List::Util qw(first);
	use Scalar::Util qw(blessed refaddr weaken);
	use Term::Fabulous::Check qw(describe);
	use Term::Fabulous::Roving qw(roving_target);
	use Term::Fabulous::Event::Select;

	use constant PAGE_CLASS => 'Term::Fabulous::Widget::Tabs::Page';

	# The look is the bar's; these constructor parameters go to it. The
	# themed ones live on the bar (see forwarded_looks).
	my @BAR_LOOKS  = qw(line_style line_color text_color active_text_color hover_background_color focus_border_color disabled_color);
	my @BAR_PARAMS = ( qw(side orientation tab_alignment tab_gap tab_margin tab_padding active_bold page_border), @BAR_LOOKS );

	# The bar, the slot that shows the active page, and the pages, in the
	# order of the bar's tabs.
	field $_bar;
	field $_slot;
	field @_pages;

	ADJUSTPARAMS($params) {
		my %look = ( page_border => 1, map { $_ => delete $params->{$_} } grep { exists $params->{$_} } @BAR_PARAMS );
		$_bar  = Term::Fabulous::Widget::Tabs::Bar->new(%look);
		$_slot = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow(), height => sizing_grow() } } );
		$_bar->_set_owner($self);

		my $layout = $self->layout;
		$self->layout( { %$layout, sizing => { width => sizing_grow(), height => sizing_grow(), %{ $layout->{sizing} // {} } } } );
		$self->_arrange;

		weaken( my $weak_self = $self );
		$_bar->on( Select   => sub ($event) { $weak_self->_tab_chosen($event) if $weak_self; return } );
		$self->on( KeyPress => sub ($event) { return $weak_self && $weak_self->_handle_key($event) ? Clay::UI::Enum::Result->HANDLED : Clay::UI::Enum::Result->CONTINUE } );
	}

	# ---------------------------------------------------------------------
	# Layout: the bar and the slot, the bar on its side.
	# ---------------------------------------------------------------------

	method _arrange () {
		my $side = $_bar->side;
		$self->layout( { %{ $self->layout }, layout_direction => $_bar->is_horizontal ? CLAY_TOP_TO_BOTTOM : CLAY_LEFT_TO_RIGHT } );
		my @parts = $side eq 'top' || $side eq 'left' ? ( $_bar, $_slot ) : ( $_slot, $_bar );
		$self->_reattach(@parts) unless join( ' ', map { refaddr $_ } @parts ) eq join( ' ', map { refaddr $_ } @{ $self->children } );
		$self->_restyle_pages;
		return;
	}

	# Puts the parts in this order; a tab that had the focus keeps it.
	method _reattach (@parts) {
		my $focused = first { $_->is_focused } $_bar->buttons;
		$self->SUPER::clear_children;
		$self->SUPER::add_child(@parts);
		$focused->focus if defined $focused;
		return;
	}

	# ---------------------------------------------------------------------
	# Pages
	# ---------------------------------------------------------------------

	method add_child :override (@kids) {
		foreach my $kid (@kids) {
			die ref($self) . ": a Tabs holds only Term::Fabulous::Widget::Tabs::Page widgets, got " . ( blessed $kid ? ref $kid : describe($kid) )
				unless blessed $kid && $kid->isa(PAGE_CLASS);
			die ref($self) . ": the page is part of a Tabs already" if defined $kid->tabs;
		}
		foreach my $page (@kids) {
			my $button = Term::Fabulous::Widget::Tabs::Button->new( title => $page->title, icon => $page->icon, disabled => $page->disabled );
			push @_pages, $page;
			$page->_set_tabs($self);
			$_bar->add_child($button);
			$_bar->select($button) if $page->_wants_active;
		}
		$self->_restyle_pages;
		$self->_sync;
		return $self;
	}

	method remove_child :override (@kids) {
		foreach my $kid (@kids) {
			die ref($self) . ": remove_child takes pages, got " . describe($kid) . "; remove a page by its id with remove_child_with_id"
				unless blessed $kid;
		}
		my %given = map { refaddr($_) => 1 } @kids;
		$self->_remove_pages( grep { $given{ refaddr $_ } } @_pages );
		return $self;
	}

	method remove_child_with_id :override ($target_id) {
		$self->_remove_pages( grep { defined $_->id && $_->id eq $target_id } @_pages );
		return $self;
	}

	method remove_children_with :override ($predicate) {
		$self->_remove_pages( grep { $predicate->($_) } @_pages );
		return $self;
	}

	method clear_children :override () {
		$self->_remove_pages(@_pages);
		return $self;
	}

	# Takes pages and their tabs out; the bar picks a new active tab when
	# the active one leaves, and _sync shows its page.
	method _remove_pages (@gone) {
		foreach my $page (@gone) {
			my $index  = $self->index_of($page);
			my $button = $_bar->button($index);
			splice @_pages, $index, 1;
			$page->_set_tabs(undef);
			$_bar->remove_child($button);
		}
		$self->_sync;
		return;
	}

	method pages () {
		return @_pages;
	}

	method page ($index) {
		die ref($self) . ": page needs an index in 0.." . $#_pages . ", got " . describe($index) unless defined $index && !ref $index && $index =~ /\A[0-9]+\z/ && $index < @_pages;
		return $_pages[$index];
	}

	# A page or its index: the page.
	method _page_of ($which) {
		return $self->page($which) unless blessed $which;
		die ref($self) . ": not a page of this Tabs" unless defined $self->index_of($which);
		return $which;
	}

	method index_of ($page) {
		return first { refaddr( $_pages[$_] ) == refaddr($page) } 0 .. $#_pages;
	}

	method _button_for ($page) {
		return $_bar->button( $self->index_of($page) );
	}

	method active () {
		my $index = $_bar->active_index // return undef;
		return $_pages[$index];
	}

	method active_index () {
		return $_bar->active_index;
	}

	method bar () {
		return $_bar;
	}

	# Shows a page from the program; undef shows none. Fires nothing.
	method select ($which) {
		$_bar->select( defined $which ? $self->_button_for( $self->_page_of($which) ) : undef );
		return $self;
	}

	# Chooses a page as the user does: fires Select when the active page
	# changes. A disabled page changes nothing.
	method choose ($which) {
		$_bar->choose( $self->_button_for( $self->_page_of($which) ) );
		return $self;
	}

	# The bar's Select names its tab; the Tabs fires its own with the page
	# and keeps the bar's from bubbling on.
	method _tab_chosen ($event) {
		$self->_sync;
		$self->fire_event( Term::Fabulous::Event::Select->new( item => $_pages[ $event->index ], index => $event->index ) );
		return;
	}

	# Puts the page of the active tab into the slot, in place of whatever
	# is there. Called by the bar when its active tab changes.
	method _sync () {
		my $page = $self->active;
		my ($shown) = @{ $_slot->children };
		return if defined $page ? defined $shown && refaddr($shown) == refaddr($page) : !defined $shown;
		$_slot->clear_children if defined $shown;
		$_slot->add_child($page) if defined $page;
		return;
	}

	# A page changed its title, icon or disabled flag: its tab follows.
	method _page_changed ($page) {
		my $button = $self->_button_for($page);
		$button->title( $page->title );
		$button->icon( $page->icon );
		$button->disabled( $page->disabled );
		$_bar->_restyle;
		return;
	}

	# ---------------------------------------------------------------------
	# Look: the bar's, and the border of the pages
	# ---------------------------------------------------------------------

	# A page has a border around it, or none, as page_border says; its
	# style and color follow the bar (see
	# Term::Fabulous::Widget::Tabs::Page).
	method _restyle_pages () {
		my $on = $_bar->page_border ? 1 : 0;
		foreach my $page (@_pages) {
			$page->bordered($on) unless $page->has_look_override('bordered') && $page->bordered->{top} == $on;
		}
		return;
	}

	method _forward ( $name, $arranges, $restyles_pages, @new ) {
		my $value = $_bar->$name(@new);
		return $value unless @new;
		$self->_arrange if $arranges;
		$self->_restyle_pages if $restyles_pages;
		return $value;
	}

	method side          (@new) { return $self->_forward( side          => 1, 1, @new ) }
	method orientation   (@new) { return $self->_forward( orientation   => 0, 0, @new ) }
	method tab_alignment (@new) { return $self->_forward( tab_alignment => 0, 0, @new ) }
	method tab_gap       (@new) { return $self->_forward( tab_gap       => 0, 0, @new ) }
	method tab_margin    (@new) { return $self->_forward( tab_margin    => 0, 0, @new ) }
	method tab_padding   (@new) { return $self->_forward( tab_padding   => 0, 0, @new ) }
	method active_bold   (@new) { return $self->_forward( active_bold   => 0, 0, @new ) }
	method page_border   (@new) { return $self->_forward( page_border   => 0, 1, @new ) }

	# The looks live on the bar (Term::Fabulous::Role::Themed): the bar
	# takes them from the constructor, and reset_look returns them to the
	# theme there.
	method forwarded_looks :common () {
		return ( bar => [ 'Term::Fabulous::Widget::Tabs::Bar', @BAR_LOOKS ] );
	}

	method line_style             (@new) { return @new ? $self->set_look( line_style             => $new[0] ) : $_bar->line_style }
	method line_color             (@new) { return @new ? $self->set_look( line_color             => $new[0] ) : $self->look_value('line_color') }
	method text_color             (@new) { return @new ? $self->set_look( text_color             => $new[0] ) : $self->look_value('text_color') }
	method active_text_color      (@new) { return @new ? $self->set_look( active_text_color      => $new[0] ) : $self->look_value('active_text_color') }
	method hover_background_color (@new) { return @new ? $self->set_look( hover_background_color => $new[0] ) : $self->look_value('hover_background_color') }
	method focus_border_color     (@new) { return @new ? $self->set_look( focus_border_color     => $new[0] ) : $self->look_value('focus_border_color') }
	method disabled_color         (@new) { return @new ? $self->set_look( disabled_color         => $new[0] ) : $self->look_value('disabled_color') }

	method layout_properties :common () {
		return (
			$class->SUPER::layout_properties,
			( map { $_ => 'scalar' } qw(side orientation tab_alignment tab_gap tab_margin tab_padding) ),
			( map { $_ => 'boolean' } qw(active_bold page_border) ),
		);
	}

	# ---------------------------------------------------------------------
	# Keys: Ctrl+PageUp and Ctrl+PageDown turn the pages from anywhere in
	# the Tabs, as in a browser.
	# ---------------------------------------------------------------------

	method _handle_key ($event) {
		my @enabled = grep { $_pages[$_]->is_enabled } 0 .. $#_pages;
		my $target  = roving_target( \@enabled, $self->active_index, $event->main_key_name, keys => 'pages' ) // return 0;
		$self->choose($target);
		return 1;
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Widget::Tabs - Pages behind a row of tabs

=head1 SYNOPSIS

	use Term::Fabulous::Widget::Tabs;
	use Term::Fabulous::Widget::Tabs::Page;
	use Term::Fabulous::Widget::Text;

	my $settings = Term::Fabulous::Widget::Tabs->new( id => 'settings' );
	foreach my $section ( [ General => 'Language, time zone' ], [ Network => 'Hostname, ports' ], [ Users => 'Accounts and groups' ] ) {
		my $page = Term::Fabulous::Widget::Tabs::Page->new( title => $section->[0] );
		$page->add_child( Term::Fabulous::Widget::Text->new( text => $section->[1], text_color => '#c8cdd7' ) );
		$settings->add_child($page);
	}

	$settings->on( Select => sub ($event) {
		$status->text( 'Showing ' . $event->item->title );
		return;
	} );

	$settings->select(1);    # from the program: fires nothing

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.03/screenshots/widget-tabs.svg" alt="Four Tabs widgets: tabs along the top with the Network page shown and a disabled Licenses tab, tabs with vertical labels along the left side, a tab bar at the bottom in the Heavy style, and tabs on the right without a page border"></p>

=end html

=head1 DESCRIPTION

The picture shows the Tabs widget in four forms: tabs along the top
with its second page shown and a disabled tab, tabs with downward
labels along the left side, a bar at the bottom in another line
style, and tabs on the right without a border around the page. The
program is F<examples/widgets/tabs.pl>.

A Tabs widget shows one of several pages at a time, chosen with the
tabs of its bar. The bar is drawn as a row of boxes that join the
border of the page: the active tab is one cell larger and open toward
the page, so that it and the page are one shape, while the others are
closed by the page's line and look as if they stood behind it:

=for highlighter language=text

	 ╭─────────╮
	 │ General │ ╭─────────╮ ╭───────╮
	 │         │ │ Network │ │ Users │
	╭╯         ╰─┴─────────┴─┴───────┴───────╮
	│                                        │
	│  Language   en                         │
	│  Time zone  UTC                        │
	│                                        │
	╰────────────────────────────────────────╯

The bar can be on any side of the page (C<side>), and the labels can
be written from left to right or downwards (C<orientation>), on any
side; the tabs can sit at the start, in the center or at the end of
the bar. The border around the page can be left out (C<page_border>).

The user switches pages with a click on a tab, with C<Left>, C<Right>,
C<Up>, C<Down>, C<Home> and C<End> while the active tab has the focus,
and with C<Ctrl+PageUp> and C<Ctrl+PageDown> from anywhere inside the
Tabs. Only the active tab takes the focus, so C<Tab> walks from it
into the page and on. A page can be disabled, and the Tabs fires
L<Term::Fabulous::Event::Select> for every change the user makes.

Each page is a L<Term::Fabulous::Widget::Tabs::Page>: a box with a
title and an optional icon for its tab, holding the widgets you add to
it. Only the active page is part of the widget tree, so the other
pages take no space and their widgets cannot take the focus. The Tabs
makes a L<Term::Fabulous::Widget::Tabs::Button> for every page in its
L<Term::Fabulous::Widget::Tabs::Bar>; the look of the tabs (side,
orientation, line style, colors) is set once, on the Tabs.

A Tabs is a L<Term::Fabulous::Widget::Box> that grows in both
directions unless the C<layout> says otherwise; C<add_child> accepts
only pages. Its children are the bar and a box that holds the shown
page, so use L</pages> rather than C<children> to get at the pages.

=head1 CONSTRUCTOR

=head2 new

=for highlighter language=perl

	my $tabs = Term::Fabulous::Widget::Tabs->new(%parameters);

Accepts the parameters of L<Term::Fabulous::Widget::Box/CONSTRUCTOR>
(C<id>, C<layout>, C<background_color>, ...), the look parameters of
L<Term::Fabulous::Widget::Tabs::Bar/CONSTRUCTOR>, which it passes to
its bar, and C<page_border>. All are optional; unknown parameters die.
The look parameters are:

=over

=item C<side>

C<top> (the default), C<right>, C<bottom> or C<left>: the side the
bar is on.

=item C<orientation>

C<horizontal> (the default) or C<vertical>: whether the tab labels are
written from left to right, or downwards.

=item C<tab_alignment>

C<start> (the default), C<center> or C<end>: where the tabs sit along
the bar.

=item C<tab_gap>

=item C<tab_margin>

=item C<tab_padding>

Non-negative integers, all 1 by default: the cells between two tabs,
between the ends of the bar and the outer tabs, and on each side of a
label along its writing direction.

=item C<line_style>

A L<Term::Fabulous::Enum::BorderStyle> item with grid joints
(C<Ascii>, C<Dashed>, C<Double>, C<Heavy>, C<Round> or C<Solid>), or
the name of one. Default: C<Round>. The style of the tabs' borders,
of the line that closes them and of the page's border.

=item C<line_color>

The color of those lines. Default: C<[90, 96, 110, 255]>, a gray.

=item C<text_color>

=item C<active_text_color>

The colors of the labels of the inactive tabs and of the active one.
Defaults: C<[150, 160, 180, 255]> and C<[220, 223, 228, 255]>.

=item C<active_bold>

A boolean. Default: 0. Whether the active tab's label is bold.

=item C<hover_background_color>

The background of an inactive tab under the pointer. Default:
C<[40, 45, 58, 255]>.

=item C<focus_border_color>

The color of the active tab's outline while it has the focus, or
C<undef> for none. Default: C<[97, 175, 239, 255]>, a blue.

=item C<disabled_color>

The color of a disabled tab. Default: C<[108, 112, 120, 255]>.

=item C<page_border>

A boolean. Default: 1. Whether the page has a border on the three
sides away from the bar, in C<line_style> and C<line_color>; on the
bar's side the bar's line closes it. Without it, only the bar's line
separates the tabs from the page.

=back

=head1 METHODS

The methods of L<Term::Fabulous::Widget>, plus:

=head2 add_child

	$tabs->add_child( $page, $other_page );

Appends pages. Dies for anything but a
L<Term::Fabulous::Widget::Tabs::Page>, and for a page that is part of
a Tabs already. The first enabled page added becomes the active one,
unless a page asks for it with C<< active => 1 >>. Returns the Tabs.

=head2 remove_child, remove_child_with_id, remove_children_with, clear_children

As in L<Term::Fabulous::Widget>, for the pages (also those not shown);
C<remove_child> dies for anything but a widget and ignores widgets that
are not pages of this Tabs. When the active page is removed, the first
enabled page left becomes the active one. Fires nothing. C<children>
and C<has_child> see the bar and the box that holds the shown page, not
the pages.

=head2 pages

	my @pages = $tabs->pages;

The pages, in the order of their tabs.

=head2 page

	my $page = $tabs->page(2);

The page at an index, from 0. Dies for an index outside the pages.

=head2 index_of

	my $index = $tabs->index_of($page);

The index of a page, or C<undef>.

=head2 active

	my $page = $tabs->active;    # or undef

The page shown now.

=head2 active_index

	my $index = $tabs->active_index;    # or undef

Its index.

=head2 select

	$tabs->select(1);        # by index
	$tabs->select($page);    # or the page
	$tabs->select(undef);    # no page

Shows a page from the program. Fires nothing. A tab that had the
focus passes it on to the new active tab. Dies for an index outside
the pages or a page of another Tabs. Returns the Tabs.

=head2 choose

	$tabs->choose($index);

Chooses a page as the user does: shows it, focuses its tab and fires
C<Select> when the active page changed. A disabled page changes
nothing. Returns the Tabs.

=head2 bar

	my $bar = $tabs->bar;

The L<Term::Fabulous::Widget::Tabs::Bar>, for its tabs
(C<< $tabs->bar->button($index) >>) and their events. Change the
active tab and the look through the Tabs, which keeps the pages in
step.

=head2 side

	$tabs->side('left');

Accessor for the C<side> parameter. Changing it lays the Tabs out
again; a tab that had the focus keeps it.

=head2 orientation

	$tabs->orientation('vertical');

Accessor for the C<orientation> parameter.

=head2 tab_alignment

	$tabs->tab_alignment('center');

Accessor for the C<tab_alignment> parameter.

=head2 tab_gap

	$tabs->tab_gap(0);

Accessor for the C<tab_gap> parameter.

=head2 tab_margin

	$tabs->tab_margin(2);

Accessor for the C<tab_margin> parameter.

=head2 tab_padding

	$tabs->tab_padding(2);

Accessor for the C<tab_padding> parameter.

=head2 line_style

	$tabs->line_style('Heavy');

Accessor for the C<line_style> parameter; the reader returns the
style item. The borders of the pages follow it.

=head2 line_color

	$tabs->line_color('#5a606e');

Accessor for the C<line_color> parameter. The reader returns
C<[r, g, b, a]>; an invalid color dies and leaves the old one, and so
does C<undef>. The borders of the pages follow it. The bar keeps the
colors and the line style; C<< $tabs->reset_look('line_color') >>
returns them to the theme (see L<Term::Fabulous::Widget/reset_look>).

=head2 text_color

	$tabs->text_color('#96a0b4');

Accessor for the C<text_color> parameter; works like L</line_color>.

=head2 active_text_color

	$tabs->active_text_color('#ffffff');

Accessor for the C<active_text_color> parameter; works like
L</line_color>.

=head2 active_bold

	$tabs->active_bold(1);

Accessor for the C<active_bold> parameter. Returns 1 or 0.

=head2 hover_background_color

	$tabs->hover_background_color( [ 40, 45, 58 ] );

Accessor for the C<hover_background_color> parameter; works like
L</line_color>.

=head2 focus_border_color

	$tabs->focus_border_color(undef);

Accessor for the C<focus_border_color> parameter; C<undef> switches
the focus look off.

=head2 disabled_color

	$tabs->disabled_color('#6c7078');

Accessor for the C<disabled_color> parameter; works like
L</line_color>.

=head2 page_border

	$tabs->page_border(0);

Accessor for the C<page_border> parameter. Returns 1 or 0. Restyles
the pages as well.

Every writer passes the value to the bar (see
L<Term::Fabulous::Widget::Tabs::Bar/METHODS>) and shows its change in
the next frame.

=head1 KEYS

While the active tab has the focus, C<Left> and C<Up> choose the
previous enabled tab, C<Right> and C<Down> the next one, wrapping
around, and C<Home> and C<End> the first and the last; see
L<Term::Fabulous::Widget::Tabs::Bar/KEYS>. From anywhere inside the
Tabs, also from a widget on the page:

=over

=item C<Ctrl+PageUp>, C<Ctrl+PageDown>

Choose the previous or the next enabled page, wrapping around.

=back

C<Tab> and C<Shift+Tab> move through the active tab and the widgets
of the shown page in order, as everywhere. All other keys bubble to
the ancestors.

=head1 MOUSE

A click on a tab shows its page and focuses the tab. An inactive tab
under the pointer is painted on C<hover_background_color>.

=head1 EVENTS

=over

=item C<Select>

L<Term::Fabulous::Event::Select> when the user chooses another tab (or
L</choose> is called and the active page changes); C<< $event->item >>
is the page now shown and C<< $event->index >> its position.
Programmatic changes fire nothing. The bar's own C<Select>, which
names the tab, does not bubble past the Tabs; listen on
C<< $tabs->bar >> for it.

=back

The C<Activate> of the tabs and the events of the widgets on the pages
bubble through the Tabs as well.

=head1 KDL PROPERTIES

The properties of L<Term::Fabulous::Widget::Box/KDL PROPERTIES>, plus
C<side>, C<orientation>, C<tab_alignment>, C<tab_gap>, C<tab_margin>,
C<tab_padding> and C<line_style> (strings and numbers),
C<active_bold> and C<page_border> (C<#true> / C<#false>),
C<focus_border_color> (a color string, or C<#null> for no focus look)
and the colors C<line_color>, C<text_color>, C<active_text_color>,
C<hover_background_color> and C<disabled_color>. The pages are C<Page>
child nodes (see L<Term::Fabulous::Widget::Tabs::Page/KDL PROPERTIES>):

=for highlighter language=kdl

	use Term::Fabulous::Widget::Tabs as Tabs
	use Term::Fabulous::Widget::Tabs::Page as Page
	use Term::Fabulous::Widget::Text as Text

	Tabs "settings" {
		side "left"
		line_style "Solid"
		Page "general" {
			title "General"
			Text { text "Language, time zone"; }
		}
		Page "network" {
			title "Network"
			active #true
			Text { text "Hostname, ports"; }
		}
	}

=head1 EXAMPLES

=head2 A sidebar of tabs

=for highlighter language=perl

	my $tabs = Term::Fabulous::Widget::Tabs->new( side => 'left', tab_alignment => 'start' );

=head2 Tabs without a frame around the page

	my $tabs = Term::Fabulous::Widget::Tabs->new( page_border => 0, active_bold => 1 );

=head2 Remember the shown page

	$settings->on( Select => sub ($event) {
		$config->{page} = $event->item->id;
		return;
	} );

=head1 SEE ALSO

L<Term::Fabulous::Widget::Tabs::Page>, L<Term::Fabulous::Widget::Tabs::Bar>,
L<Term::Fabulous::Widget::Tabs::Button>, L<Term::Fabulous::Event::Select>,
L<Term::Fabulous::Widget::Accordion>,
L<Term::Fabulous::Manual::Layout/TABS>.

=cut
