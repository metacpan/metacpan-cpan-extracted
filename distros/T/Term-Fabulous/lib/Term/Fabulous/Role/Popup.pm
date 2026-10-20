package Term::Fabulous::Role::Popup;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.05';

use Object::Pad 0.825;

role Term::Fabulous::Role::Popup {
	use Clay::XS qw(CLAY_ATTACH_TO_ROOT CLAY_ATTACH_POINT_LEFT_TOP);

	# Where the popup goes in this frame, { x, y } on the screen, or undef
	# while that is not known (an anchor that was never laid out).
	method popup_position;

	field $_placed_at;    # the position the last layout used

	# Attaches a floating config to the root at the popup's position.
	# Positions come from the boxes of the frame before, which this frame
	# may change (an anchor that moves or grows, a popup laid out for the
	# first time), so after the frame the popup looks again and asks for
	# one more frame when it belongs elsewhere.
	method float_popup ($config) {
		$self->each_frame( sub ($popup) { $popup->_recheck_popup_position; return 1 }, name => 'popup position' );
		my $position = $self->popup_position // return;
		$_placed_at = $position;
		my $corner = CLAY_ATTACH_POINT_LEFT_TOP;
		$config->{floating} = { %{ $config->{floating} }, attach_to => CLAY_ATTACH_TO_ROOT, attach_points => { element => $corner, parent => $corner }, offset => {%$position} };
		return;
	}

	method _recheck_popup_position () {
		my $position = $self->popup_position // return;
		return if defined $_placed_at && $_placed_at->{x} == $position->{x} && $_placed_at->{y} == $position->{y};
		$self->mark_changed;
		return;
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Role::Popup - A floating widget that keeps its place on the screen

=head1 SYNOPSIS

	use Object::Pad;
	use Term::Fabulous::Placement qw(place_popup TOPMOST_Z_INDEX);

	class My::Tooltip
		:isa(Term::Fabulous::Widget::Display)
		:does(Term::Fabulous::Role::Popup)
	{
		use Term::Fabulous::Placement qw(place_popup);

		field $anchor :param :weak;

		# Below the anchor, or above it when there is no room below.
		method popup_position () {
			my $ui  = $self->ui                   // return undef;
			my $box = $ui->bounding_box($anchor) // return undef;
			my $place = place_popup( anchor => $box, size => [ 20, 3 ], screen => [ $ui->width, $ui->height ] );
			return { x => $place->{x}, y => $place->{y} };
		}

		method contribute_floating :override ($config) {
			$self->SUPER::contribute_floating($config);
			$self->float_popup($config) if defined $config->{floating};
			return;
		}
	}

	my $tip = My::Tooltip->new( anchor => $button, floating => { z_index => TOPMOST_Z_INDEX } );

=head1 DESCRIPTION

A role for floating widgets that float over everything at a position
they work out themselves (with L<Term::Fabulous::Placement>), from the
boxes the last frame laid out: the list of a
L<Term::Fabulous::Widget::Dropdown>, a L<Term::Fabulous::Widget::Menu>,
a table's column chooser
(L<Term::Fabulous::Widget::Table/open_column_chooser>). The widget calls
L</float_popup> from its C<contribute_floating>; the role attaches it to
the root at the position, and after each frame checks whether the frame
moved what the position depends on (an anchor that grew, a popup laid
out for the first time). If so, it marks the widget changed, and the
next frame puts it where it belongs. A popup therefore finds its place
within two frames of any change, and stays put while nothing changes.

A widget composing the role needs C<each_frame> and C<mark_changed>, as
every L<Term::Fabulous::Widget> has.

=head1 REQUIRED METHODS

=head2 popup_position

	my $position = $popup->popup_position;    # { x => 12, y => 3 }

Where the popup's top left corner goes in this frame, in screen cells,
or C<undef> while that is not known (its anchor has no box yet). Called
while the frame is laid out and after it is drawn.

=head1 PROVIDED METHODS

=head2 float_popup

	$self->float_popup($config);

For C<contribute_floating>: changes the C<floating> hash of C<$config>
to attach the widget to the root (both attach points at the left top
corner) with L</popup_position> as its offset, and keeps everything
else of it (the C<z_index>, for example). Without a position, the
floating hash stays as the widget declared it for this frame. Either
way, the position is checked again after the frame (see
L</DESCRIPTION>). C<$config> must have a C<floating> hash.

=head1 SEE ALSO

L<Term::Fabulous::Placement>, L<Term::Fabulous::Widget::Dropdown>,
L<Term::Fabulous::Widget::Menu>,
L<Term::Fabulous::Widget::Table/open_column_chooser>,
L<Term::Fabulous::Manual::Layout/Floating widgets>.

=cut
