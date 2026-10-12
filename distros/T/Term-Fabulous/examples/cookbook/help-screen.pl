#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Commands;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Checkbox;
use Term::Fabulous::Widget::KeyReference;
use Term::Fabulous::Widget::Text;
use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

my $root = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 2,             top    => 1 },
		child_gap        => 1,
	},
);
my $list = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM } );
$root->add_child( Term::Fabulous::Widget::Text->new( text => 'To do. F1 shows the keys.' ), $list );

my @todos = ( [ 'Water the plants', 1 ], [ 'Call the bank', 0 ], [ 'Fix the bike', 0 ], [ 'Book the train', 1 ] );

sub show_todos () {
	$list->clear_children;
	foreach my $todo (@todos) {
		my $box = Term::Fabulous::Widget::Checkbox->new( label => $todo->[0], checked => $todo->[1] );
		$box->on( Change => sub ($event) { $todo->[1] = $event->value; return } );
		$list->add_child($box);
	}
	return;
}
show_todos();

my ( $ui, $commands );

# The keys that no command runs: those of the list and of the help itself.
my @other_keys = (
	[ 'The list',  'Tab, Shift+Tab', 'The next, the previous to-do' ],
	[ 'The list',  'Space, Enter',   'Check or uncheck the to-do' ],
	[ 'This help', 'Typing',         'Show only the keys with the text' ],
	[ 'This help', 'Escape',         'Close the help' ],
);

sub show_keys () {
	Term::Fabulous::Widget::KeyReference->new( title => 'Keys of the to-do list', commands => $commands, keys => \@other_keys, width => 60, height => 26 )->open($ui);
	return;
}

$commands = Term::Fabulous::Commands->new(
	commands => [
		{ id => 'keys', label => 'Keys...',   keys => ['F1'],     run => \&show_keys },
		{ id => 'all',  label => 'Check all', keys => ['Ctrl+A'], run => sub { $_->[1] = 1 foreach @todos; show_todos() } },
		{
			id    => 'clean',
			label => 'Remove done',
			keys  => ['Ctrl+D'],
			run   => sub {
				@todos = grep { !$_->[1] } @todos;
				show_todos();
			}
		},
		{
			id    => 'sort',
			label => 'Sort by name',
			keys  => ['Alt+s'],
			run   => sub {
				@todos = sort { $a->[0] cmp $b->[0] } @todos;
				show_todos();
			}
		},
		{ id => 'quit', label => 'Quit', keys => ['Ctrl+Q'], run => sub { $ui->loop->stop } },
	],
);

$ui = Term::Fabulous->new( root => $root, width => 80, height => 24 );
$commands->listen($root);
$ui->run;
