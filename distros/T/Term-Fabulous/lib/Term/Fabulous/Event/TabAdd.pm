package Term::Fabulous::Event::TabAdd;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.03';

use Object::Pad 0.825;

use Clay::UI::Events::Event;

class Term::Fabulous::Event::TabAdd :isa(Clay::UI::Events::Event) :strict(params) {
	method event_name :common { 'TabAdd' }
}

1;

__END__

=head1 NAME

Term::Fabulous::Event::TabAdd - The user asked for a new document tab

=head1 SYNOPSIS

	$tabs->on( TabAdd => sub ($event) {
		push @documents, new_document();
		$tabs->active($#documents);
		return;
	} );

=head1 DESCRIPTION

A L<Term::Fabulous::Widget::DocumentTabs> fires C<TabAdd> on itself
when the user clicks the C<+> button at the end of its tabs. The tabs
add nothing themselves: the program makes the new document, adds its
tab to the list it gave the tabs (or to what its code reference
returns) and usually makes it the active one.

The event has no fields of its own; C<< $event->target >> is the
DocumentTabs. It is a L<Clay::UI::Events::Event> whose name is
C<TabAdd>, and it bubbles to the widget's ancestors like every event.

=head1 CONSTRUCTOR

=head2 new

	my $event = Term::Fabulous::Event::TabAdd->new;

Unknown parameters die. The C<name> and C<bubble_mode> parameters of
L<Clay::UI::Events::Event> are accepted.

=head1 SEE ALSO

L<Term::Fabulous::Widget::DocumentTabs>, L<Term::Fabulous::Event::TabClose>,
L<Clay::UI::Events::Event>.

=cut
