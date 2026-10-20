#!/usr/bin/env perl

# Term::Fabulous::Widget::DocumentView: a document of headings, lists,
# a quote, code, links and a table. Scroll with the keys (Down, Up,
# PageDown, PageUp, Home, End, or j k Space b g G) and the wheel; l and L
# select a link, Enter follows it; Tab reaches the table; / is not a key
# here, but the program searches for "block" at the start: n and N step
# through the matches, Escape drops them. Ctrl+C quits.
#
#     perl examples/widgets/document-view.pl

use v5.32;
use warnings;
use strict;
use utf8;
use experimental 'signatures';
no warnings 'experimental::signatures';

use FindBin;
use lib "$FindBin::Bin/../../lib/";

use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM CLAY_TEXT_WRAP_NONE);
use Term::Fabulous;
use Term::Fabulous::Document;
use Term::Fabulous::Enum::BorderStyle;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::DocumentView;
use Term::Fabulous::Widget::Table;
use Term::Fabulous::Widget::Text;

# A text with marks as <kind>...</kind> and links as <link=TARGET>...</link>,
# as the factories of a document take it: the plain text and the marks.
sub marked ($tagged) {
	my ( $text, @marks, @open ) = ('');
	foreach my $piece ( split /(<\/?\w+(?:=[^>]*)?>)/, $tagged ) {
		if    ( $piece =~ /\A<(\w+)(?:=([^>]*))?>\z/ ) { push @open, [ length $text, $1, $2 ] }
		elsif ( $piece =~ /\A<\/\w+>\z/ )              { my ( $start, $kind, $link ) = @{ pop @open }; push @marks, [ $start, length $text, $kind, defined $link ? ($link) : () ] }
		else                                           { $text .= $piece }
	}
	return { text => $text, marks => \@marks };
}

my $document = Term::Fabulous::Document->new;
$document->heading( 1, 'DOCUMENT VIEW' );
$document->paragraph( marked('A <bold>DocumentView</bold> shows a <code>Term::Fabulous::Document</code>: a list of widgets that a parser made of some source, POD or Markdown or anything else.') );
$document->heading( 2, 'Items' );
$document->paragraph('The factories of the document make the common items, in the styles of the theme:');
$document->list_item( "\x{2022}", 'headings, in six levels, the first with a rule under it;' );
$document->list_item( "\x{2022}", marked('paragraphs, wrapped to the width of the view, with <bold>bold</bold>, <italic>italic</italic> and <code>code</code> marks;'), position => 2 );
$document->list_item( "\x{2022}", 'items of bulleted and numbered lists, with a hanging indent;',                                                                       position => 3 );
$document->list_item( "\x{2022}", 'code, which never wraps;',                                                                                                           position => 4 );
$document->list_item( "\x{2022}", 'and quotes, with a bar beside them.',                                                                                                position => 5 );
$document->paragraph( marked('A quoted paragraph looks like this, and may <italic>itself</italic> hold marks.'), quote => 1 );
$document->heading( 2, 'Code' );
$document->paragraph('The code blocks scroll sideways together with Left and Right, or with a horizontal wheel:');
$document->code(
	join( "\n", 'my $view = Term::Fabulous::Widget::DocumentView->new(', '    id       => "document",', '    document => $document,    # from a parser of your format', ');' ),
	language => 'perl'
);
$document->heading( 2, 'Links' );
$document->paragraph(
	marked(
'A link such as <link=https://metacpan.org/pod/Term::Fabulous>Term::Fabulous on MetaCPAN</link> is selected with l and L and followed with Enter or a click; the text fires <code>LinkActivate</code> and the program does the rest. The <link=/Items>Items</link> section above is a link too.'
	)
);
$document->heading( 2, 'Any widget' );
$document->paragraph('Any other widget is an item as it is, this table for one; a search finds the text of its cells, and Tab reaches it.');
$document->add(
	Term::Fabulous::Widget::Table->new(
		id      => 'kinds',
		columns => [ { key => 'factory', title => 'Factory' }, { key => 'block', title => 'Makes' } ],
		rows    => [ map { { id => $_->[0], factory => $_->[0], block => $_->[1] } } [ heading => 'a heading block' ], [ paragraph => 'a paragraph block' ], [ code => 'a code block' ] ],
		layout  => { sizing => { width => sizing_grow() } },
	)
);
$document->heading( 1, 'MORE' );
$document->paragraph("Paragraph $_ of a longer document, so that there is something to scroll through and to search for: the word block appears in every one of them.") foreach 1 .. 40;

my $view = Term::Fabulous::Widget::DocumentView->new(
	id           => 'document',
	document     => $document,
	bordered     => 1,
	border_style => Term::Fabulous::Enum::BorderStyle->Round,
	layout       => { sizing => { width => sizing_grow(), height => sizing_grow() }, padding => { left => 1, right => 1 } },
);

my $status = Term::Fabulous::Widget::Text->new( text => '', text_color => [ 150, 160, 180, 255 ], wrap_mode => CLAY_TEXT_WRAP_NONE );
my $root   = Term::Fabulous::Widget::Box->new(
	layout => {
		layout_direction => CLAY_TOP_TO_BOTTOM,
		sizing           => { width => sizing_grow(), height => sizing_grow() },
		padding          => { left  => 1,             right  => 1 },
	},
);
$root->add_child( $view, $status );

# The view tells after every frame what it shows; the program follows
# links by naming them in the status line.
$view->on(
	ViewChange => sub ($event) {
		my $where = defined $event->section_title ? $event->section_title : 'top';
		my $marks
			= defined $event->link ? 'Enter follows ' . $event->link
			: $event->matches      ? sprintf( 'match %d of %d for "%s"', $event->match, $event->matches, $event->query )
			:                        'l selects a link, n the next match';
		$status->text( sprintf '%s  %3d%%  |  %s', $where, $event->percent, $marks );
		return;
	}
);
$view->on( LinkActivate => sub ($event) { $status->text( 'Followed the link to ' . $event->link ); return } );

my $ui = Term::Fabulous->new( width => 80, height => 24, root => $root );
$ui->interaction->set_focused_widget($view);
$view->search('block');
$ui->run;
