#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Term::Fabulous;
use Term::Fabulous::Commands;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::DocumentTabs;
use Term::Fabulous::Widget::Prompt;
use Term::Fabulous::Widget::StatusBar;
use Term::Fabulous::Widget::Text;
use Term::Fabulous::Widget::TextArea;
use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);
use List::Util qw(min);

# Every document has a title, a text area and the text it had when it
# was last saved; it is modified while the two differ.
my @documents;
my $untitled = 0;

sub is_modified ($document) {
	return $document->{area}->value ne $document->{saved};
}

# The tabs read the documents whenever a frame is drawn, so the dot for
# unsaved changes comes and goes with the typing.
my $tabs = Term::Fabulous::Widget::DocumentTabs->new(
	tabs => sub {
		map { { title => $_->{title}, modified => is_modified($_) } } @documents;
	}
);
my $page  = Term::Fabulous::Widget::Box->new( layout => { sizing  => { width => sizing_grow(), height => sizing_grow() } } );
my $empty = Term::Fabulous::Widget::Box->new( layout => { padding => { left  => 2, top => 1 } } );
$empty->add_child( Term::Fabulous::Widget::Text->new( text => 'No document is open. Click + or press Ctrl+N for a new one.' ) );
my $status = Term::Fabulous::Widget::StatusBar->new(
	message => 'Ctrl+N new, Ctrl+S save, Alt+w close, Ctrl+Q quit.',
	timeout => 3,
);
my $root = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() } } );
$root->add_child( $tabs, $page, $status );

my $ui = Term::Fabulous->new( root => $root, width => 80, height => 24 );

# Shows a document below the tabs (for undef, a hint) and tells the tabs
# which one it is.
sub show ($index) {
	$page->clear_children;
	$tabs->active($index);
	return $page->add_child($empty) if !defined $index;
	my $area = $documents[$index]{area};
	$page->add_child($area);
	$ui->interaction->set_focused_widget($area);
	return;
}

sub add_document ( $title, $text = '' ) {
	my $area = Term::Fabulous::Widget::TextArea->new( value => $text, wrap => 1, layout => { sizing => { width => sizing_grow(), height => sizing_grow() } } );
	push @documents, { title => $title, area => $area, saved => $text };
	show($#documents);
	return;
}

sub save_document ($index) {
	my $document = $documents[$index];
	$document->{saved} = $document->{area}->value;
	$status->message( "Saved $document->{title}.", 'success' );
	return;
}

sub remove_document ($index) {
	my $active = $tabs->active;
	splice @documents, $index, 1;
	if ( !@documents ) {
		show(undef);
		return;
	}
	show( $active > $index ? $active - 1 : min( $active, $#documents ) );
	return;
}

# A document with unsaved changes is closed only after a question.
sub close_document ($index) {
	my $document = $documents[$index];
	return remove_document($index) if !is_modified($document);
	Term::Fabulous::Widget::Prompt->confirm(
		$ui,
		title   => "Close $document->{title}?",
		message => 'Its changes are not saved.',
		ok      => 'Close',
		cancel  => 'Keep it',
		focus   => 'cancel',
	)->on(
		Answer => sub ($event) {
			remove_document($index) if $event->button eq 'ok';
			return;
		}
	);
	return;
}

# The tabs change nothing themselves: the program answers their events.
$tabs->on( Select   => sub ($event) { show( $event->index );                     return } );
$tabs->on( TabClose => sub ($event) { close_document( $event->index );           return } );
$tabs->on( TabAdd   => sub ($event) { add_document( 'Untitled ' . ++$untitled ); return } );

# The same through the keys. Each command that needs a document is
# enabled only while one is shown.
my $shown    = sub { defined $tabs->active };
my $commands = Term::Fabulous::Commands->new(
	commands => [
		{ id => 'new',      label => 'New',      keys => ['Ctrl+N'],       run => sub { add_document( 'Untitled ' . ++$untitled ) } },
		{ id => 'save',     label => 'Save',     keys => ['Ctrl+S'],       run => sub { save_document( $tabs->active ) },             enabled => $shown },
		{ id => 'close',    label => 'Close',    keys => ['Alt+w'],        run => sub { close_document( $tabs->active ) },            enabled => $shown },
		{ id => 'previous', label => 'Previous', keys => ['Alt+PageUp'],   run => sub { show( ( $tabs->active - 1 ) % @documents ) }, enabled => $shown },
		{ id => 'next',     label => 'Next',     keys => ['Alt+PageDown'], run => sub { show( ( $tabs->active + 1 ) % @documents ) }, enabled => $shown },
		{ id => 'quit',     label => 'Quit',     keys => ['Ctrl+Q'],       run => sub { $ui->loop->stop } },
	],
);
$commands->listen($root);

add_document( 'shopping.txt', "Milk\nBread\nApples\n" );
add_document( 'letter.txt',   "Dear Grace,\n\nthank you for the plums.\n" );
add_document( 'ideas.txt',    "A clock that runs backwards.\n" );
show(0);

$ui->run;
