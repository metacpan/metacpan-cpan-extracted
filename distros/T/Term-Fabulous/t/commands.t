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
use Term::Fabulous::Widget::TextField;

subtest 'a command' => sub {
	my ( $ran, $on, $can ) = ( 0, 0, 1 );
	my $command = Term::Fabulous::Command->new( id => 'wrap', label => 'Wrap lines', keys => [ 'Alt+Z', 'F4' ], run => sub { $ran++; $on = !$on }, enabled => sub { $can }, checked => sub { $on } );
	is [ $command->id, $command->label, [ $command->keys ], $command->keys_text ], [ 'wrap', 'Wrap lines', [ 'Alt+Z', 'F4' ], 'Alt+Z, F4' ], 'what it says about itself';
	is [ $command->is_toggle, $command->is_checked ],                              [ 1, 0 ],                                                 'a toggle that is off';
	is $command->run,                                                              1,                                                        'run returns 1 when it ran';
	is [ $ran, $command->is_checked ],                                             [ 1, 1 ],                                                 'checked follows the program';
	$can = 0;
	is [ $command->is_enabled, $command->run, $ran ], [ 0, 0, 1 ], 'a disabled command does not run';

	my $plain = Term::Fabulous::Command->new( id => 'about', label => 'About' );
	is [ $plain->is_enabled, $plain->is_toggle, $plain->is_checked, $plain->keys_text, $plain->run ], [ 1, 0, 0, '', 1 ], 'without the optional parts';

	like dies { Term::Fabulous::Command->new( id => 'x', label => 'X', keys => ['Ctrl+Shft+S'] ) }, qr/the command 'x' has a key that does not exist: .*no key is named 'Ctrl\+Shft\+S'/,
		'a key that does not exist dies';
	like dies { Term::Fabulous::Command->new( id => 'x', label => 'X', run => 'save' ) }, qr/run of the command 'x' must be a code reference or undef, got 'save'/, 'run must be code';
	like dies { Term::Fabulous::Command->new( id => '', label => 'X' ) },                 qr/id must not be empty/,                                                 'an empty id dies';
	like dies { Term::Fabulous::Command->new( id => 'x' ) },                              qr/Required parameter 'label' is missing/,                                'a label is required';
};

subtest 'the table' => sub {
	my @ran;
	my $commands = Term::Fabulous::Commands->new(
		commands => [
			{ id => 'save', label => 'Save', keys => ['Ctrl+S'], run => sub { push @ran, 'save' } },
			Term::Fabulous::Command->new( id => 'quit', label => 'Quit', keys => ['Ctrl+Q'], run => sub { push @ran, 'quit' } ),
		],
	);
	ref_is $commands->add( { id => 'help', label => 'Help', keys => ['F1'], run => sub { push @ran, 'help' }, enabled => sub { 0 } } ), $commands, 'add returns the table';
	is [ map { $_->id } $commands->commands ],   [qw(save quit help)], 'commands in the order they were added';
	is $commands->command('quit')->label,        'Quit',               'command by id';
	is $commands->command_for_key('Ctrl+S')->id, 'save',               'command_for_key';
	is $commands->command_for_key('Ctrl+X'),     undef,                'a key without a command';

	like dies { $commands->command('nope') },                                                qr/there is no command 'nope'/,                                             'an unknown id dies';
	like dies { $commands->add( { id => 'save', label => 'Again' } ) },                      qr/there is a command 'save' already/,                                      'a taken id dies';
	like dies { $commands->add( { id => 'store', label => 'Store', keys => ['Ctrl+S'] } ) }, qr/the key Ctrl\+S of the command 'store' runs the command 'save' already/, 'a taken key dies';
	like dies { $commands->add('save') },                                                    qr/a command must be a Term::Fabulous::Command or a hash reference/,        'anything else dies';
	is [ map { $_->id } $commands->commands ], [qw(save quit help)], 'and adds nothing';
	like dies { $commands->add( { id => 'find', label => 'Find' }, { id => 'quit', label => 'Again' } ) }, qr/there is a command 'quit' already/, 'a taken id in a list dies';
	ok !( grep { $_->id eq 'find' } $commands->commands ), 'and adds none of the list';
	like dies { $commands->add( { id => 'a', label => 'A', keys => ['F9'] }, { id => 'b', label => 'B', keys => ['F9'] } ) }, qr/the key F9 of the command 'b' runs the command 'a' already/,
		'two commands of one list with one key die';
};

subtest 'keys run commands' => sub {
	my @ran;
	my $root     = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow(), height => sizing_grow() } } );
	my $panel    = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow() } } );
	my $field    = Term::Fabulous::Widget::TextField->new( layout => { sizing => { width => sizing_grow() } } );
	my $terminal = Term::Fabulous::Terminal::Memory->new( width => 40, height => 5 );
	my $ui       = Term::Fabulous->new( width => 40, height => 5, root => $root, terminal => $terminal );
	$panel->add_child($field);
	$root->add_child($panel);
	my $commands = Term::Fabulous::Commands->new(
		commands => [
			{ id => 'save',  label => 'Save',  keys => ['Ctrl+S'], run => sub { push @ran, 'save' } },
			{ id => 'print', label => 'Print', keys => ['p'],      run => sub { push @ran, 'print' } },
			{ id => 'close', label => 'Close', keys => ['F5'],     run => sub { push @ran, 'close' }, enabled => sub { 0 } },
		],
	);
	ref_is $commands->listen($panel), $commands, 'listen returns the table';
	my @past;
	$root->on( KeyPress => sub ($event) { push @past, $event->key_name; return } );
	$ui->step;
	$ui->interaction->set_focused_widget($field);
	$terminal->press_key($_) foreach qw(Ctrl+S p F5);
	$ui->step;
	is \@ran,         ['save'], 'a key that reaches the widget runs its command, and p was typed into the field';
	is $field->value, 'p',      'the field kept the letter it types';
	is \@past,        ['F5'],   'the key of a disabled command bubbles on, the others stop';
	like dies { $commands->listen('root') }, qr/listen needs a widget that fires events, got 'root'/, 'listen needs a widget';
};

done_testing;
