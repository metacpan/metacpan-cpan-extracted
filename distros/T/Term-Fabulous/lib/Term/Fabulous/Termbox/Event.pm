package Term::Fabulous::Termbox::Event;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.02';

use Object::Pad 0.825;

class Term::Fabulous::Termbox::Event :strict(params) {
	field $type :param :accessor = 0;
	field $mod  :param :accessor = 0;
	field $key  :param :accessor = 0;
	field $ch   :param :accessor = 0;
	field $w    :param :accessor = 0;
	field $h    :param :accessor = 0;
	field $x    :param :accessor = 0;
	field $y    :param :accessor = 0;
}

1;

__END__

=head1 NAME

Term::Fabulous::Termbox::Event - One termbox2 input event

=head1 SYNOPSIS

	use Term::Fabulous::Termbox qw(tb_peek_event TB_OK TB_EVENT_KEY TB_EVENT_MOUSE TB_KEY_MOUSE_LEFT);
	use Term::Fabulous::Termbox::Event;

	my $event = Term::Fabulous::Termbox::Event->new;
	if ( tb_peek_event( $event, 0 ) == TB_OK && $event->type == TB_EVENT_KEY ) {
		printf "key %d char %d modifiers %d\n", $event->key, $event->ch, $event->mod;
	}

	# Tests build events by hand:
	my $click = Term::Fabulous::Termbox::Event->new( type => TB_EVENT_MOUSE, key => TB_KEY_MOUSE_LEFT, x => 3, y => 1 );

=head1 DESCRIPTION

The Perl side of termbox2's C<struct tb_event>.
L<C<tb_peek_event>|Term::Fabulous::Termbox/tb_peek_event> and
L<C<tb_poll_event>|Term::Fabulous::Termbox/tb_poll_event> fill an instance in place;
L<Term::Fabulous::Event::KeyPress>, L<Term::Fabulous::Event::Mouse> and
L<Term::Fabulous::Event::Resize> build their events from one.

=head1 CONSTRUCTOR

=head2 new

	my $event = Term::Fabulous::Termbox::Event->new(%fields);

Every field is optional and defaults to 0. Unknown names die.

=head1 FIELDS

Each field has a combined accessor: without an argument it returns the
value, with one it sets it.

=over

=item C<type>

One of C<TB_EVENT_KEY>, C<TB_EVENT_RESIZE>, C<TB_EVENT_MOUSE>.

=item C<mod>

Bitwise C<TB_MOD_*> modifiers, and the C<TF_MOD_SUPER>,
C<TF_MOD_HYPER> and C<TF_MOD_META> of the kitty keyboard protocol.

=item C<key>

A C<TB_KEY_*> or C<TF_KEY_*> code, 0 for a printable character.

=item C<ch>

The Unicode codepoint of a printable character, 0 for a special key.
With the kitty keyboard protocol it also holds the key of a Ctrl
combination the legacy encoding cannot carry, such as Ctrl+Enter or
Ctrl+I (see L<Term::Fabulous::Termbox/tf_install_input_parser>). For
a C<TB_KEY_MOUSE_RELEASE>, it names the released button
(C<TB_KEY_MOUSE_LEFT>, C<TB_KEY_MOUSE_MIDDLE> or C<TB_KEY_MOUSE_RIGHT>),
or is 0 when the terminal did not say.

=item C<w>, C<h>

The new terminal size of a resize event.

=item C<x>, C<y>

The cell of a mouse event.

=back

=head1 SEE ALSO

L<Term::Fabulous::Termbox>, L<Term::Fabulous>.

=head1 AUTHOR

davenonymous <perl@davenonymous.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
