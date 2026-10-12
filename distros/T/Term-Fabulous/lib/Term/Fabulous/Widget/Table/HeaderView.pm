package Term::Fabulous::Widget::Table::HeaderView;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.02';

use Object::Pad 0.825;

use Term::Fabulous::Widget::Box;

class Term::Fabulous::Widget::Table::HeaderView :isa(Term::Fabulous::Widget::Box) :strict(params) {
	use Scalar::Util qw(weaken);

	# The scroll container whose horizontal position the header follows.
	field $follows :param;

	ADJUST {
		die "Term::Fabulous::Widget::Table::HeaderView: follows must be a scroll container"
			unless defined $follows && $follows->DOES('Clay::UI::Role::Layout::HasScroll');
		weaken $follows;
	}

	# Clips the header at its own width and shifts it by the horizontal
	# scroll position the scroll container has in this frame (Clay has
	# applied the wheel before the layout starts).
	method contribute_clip ($config) {
		my $ui    = $self->ui;
		my $state = defined $ui && defined $follows ? $ui->scroll_state($follows) : undef;
		$config->{clip} = { horizontal => 1, vertical => 0, child_offset => { x => defined $state ? $state->{position}{x} : 0, y => 0 } };
		return;
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Widget::Table::HeaderView - The header of a table, scrolled sideways with its body

=head1 DESCRIPTION

The box around the header grid of a L<Term::Fabulous::Widget::Table>.
The body of a table scrolls up and down below the header, which stays;
sideways, the header has to move with the body. This box clips its
content to its own width and shifts it by the horizontal scroll position
of the scroll container it C<follows>, in the same frame. It is not a
scroll container itself, so the mouse wheel does not move it on its own.

=head1 SEE ALSO

L<Term::Fabulous::Widget::Table>.

=cut
