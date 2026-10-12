package Term::Fabulous::Commands;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.02';

use Object::Pad 0.825;

use Term::Fabulous::Command;

class Term::Fabulous::Commands :strict(params) {
	use Clay::UI::Enum::Result;
	use Scalar::Util qw(blessed);
	use Term::Fabulous::Check qw(describe);

	field @_order;    # the commands, in the order they were added
	field %_by_id;
	field %_by_key;

	ADJUST :params ( :$commands = [] ) {
		die "Term::Fabulous::Commands: commands must be an array reference, got " . describe($commands) unless ref $commands eq 'ARRAY';
		$self->add(@$commands);
	}

	# Adds commands, each a Term::Fabulous::Command or the hash reference
	# of its parameters: all of them, or none when one has an id or a key
	# that is taken already.
	method add (@items) {
		my @commands  = map { $self->_parsed_command($_) } @items;
		my %id_taken  = %_by_id;
		my %key_taken = %_by_key;
		foreach my $command (@commands) {
			my $id = $command->id;
			die "Term::Fabulous::Commands: there is a command '$id' already" if exists $id_taken{$id};
			$id_taken{$id} = $command;
			foreach my $key ( $command->keys ) {
				die "Term::Fabulous::Commands: the key $key of the command '$id' runs the command '" . $key_taken{$key}->id . "' already" if exists $key_taken{$key};
				$key_taken{$key} = $command;
			}
		}
		push @_order, @commands;
		%_by_id  = %id_taken;
		%_by_key = %key_taken;
		return $self;
	}

	method _parsed_command ($item) {
		return $item if blessed $item && $item->isa('Term::Fabulous::Command');
		return Term::Fabulous::Command->new(%$item) if ref $item eq 'HASH';
		die "Term::Fabulous::Commands: a command must be a Term::Fabulous::Command or a hash reference of its parameters, got " . describe($item);
	}

	method command ($id) {
		return $_by_id{$id} // die "Term::Fabulous::Commands: there is no command " . describe($id);
	}

	method commands () {
		return @_order;
	}

	method command_for_key ($name) {
		return defined $name ? $_by_key{$name} : undef;
	}

	# Runs the command of a key press, when there is one and it is
	# enabled; returns whether it ran. The key's name is tried first,
	# then the name of the main key it stands for (a key of the number
	# pad).
	method handle_key ($event) {
		my $command = $self->command_for_key( $event->key_name ) // $self->command_for_key( $event->main_key_name ) // return 0;
		return $command->run;
	}

	# Runs commands for the keys that reach a widget: on the root, every
	# key no other widget used.
	method listen ($widget) {
		die "Term::Fabulous::Commands: listen needs a widget that fires events, got " . describe($widget) unless blessed $widget && $widget->can('on');
		$widget->on( KeyPress => sub ($event) { return $self->handle_key($event) ? Clay::UI::Enum::Result->HANDLED : Clay::UI::Enum::Result->CONTINUE } );
		return $self;
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Commands - The commands of a program, and the keys
that run them

=head1 SYNOPSIS

	use Term::Fabulous::Commands;

	my $commands = Term::Fabulous::Commands->new(
		commands => [
			{ id => 'save', label => 'Save', keys => ['Ctrl+S'], run => sub { save_file() }, enabled => sub { $modified } },
			{ id => 'quit', label => 'Quit', keys => ['Ctrl+Q'], run => sub { $ui->loop->stop } },
		],
	);
	$commands->add( { id => 'help', label => 'Help', keys => ['F1'], run => sub { show_help() } } );

	# Every key that no widget uses reaches the root, and runs its command:
	$commands->listen($root);

	# The same commands in a menu bar:
	my $menu_bar = Term::Fabulous::Widget::MenuBar->new(
		commands => $commands,
		menus    => [ { title => 'File', items => [ 'save', '-', 'quit' ] } ],
	);

=head1 DESCRIPTION

A program that has more than a few keys keeps them in one place: a
table of L<Term::Fabulous::Command> objects, each with its id, its
label, its keys and its code. The table runs a command when one of its
keys is pressed, and the menus of a L<Term::Fabulous::Widget::MenuBar>
or a L<Term::Fabulous::Widget::Menu> show the same commands, with their
keys, by id.

The table makes sure that a key runs one command only: a key that two
commands claim dies when the second one is added, so a conflict shows
up when the program starts, not when the user wonders why a key does
the wrong thing.

=head2 Where the keys come from

A key press goes to the widget that has the focus and then bubbles up
to the root (see L<Term::Fabulous::Manual::Events/Return values and bubbling>).
L</listen> on the root runs the commands of the keys that no widget
below used: a text field keeps the letters it types, and Ctrl+S
reaches the root and saves.

A command that is disabled does not use its key: the key goes on, and
nothing happens. A program that wants to say why, for example in a
L<Term::Fabulous::Widget::StatusBar>, listens for the keys itself and
asks L</command_for_key> and L<Term::Fabulous::Command/is_enabled>.

=head1 CONSTRUCTOR

=head2 new

	my $commands = Term::Fabulous::Commands->new( commands => [ ... ] );

=over

=item C<commands>

An array reference of commands, each a L<Term::Fabulous::Command> or a
hash reference of the parameters of
L<Term::Fabulous::Command/new>. Default: C<[]>. They are added as
L</add> adds them.

=back

Unknown parameters die.

=head1 METHODS

=head2 add

	$commands->add(
		{ id => 'find', label => 'Find...', keys => ['Ctrl+F'], run => sub { ... } },
		$command_object,
	);

Adds commands at the end of the table. Dies when a command's id is
taken already, when one of its keys runs another command already, and
for anything that is not a command or a hash reference. A call that
dies adds none of its commands. Returns the table.

=head2 command

	my $save = $commands->command('save');

The command with an id. Dies for an id the table has no command of.

=head2 commands

	foreach my $command ( $commands->commands ) {
		printf "%-20s %s\n", $command->label, $command->keys_text;
	}

Every command, in the order they were added. A list of keys for a
help screen comes from here.

=head2 command_for_key

	my $command = $commands->command_for_key('Ctrl+S');

The command a key name runs, or C<undef>.

=head2 handle_key

	return Clay::UI::Enum::Result->HANDLED if $commands->handle_key($event);

Runs the command of a L<Term::Fabulous::Event::KeyPress>: the command
of its C<key_name>, or else of its C<main_key_name> (so the Enter and
digit keys of the number pad run the commands of the main keys).
Returns 1 when a command ran, and 0 when the key runs no command or its
command is disabled.

=head2 listen

	$commands->listen( $ui->root );

Adds a C<KeyPress> listener to a widget that calls L</handle_key>, and
stops the key from bubbling further when a command ran. Listen on the
root for keys that work everywhere, or on a part of the screen for keys
that work only while the focus is inside it. The listener keeps the
table alive as long as the widget lives, so the program need not keep
it in a variable, and it cannot be taken away again. Returns the
table.

=head1 SEE ALSO

L<Term::Fabulous::Command>, L<Term::Fabulous::Widget::MenuBar>,
L<Term::Fabulous::Widget::Menu>, L<Term::Fabulous::Manual::Menus>,
L<Term::Fabulous::Cookbook::Menus>.

=cut
