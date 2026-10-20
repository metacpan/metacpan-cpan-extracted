package Term::Fabulous::Command;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.05';

use Object::Pad 0.825;

class Term::Fabulous::Command :strict(params) {
	use Feature::Compat::Try;
	use Term::Fabulous::Check qw(describe string);
	use Term::Fabulous::Event::KeyPress;

	field $id      :param :reader;
	field $label   :param :reader;
	field $run     :param = undef;
	field $enabled :param = undef;
	field $checked :param = undef;
	field @keys;

	ADJUST :params ( :$keys = [] ) {
		$id = string( $self, id => $id );
		die "Term::Fabulous::Command: id must not be empty" unless length $id;
		$label = string( $self, "the label of the command '$id'" => $label );
		my %code = ( run => $run, enabled => $enabled, checked => $checked );
		foreach my $name ( sort keys %code ) {
			die "Term::Fabulous::Command: $name of the command '$id' must be a code reference or undef, got " . describe( $code{$name} ) if defined $code{$name} && ref $code{$name} ne 'CODE';
		}
		die "Term::Fabulous::Command: keys of the command '$id' must be an array reference, got " . describe($keys) unless ref $keys eq 'ARRAY';
		@keys = map { $self->_checked_key($_) } @$keys;
	}

	# A key name as Term::Fabulous::Event::KeyPress->key_name gives it;
	# anything else dies here, not when the key never fires.
	method _checked_key ($name) {
		try {
			Term::Fabulous::Event::KeyPress->fields_for_name($name);
		}
		catch ($error) {
			chomp $error;
			die "Term::Fabulous::Command: the command '$id' has a key that does not exist: $error";
		}
		return $name;
	}

	method keys () {
		return @keys;
	}

	# The label where the command is named outside a menu: without the
	# "..." that says it opens a dialog.
	method plain_label () {
		return $label =~ s/\.\.\.\z//r;
	}

	# The keys as a menu shows them.
	method keys_text () {
		return join ', ', @keys;
	}

	method is_enabled () {
		return !defined $enabled || $enabled->() ? 1 : 0;
	}

	method is_toggle () {
		return defined $checked ? 1 : 0;
	}

	method is_checked () {
		return defined $checked && $checked->() ? 1 : 0;
	}

	# Runs the command when it is enabled; returns whether it ran.
	method run () {
		return 0 unless $self->is_enabled;
		$run->() if defined $run;
		return 1;
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Command - Something the user can do, with a name and
keys

=head1 SYNOPSIS

	use Term::Fabulous::Command;

	my $save = Term::Fabulous::Command->new(
		id      => 'save',
		label   => 'Save',
		keys    => ['Ctrl+S'],
		run     => sub { save_file() },
		enabled => sub { $document->is_modified },
	);

	my $wrap = Term::Fabulous::Command->new(
		id      => 'wrap',
		label   => 'Wrap long lines',
		keys    => ['Alt+Z'],
		run     => sub { $wrap_lines = !$wrap_lines },
		checked => sub { $wrap_lines },
	);

	$save->run if $save->is_enabled;

=head1 DESCRIPTION

A command is one thing a program lets the user do: save a file, quit,
switch a setting on or off. It has an id for the program, a label for
the user, the keys that run it, and the code that does it.

Commands are usually kept in a L<Term::Fabulous::Commands> table, which
runs them when their keys are pressed, and shown in a
L<Term::Fabulous::Widget::MenuBar> or a L<Term::Fabulous::Widget::Menu>,
which run them when they are chosen. Because the menus and the keys use
the same command, they always agree: the menu shows the keys that work,
and a command that cannot run now is disabled in the menu and does
nothing when its key is pressed.

A command may be I<enabled> only at times, for example Save only while
there are unsaved changes, and it may be a I<toggle>, a setting that is
on or off, which a menu shows with a check mark. Both are decided by
code that the command calls whenever it needs to know, so the command
always follows the program's state without being told.

See L<Term::Fabulous::Manual::Menus> for how commands, keys and menus
work together.

=head1 CONSTRUCTOR

=head2 new

	my $command = Term::Fabulous::Command->new(%parameters);

Unknown parameters die.

=over

=item C<id>

A non-empty string that names the command. Required. Menus and the
L<Term::Fabulous::Commands> table refer to the command by it.

=item C<label>

What a menu shows, a string. Required. End it with three dots
(C<Save as...>) when the command asks for more before it does
anything, as is the custom in menus. L</plain_label> gives the label
without them.

=item C<keys>

An array reference of key names, as
L<Term::Fabulous::Event::KeyPress/key_name> gives them: C<'Ctrl+S'>,
C<'F5'>, C<'Alt+Left'>. Default: C<[]>, no keys. A name that is not a
key dies, naming the command. A menu shows the keys after the label.

=item C<run>

A code reference that does what the command does. It is called without
arguments. Default: C<undef>, nothing. A command without C<run> is
still useful in a menu whose C<Choose> event the program handles
itself.

=item C<enabled>

A code reference that returns whether the command can run now.
Default: C<undef>, always.

=item C<checked>

A code reference that returns whether the setting the command switches
is on. Default: C<undef>, the command is no toggle. With it, a menu
draws a check mark in front of the label while the code returns true.
Running the command does not switch anything by itself: C<run> does
that.

=back

=head1 METHODS

=head2 id, label

	say $command->label;

The parameters of the same names.

=head2 plain_label

	say $command->plain_label;    # "Save as" for the label "Save as..."

The label without a trailing C<...>, for the places that name the
command outside a menu (a key reference, a status message; see
L<Term::Fabulous::Widget::KeyReference/command_rows>). Menus show
L</label>, whose C<...> says that the command opens a dialog.

=head2 keys

	my @keys = $command->keys;

The key names, in the order given.

=head2 keys_text

	say $command->keys_text;    # "Ctrl+S, F2"

The key names as a menu shows them, joined with commas, or C<''>
without keys.

=head2 is_enabled

	if ( $command->is_enabled ) { ... }

1 when the command can run now, 0 when not. Asks C<enabled> each time.

=head2 is_toggle

1 when the command has a C<checked> code reference, 0 when not.

=head2 is_checked

1 while the command's setting is on, 0 while it is off or the command
is no toggle. Asks C<checked> each time.

=head2 run

	$command->run or $status->message('Nothing to save.');

Runs the command when it is enabled, and returns 1. Returns 0 and does
nothing when it is disabled.

=head1 SEE ALSO

L<Term::Fabulous::Commands>, L<Term::Fabulous::Widget::Menu>,
L<Term::Fabulous::Widget::MenuBar>, L<Term::Fabulous::Manual::Menus>.

=cut
