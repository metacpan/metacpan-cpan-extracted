package Term::Fabulous::Widget::Toast::Stack;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

use Term::Fabulous::Widget::Box;

our $VERSION = '0.02';

class Term::Fabulous::Widget::Toast::Stack
	:isa(Term::Fabulous::Widget::Box)
	:strict(params)
{
	use Term::Fabulous::Check qw(one_of);
	use Clay::XS qw(
		CLAY_ATTACH_TO_ROOT CLAY_TOP_TO_BOTTOM
		CLAY_ATTACH_POINT_LEFT_TOP CLAY_ATTACH_POINT_CENTER_TOP CLAY_ATTACH_POINT_RIGHT_TOP
		CLAY_ATTACH_POINT_LEFT_BOTTOM CLAY_ATTACH_POINT_CENTER_BOTTOM CLAY_ATTACH_POINT_RIGHT_BOTTOM
	);

	my %ATTACH_POINT_OF_POSITION = (
		top_left      => CLAY_ATTACH_POINT_LEFT_TOP,
		top_center    => CLAY_ATTACH_POINT_CENTER_TOP,
		top_right     => CLAY_ATTACH_POINT_RIGHT_TOP,
		bottom_left   => CLAY_ATTACH_POINT_LEFT_BOTTOM,
		bottom_center => CLAY_ATTACH_POINT_CENTER_BOTTOM,
		bottom_right  => CLAY_ATTACH_POINT_RIGHT_BOTTOM,
	);

	field $position :param :reader;
	field $z_index  :param;
	field $margin   :param;

	ADJUST {
		one_of( $self, position => $position, keys %ATTACH_POINT_OF_POSITION );
		my $point = $ATTACH_POINT_OF_POSITION{$position};
		my ( $vertical, $horizontal ) = split /_/, $position;
		$self->floating(
			{
				attach_to     => CLAY_ATTACH_TO_ROOT,
				attach_points => { element => $point, parent => $point },
				offset        => {
					x => $horizontal eq 'left' ? $margin : $horizontal eq 'right' ? -$margin : 0,
					y => $vertical eq 'top' ? $margin : -$margin,
				},
				z_index => $z_index,
			}
		);
		$self->layout( { layout_direction => CLAY_TOP_TO_BOTTOM, child_gap => 1 } );
	}

	method positions :common () {
		my @positions = sort keys %ATTACH_POINT_OF_POSITION;
		return @positions;
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Widget::Toast::Stack - The column of toasts in one
corner of the screen

=head1 SYNOPSIS

	# Created by Term::Fabulous::Widget::Toast->show; not used directly.
	my @corners = Term::Fabulous::Widget::Toast::Stack->positions;

=head1 DESCRIPTION

Used internally by L<Term::Fabulous::Widget::Toast>. When a toast is
shown, it is added to the stack of its C<position>: a
L<Term::Fabulous::Widget::Box> floating over the root widget, attached
to that corner (or edge center) of the screen, that lists its toasts
top to bottom with a row between them, newest last. The stack is
created when the first toast of a position is shown and removed when
its last toast hides. A stack neither takes the focus nor paints
anything of its own.

=head1 CONSTRUCTOR

=head2 new

	my $stack = Term::Fabulous::Widget::Toast::Stack->new( position => 'top_right', z_index => 2000, margin => 1 );

All three parameters are required: the C<position> (one of
L</positions>), the C<z_index> of the floating box and the C<margin>,
the cells between the stack and the edges of the screen.

=head1 METHODS

=head2 position

The stack's position.

=head2 positions

	my @names = Term::Fabulous::Widget::Toast::Stack->positions;

A class method: C<bottom_center>, C<bottom_left>, C<bottom_right>,
C<top_center>, C<top_left> and C<top_right>.

=head1 SEE ALSO

L<Term::Fabulous::Widget::Toast>.

=cut
