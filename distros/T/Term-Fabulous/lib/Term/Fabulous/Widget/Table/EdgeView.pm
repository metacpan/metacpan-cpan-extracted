package Term::Fabulous::Widget::Table::EdgeView;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.05';

use Object::Pad 0.825;

use Term::Fabulous::Widget::Box;

class Term::Fabulous::Widget::Table::EdgeView :isa(Term::Fabulous::Widget::Box) :strict(params) {
	use Scalar::Util qw(weaken);

	# The scroll container whose horizontal position the view follows.
	field $follows :param;

	ADJUST {
		die "Term::Fabulous::Widget::Table::EdgeView: follows must be a scroll container"
			unless defined $follows && $follows->DOES('Clay::UI::Role::Layout::HasScroll');
		weaken $follows;
	}

	# While the scroll container scrolls sideways, clips the view at its
	# own width and shifts it by the horizontal scroll position the
	# container has in this frame (Clay has applied the wheel before the
	# layout starts). Otherwise the view is not clipped either, so that
	# Clay squeezes its columns as it squeezes the body's.
	method contribute_clip ($config) {
		my $ui       = $self->ui;
		my $sideways = defined $follows && $follows->horizontal ? 1                           : 0;
		my $state    = $sideways        && defined $ui          ? $ui->scroll_state($follows) : undef;
		$config->{clip} = { horizontal => $sideways, vertical => 0, child_offset => { x => defined $state ? $state->{position}{x} : 0, y => 0 } };
		return;
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Widget::Table::EdgeView - The header and the footer of a table, scrolled sideways with its body

=head1 DESCRIPTION

The box around the header grid and the one around the footer grid of a
L<Term::Fabulous::Widget::Table>. The body of a table scrolls up and
down between its header and its footer, which stay; sideways, both
have to move with the body. This box clips its content to its own
width and shifts it by the horizontal scroll position of the scroll
container it C<follows>, in the same frame, while that container
scrolls sideways; otherwise it does not clip its content either, so
that Clay narrows the columns of the header and the footer along with
the body's. It is not a scroll container itself, so the mouse wheel
does not move it on its own.

=head1 SEE ALSO

L<Term::Fabulous::Widget::Table>.

=cut
