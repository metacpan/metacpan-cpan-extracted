#!/usr/bin/env perl

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/lib";    # where My/Markdown.pm lives

use Clay::UI::Enum::Result;
use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);
use My::Markdown;
use Term::Fabulous;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::DocumentView;
use Term::Fabulous::Widget::StatusBar;

my $directory = "$FindBin::Bin/documents";
my %document_of;    # the pages read so far, by file name
my @history;    # where Backspace goes back to: [ page, block at the top ]
my $page  = 'snapback.md';
my $where = '';    # the section and the percentage, from the last ViewChange

sub document_of ($name) {
	return $document_of{$name} //= My::Markdown->parse_file("$directory/$name");
}

my $view = Term::Fabulous::Widget::DocumentView->new(
	id       => 'manual',
	document => document_of($page),
	layout   => { sizing => { width => sizing_grow(), height => sizing_grow() }, padding => { left => 1, right => 1 } },
);
my $status = Term::Fabulous::Widget::StatusBar->new(
	message => 'l: next link  Enter: follow  Backspace: back',
	timeout => 4,
	parts   => sub { return ( [ $page, 'accent' ], [ $where, 'dim' ] ) },
);
my $root = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() } } );
$root->add_child( $view, $status );

# Shows a page, at the block of a section when the link names one, and
# remembers where the reader was.
sub open_page ( $name, $section ) {
	unless ( -e "$directory/$name" ) {
		$status->message( "There is no page $name.", 'danger' );
		return;
	}
	my $document = document_of($name);
	my $index    = length $section ? $document->find_section($section) : 0;
	unless ( defined $index ) {
		$status->message( "$name has no section \"$section\".", 'danger' );
		return;
	}
	push @history, [ $page, $view->top_item // 0 ];
	$view->document($document) if $name ne $page;
	$view->show_item($index);
	$page = $name;
	return;
}

# A link's target is what the parser put into the mark: here the text
# between the parentheses of [text](target). A Markdown target cannot
# contain a space, so the pages write a section name with %20.
$view->on(
	LinkActivate => sub ($event) {
		my $target = $event->link;
		if ( $target =~ m{\A\w+://} ) {
			$status->message( "Open $target in your browser.", 'info' );
			return;
		}
		$target =~ s/%([0-9A-Fa-f]{2})/chr hex $1/ge;
		my ( $name, $section ) = $target =~ /\A([^#]*)(?:#(.*))?\z/;
		open_page( length $name ? $name : $page, $section // '' );
		return;
	}
);

$view->on(
	ViewChange => sub ($event) {
		$where = sprintf '%s  %d%%', $event->section_title // '', $event->percent;
		return;
	}
);

$root->on(
	KeyPress => sub ($event) {
		return Clay::UI::Enum::Result->CONTINUE unless ( $event->key_name // '' ) eq 'Backspace';
		my $back = pop @history;
		unless ($back) {
			$status->message( 'This is the first page.', 'warning' );
			return;
		}
		( $page, my $top ) = @$back;
		$view->document( document_of($page) );
		$view->show_item($top);
		return;
	}
);

my $ui = Term::Fabulous->new( root => $root, width => 80, height => 24 );
$ui->interaction->set_focused_widget($view);
$ui->run;
