use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use Clay::XS qw(sizing_grow);
use Term::Fabulous;
use Term::Fabulous::Command;
use Term::Fabulous::Commands;
use Term::Fabulous::Terminal::Memory;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::KeyReference;
use Term::Fabulous::Widget::TextField;

my $KeyReference = 'Term::Fabulous::Widget::KeyReference';

my $root     = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow(), height => sizing_grow() } } );
my $behind   = Term::Fabulous::Widget::TextField->new( value => 'behind' );
my $terminal = Term::Fabulous::Terminal::Memory->new( width => 90, height => 40 );
my $ui       = Term::Fabulous->new( width => 90, height => 40, root => $root, terminal => $terminal );
$root->add_child($behind);

my $commands = Term::Fabulous::Commands->new(
	commands => [
		{ id => 'open',  label => 'Open...', keys => ['Ctrl+O'] },
		{ id => 'save',  label => 'Save',    keys => [ 'Ctrl+S', 'F2' ] },
		{ id => 'about', label => 'About' },
	],
);

sub keys_ (@names) {
	$terminal->press_key($_) foreach @names;
	$ui->step;
	return;
}

sub focused () {
	return $ui->interaction->get_focused_widget;
}

# The rows the table shows, in their order: [ keys, action ].
sub listed ($reference) {
	my $table = $reference->table;
	return [ map { my $row = $table->row($_); [ $row->{keys}, $row->{action} ] } $table->filtered_row_ids ];
}

# The group names on the screen, from the top.
sub shown_groups () {
	return [ map { /\x{25be} (\S[^\x{2502}\x{2503}]*?)\s*[\x{2502}\x{2503}]/ ? $1 : () } $terminal->lines ];
}

$ui->interaction->set_focused_widget($behind);
$ui->step;

subtest 'rows from a Commands object' => sub {
	my $reference = $KeyReference->new( commands => $commands );
	is listed($reference), [ [ 'Ctrl+O', 'Open' ], [ 'Ctrl+S, F2', 'Save' ] ], 'commands with keys, their labels without a trailing ..., About without keys has no row';
	$reference->open($ui);
	$ui->step;
	is shown_groups(), ['Everywhere'], 'in the group Everywhere';
	$reference->close;
};

subtest 'rows from a list of Command objects, in a group of their own' => sub {
	my $reference = $KeyReference->new( commands => [ $commands->command('save'), Term::Fabulous::Command->new( id => 'help', label => 'Help', keys => ['F1'] ) ], group => 'Anywhere' );
	is listed($reference), [ [ 'Ctrl+S, F2', 'Save' ], [ 'F1', 'Help' ] ], 'one row per command, in the order given';
	$reference->open($ui);
	$ui->step;
	is shown_groups(), ['Anywhere'], 'group names the group';
	$reference->close;
};

subtest 'more rows from keys, groups in the order they first appear' => sub {
	my $reference = $KeyReference->new(
		commands => $commands,
		keys     => [ [ 'The list', 'Up', 'Up one' ], [ 'Everywhere', 'Tab', 'Move the focus' ], [ 'Dialogs', 'Escape', 'Cancel' ], [ 'The list', 'Down', 'Down one' ] ],
	);
	is listed($reference), [ [ 'Ctrl+O', 'Open' ], [ 'Ctrl+S, F2', 'Save' ], [ 'Tab', 'Move the focus' ], [ 'Up', 'Up one' ], [ 'Down', 'Down one' ], [ 'Escape', 'Cancel' ] ],
		'the rows of a group stay together, in the order given';
	$reference->open($ui);
	$ui->step;
	is shown_groups(), [ 'Everywhere', 'The list', 'Dialogs' ], 'the groups in the order they first appear';
	$reference->close;
};

subtest 'the search field filters the table' => sub {
	my $reference = $KeyReference->new( commands => $commands, keys => [ [ 'The list', 'Up', 'Up one' ], [ 'The list', 'Down', 'Down one' ] ] )->open($ui);
	ref_is focused(), $reference->search, 'the search field has the focus when it opens';
	$terminal->type_text('one');
	$ui->step;
	is listed($reference), [ [ 'Up', 'Up one' ], [ 'Down', 'Down one' ] ], 'only the rows with the text are left';
	keys_( ('Backspace') x 3 );
	$terminal->type_text('ctrl+s');
	$ui->step;
	is listed($reference), [ [ 'Ctrl+S, F2', 'Save' ] ], 'keys are searched too, without case';
	$reference->close;
};

