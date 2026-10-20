package Term::Fabulous::Widget::KeyReference;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

use Term::Fabulous::Widget::Dialog;

our $VERSION = '0.05';

class Term::Fabulous::Widget::KeyReference
	:isa(Term::Fabulous::Widget::Dialog)
	:strict(params)
{
	use Clay::UI::Enum::Result;
	use Clay::XS qw(sizing_grow CLAY_ALIGN_Y_CENTER);
	use List::Util qw(min sum0 uniq);
	use Scalar::Util qw(blessed refaddr weaken);
	use Term::Fabulous::Check qw(describe positive_integer string);
	use Term::Fabulous::Widget::Box;
	use Term::Fabulous::Widget::Table;
	use Term::Fabulous::Widget::TextField;

	use constant DEFAULT_WIDTH  => 78;
	use constant DEFAULT_HEIGHT => 30;

	# The roomy layout gives the table at least this many lines (or all
	# it needs); with fewer the layout is compact.
	use constant ROOMY_TABLE_MINIMUM => 10;
	use constant CLOSE_HEIGHT        => 3;    # a bordered button

	field $group :param = 'Everywhere';

	field $search :reader;
	field $table  :reader;

	field $_search_row;    # the search field and Close, in the compact layout
	field %_layout_of;    # roomy, compact => the dialog's layout
	field $_table_height;    # the lines the table needs for all its rows
	field $_is_compact = 0;
	field $_resize_root;    # the root whose Resize events the reference follows (weak)

	my $generated_ids = 0;

	# A key reference is a dialog with room around its table: two columns
	# at the sides, a row above and below. It grows up to the width and
	# the height the program asks for, and is never larger than the
	# screen. Without an id it gets one, for the id of its table. Its one
	# button, Close, answers close.
	sub BUILDARGS ( $class, %params ) {
		my $width  = positive_integer( $class, width  => delete $params{width}  // DEFAULT_WIDTH );
		my $height = positive_integer( $class, height => delete $params{height} // DEFAULT_HEIGHT );
		my $layout = $params{layout} // {};
		$params{id} //= 'key-reference-' . ++$generated_ids;
		$params{layout} = {
			padding => { left => 2, right => 2, top => 1, bottom => 1 },
			%$layout,
			sizing => { width => sizing_grow( 0, $width ), height => sizing_grow( 0, $height ), %{ $layout->{sizing} // {} } },
		};
		$params{title} //= 'Keys';
		die "$class: a key reference has its own buttons" if exists $params{buttons};
		$params{buttons} = [ { id => 'close', label => 'Close', primary => 1 } ];
		return $class->SUPER::BUILDARGS(%params);
	}

	ADJUST :params ( :$commands = undef, :$keys = [] ) {
		$group = string( $self, group => $group );
		my @rows = ( $self->_command_rows($commands), $self->_parsed_keys($keys) );

		$search = Term::Fabulous::Widget::TextField->new( placeholder => 'Search keys and actions', layout => { sizing => { width => sizing_grow() } } );
		$table  = $self->_table( \@rows );
		$search->on( Change => sub ( $table, $event ) { $table->search( $event->value ); return Clay::UI::Enum::Result->CONTINUE }, owner => $table );

		$_search_row   = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow() }, child_gap => 2, child_alignment => { y => CLAY_ALIGN_Y_CENTER } } );
		$_table_height = 2 + scalar( uniq map { $_->[0] } @rows ) + @rows;    # the header and its line, a row per group, the rows
		my $roomy = $self->layout;
		%_layout_of = ( roomy => $roomy, compact => { %$roomy, child_gap => 0, padding => { %{ $roomy->{padding} // {} }, top => 0, bottom => 0 } } );
		$self->_arrange_roomy;
	}

	# ---------------------------------------------------------------------
	# Parameters
	# ---------------------------------------------------------------------

	method _command_rows ($commands) {
		return () unless defined $commands;
		return __CLASS__->command_rows( $group, $self->_listed_commands($commands) );
	}

	# One row of keys for every command that has keys: [ group, its keys,
	# its plain label ].
	method command_rows :common ( $in_group, @commands ) {
		return map { [ $in_group, $_->keys_text, $_->plain_label ] } grep { $_->keys } @commands;
	}

	method _listed_commands ($commands) {
		return $commands->commands if blessed $commands && $commands->isa('Term::Fabulous::Commands');
		die ref($self) . ": commands must be a Term::Fabulous::Commands, an array reference of Term::Fabulous::Command objects or undef, got " . describe($commands)
			unless ref $commands eq 'ARRAY';
		foreach my $command (@$commands) {
			die ref($self) . ": commands must hold Term::Fabulous::Command objects, got " . describe($command) unless blessed $command && $command->isa('Term::Fabulous::Command');
		}
		return @$commands;
	}

	method _parsed_keys ($keys) {
		die ref($self) . ": keys must be an array reference, got " . describe($keys) unless ref $keys eq 'ARRAY';
		my @parsed;
		foreach my $row (@$keys) {
			die ref($self) . ": a row of keys must be an array reference of a group, the keys and the action, got " . describe($row) unless ref $row eq 'ARRAY' && @$row == 3;
			push @parsed, [ map { string( $self, 'a group, the keys and the action of a row of keys' => $_ ) } @$row ];
		}
		return @parsed;
	}

	# ---------------------------------------------------------------------
	# The parts
	# ---------------------------------------------------------------------

	# The table groups its rows by their hidden group value, which sorts:
	# it starts with the number of the group in the order the groups first
	# appear, and the label leaves the number out.
	method _table ($rows) {
		return Term::Fabulous::Widget::Table->new(
			id           => $self->id . '/list',
			row_id       => 'id',
			group_by     => 'group',
			group_label  => sub ($shown_group) { return $shown_group->{value} =~ s/\A\d+ //r },
			sort         => [ [ order => 'asc' ] ],
			border       => 'none',
			column_lines => 'none',
			header_line  => 'Solid',
			columns      => [
				{ key => 'order',  title => '',       type    => 'number', visible => 0 },
				{ key => 'group',  title => 'Where',  visible => 0 },
				{ key => 'keys',   title => 'Keys',   width   => 'fit(0, 26)', sortable => 0 },
				{ key => 'action', title => 'Action', width   => 'grow',       sortable => 0 },
			],
			rows   => [ _table_rows($rows) ],
			layout => { sizing => { width => sizing_grow(), height => sizing_grow() } },
		);
	}

	# The rows of the table, numbered in the order given, each in the group
	# value of its group.
	sub _table_rows ($rows) {
		my %rank;
		$rank{ $_->[0] } //= sprintf( '%03d', scalar keys %rank ) foreach @$rows;
		return map {
			my ( $key_group, $keys, $action ) = $rows->[$_]->@*;
			+{ id => $_ + 1, order => $_ + 1, group => "$rank{$key_group} $key_group", keys => $keys, action => $action };
		} 0 .. $#$rows;
	}

	# ---------------------------------------------------------------------
	# Roomy and compact
	# ---------------------------------------------------------------------

	# The roomy layout puts the search field, the table and Close below
	# each other with a gap between them; when that leaves the table too
	# few lines, the compact layout drops the gaps and the padding above
	# and below, and puts Close next to the search field.
	method open :override ($ui) {
		return $self if $self->is_open;
		$self->_fit_height( $ui->height );
		$self->SUPER::open($ui);
		$self->_follow_resizes( $ui->root );
		return $self;
	}

	# One listener for each root the reference opens on.
	method _follow_resizes ($root) {
		return if defined $_resize_root && refaddr($_resize_root) == refaddr($root);
		weaken( $_resize_root = $root );
		$root->on( Resize => sub ( $self, $event ) { $self->_fit_height( $event->height ) if $self->is_open && $event->is_post_event; return Clay::UI::Enum::Result->CONTINUE }, owner => $self );
		return;
	}

	method _fit_height ($screen_height) {
		my $wants_compact = $self->_roomy_table_lines( $self->_dialog_height($screen_height) ) < min( ROOMY_TABLE_MINIMUM, $_table_height );
		return if $wants_compact == $_is_compact;
		my $interaction = defined $self->ui    ? $self->ui->interaction           : undef;
		my $focused     = defined $interaction ? $interaction->get_focused_widget : undef;
		$wants_compact ? $self->_arrange_compact : $self->_arrange_roomy;
		$interaction->set_focused_widget($focused) if defined $focused && $interaction->can_take_focus($focused);    # moving the parts handed it to a focus heir
		return;
	}

	# The height the dialog gets on a screen this high: the most its
	# sizing allows (the height parameter, or the layout's), at most the
	# screen.
	method _dialog_height ($screen_height) {
		my $most = $_layout_of{roomy}{sizing}{height}{max} // 0;
		return $most > 0 ? min( $most, $screen_height ) : $screen_height;
	}

	# The lines the roomy layout leaves the table in a dialog this high:
	# the border, the padding, the title, the search field, Close and the
	# gaps between them take the rest.
	method _roomy_table_lines ($dialog_height) {
		my $layout  = $_layout_of{roomy};
		my $padding = $layout->{padding} // {};
		my @others  = ( length $self->title ? 1 : (), 1, CLOSE_HEIGHT );
		my $gaps    = ( $layout->{child_gap} // 0 ) * @others;
		return $dialog_height - 2 - ( $padding->{top} // 0 ) - ( $padding->{bottom} // 0 ) - $gaps - sum0(@others);
	}

	# Roomy: the title, the search field, the table and Close (the
	# dialog's button row) below each other.
	method _arrange_roomy () {
		$_search_row->clear_children;
		$self->clear_children;
		$self->layout( $_layout_of{roomy} );
		$self->add_child( $search, $table );
		$self->place_parts;
		$_is_compact = 0;
		return;
	}

	# Compact: Close moves next to the search field.
	method _arrange_compact () {
		$self->clear_children;
		$_search_row->add_child( $search, $self->button_row );
		$self->layout( $_layout_of{compact} );
		$self->add_child( $_search_row, $table );
		$self->place_parts;
		$_is_compact = 1;
		return;
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Widget::KeyReference - A dialog that lists the keys of
a program and what they do

=head1 SYNOPSIS

	use Term::Fabulous::Widget::KeyReference;

	# The keys of the program and of its $commands, a Term::Fabulous::Commands table:
	sub show_keys () {
		Term::Fabulous::Widget::KeyReference->new(
			title    => 'Keys of the notes editor',
			commands => $commands,
			keys     => [
				[ 'Text', 'Ctrl+Z, Ctrl+Y', 'Undo, redo' ],
				[ 'Text', 'Shift+arrows',   'Select' ],
			],
		)->open($ui);
		return;
	}

	$commands->add( { id => 'keys', label => 'Keys...', keys => ['F1'], run => \&show_keys } );

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.05/screenshots/widget-key-reference.svg" alt="A Keys of the notes editor dialog over a dimmed notes editor: the search field holds ctrl, and the table below lists only the keys with Ctrl, Ctrl+N New note, Ctrl+S Save, Ctrl+A Select all and Ctrl+Q Quit under Everywhere, and the undo, copy and word keys under Text; a Close button at the bottom"></p>

=end html

The program is F<examples/widgets/key-reference.pl>. The picture shows
the key reference after the user pressed F1 and typed C<ctrl> into its
search field: only the rows with that text are left, in their groups.

=head1 DESCRIPTION

A key reference is a L<Term::Fabulous::Widget::Dialog> that answers the
question "which key does what?". It shows a table with the keys of the
program in one column and what they do in the other, in groups that
say where the keys work, and a search field above it.

=head2 Rows

The rows come from two places, in this order:

=over

=item *

the commands of a L<Term::Fabulous::Commands> table (or a list of
L<Term::Fabulous::Command> objects): one row for every command with
keys, with the keys as a menu shows them (C<Ctrl+S, F2>) and the
L<plain_label|Term::Fabulous::Command/plain_label> of the command: a
label that ends in C<...>, which in a menu means that the command opens
a dialog, is shown without it. Commands without keys have no row (see
L</command_rows>). All of them are in one group, C<Everywhere> unless
C<group> names another one;

=item *

the rows of C<keys>, for the keys no command runs: the keys of a list,
of a text area, of the dialogs of the program.

=back

The groups are shown in the order they first appear in the rows, each
under its name, and the rows of a group in the order they were given.

=head2 Searching and closing

When the key reference opens, the search field has the focus. Typing
filters the table: only the rows whose keys or action contain the text
are left, without regard to case. Tab moves to the table, where the
arrow keys and the mouse wheel scroll it, and to the Close button (in
the compact layout, see L</Size>, to the Close button first). C<Escape>
or C<Close> closes the key reference, and the focus goes back to the
widget that had it before. Close is the dialog's one button
(L<Term::Fabulous::Widget::Dialog/buttons>), with the id C<close>;
giving C<buttons> dies.

=head2 Size

A key reference is as wide as C<width> and as high as C<height>, or as
wide and as high as the screen when that is smaller. The table takes
the room that is left below the search field and scrolls when the rows
do not fit.

On a short screen, where the layout above would leave the table fewer
than ten lines and fewer than its rows need, the key reference becomes
compact: it drops the empty rows between its parts and above and below
them, and puts the Close button next to the search field, above the
table. It goes back when the screen grows again.

=head1 CONSTRUCTOR

=head2 new

=for highlighter language=perl

	my $reference = Term::Fabulous::Widget::KeyReference->new(%parameters);

Accepts the parameters of L<Term::Fabulous::Widget::Dialog/new>
(C<id>, C<layout>, C<backdrop_color>, C<close_on_escape>, ...) and the
ones below. All are optional, and unknown parameters die. A key
reference is laid out like a dialog, with two columns of padding at the
sides instead of one.

=over

=item C<id>

The id of the dialog, a string. Its table gets the id C<"$id/list">,
which keeps the place it is scrolled to. Default: a new id for each key
reference.

=item C<title>

The dialog's title (L<Term::Fabulous::Widget::Dialog/title>), drawn in
bold on the first row. Default: C<Keys>. An empty string shows no
title.

=item C<commands>

A L<Term::Fabulous::Commands> table or an array reference of
L<Term::Fabulous::Command> objects, whose keys the key reference lists
(see L</Rows>). Default: C<undef>, no commands.

=item C<group>

The name of the group the rows of the commands are in, a string.
Default: C<Everywhere>.

=item C<keys>

An array reference of more rows, each an array reference of three
strings: the name of the group, the keys, and what they do:

	keys => [
		[ 'The list', 'Up, Down', 'Another note' ],
		[ 'The list', 'Enter',    'Open the note' ],
	],

Default: C<[]>.

=item C<width>

The largest width of the key reference in columns, a positive integer.
Default: 78. A width in the C<sizing> of C<layout> wins over it.

=item C<height>

The largest height of the key reference in rows, a positive integer.
Default: 30. A height in the C<sizing> of C<layout> wins over it.

=back

=head1 METHODS

A key reference has all methods of L<Term::Fabulous::Widget::Dialog>
(C<open>, C<close>, C<is_open>, ...) plus these.

=head2 search

	$reference->search->value($text);
	$reference->table->search($text);

The L<Term::Fabulous::Widget::TextField> that filters the table as the
user types. Setting its value from the program fires no C<Change>, so
it does not filter: filter the table with its C<search> as well.

=head2 table

	my @ids = $reference->table->filtered_row_ids;

The L<Term::Fabulous::Widget::Table> of the keys.

=head2 command_rows

	my @rows = Term::Fabulous::Widget::KeyReference->command_rows( 'Everywhere', $commands->commands );
	# ( [ 'Everywhere', 'Ctrl+S, F2', 'Save' ], ... )

A class method: the rows a key reference makes of commands, in the
form of C<keys> (C<[ group, keys, action ]>): one for every command
that has keys, with its
L<keys_text|Term::Fabulous::Command/keys_text> and its
L<plain_label|Term::Fabulous::Command/plain_label>, in the group
given. A program that lists its keys elsewhere (a help page, the
theme editor's C<key_list>) builds them with it.

=head1 EVENTS

A key reference fires the events of every dialog: C<Close> when it
closes, then C<Answer> (L<Term::Fabulous::Event::Answer>): C<close>
from the Close button, C<cancel> as dismissed for C<Escape> or
C<close>. The events of its search field and its table bubble through
it as usual. The C<Activate> of its Close button stops at the button,
which answers.

=head1 KDL PROPERTIES

A key reference is built in Perl only: its rows come from a command
table, which a layout file cannot express.

=head1 SEE ALSO

L<Term::Fabulous::Commands>, L<Term::Fabulous::Command>,
L<Term::Fabulous::Widget::Dialog>, L<Term::Fabulous::Event::Answer>,
L<Term::Fabulous::Widget::Table>, L<Term::Fabulous::Widget::MenuBar>,
which shows the same commands in menus,
L<Term::Fabulous::Manual::Menus/KEY REFERENCES>,
L<Term::Fabulous::Cookbook::Menus/Show the keys in a help screen (KeyReference)>.

=cut
