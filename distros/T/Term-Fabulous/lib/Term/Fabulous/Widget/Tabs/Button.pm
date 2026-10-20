package Term::Fabulous::Widget::Tabs::Button;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

use Term::Fabulous::Widget::Button;
use Term::Fabulous::Widget::Text;

our $VERSION = '0.05';

class Term::Fabulous::Widget::Tabs::Button
	:isa(Term::Fabulous::Widget::Button)
	:strict(params)
{
	use Clay::UI::Enum::Result;
	use Clay::XS qw(CLAY_LEFT_TO_RIGHT CLAY_TOP_TO_BOTTOM CLAY_TEXT_WRAP_NONE CLAY_TEXT_WRAP_NEWLINES);
	use List::Util qw(first);
	use Term::Fabulous::Check qw(optional string);
	use Term::Fabulous::Enum::BorderStyle;
	use Term::Fabulous::Unicode qw(grapheme_clusters);

	# The settings a tab shows while it has no bar to take them from; the
	# bar's defaults are these as well. The colors and the line style come
	# from the theme's tabs family (see Term::Fabulous::Widget::Tabs::Bar).
	my %DEFAULT_LOOK = (
		side           => 'top',
		orientation    => 'horizontal',
		tab_padding    => 1,
		active_padding => 0,
		active_bold    => 0,
	);

	# The side of a tab that faces the page, by the side of the bar.
	my %PAGE_SIDE = ( top => 'bottom', bottom => 'top', left => 'right', right => 'left' );

	field $title :param = '';
	field $icon  :param = undef;

	field $_icon_text;
	field $_title_text;
	field $_active = 0;

	method default_look :common () {
		return %DEFAULT_LOOK;
	}

	ADJUST {
		$title = string( $self, title => $title );
		$icon  = optional( \&string, $self, icon => $icon );

		$self->bordered(1);
		$self->pressed_background_color(undef);
		$_icon_text  = Term::Fabulous::Widget::Text->new( text => '' );
		$_title_text = Term::Fabulous::Widget::Text->new( text => '' );

		my $continue = Clay::UI::Enum::Result->CONTINUE;
		$self->on( Activate => sub ( $self, $event ) { $self->_activated;   return $continue }, owner => $self );
		$self->on( $_       => sub ( $self, $event ) { $self->refresh_look; return $continue }, owner => $self ) foreach qw(OnFocus OnBlur OnHoverStart OnHoverStopped);
		$self->refresh_look;
	}

	# The bar the tab belongs to, if any: the tab's parent is the bar's row.
	method bar () {
		return first { $_->isa('Term::Fabulous::Widget::Tabs::Bar') } $self->ancestors;
	}

	method is_active () {
		return $_active;
	}

	# Set by the bar: the active tab is open toward the page and grows
	# active_padding cells that way.
	method _set_active ($flag) {
		$_active = $flag ? 1 : 0;
		$self->refresh_look;
		return;
	}

	method title (@new) {
		return $title unless @new;
		$title = string( $self, title => $new[0] );
		$self->refresh_look;
		return $title;
	}

	method icon (@new) {
		return $icon unless @new;
		$icon = optional( \&string, $self, icon => $new[0] );
		$self->refresh_look;
		return $icon;
	}

	method focus () {
		my $ui = $self->ui // die ref($self) . ": the tab is not part of a Term::Fabulous, so nothing can focus it";
		$ui->interaction->set_focused_widget($self);
		return $self;
	}

	method layout_properties :common () {
		return ( $class->SUPER::layout_properties, title => 'scalar', icon => 'scalar' );
	}

	# The user activated the tab: the bar makes it the active one and fires
	# Select. A tab on its own does nothing.
	method _activated () {
		my $bar = $self->bar;
		$bar->_button_activated($self) if defined $bar;
		return;
	}

	# ---------------------------------------------------------------------
	# Look
	# ---------------------------------------------------------------------

	# One setting of the look: the bar's; without a bar, the default
	# setting, or the tabs look of the theme the tab draws with.
	method _look ($name) {
		my $bar = $self->bar;
		return $bar->$name if defined $bar;
		return $DEFAULT_LOOK{$name} if exists $DEFAULT_LOOK{$name};
		my %themed = Term::Fabulous::Widget::Tabs::Bar->themed_params;
		return $self->family_look( tabs => @{ $themed{$name} }[ 0, 1 ] );    # slot and state
	}

	# The tab's border and background follow the bar's colors and the
	# tab's state, read when the frame is built, so a theme switch shows
	# at once.
	method contribute_look_theme :override ($config) {
		my $border = $config->{border} // return;
		my $color
			= !$self->is_enabled ? $self->_look('disabled_color')
			: $self->is_focused  ? $self->_look('focus_border_color') // $self->_look('line_color')
			:                      $self->_look('line_color');
		$config->{border}           = { %$border, color => $color };
		$config->{background_color} = $self->_look('hover_background_color') if $self->is_enabled && !$_active && $self->is_hovered;
		return;
	}

	# A side without a style of its own is drawn in the line's style on
	# the three sides away from the page and not at all on the page's
	# side, read when the frame is drawn
	# (Term::Fabulous::Role::HasBorderStyle).
	method derived_border_style ($side) {
		return $side eq $PAGE_SIDE{ $self->_look('side') } ? Term::Fabulous::Enum::BorderStyle->Hidden : $self->_look('line_style');
	}

	# The labels are drawn in the bar's text colors.
	method child_text_color :override ($explicit) {
		return $self->_look( !$self->is_enabled ? 'disabled_color' : $_active ? 'active_text_color' : 'text_color' );
	}

	# A label as a Text shows it: as it is, or one cluster per line for a
	# vertical label.
	sub _label_text ( $text, $vertical ) {
		return $vertical ? join( "\n", grapheme_clusters($text) ) : $text;
	}

	# Updates the borders, the padding and the label from the tab's state
	# and the bar's settings. Called by the bar when they change.
	method refresh_look () {
		my $side      = $self->_look('side');
		my $vertical  = $self->_look('orientation') eq 'vertical';
		my $page_side = $PAGE_SIDE{$side};

		# The padding lies along the label; the active tab gets
		# active_padding cells more toward the page.
		my $padding = $self->_look('tab_padding');
		my %padding = $vertical ? ( top => $padding, bottom => $padding ) : ( left => $padding, right => $padding );
		$padding{$page_side} = ( $padding{$page_side} // 0 ) + $self->_look('active_padding') if $_active;
		$self->layout( { %{ $self->layout }, layout_direction => $vertical ? CLAY_TOP_TO_BOTTOM : CLAY_LEFT_TO_RIGHT, child_gap => 1, padding => \%padding } );

		my $wrap_mode = $vertical ? CLAY_TEXT_WRAP_NEWLINES : CLAY_TEXT_WRAP_NONE;
		$_title_text->text( _label_text( $title, $vertical ) );
		$_icon_text->text( _label_text( $icon // '', $vertical ) );
		foreach my $text ( $_icon_text, $_title_text ) {
			$text->wrap_mode($wrap_mode);
			$text->bold( $_active && $self->_look('active_bold') ? 1 : 0 );
		}
		$self->clear_children;
		$self->add_child( ( defined $icon ? $_icon_text : () ), $_title_text );
		return $self;
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Widget::Tabs::Button - The button of one tab in a tab
bar

=head1 SYNOPSIS

	use Term::Fabulous::Widget::Tabs::Bar;
	use Term::Fabulous::Widget::Tabs::Button;

	my $bar = Term::Fabulous::Widget::Tabs::Bar->new;
	$bar->add_child(
		Term::Fabulous::Widget::Tabs::Button->new( title => 'General' ),
		Term::Fabulous::Widget::Tabs::Button->new( title => 'Network', icon => "\x{2601}" ),
		Term::Fabulous::Widget::Tabs::Button->new( title => 'Licenses', disabled => 1 ),
	);

=head1 DESCRIPTION

A tab button is one tab of a L<Term::Fabulous::Widget::Tabs::Bar>: a
L<Term::Fabulous::Widget::Button> with a border on three sides, open
toward the page, that shows a title and an optional icon. The bar makes
one tab the I<active> one: it is open toward the page, so that it joins
the page's border. It has C<active_padding> more cells of padding on
that side than the other tabs, so it rises that far out of the row, and
its label is drawn in the C<active_text_color> of its bar or, without a
bar, of the theme it draws with. The other tabs are closed by the line
of the bar and show their labels in C<text_color>.

The look (the side the bar is on, whether the label is written
horizontally or downwards, the padding, the line style and the
colors) comes from the bar, see
L<Term::Fabulous::Widget::Tabs::Bar/CONSTRUCTOR>. As a Button, a tab
takes the focus (only the active tab does, see
L<Term::Fabulous::Widget::Tabs::Bar/KEYS>), reacts to clicks and
C<Enter> and C<Space>, shows the focus with its border color, the
pointer with C<hover_background_color> and can be disabled; a pressed
tab shows no pressed look.

A L<Term::Fabulous::Widget::Tabs> makes the tab buttons for its pages
itself; you create them only for a bar of your own.

=head1 CONSTRUCTOR

=head2 new

	my $tab = Term::Fabulous::Widget::Tabs::Button->new(%parameters);

Accepts the parameters of L<Term::Fabulous::Widget::Button/CONSTRUCTOR>
(C<id>, C<layout>, C<disabled>, C<can_focus>, ...), of which the
border, the padding, the layout direction, the colors and
C<pressed_background_color> are set by the look, and the ones below.
Unknown parameters die.

=over

=item C<title>

A character string. Default: C<''>. The text of the tab.

=item C<icon>

A character string, or C<undef>. Default: C<undef>. A short text, for
example a symbol, shown before the title with a cell between them;
above the title in a tab with a vertical label.

=back

=head1 METHODS

The methods of L<Term::Fabulous::Widget::Button> (C<disabled>,
C<is_enabled>, C<is_focused>, C<is_hovered>, C<activate>, ...), plus:

=head2 title

	$tab->title('Advanced');

Accessor for the title; the new text shows in the next frame.

=head2 icon

	$tab->icon("\x{2699}");
	$tab->icon(undef);

Accessor for the icon.

=head2 is_active

	if ( $tab->is_active ) { ... }

1 while the tab is the active one of its bar. The bar sets it: see
L<Term::Fabulous::Widget::Tabs::Bar/select>.

=head2 focus

	$tab->focus;

Gives the keyboard focus to the tab. Dies when the tab is not part of
a L<Term::Fabulous>, or cannot take the focus (an inactive or
disabled tab).

=head2 bar

	my $bar = $tab->bar;

The L<Term::Fabulous::Widget::Tabs::Bar> the tab is in, or C<undef>.

=head2 refresh_look

	$tab->refresh_look;

Updates the borders, the padding, the label and the colors from the
tab's state and the bar's settings. The bar calls it when its
settings change; call it yourself after changing the tab's look
behind its back. Returns the tab.

=head2 default_look

	my %look = Term::Fabulous::Widget::Tabs::Button->default_look;

Class method: the settings a tab uses outside a bar that are not
themed, as a hash (C<side>, C<orientation>, C<tab_padding>,
C<active_padding>, C<active_bold>) with their defaults; the line style
and the colors come from the C<tabs> family of the theme the tab draws
with.

=head1 EVENTS

A tab fires the events of a Button: C<Activate> for a click or
C<Enter> or C<Space>, C<OnFocus>, C<OnBlur>, C<OnHoverStart>, ... The
bar fires L<Term::Fabulous::Event::Select> when a tab is chosen.

=head1 KDL PROPERTIES

The properties of L<Term::Fabulous::Widget::Button/KDL PROPERTIES>,
plus C<title> and C<icon> (strings):

=for highlighter language=kdl

	use Term::Fabulous::Widget::Tabs::Button as Tab

	Tab "network" {
		title "Network"
		icon "#"
		disabled #true
	}

=head1 SEE ALSO

L<Term::Fabulous::Widget::Tabs::Bar>, L<Term::Fabulous::Widget::Tabs>,
L<Term::Fabulous::Widget::Button>,
L<Term::Fabulous::Manual::Layout/TABS>.

=cut
