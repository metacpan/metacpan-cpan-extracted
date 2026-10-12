#!/usr/bin/env perl

# Term::Fabulous::Widget::DocumentTabs: a row of tabs for the open
# documents of an editor, some with unsaved changes (a dot), one with an
# error (an exclamation mark). A click on a tab shows its document
# below, a click on its close mark or a middle click closes it, + adds a
# new one. When the tabs do not fit, the arrows at the ends lead to the
# hidden ones. The program gives the same actions keys: Alt+PageUp and
# Alt+PageDown switch, Alt+w closes, Ctrl+N adds. Ctrl+C quits.
#
#     perl examples/widgets/document-tabs.pl

use v5.32;
use warnings;
use strict;
use utf8;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../../lib/";

use Term::Fabulous;
use Term::Fabulous::Commands;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::DocumentTabs;
use Term::Fabulous::Widget::StatusBar;
use Term::Fabulous::Widget::Text;

use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);
use List::Util qw(min);

my @documents = (
	{ title => 'README.md',  text => "# Groceries\n\nA list of what to buy this week." },
	{ title => 'notes.txt',  text => "Call the plumber on Monday.\nReturn the library books.", modified => 1 },
	{ title => 'config.kdl', text => "shop \"corner\" {\n    opens 8\n    closes\n}",          error    => 1 },
	{ title => 'todo.md',    text => "- milk\n- bread\n- apples" },
	{ title => 'budget.csv', text => "item,price\nmilk,1.20\nbread,2.50", modified => 1 },
	{ title => 'letter.md',  text => "Dear neighbour,\n\nthank you for the apples." },
);
my $active   = 2;
my $untitled = 0;

my $root = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() } } );

# The tabs show the documents as they are now: the code is read whenever
# a frame is drawn.
my $tabs = Term::Fabulous::Widget::DocumentTabs->new(
	tabs => sub {
		map { { title => $_->{title}, modified => $_->{modified}, error => $_->{error} } } @documents;
	},
	active => $active,
);
my $page = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow(), height => sizing_grow() }, padding => { left => 2, right => 2, top => 1 } } );
my $body = Term::Fabulous::Widget::Text->new( text => '' );
$page->add_child($body);
my $keys = Term::Fabulous::Widget::Box->new( layout => { padding => { left => 2, right => 2 } } );
$keys->add_child( Term::Fabulous::Widget::Text->new( text => 'Alt+PageUp, Alt+PageDown switch; Alt+w closes; Ctrl+N adds.', text_color => [ 150, 160, 180, 255 ] ) );
my $status = Term::Fabulous::Widget::StatusBar->new(
	message => 'Click a tab to show it or close it; + adds one.',
	parts   => [ [ 'Ctrl+C quits', 'dim' ] ],
);
$root->add_child( $tabs, $page, $keys, $status );

# Shows a document below the tabs, and tells the tabs which one it is.
sub show ($index) {
	$active = @documents ? $index : undef;
	$tabs->active($active);
	$body->text( defined $active ? $documents[$active]{text} : 'No document is open. Click + or press Ctrl+N for a new one.' );
	return;
}
show($active);

sub close_document ($index) {
	my ($closed) = splice @documents, $index, 1;
	$status->message("Closed $closed->{title}.");
	show( $active > $index ? $active - 1 : min( $active, $#documents ) );
	return;
}

sub add_document () {
	push @documents, { title => 'Untitled ' . ++$untitled, text => '' };
	show($#documents);
	return;
}

# The tabs change nothing themselves: the program answers their events.
$tabs->on( Select   => sub ($event) { show( $event->index );           return } );
$tabs->on( TabClose => sub ($event) { close_document( $event->index ); return } );
$tabs->on( TabAdd   => sub ($event) { add_document();                  return } );

# The tabs take no keys: the program gives them some, as commands.
my $open     = sub { defined $active };
my $commands = Term::Fabulous::Commands->new(
	commands => [
		{ id => 'previous', label => 'Previous', keys => ['Alt+PageUp'],   run => sub { show( ( $active - 1 ) % @documents ) }, enabled => $open },
		{ id => 'next',     label => 'Next',     keys => ['Alt+PageDown'], run => sub { show( ( $active + 1 ) % @documents ) }, enabled => $open },
		{ id => 'close',    label => 'Close',    keys => ['Alt+w'],        run => sub { close_document($active) },              enabled => $open },
		{ id => 'new',      label => 'New',      keys => ['Ctrl+N'],       run => \&add_document },
	],
);
$commands->listen($root);

my $ui = Term::Fabulous->new( width => 72, height => 14, root => $root );
$ui->run;
