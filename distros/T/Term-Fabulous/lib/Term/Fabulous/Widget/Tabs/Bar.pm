package Term::Fabulous::Widget::Tabs::Bar;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Tabs::Button;
use Term::Fabulous::Widget::Tabs::Line;

our $VERSION = '0.05';

class Term::Fabulous::Widget::Tabs::Bar
	:isa(Term::Fabulous::Widget::Box)
	:strict(params)
{
	use Clay::UI::Enum::Result;
	use Clay::XS qw(
		sizing_grow sizing_fit CLAY_LEFT_TO_RIGHT CLAY_TOP_TO_BOTTOM
		CLAY_ALIGN_X_LEFT CLAY_ALIGN_X_CENTER CLAY_ALIGN_X_RIGHT CLAY_ALIGN_Y_TOP CLAY_ALIGN_Y_CENTER CLAY_ALIGN_Y_BOTTOM
	);
	use List::Util qw(first);
	use Scalar::Util qw(blessed refaddr weaken);
	use Term::Fabulous::Check qw(boolean describe non_negative_integer one_of);
	use Term::Fabulous::Roving qw(roving_target);
	use Term::Fabulous::Enum::BorderStyle;
	use Term::Fabulous::Event::Select;

	use constant BUTTON_CLASS => 'Term::Fabulous::Widget::Tabs::Button';

	my %DEFAULT_LOOK = Term::Fabulous::Widget::Tabs::Button->default_look;

	# The geometry of each side the bar can be on: whether the tabs run
	# from left to right, and the directions toward the page and away from
	# it, as the arms of Term::Fabulous::Enum::BorderStyle->junction.
	my %SIDE = (
		top    => { horizontal => 1, toward_page => 'down',  away => 'up' },
		bottom => { horizontal => 1, toward_page => 'up',    away => 'down' },
		left   => { horizontal => 0, toward_page => 'right', away => 'left' },
		right  => { horizontal => 0, toward_page => 'left',  away => 'right' },
	);
	my @ORIENTATIONS = qw(horizontal vertical);
	my %ALIGN_X      = ( start => CLAY_ALIGN_X_LEFT, center => CLAY_ALIGN_X_CENTER, end => CLAY_ALIGN_X_RIGHT );
	my %ALIGN_Y      = ( start => CLAY_ALIGN_Y_TOP,  center => CLAY_ALIGN_Y_CENTER, end => CLAY_ALIGN_Y_BOTTOM );

	field $side           :param = $DEFAULT_LOOK{side};
	field $orientation    :param = $DEFAULT_LOOK{orientation};
	field $tab_alignment  :param = 'start';
	field $tab_gap        :param = 1;
	field $tab_margin     :param = 1;
	field $tab_padding    :param = $DEFAULT_LOOK{tab_padding};
	field $active_padding :param = $DEFAULT_LOOK{active_padding};
	field $active_bold    :param = $DEFAULT_LOOK{active_bold};
	field $page_border    :param = 0;

	# The row of tabs and the line toward the page; the active tab; the
	# sizing the layout asked for, which wins over the side's.
	field $_row;
	field $_line;
	field $_active;
	field $_sizing_wish;

	# The Tabs the bar belongs to, which shows the page of the active tab.
	field $_owner;

	ADJUST {
		$side           = one_of( $self, side          => $side,          keys %SIDE );
		$orientation    = one_of( $self, orientation   => $orientation,   @ORIENTATIONS );
		$tab_alignment  = one_of( $self, tab_alignment => $tab_alignment, keys %ALIGN_X );
		$tab_gap        = non_negative_integer( $self, tab_gap        => $tab_gap );
		$tab_margin     = non_negative_integer( $self, tab_margin     => $tab_margin );
		$tab_padding    = non_negative_integer( $self, tab_padding    => $tab_padding );
		$active_padding = non_negative_integer( $self, active_padding => $active_padding );
		$active_bold    = boolean( $self, active_bold => $active_bold );
		$page_border    = boolean( $self, page_border => $page_border );

		$_sizing_wish = $self->layout->{sizing} // {};
		$_row         = Term::Fabulous::Widget::Box->new;
		$_line        = Term::Fabulous::Widget::Tabs::Line->new;
		$self->_arrange;

		$self->on( KeyPress => sub ( $self, $event ) { return $self->_handle_key($event) ? Clay::UI::Enum::Result->HANDLED : Clay::UI::Enum::Result->CONTINUE }, owner => $self );
	}

	# ---------------------------------------------------------------------
	# The theme: the tabs family
	# ---------------------------------------------------------------------

	method theme_family :common () {
		return 'tabs';
	}

	# The colors and the line style come from the theme's tabs family
	# unless given.
	method themed_params :common () {
		return (
			$class->SUPER::themed_params,
			line_style             => [ 'line.style',       'normal',   'grid_border_style' ],
			line_color             => [ 'line.color',       'normal',   'color' ],
			text_color             => [ 'text',             'normal',   'color' ],
			active_text_color      => [ 'text',             'active',   'color' ],
			disabled_color         => [ 'text',             'disabled', 'color' ],
			hover_background_color => [ 'hover_background', 'normal',   'color' ],
			focus_border_color     => [ 'focus_border',     'normal',   'optional_color' ],
		);
	}

	# The tabs and the line read the looks; they paint again
	# (Term::Fabulous::Role::Themed).
	method looks_changed (@names) {
		$self->_restyle;
		return;
	}

	# ---------------------------------------------------------------------
	# Geometry
	# ---------------------------------------------------------------------

	method is_horizontal () {
		return $SIDE{$side}{horizontal};
	}

	method toward_page () {
		return $SIDE{$side}{toward_page};
	}

	method away_from_page () {
		return $SIDE{$side}{away};
	}

	# Lays the bar out for its side: the tabs in a row (or a column) that
	# runs along the bar, aligned toward the page and along the bar as
	# tab_alignment says, and the line between them and the page.
	method _arrange () {
		my $horizontal = $self->is_horizontal;
		my ( $along, $across ) = $horizontal ? qw(width height) : qw(height width);
		my %sizing = ( $along => sizing_grow(), $across => sizing_fit(), %$_sizing_wish );
		$self->SUPER::layout( { %{ $self->layout }, layout_direction => $horizontal ? CLAY_TOP_TO_BOTTOM : CLAY_LEFT_TO_RIGHT, sizing => \%sizing } );

		my %alignment
			= $horizontal
			? ( x => $ALIGN_X{$tab_alignment}, y => $side eq 'top' ? CLAY_ALIGN_Y_BOTTOM : CLAY_ALIGN_Y_TOP )
			: ( y => $ALIGN_Y{$tab_alignment}, x => $side eq 'left' ? CLAY_ALIGN_X_RIGHT : CLAY_ALIGN_X_LEFT );
		my %margin = $horizontal ? ( left => $tab_margin, right => $tab_margin ) : ( top => $tab_margin, bottom => $tab_margin );
		$_row->layout(
			{
				layout_direction => $horizontal ? CLAY_LEFT_TO_RIGHT : CLAY_TOP_TO_BOTTOM,
				child_gap        => $tab_gap,
				child_alignment  => \%alignment,
				padding          => \%margin,
				sizing           => { $along => sizing_grow(), $across => sizing_fit() },
			}
		);

		my @parts = $side eq 'top' || $side eq 'left' ? ( $_row, $_line ) : ( $_line, $_row );
		$self->_reattach(@parts) unless join( ' ', map { refaddr $_ } @parts ) eq join( ' ', map { refaddr $_ } @{ $self->children } );
		return;
	}

	# Puts the parts in this order; a tab that had the focus keeps it.
	method _reattach (@parts) {
		my $focused = first { $_->is_focused } $self->buttons;
		$self->SUPER::clear_children;
		$self->SUPER::add_child(@parts);
		$focused->focus if defined $focused;
		return;
	}

	# A sizing written later wins over the side's as well.
	method layout :override (@new) {
		return $self->SUPER::layout unless @new;
		my $layout = $self->SUPER::layout(@new);
		$_sizing_wish = $layout->{sizing} // {};
		return $layout;
	}

	# ---------------------------------------------------------------------
	# Tabs
	# ---------------------------------------------------------------------

	method add_child :override (@kids) {
		foreach my $kid (@kids) {
			die ref($self) . ": a tab bar holds only Term::Fabulous::Widget::Tabs::Button widgets, got " . ( blessed $kid ? ref $kid : describe($kid) )
				unless blessed $kid && $kid->isa(BUTTON_CLASS);
		}
		$_row->add_child(@kids);
		my $first_enabled = first { $_->is_enabled } @kids;
		$self->_activate($first_enabled) if !defined $_active && defined $first_enabled;
		$self->_restyle;
		return $self;
	}

	method remove_child :override (@kids) {
		$_row->remove_child(@kids);
		$self->_dropped;
		return $self;
	}

	method remove_child_with_id :override ($target_id) {
		$_row->remove_child_with_id($target_id);
		$self->_dropped;
		return $self;
	}

	method remove_children_with :override ($predicate) {
		$_row->remove_children_with($predicate);
		$self->_dropped;
		return $self;
	}

	method clear_children :override () {
		$_row->clear_children;
		$self->_dropped;
		return $self;
	}

	# After tabs left the bar: when the active one did, the first enabled
	# tab left takes its place.
	method _dropped () {
		$self->_activate( first { $_->is_enabled } $self->buttons ) if defined $_active && !$_row->has_child($_active);
		$self->_restyle;
		return;
	}

	method buttons () {
		return @{ $_row->children };
	}

	method button ($index) {
		my @buttons = $self->buttons;
		die ref($self) . ": button needs an index in 0.." . $#buttons . ", got " . describe($index) unless defined $index && !ref $index && $index =~ /\A[0-9]+\z/ && $index < @buttons;
		return $buttons[$index];
	}

	# A tab or its index: the tab.
	method _button_of ($which) {
		return $self->button($which) unless blessed $which;
		die ref($self) . ": not a tab of this bar" unless defined $self->index_of($which);
		return $which;
	}

	method index_of ($button) {
		my @buttons = $self->buttons;
		return first { refaddr( $buttons[$_] ) == refaddr($button) } 0 .. $#buttons;
	}

	method active () {
		return $_active;
	}

	method active_index () {
		return defined $_active ? $self->index_of($_active) : undef;
	}

	# Makes a tab the active one from the program; undef makes none
	# active. Fires nothing.
	method select ($which) {
		$self->_activate( defined $which ? $self->_button_of($which) : undef );
		return $self;
	}

	# Chooses a tab as the user does: fires Select when the active tab
	# changes, and focuses it. A disabled tab changes nothing.
	method choose ($which) {
		my $button = $self->_button_of($which);
		return $self unless $button->is_enabled;
		$self->_chosen($button);
		return $self;
	}

	sub _same ( $one, $other ) {
		return defined $one ? defined $other && refaddr($one) == refaddr($other) : !defined $other;
	}

	method _activate ($button) {
		return if _same( $_active, $button );
		my $had_focus = defined $_active && $_active->is_focused;
		$_active = $button;
		$self->_restyle;
		$self->_focus_active if $had_focus;
		$_owner->_sync if defined $_owner;
		return;
	}

	method _chosen ($button) {
		my $changed = !_same( $_active, $button );
		$self->_activate($button);
		$self->_focus_active;
		$self->fire_event( Term::Fabulous::Event::Select->new( item => $button, index => $self->index_of($button) ) ) if $changed;
		return;
	}

	method _focus_active () {
		my $ui = $self->ui;
		return unless defined $_active && defined $ui && $ui->interaction->can_take_focus($_active);
		$_active->focus unless $_active->is_focused;
		return;
	}

	# The user activated a tab (a click, Enter or Space).
	method _button_activated ($button) {
		$self->_chosen($button) if $button->is_enabled;
		return;
	}

	# The Tabs that owns the bar, told when the active tab changes.
	method _set_owner ($owner) {
		$_owner = $owner;
		weaken $_owner if defined $_owner;
		return;
	}

	# ---------------------------------------------------------------------
	# Look
	# ---------------------------------------------------------------------

	# Only the active tab takes the focus: Tab stops at the bar once, and
	# the arrow keys move between the tabs.
	method _restyle () {
		foreach my $button ( $self->buttons ) {
			my $is_active = _same( $_active, $button );
			$button->_set_active($is_active);
			$button->can_focus($is_active);
		}
		$_line->mark_changed;
		$self->mark_changed;
		return;
	}

	method _set ( $field_ref, $value, $arranges = 0 ) {
		$$field_ref = $value;
		$self->_arrange if $arranges;
		$self->_restyle;
		return $$field_ref;
	}

	method side           (@new) { return @new ? $self->_set( \$side, one_of( $self, side => $new[0], keys %SIDE ), 1 )                      : $side }
	method orientation    (@new) { return @new ? $self->_set( \$orientation, one_of( $self, orientation => $new[0], @ORIENTATIONS ), 1 )     : $orientation }
	method tab_alignment  (@new) { return @new ? $self->_set( \$tab_alignment, one_of( $self, tab_alignment => $new[0], keys %ALIGN_X ), 1 ) : $tab_alignment }
	method tab_gap        (@new) { return @new ? $self->_set( \$tab_gap, non_negative_integer( $self, tab_gap => $new[0] ), 1 )              : $tab_gap }
	method tab_margin     (@new) { return @new ? $self->_set( \$tab_margin, non_negative_integer( $self, tab_margin => $new[0] ), 1 )        : $tab_margin }
	method tab_padding    (@new) { return @new ? $self->_set( \$tab_padding, non_negative_integer( $self, tab_padding => $new[0] ) )         : $tab_padding }
	method active_padding (@new) { return @new ? $self->_set( \$active_padding, non_negative_integer( $self, active_padding => $new[0] ) )   : $active_padding }
	method active_bold    (@new) { return @new ? $self->_set( \$active_bold, boolean( $self, active_bold => $new[0] ) )                      : $active_bold }
	method page_border    (@new) { return @new ? $self->_set( \$page_border, boolean( $self, page_border => $new[0] ) )                      : $page_border }

	method line_style (@new) {
		return @new ? $self->set_look( line_style => $new[0] ) : $self->look_value('line_style');    # set_look and the theme both check for joints
	}
	method line_color             (@new) { return @new ? $self->set_look( line_color             => $new[0] ) : $self->look_value('line_color') }
	method text_color             (@new) { return @new ? $self->set_look( text_color             => $new[0] ) : $self->look_value('text_color') }
	method active_text_color      (@new) { return @new ? $self->set_look( active_text_color      => $new[0] ) : $self->look_value('active_text_color') }
	method hover_background_color (@new) { return @new ? $self->set_look( hover_background_color => $new[0] ) : $self->look_value('hover_background_color') }
	method focus_border_color     (@new) { return @new ? $self->set_look( focus_border_color     => $new[0] ) : $self->look_value('focus_border_color') }
	method disabled_color         (@new) { return @new ? $self->set_look( disabled_color         => $new[0] ) : $self->look_value('disabled_color') }

	method layout_properties :common () {
		return (
			$class->SUPER::layout_properties,
			( map { $_ => 'scalar' } qw(side orientation tab_alignment tab_gap tab_margin tab_padding active_padding) ),
			( map { $_ => 'boolean' } qw(active_bold page_border) ),
		);
	}

	# ---------------------------------------------------------------------
	# Keys: the arrows, Home and End choose another tab while a tab of the
	# bar has the focus.
	# ---------------------------------------------------------------------

	method _handle_key ($event) {
		my @buttons = $self->buttons;
		return 0 unless grep { $_->is_focused } @buttons;
		my @enabled = grep { $buttons[$_]->is_enabled } 0 .. $#buttons;
		my $target  = roving_target( \@enabled, $self->active_index, $event->main_key_name ) // return 0;
		$self->_chosen( $buttons[$target] );
		return 1;
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Widget::Tabs::Bar - A row of tabs, one of them active

=head1 SYNOPSIS

	use Term::Fabulous::Widget::Tabs::Bar;
	use Term::Fabulous::Widget::Tabs::Button;

	my $bar = Term::Fabulous::Widget::Tabs::Bar->new( id => 'views', page_border => 1 );
	$bar->add_child( map { Term::Fabulous::Widget::Tabs::Button->new( title => $_ ) } qw(List Grid Map) );

	$bar->on( Select => sub ($event) {
		show_view( $event->index );    # 0, 1 or 2
		return;
	} );

	$bar->select(1);    # from the program: fires nothing
	say $bar->active->title;    # Grid

=head1 DESCRIPTION

A tab bar is the strip of tabs of a L<Term::Fabulous::Widget::Tabs>:
a row of L<Term::Fabulous::Widget::Tabs::Button>s and the line that
joins them with the page. One tab is the I<active> one. It is open
toward the page, so that it and the page are one shape, while the
other tabs are closed by the line and so look as if they stood behind
the page:

=for highlighter language=text

	 ╭─────────╮ ╭─────────╮ ╭───────╮
	 │ General │ │ Network │ │ Users │
	╭╯         ╰─┴─────────┴─┴───────┴───────╮

With C<active_padding>, the active tab has that many more cells of
padding on its page side, so it stands that many cells taller (wider
on a bar at the left or right) than the others and rises out of the
row:

=for highlighter language=text

	 ╭─────────╮
	 │ General │ ╭─────────╮ ╭───────╮
	 │         │ │ Network │ │ Users │
	╭╯         ╰─┴─────────┴─┴───────┴───────╮

The bar can sit on any side of the page (C<side>), and the labels can
be written from left to right or downwards (C<orientation>), on any
side: tabs along the top with downward labels are tall and narrow,
tabs along the left with horizontal labels make a sidebar. The tabs
start at the beginning of the bar, or sit in its center or at its end
(C<tab_alignment>).

The user chooses a tab with a click, or with C<Left>, C<Right>, C<Up>,
C<Down>, C<Home> and C<End> while a tab has the focus. Only the active
tab takes the focus, so C<Tab> stops at a bar once. A tab can be
disabled, and the bar fires L<Term::Fabulous::Event::Select> whenever
the user chooses another tab.

A L<Term::Fabulous::Widget::Tabs> creates and drives its bar and shows
the page of the active tab; you need a bar of your own only to switch
something that is not a page, for example whole layouts. The bar is a
L<Term::Fabulous::Widget::Box> that grows along its side and fits
across it unless the C<layout> says otherwise; its children are its
tabs, and C<add_child> accepts nothing else.

=head1 CONSTRUCTOR

=head2 new

=for highlighter language=perl

	my $bar = Term::Fabulous::Widget::Tabs::Bar->new(%parameters);

Accepts the parameters of L<Term::Fabulous::Widget::Box/CONSTRUCTOR>
(C<id>, C<layout>, C<background_color>, ...) and the ones below. All
are optional; unknown parameters die.

=over

=item C<side>

C<top> (the default), C<right>, C<bottom> or C<left>: the side of the
page the bar is on. The tabs run from left to right on the top and
the bottom, from top to bottom on the left and the right; the line
lies on the side toward the page. Anything else dies.

=item C<orientation>

C<horizontal> (the default) or C<vertical>: whether the labels are
written from left to right, or downwards, one character per row.
Independent of C<side>.

=item C<tab_alignment>

C<start> (the default), C<center> or C<end>: where the tabs sit along
the bar when they do not fill it.

=item C<tab_gap>

A non-negative integer. Default: 1. The cells between two tabs.

=item C<tab_margin>

A non-negative integer. Default: 1. The cells between the ends of the
bar and the first and the last tab; the corners of the page's border
need one.

=item C<tab_padding>

A non-negative integer. Default: 1. The cells on each side of a label
along its writing direction: left and right of a horizontal label,
above and below a vertical one.

=item C<active_padding>

A non-negative integer. Default: 0. The cells of padding the active
tab has on its page side beyond the other tabs, so that it stands that
many cells taller (wider on a bar at the left or right) than the
others, rising out of the row; 0 keeps all tabs the same size. See
L<Term::Fabulous::Manual::Layout/TABS>.

=item C<line_style>

A L<Term::Fabulous::Enum::BorderStyle> item with grid joints
(C<Ascii>, C<Dashed>, C<Double>, C<Heavy>, C<Round> or C<Solid>), or
the name of one. Default: C<Round>. The style of the tabs' borders and
of the line, whose joints join them. Another style dies, naming the
known ones.

=item C<line_color>

The color of the borders and the line, in any format
L<Term::Fabulous::Color> accepts. Default: the theme's C<tabs.line.color>, C<[90, 96, 110, 255]> in the dark theme, a
gray.

=item C<text_color>

The color of the labels of the inactive tabs. Default:
C<[150, 160, 180, 255]>.

=item C<active_text_color>

The color of the active tab's label. Default: C<[220, 223, 228, 255]>.

=item C<active_bold>

A boolean. Default: 0. Whether the active tab's label is bold.

=item C<hover_background_color>

The background of an inactive tab under the pointer. Default:
C<[40, 45, 58, 255]>.

=item C<focus_border_color>

The color of the active tab's border, and of the line's corners at
it, while the tab has the focus; or C<undef> for no focus look.
Default: C<[97, 175, 239, 255]>, a blue.

=item C<disabled_color>

The color of a disabled tab's border and label. Default:
C<[108, 112, 120, 255]>.

=item C<page_border>

A boolean. Default: 0. True draws the ends of the line as the corners
of a page border that continues from them, as under a
L<Term::Fabulous::Widget::Tabs> with a bordered page; false ends the
line straight.

=back

=head1 METHODS

The methods of L<Term::Fabulous::Widget>, plus:

=head2 add_child

	$bar->add_child( $tab, $other_tab );

Appends tabs. Dies for anything but a
L<Term::Fabulous::Widget::Tabs::Button>. While no tab is active, the
first enabled tab added becomes the active one. Returns the bar.

=head2 remove_child, remove_child_with_id, remove_children_with, clear_children

As in L<Term::Fabulous::Widget>, for the tabs. When the active tab is
removed, the first enabled tab left becomes the active one.

=head2 buttons

	my @tabs = $bar->buttons;

The tabs, in order.

=head2 button

	my $tab = $bar->button(2);

The tab at an index, from 0. Dies for an index outside the tabs.

=head2 index_of

	my $index = $bar->index_of($tab);

The index of a tab, or C<undef>.

=head2 active

	my $tab = $bar->active;    # or undef

The active tab.

=head2 active_index

	my $index = $bar->active_index;    # or undef

Its index.

=head2 select

	$bar->select(1);        # by index
	$bar->select($tab);     # or the tab
	$bar->select(undef);    # no active tab

Makes a tab the active one from the program. Fires nothing. A tab
that had the focus passes it on to the new active tab. Dies for an
index outside the tabs or a tab of another bar. Returns the bar.

=head2 choose

	$bar->choose($index);

Chooses a tab as the user does: makes it active, focuses it and fires
C<Select> when the active tab changed. A disabled tab changes
nothing. Returns the bar.

=head2 is_horizontal

	if ( $bar->is_horizontal ) { ... }

1 when the bar is on the top or the bottom, so its tabs run from left
to right; 0 on the left and the right.

=head2 toward_page, away_from_page

	my $arm = $bar->toward_page;    # 'down' for a bar on top

The directions from the line into the page and away from it, as the
arms of L<Term::Fabulous::Enum::BorderStyle/junction>: C<down> and
C<up> on the top, C<up> and C<down> on the bottom, C<right> and
C<left> on the left, C<left> and C<right> on the right.

=head2 side

	$bar->side('left');

Accessor for the C<side> parameter. Changing it lays the bar out
again; a tab that had the focus keeps it.

=head2 orientation

	$bar->orientation('vertical');

Accessor for the C<orientation> parameter.

=head2 tab_alignment

	$bar->tab_alignment('end');

Accessor for the C<tab_alignment> parameter.

=head2 tab_gap

	$bar->tab_gap(0);

Accessor for the C<tab_gap> parameter.

=head2 tab_margin

	$bar->tab_margin(2);

Accessor for the C<tab_margin> parameter.

=head2 tab_padding

	$bar->tab_padding(2);

Accessor for the C<tab_padding> parameter.

=head2 active_padding

	$bar->active_padding(1);

Accessor for the C<active_padding> parameter.

=head2 line_style

	$bar->line_style('Heavy');
	$bar->line_style( Term::Fabulous::Enum::BorderStyle->Double );

Accessor for the C<line_style> parameter; the reader returns the
style item.

=head2 line_color

	$bar->line_color('#5a606e');

Accessor for the C<line_color> parameter. The reader returns
C<[r, g, b, a]>. An invalid color dies and leaves the old one.

=head2 text_color

	$bar->text_color('#96a0b4');

Accessor for the C<text_color> parameter; works like L</line_color>.

=head2 active_text_color

	$bar->active_text_color('#ffffff');

Accessor for the C<active_text_color> parameter; works like
L</line_color>.

=head2 hover_background_color

	$bar->hover_background_color( [ 40, 45, 58 ] );

Accessor for the C<hover_background_color> parameter; works like
L</line_color>.

=head2 disabled_color

	$bar->disabled_color('#6c7078');

Accessor for the C<disabled_color> parameter; works like
L</line_color>.

=head2 active_bold

	$bar->active_bold(1);

Accessor for the C<active_bold> parameter. Returns 1 or 0.

=head2 focus_border_color

	$bar->focus_border_color(undef);

Accessor for the C<focus_border_color> parameter; C<undef> switches
the focus look off.

=head2 page_border

	$bar->page_border(1);

Accessor for the C<page_border> parameter. Returns 1 or 0.

Every writer restyles the tabs and the line, so the next frame shows
the new look.

=head1 KEYS

While a tab of the bar has the focus (only the active tab can):

=over

=item C<Left>, C<Up>

Choose the previous enabled tab, wrapping around from the first to
the last.

=item C<Right>, C<Down>

Choose the next enabled tab, wrapping around from the last to the
first.

=item C<Home>, C<End>

Choose the first and the last enabled tab.

=back

The chosen tab takes the focus. C<Enter> and C<Space> activate the
focused tab, which is active already, and change nothing. C<Tab> and
C<Shift+Tab> move the focus away from the bar, as everywhere. All
other keys bubble to the ancestors.

=head1 MOUSE

A click on a tab chooses it and focuses it; a click on a disabled tab
does nothing. An inactive tab under the pointer is painted on
C<hover_background_color>.

=head1 EVENTS

=over

=item C<Select>

L<Term::Fabulous::Event::Select> when the user chooses another tab (or
L</choose> is called and the active tab changes); C<< $event->item >>
is the tab, a L<Term::Fabulous::Widget::Tabs::Button>, and
C<< $event->index >> its position. Programmatic changes fire nothing.

=back

The C<Activate> and the focus events of the tabs bubble through the bar
as well.

=head1 KDL PROPERTIES

The properties of L<Term::Fabulous::Widget::Box/KDL PROPERTIES>, plus
C<side>, C<orientation>, C<tab_alignment>, C<tab_gap>, C<tab_margin>,
C<tab_padding>, C<active_padding> and C<line_style> (strings and
numbers), C<active_bold> and C<page_border> (C<#true> / C<#false>),
C<focus_border_color> (a color string, or C<#null> for no focus look)
and the colors C<line_color>, C<text_color>, C<active_text_color>,
C<hover_background_color> and C<disabled_color>. The tabs are child
nodes of L<Term::Fabulous::Widget::Tabs::Button>:

=for highlighter language=kdl

	use Term::Fabulous::Widget::Tabs::Bar as TabBar
	use Term::Fabulous::Widget::Tabs::Button as Tab

	TabBar "views" {
		tab_alignment "center"
		line_style "Heavy"
		Tab { title "List"; }
		Tab { title "Grid"; }
		Tab { title "Map"; disabled #true; }
	}

=head1 SEE ALSO

L<Term::Fabulous::Widget::Tabs>, L<Term::Fabulous::Widget::Tabs::Button>,
L<Term::Fabulous::Event::Select>, L<Term::Fabulous::Manual::Layout/TABS>.

=cut
