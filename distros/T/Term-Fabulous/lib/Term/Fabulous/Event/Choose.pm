package Term::Fabulous::Event::Choose;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.03';

use Object::Pad 0.825;

use Clay::UI::Events::Event;

class Term::Fabulous::Event::Choose :isa(Clay::UI::Events::Event) :strict(params) {
	use Scalar::Util qw(blessed);
	use Term::Fabulous::Check qw(describe non_negative_integer);

	field $command :param :reader;
	field $index   :param :reader;

	ADJUST {
		die "Term::Fabulous::Event::Choose: command must be a Term::Fabulous::Command, got " . describe($command) unless blessed $command && $command->isa('Term::Fabulous::Command');
		$index = non_negative_integer( $self, index => $index );
	}

	method event_name :common { 'Choose' }
}

1;

__END__

=head1 NAME

Term::Fabulous::Event::Choose - The user chose an item of a menu

=head1 SYNOPSIS

	$menu->on( Choose => sub ($event) {
		$status->message( 'Chose ' . $event->command->label );
		return;
	} );

=head1 DESCRIPTION

A L<Term::Fabulous::Widget::Menu> fires C<Choose> on itself when the
user chooses one of its items: with C<Enter> or C<Space> on the
highlighted item, or with a click on it. A disabled item cannot be
chosen and fires nothing.

The order is always the same, so a listener and the command can rely
on it: a menu that was opened as a popup closes first and gives the
focus back, then C<Choose> fires, and then the command of the item
runs. A command that opens a dialog therefore finds the focus where
the user left it, and the dialog gives it back there when it closes.

The event bubbles from the menu up through its ancestors. A menu of a
L<Term::Fabulous::Widget::MenuBar> is a child of the bar, so a listener
on the bar or above it hears about every menu of the bar. A popup menu
has left the widget tree when it fires, so listen on the menu itself.

It is a L<Clay::UI::Events::Event> whose name is C<Choose>.

=head1 CONSTRUCTOR

=head2 new

	my $event = Term::Fabulous::Event::Choose->new( command => $command, index => 2 );

Both parameters are required, and unknown parameters die. The C<name>
and C<bubble_mode> parameters of L<Clay::UI::Events::Event> are
accepted.

=head1 METHODS

=head2 command

	my $id = $event->command->id;

The L<Term::Fabulous::Command> of the chosen item. For an item that was
given as a hash reference, the menu made the command from it, and its
id is the C<id> of the hash, or else its label.

=head2 index

The position of the item in the menu, from 0, separators counted.

=head1 SEE ALSO

L<Term::Fabulous::Widget::Menu>, L<Term::Fabulous::Widget::MenuBar>,
L<Term::Fabulous::Command>, L<Clay::UI::Events::Event>.

=cut