subtest 'Escape and Close close' => sub {
	my $reference = $KeyReference->new( commands => $commands )->open($ui);
	my $closes    = 0;
	$reference->on( Close => sub { $closes++; return } );
	keys_('Escape');
	ok !$reference->is_open, 'Escape closes';
	ref_is focused(), $behind, 'and gives the focus back';

	$reference->open($ui);
	keys_( 'Tab', 'Tab' );
	keys_('Enter');
	ok !$reference->is_open, 'Close closes';
	is $closes, 2, 'Close fired each time';
};

subtest 'the id of the table' => sub {
	is $KeyReference->new( id => 'help' )->table->id, 'help/list', 'a given id: the table is "$id/list"';
	my ( $first, $second ) = map { $KeyReference->new } 1 .. 2;
	like $first->id, qr/\S/, 'without an id one is generated';
	isnt $first->id,      $second->id,          'a different one for each key reference';
	is $first->table->id, $first->id . '/list', 'and the table is named after it';
};

subtest 'the size: up to width and height, never larger than the screen' => sub {
	my $reference = $KeyReference->new( commands => $commands )->open($ui);
	$ui->step;
	is [ @{ $ui->bounding_box($reference) }{qw(width height)} ], [ 78, 30 ], 'the default size on a large screen';
	$reference->close;

	my $small_terminal = Term::Fabulous::Terminal::Memory->new( width => 50, height => 16 );
	my $small_ui       = Term::Fabulous->new( width => 50, height => 16, root => Term::Fabulous::Widget::Box->new, terminal => $small_terminal );
	$reference = $KeyReference->new( commands => $commands, width => 60, height => 20 )->open($small_ui);
	$small_ui->step;
	is [ @{ $small_ui->bounding_box($reference) }{qw(width height)} ], [ 50, 16 ], 'as large as a smaller screen';
	$reference->close;
};

subtest 'a short screen gets the compact layout' => sub {
	my $short_terminal = Term::Fabulous::Terminal::Memory->new( width => 50, height => 16 );
	my $short_ui       = Term::Fabulous->new( width => 50, height => 16, root => Term::Fabulous::Widget::Box->new, terminal => $short_terminal );
	my $reference      = $KeyReference->new( commands => $commands, keys => [ map { [ 'Text', "F$_", "Action $_" ] } 3 .. 12 ] )->open($short_ui);
	$short_ui->step;
	my ($close) = grep { $_->isa('Term::Fabulous::Widget::Button') } $reference->descendants;
	my $row_of = sub ($widget) { return $short_ui->bounding_box($widget)->{y} };
	is $row_of->($close) + 1,                                                     $row_of->( $reference->search ), 'Close sits next to the search field';
	is sprintf( '%.0f', $short_ui->bounding_box( $reference->table )->{height} ), 16 - 6,                          'the table gets all rows but the border, the title and that row';
	ref_is $short_ui->interaction->get_focused_widget, $reference->search, 'the search field has the focus';

	$short_terminal->resize( 90, 40 );
	$short_ui->step;
	cmp_ok $row_of->($close), '>', $row_of->( $reference->table ), 'a taller screen puts Close below the table again';
	ref_is $short_ui->interaction->get_focused_widget, $reference->search, 'and the search field keeps the focus';
	$reference->close;
};

subtest 'parameters are checked' => sub {
	like dies { $KeyReference->new( commands => {} ) },                         qr/commands must be a Term::Fabulous::Commands/,        'commands of the wrong kind die';
	like dies { $KeyReference->new( commands => ['save'] ) },                   qr/commands must hold Term::Fabulous::Command objects/, 'a list of something else dies';
	like dies { $KeyReference->new( keys     => [ [ 'Everywhere', 'F1' ] ] ) }, qr/a row of keys must be an array reference/,           'a row of keys without an action dies';
	like dies { $KeyReference->new( width    => 0 ) },                          qr/width must be a positive integer/,                   'a width that is no positive integer dies';
};

done_testing;
