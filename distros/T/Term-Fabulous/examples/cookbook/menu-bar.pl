#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Commands;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Checkbox;
use Term::Fabulous::Widget::MenuBar;
use Term::Fabulous::Widget::Prompt;
use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);

my $root = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() } } );
my $list = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() }, padding => { left => 2, top => 1 } } );

my @todos     = ( [ 'Water the plants', 1 ], [ 'Call the bank', 0 ], [ 'Fix the bike', 0 ], [ 'Book the train', 1 ], [ 'Answer Grace', 0 ] );
my $show_done = 1;

# The list shows a check box per to-do; checking one marks it done.
sub show_todos () {
	$list->clear_children;
	foreach my $todo ( grep { $show_done || !$_->[1] } @todos ) {
		my $box = Term::Fabulous::Widget::Checkbox->new( label => $todo->[0], checked => $todo->[1] );
		$box->on( Change => sub ($event) { $todo->[1] = $event->value; return } );
		$list->add_child($box);
	}
	return;
}
show_todos();

my $ui;
my $commands = Term::Fabulous::Commands->new(
	commands => [
		{
			id    => 'add',
			label => 'Add...',
			keys  => ['Ctrl+N'],
			run   => sub {
				Term::Fabulous::Widget::Prompt->ask( $ui, title => 'New to-do', label => 'To do', required => 1 )->on(
					Answer => sub ($event) {
						return if $event->button ne 'ok';
						push @todos, [ $event->value('value'), 0 ];
						show_todos();
						return;
					}
				);
			},
		},
		{
			id    => 'clean',
			label => 'Remove done',
			keys  => ['Ctrl+D'],
			run   => sub {
				@todos = grep { !$_->[1] } @todos;
				show_todos();
			},
			enabled => sub {
				grep { $_->[1] } @todos;
			},
		},
		{ id => 'quit', label => 'Quit', keys => ['Ctrl+Q'], run => sub { $ui->loop->stop } },
		{ id => 'done', label => 'Show done', keys => ['Alt+d'], run => sub { $show_done = !$show_done; show_todos() }, checked => sub { $show_done } },
	],
);

my $menu_bar = Term::Fabulous::Widget::MenuBar->new(
	commands => $commands,
	caption  => 'To-do',
	menus    => [ { title => 'List', items => [qw(add clean - quit)] }, { title => 'View', items => ['done'] } ],
);
$root->add_child( $menu_bar, $list );

$ui = Term::Fabulous->new( root => $root, width => 80, height => 24 );
$commands->listen($root);
$menu_bar->listen($root);
$ui->run;
