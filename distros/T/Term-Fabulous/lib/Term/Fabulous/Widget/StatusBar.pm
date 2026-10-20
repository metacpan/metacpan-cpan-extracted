package Term::Fabulous::Widget::StatusBar;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

use Term::Fabulous::Widget::Display;

our $VERSION = '0.05';

class Term::Fabulous::Widget::StatusBar
	:isa(Term::Fabulous::Widget::Display)
	:strict(params)
{
	use Clay::XS qw(sizing_grow);
	use IO::Async::Loop;
	use IO::Async::Timer::Countdown;
	use List::Util qw(max sum0);
	use Scalar::Util qw(weaken);
	use Term::Fabulous::Check qw(describe number one_of string);
	use Term::Fabulous::Unicode qw(fit_columns string_columns);

	use constant PART_GAP => 2;    # columns between two parts

	# The kinds of a message, and the kinds a part may have besides them,
	# each with the themed parameter that colors it.
	my %COLOR_OF_MESSAGE_KIND = ( info => 'text_color', success => 'success_color', warning => 'warning_color', danger => 'danger_color' );
	my %COLOR_OF_PART_KIND    = ( %COLOR_OF_MESSAGE_KIND, dim => 'dim_color', accent => 'accent_color' );

	field $message :param = '';
	field $kind    :param = 'info';
	field $timeout :param = undef;

	field $_parts;    # [ [ text, kind ], ... ], or a code reference that returns parts
	field @_shown_parts;    # the parts the next paint draws, read by paint_key
	field $_timer;

	ADJUST :params ( :$parts = [] ) {
		$message = _one_row( string( $self, message => $message ) );
		$kind    = one_of( $self, kind => $kind, keys %COLOR_OF_MESSAGE_KIND );
		$timeout = $self->_checked_timeout($timeout);
		$_parts  = $self->_checked_parts($parts);
	}

	method theme_family :common () {
		return 'status_bar';
	}

	method themed_params :common () {
		return (
			$class->SUPER::themed_params,
			text_color    => [ 'text',    'normal', 'cell_color' ],
			dim_color     => [ 'dim',     'normal', 'cell_color' ],
			accent_color  => [ 'accent',  'normal', 'cell_color' ],
			success_color => [ 'success', 'normal', 'cell_color' ],
			warning_color => [ 'warning', 'normal', 'cell_color' ],
			danger_color  => [ 'danger',  'normal', 'cell_color' ],
		);
	}

	method layout_properties :common () {
		return ( $class->SUPER::layout_properties, map { $_ => 'scalar' } qw(message kind timeout) );
	}

	# A status bar is one row: line breaks and runs of white space become
	# one space, and white space at the ends goes.
	sub _one_row ($text) {
		return $text =~ s/\s+/ /gr =~ s/\A | \z//gr;
	}

	method _checked_timeout ($seconds) {
		return undef unless defined $seconds;
		$seconds = number( $self, timeout => $seconds );
		die ref($self) . ": timeout must be positive, or undef for no timeout, got $seconds" unless $seconds > 0;
		return $seconds;
	}

	# The parts as given to new or parts: an array reference of parts, or
	# a code reference that returns them whenever a frame is drawn.
	method _checked_parts ($parts) {
		return $parts if ref $parts eq 'CODE';
		die ref($self) . ": parts must be an array reference or a code reference, got " . describe($parts) unless ref $parts eq 'ARRAY';
		return [ map { $self->_checked_part($_) } @$parts ];
	}

	# A part is a string, drawn like an info message, or [ text, kind ].
	method _checked_part ($part) {
		return [ _one_row($part), 'info' ] if defined $part && !ref $part;
		die ref($self) . ": a part must be a string or [ text, kind ], got " . describe($part) unless ref $part eq 'ARRAY' && @$part == 2;
		my ( $text, $part_kind ) = @$part;
		return [ _one_row( string( $self, 'the text of a part' => $text ) ), one_of( $self, 'the kind of a part' => $part_kind, keys %COLOR_OF_PART_KIND ) ];
	}

	# ---------------------------------------------------------------------
	# The message
	# ---------------------------------------------------------------------

	method message (@new) {
		return $message unless @new;
		my ( $text, $new_kind ) = @new;
		$text     = _one_row( string( $self, message => $text ) );
		$new_kind = one_of( $self, kind => $new_kind // 'info', keys %COLOR_OF_MESSAGE_KIND );
		if ( !length $text ) {
			$self->clear_message;
			return '';
		}
		( $message, $kind ) = ( $text, $new_kind );
		$self->_restart_timer;
		$self->mark_changed;
		return $message;
	}

	method kind (@new) {
		return $kind unless @new;
		$kind = one_of( $self, kind => $new[0], keys %COLOR_OF_MESSAGE_KIND );
		$self->mark_changed;
		return $kind;
	}

	method clear_message () {
		$self->_stop_timer;
		( $message, $kind ) = ( '', 'info' );
		$self->mark_changed;
		return $self;
	}

	method timeout (@new) {
		return $timeout unless @new;
		$timeout = $self->_checked_timeout( $new[0] );
		$self->_restart_timer if length $message;
		return $timeout;
	}

	# The timeout runs on the process-wide IO::Async loop, which run
	# drives; without a running loop (step in tests) the message stays.
	method _restart_timer () {
		$self->_stop_timer;
		return unless defined $timeout;
		weaken( my $weak_self = $self );
		$_timer = IO::Async::Timer::Countdown->new( delay => $timeout, remove_on_expire => 1, on_expire => sub { $weak_self->clear_message if $weak_self; return } );
		IO::Async::Loop->new->add($_timer);
		$_timer->start;
		return;
	}

	method _stop_timer () {
		return unless defined $_timer;
		$_timer->stop if $_timer->is_running;
		$_timer->remove_from_parent if defined $_timer->loop;
		$_timer = undef;
		return;
	}

	# Lets the timeout run out now, as the loop would: for tests.
	method expire () {
		return $self unless defined $_timer;
		return $self->clear_message;
	}

	# ---------------------------------------------------------------------
	# The parts on the right
	# ---------------------------------------------------------------------

	method parts (@new) {
		return ref $_parts eq 'CODE' ? $_parts : [ map { [@$_] } @$_parts ] unless @new;
		$_parts = $self->_checked_parts( $new[0] );
		$self->mark_changed;
		return $self->parts;
	}

	# The parts to draw now, checked: a code reference is called.
	method current_parts () {
		return map { [@$_] } @$_parts unless ref $_parts eq 'CODE';
		return map { $self->_checked_part($_) } $_parts->();
	}

	# ---------------------------------------------------------------------
	# Colors
	# ---------------------------------------------------------------------

	method text_color    (@new) { return @new ? $self->set_look( text_color    => $new[0] ) : $self->look_value('text_color') }
	method dim_color     (@new) { return @new ? $self->set_look( dim_color     => $new[0] ) : $self->look_value('dim_color') }
	method accent_color  (@new) { return @new ? $self->set_look( accent_color  => $new[0] ) : $self->look_value('accent_color') }
	method success_color (@new) { return @new ? $self->set_look( success_color => $new[0] ) : $self->look_value('success_color') }
	method warning_color (@new) { return @new ? $self->set_look( warning_color => $new[0] ) : $self->look_value('warning_color') }
	method danger_color  (@new) { return @new ? $self->set_look( danger_color  => $new[0] ) : $self->look_value('danger_color') }

	method _attr_of_kind ($part_kind) {
		return $self->color_attr( $self->look_value( $COLOR_OF_PART_KIND{$part_kind} ) );
	}

	# ---------------------------------------------------------------------
	# Painting
	# ---------------------------------------------------------------------

	method natural_size () {
		return ( sizing_grow(), 1 );
	}

	# The parts are read here, once per frame, and painted from what was
	# read.
	method paint_key :override () {
		@_shown_parts = $self->current_parts;
		return ( $self->SUPER::paint_key, $message, $kind, map { @$_ } @_shown_parts );
	}

	# The message from the left, a column in; the parts against the right
	# edge, a column in, with a gap between them. A message that runs into
	# the parts is cut and ends in an ellipsis.
	method paint () {
		my $columns     = $self->columns;
		my $parts_width = sum0( map { string_columns( $_->[0] ) } @_shown_parts ) + PART_GAP * max( 0, $#_shown_parts );
		my $parts_start = max( 1, $columns - 1 - $parts_width );
		my $x           = $parts_start;
		foreach my $part (@_shown_parts) {
			$x = $self->paint_text( $x, 0, $part->[0], $self->_attr_of_kind( $part->[1] ), undef, $columns - 1 ) + PART_GAP;
		}
		my $room = ( @_shown_parts ? $parts_start - PART_GAP : $columns - 1 ) - 1;
		$self->paint_text( 1, 0, fit_columns( $message, $room ), $self->_attr_of_kind($kind), undef );
		return;
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Widget::StatusBar - A row at the bottom of the screen
for messages and the program's state

=head1 SYNOPSIS

	use Term::Fabulous::Widget::StatusBar;

	my $status = Term::Fabulous::Widget::StatusBar->new(
		message => 'Ready.',
		parts   => sub { ( [ "Line $line", 'info' ], [ 'F1 help', 'dim' ] ) },
		timeout => 5,
	);
	$root->add_child( $content, $status );

	# Later, from a key binding or a timer:
	$status->message( 'Saved notes.txt.', 'success' );
	$status->message( 'The disk is full.', 'danger' );

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.05/screenshots/widget-status-bar.svg" alt="A list of files with the cursor on budget.csv and, at the bottom, a status bar with the green message Saved budget.csv. and the parts file 3 of 6 and Ctrl+C quits. Above the list, status bars with a success message, a yellow warning with a blue modified part, and a red error with a red read-only part"></p>

=end html

The program is F<examples/widgets/status-bar.pl>. Its status bar at
the bottom shows what the keys do until a key shows a message, and the
position of the cursor on the right. The three bars above the list show
a success, a warning and a danger message.

=head1 DESCRIPTION

A status bar is a single row, usually the last one of the screen. Its
left side shows a message: what just happened, or what a key does now.
Its right side shows I<parts>, short texts about the program's state,
such as the position of the cursor, whether a file has unsaved
changes, or a reminder of a key.

A message has a I<kind>, which decides its color: C<info> for plain
news, C<success> when something worked, C<warning> when something needs
attention, and C<danger> when something failed. These are the kinds a
L<Term::Fabulous::Widget::Toast> has. A part has one of these kinds as
well, or C<dim> for a hint that should not draw the eye, or C<accent>
for one that should.

A message stays until the program shows another one or calls
L</clear_message>. With a L</timeout>, every message goes away by itself after
that many seconds.

When the message and the parts do not fit next to each other, the
parts win: the message is cut where it would run into them and ends in
an ellipsis (E<hellip>). A status bar has no line breaks, so line
breaks and runs of white space in a message or a part become a single
space.

A status bar takes no input. It grows to the width of its parent and is
one row high (see L<Term::Fabulous::Widget::Display/Size>).

=head1 CONSTRUCTOR

=head2 new

=for highlighter language=perl

	my $status = Term::Fabulous::Widget::StatusBar->new(%parameters);

Accepts the parameters of L<Term::Fabulous::Widget::Box/CONSTRUCTOR>
(C<id>, C<layout>, C<background_color>, ...) and the ones below. All
are optional, and unknown parameters die.

=over

=item C<message>

The message the bar starts with, a character string. Default: C<''>,
no message. The timeout does not apply to it: it stays until the
program changes it.

=item C<kind>

The kind of that message: C<info> (the default), C<success>,
C<warning> or C<danger>. Anything else dies.

=item C<parts>

What the right side shows. Either an array reference of parts, or a
code reference that returns a list of parts. Default: C<[]>, no parts.

A part is a string, which is drawn like an C<info> message, or an array
reference C<[ $text, $kind ]> whose kind is one of the message kinds,
C<dim> or C<accent>. The parts are drawn from left to right with two
columns between them, and the last one ends a column before the right
edge. Anything else dies, when it is given and, for a code reference,
when the parts it returned are drawn.

A code reference is called whenever a frame is drawn, so the parts
always show the program's state without being set again. It is not a
timer, though: a frame is drawn when something happens (a key, the
mouse, a change of a widget), so a part that shows the time of day
needs a timer that makes a frame due (see
L<Term::Fabulous/request_frame_at>).

=item C<timeout>

A positive number of seconds, or C<undef> (the default). With a
timeout, each message that L</message> shows goes away by itself after
that many seconds, and the bar is empty again until the next one. The
timer runs on the L<IO::Async> loop that L<Term::Fabulous/run> drives.

=item C<text_color>, C<dim_color>, C<accent_color>, C<success_color>, C<warning_color>, C<danger_color>

The colors of the kinds, in any format
L<Term::Fabulous::Widget::Canvas/Colors> accepts. A message or a part
of the kind C<info> is drawn in C<text_color>, every other kind in the
color of its name. Default: the theme's C<status_bar.text>,
C<status_bar.dim>, C<status_bar.accent>, C<status_bar.success>,
C<status_bar.warning> and C<status_bar.danger>. In the dark theme
these are the text color, a gray, a blue, a green, a yellow and a red.

=item C<background_color>

As for every widget. Default: the theme's C<status_bar.background>,
C<surface_low> in the built-in themes, which sets the bar apart from
the screen.

=back

=head1 METHODS

The methods of L<Term::Fabulous::Widget::Display> (C<mark_changed>, the
Box and Canvas methods), plus these. The accessors work like those of
the other widgets. Without an argument they return the current value.
With one they set the value, checked as C<new> checks it, mark the bar
changed, so the next frame paints it, and return the new value. An
invalid value dies and leaves the old one.

=head2 message

	my $text = $status->message;
	$status->message('Opened notes.txt.');
	$status->message( 'Could not write notes.txt: Permission denied.', 'danger' );

Without an argument, returns the message shown now (C<''> when there is
none). With a text and an optional kind (C<info> by default), shows
that message instead of the one before, starts the timeout again when
there is one, and returns the text as it is shown. An empty text
removes the message, like L</clear_message>.

=head2 kind

	$status->kind('warning');

The kind of the message shown now. Writing it recolors the message and
keeps its text.

=head2 clear_message

	$status->clear_message;

Removes the message, and stops its timeout. Returns the status bar.

=head2 parts

	$status->parts( [ 'UTF-8', [ 'modified', 'accent' ] ] );
	$status->parts( sub { [ $mode, 'info' ] } );

The parts of the right side, as described under L</new>. Reading it
returns the parts as C<[ $text, $kind ]> pairs (a string part reads
back as C<[ $text, 'info' ]>), or the code reference.

=head2 current_parts

	my @parts = $status->current_parts;

The parts the bar shows now, as a list of C<[ $text, $kind ]> pairs.
For a code reference, it calls it.

=head2 timeout

	$status->timeout(3);
	$status->timeout(undef);    # messages stay

Writing it starts the timeout of the message shown now again.

=head2 expire

	$status->expire;

Lets the timeout of the message shown now run out at once, as the loop
would when the time is up. For tests that drive the UI with
L<Term::Fabulous/step>, which runs no timers. Does nothing when no
timeout is running. Returns the status bar.

=head2 text_color, dim_color, accent_color, success_color, warning_color, danger_color

	$status->success_color('#98c379');
	$status->reset_look('success_color');    # back to the theme

The readers return C<[r, g, b, a]>.

=head1 EVENTS

A status bar fires no events of its own.

=head1 KDL PROPERTIES

The properties of L<Term::Fabulous::Widget::Box/KDL PROPERTIES>, plus
C<message> and C<kind> (strings), C<timeout> (a number), and the six
colors (color strings). The parts can only be set from Perl:

=for highlighter language=kdl

	use Term::Fabulous::Widget::StatusBar as StatusBar

	StatusBar "status" {
		message "Ready."
		timeout 5
	}

=for highlighter language=perl

	my $status = $root->find_by_id('status');
	$status->parts( sub { [ $mode, 'info' ] } );

=head1 SEE ALSO

L<Term::Fabulous::Manual::Feedback/STATUS BARS>,
L<Term::Fabulous::Cookbook::Menus/Show messages and state in a status bar (StatusBar)>,
L<Term::Fabulous::Widget::Toast> for messages that float over the
screen, L<Term::Fabulous::Widget::Display>.

=cut
