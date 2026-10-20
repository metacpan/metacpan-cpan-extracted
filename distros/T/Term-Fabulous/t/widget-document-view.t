use v5.32;
use warnings;
use utf8;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use FindBin;
use lib "$FindBin::Bin/lib";

use Clay::UI;
use Clay::XS qw(sizing_fixed sizing_grow CLAY_TOP_TO_BOTTOM);
use DocumentTest;
use List::Util qw(first);
use Scalar::Util qw(refaddr);
use Object::Pad 0.825;
use Term::Fabulous;
use Term::Fabulous::Color;
use Term::Fabulous::Document;
use Term::Fabulous::Document::Look;
use Term::Fabulous::Event::ViewChange;
use Term::Fabulous::Render::Attr qw(color_attr);
use Term::Fabulous::Terminal::Memory;
use Term::Fabulous::Termbox qw(TF_KEY_MOUSE_WHEEL_RIGHT);
use Term::Fabulous::Theme;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Button;
use Term::Fabulous::Widget::Dialog;
use Term::Fabulous::Widget::Divider;
use Term::Fabulous::Widget::DocumentView;
use Term::Fabulous::Widget::Table;
use Term::Fabulous::Widget::Tabs;
use Term::Fabulous::Widget::Tabs::Page;
use Term::Fabulous::Widget::Text;

# The view of a document, focused, filling a memory terminal of the
# given size; every LinkActivate and ViewChange is collected. Widgets
# given as before and after go above and below the view.
sub document_ui ( $document, $width = 60, $height = 12, %around ) {
	my $view = Term::Fabulous::Widget::DocumentView->new(
		id       => 'document',
		document => $document,
		bordered => 1,
		layout   => { sizing => { width => sizing_grow(), height => sizing_grow() }, padding => { left => 1, right => 1 } },
	);
	my $root = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() } } );
	$root->add_child( @{ $around{before} // [] }, $view, @{ $around{after} // [] } );
	my $terminal = Term::Fabulous::Terminal::Memory->new( width => $width, height => $height );
	my $ui       = Term::Fabulous->new( root => $root, width => $width, height => $height, terminal => $terminal );
	my %h        = ( terminal => $terminal, ui => $ui, activated => [], views => [] );
	$view->on( LinkActivate => sub ($event) { push @{ $h{activated} }, $event; return } );
	$view->on( ViewChange   => sub ($event) { push @{ $h{views} },     $event; return } );
	$ui->interaction->set_focused_widget($view);
	$ui->step;
	return ( $view, \%h );
}

# The rows inside the border, without the scrollbar column: row 0 is
# the terminal's row 1, and column 0 its column 1.
sub screen ($h) {
	my @lines = $h->{terminal}->lines;
	return [ map { substr( $_, 1, length($_) - 3 ) =~ s/\s+\z//r } @lines[ 1 .. $#lines - 1 ] ];
}

sub press ( $h, @keys ) {
	$h->{terminal}->press_key($_) foreach @keys;
	$h->{ui}->step;
	return;
}

sub steps ( $h, $count ) {
	$h->{ui}->step foreach 1 .. $count;
	return;
}

sub row_of ( $h, $text ) {
	my $rows = screen($h);
	return ( grep { index( $rows->[$_], $text ) >= 0 } 0 .. $#$rows )[0];
}

# The terminal column and row of the first occurrence of a text on the
# screen, and its cell.
sub position_of ( $h, $text ) {
	my $row = row_of( $h, $text ) // return ();
	return ( 1 + index( screen($h)->[$row], $text ), 1 + $row );
}

sub cell_of ( $h, $text ) {
	my @position = position_of( $h, $text ) or return undef;
	return $h->{terminal}->cell(@position);
}

# The text of the document that starts so.
sub text_of ( $document, $start ) {
	return first { index( $_->text, $start ) == 0 } map { $document->texts($_) } 0 .. $document->count - 1;
}

sub focused ($h) {
	return $h->{ui}->interaction->get_focused_widget;
}

sub attr_of ($color) {
	return color_attr( Term::Fabulous::Color->new( color => $color ) );
}

sub button ($label) {
	my $button = Term::Fabulous::Widget::Button->new( layout => { sizing => { width => sizing_fixed(12), height => sizing_fixed(1) } } );
	$button->add_child( Term::Fabulous::Widget::Text->new( text => $label ) );
	return $button;
}

subtest 'parameters' => sub {
	like dies {
		Term::Fabulous::Widget::DocumentView->new( id => 'd', build => sub { } )
	}, qr/build cannot be given/, 'the items come from the document';
	like dies { Term::Fabulous::Widget::DocumentView->new( id => 'd', document => {} ) }, qr/document must be a Term::Fabulous::Document/, 'a document is a document';
	my $sample = sample_document();
	my $view   = Term::Fabulous::Widget::DocumentView->new( id => 'd', document => $sample );
	is $view->count, $sample->count, 'there is an item per item of the document';
	like dies { $view->count(3) }, qr/count cannot be set/, 'and nobody else decides that';
	ref_is $sample->shown_by, $view, 'the document knows its view';
	like dies { Term::Fabulous::Widget::DocumentView->new( id => 'e', document => $sample ) }, qr/the document is shown by the Term::Fabulous::Widget::DocumentView 'd' already/,
		'a document is shown by one view at a time';
	$view->document(undef);
	ok lives { Term::Fabulous::Widget::DocumentView->new( id => 'e', document => $sample ) }, 'once the first view lets it go, another may show it';
	is( Term::Fabulous::Widget::DocumentView->new( id => 'f' )->count, 0, 'a view without a document is empty' );
};

subtest 'items' => sub {
	my ( $view, $h ) = document_ui( sample_document(), 60, 40 );
	my $rows = screen($h);
	is [ @$rows[ 0 .. 4 ] ], [ ' NAME', ' ' . ( "\x{2500}" x 55 ), '', '   Sample - a page to test the document view with', '' ], 'a first-level heading has a rule, paragraphs are indented';
	my $item = row_of( $h, 'First point.' );
	is [ @$rows[ $item .. $item + 4 ] ], [ "   \x{2022} First point.", "   \x{2022} Second point with Details.", '', '   1. One.', '   2. Two.' ],
		'the items of a list follow each other, lists are apart';
	my $term = row_of( $h, 'frobnicate VALUE' );
	is $rows->[ $term + 1 ],                   '       Frobnicates the VALUE.', 'a term is followed by its definition';
	is $rows->[ row_of( $h, 'use Sample;' ) ], '    use Sample;',               'code is shown as it is';

	my $look = $view->document_look;
	my $bold = cell_of( $h, 'bold,' );
	is $bold->[0], 'b', 'the bold word';
	ok $bold->[1] & $look->style('bold')->{set}, 'is drawn bold';
};

subtest 'a quote builds in a UI that has no theme' => sub {
	my $view = Term::Fabulous::Widget::DocumentView->new(
		id     => 'plain', document => document( [ paragraph => 'Quoted.', quote => 1 ] ),
		layout => { sizing => { width => sizing_fixed(30), height => sizing_fixed(5) } }
	);
	my $ui = Clay::UI->new( root => $view, width => 30, height => 5 );
	ok lives { $ui->render for 1 .. 2 }, 'a plain Clay::UI lays the view out';
	is $view->window, { first => 0, last => 0 }, 'with the quote built';
	ref_is $view->document_look->theme, Term::Fabulous::Theme->default, 'in the default theme';
};

subtest 'block quotes' => sub {
	my ( $view, $h ) = document_ui( document( [ paragraph => 'Quoted.', quote => 1 ], [ paragraph => 'Deeper.', quote => 2 ] ), 40, 8 );
	is [ @{ screen($h) }[ 0 .. 2 ] ], [ " \x{2502}   Quoted.", " \x{2502} \x{2502}", " \x{2502} \x{2502}   Deeper." ],    'a bar per quote level, and the blank row between the items inside the bars';
	is $h->{terminal}->cell( 2, 1 )->[1] & 0xFFFFFF, attr_of( $view->document_look->style('quote')->{color} ) & 0xFFFFFF, 'in the quote color';
	$h->{ui}->theme('light');
	$h->{ui}->step;
	is $h->{terminal}->cell( 2, 1 )->[1] & 0xFFFFFF, attr_of( $view->document_look->style('quote')->{color} ) & 0xFFFFFF, 'which follows the theme';
};

subtest 'scrolling keys' => sub {
	my ( $view, $h ) = document_ui( long_document() );
	press( $h, 'Down', 'j' );
	is screen($h)->[0], '', 'Down and j scroll a row each';
	press( $h, 'End' );
	is screen($h)->[-1],         '   The last paragraph.', 'End shows the end';
	is $h->{views}[-1]->percent, 100,                      'which is 100 percent';
	press( $h, 'Home' );
	is screen($h)->[0], ' NAME', 'Home shows the top';
	press( $h, 'PageDown' );
	is $view->top_item, 4, 'PageDown scrolls by the rows shown less one';
	press( $h, 'b' );
	is $view->top_item, 0, 'b scrolls back';
};

subtest 'links' => sub {
	my $sample = sample_document();
	my ( $view, $h ) = document_ui($sample);
	my $marks = text_of( $sample, 'Some bold' );
	press( $h, 'Enter' );
	is $h->{activated}, [], 'Enter does nothing while no link is selected';
	press( $h, 'l' );
	is $view->selected_link,                'Other',                                                                   'l selects the first link in view';
	is $marks->selected_link,               0,                                                                         'the text shows it selected';
	is cell_of( $h, 'Other and one' )->[2], attr_of( $h->{ui}->theme->look( 'text', 'link.background', 'selected' ) ), 'in the look of a selected link';
	press( $h, 'l', 'Enter' );
	my $section = $marks->links->[1];
	is [ map { [ $_->link, $_->index, $_->start, $_->end ] } @{ $h->{activated} } ], [ [ '/Methods', 1, @$section[ 0, 1 ] ] ], 'Enter fires LinkActivate for the selected link';
	ref_is $h->{activated}[0]->target, $marks, 'from the text of the link, through the view';
	press( $h, 'L', 'L', 'L' );
	is $view->selected_link,  'Other', 'L goes back and stops at the first link';
	is $h->{views}[-1]->link, 'Other', 'ViewChange reports the selected link';
	$view->rebuild;
	$h->{ui}->step;
	is $marks->selected_link, 0, 'the selection stays when the slots are built again';
	press( $h, 'Escape' );
	is [ $view->selected_link, $marks->selected_link ], [ undef, undef ], 'Escape drops the selection';
};

subtest 'clicking a link' => sub {
	my $sample = sample_document();
	my ( $view, $h ) = document_ui( $sample, 60, 40 );
	press( $h, 'l' );
	$h->{terminal}->click( position_of( $h, 'Details' ) );
	$h->{ui}->step;
	my ($event) = @{ $h->{activated} };
	is [ $event->link, $view->selected_link ], [ 'Other/Details', 'Other/Details' ], 'a click on a link fires LinkActivate with its link and selects the link in the view';
	is [ text_of( $sample, 'Some bold' )->selected_link, text_of( $sample, 'Second point' )->selected_link ], [ undef, 0 ], 'the selection moved from one text to the other';
	ref_is focused($h), $view, 'and the view keeps the focus';
	press( $h, 'l' );
	is $view->selected_link, 'Other', 'l goes on from the clicked link';
};

subtest 'search' => sub {
	my ( $view, $h ) = document_ui( long_document() );
	is $view->search('needle'), 120, 'search counts the matches';
	$h->{ui}->step;
	is [ $view->current_match, $h->{views}[-1]->matches, $h->{views}[-1]->query ], [ 1, 120, 'needle' ], 'the first one is current, and the ViewChange names the query';
	press( $h, 'N' );
	is $view->current_match, 120, 'N goes around to the last';
	ok defined row_of( $h, 'Paragraph 120 ' ), 'and scrolls it into view';
	my $look = $view->document_look;
	my $row  = row_of( $h, 'Paragraph 120 ' );
	is $h->{terminal}->cell( 1 + index( screen($h)->[$row], 'needle' ), 1 + $row )->[2], attr_of( $look->style('match_current')->{background} ), 'in the style of the current match';
	press( $h, 'n' );
	is $view->current_match, 1, 'n goes around to the first';
	press( $h, 'Escape' );
	is [ $view->query, $view->match_count ], [ undef, 0 ], 'Escape ends the search';
	is $view->document->item(1)->highlights, [],           'and takes its highlights away';
};

subtest 'ViewChange' => sub {
	my $sample = sample_document();
	my ( $view, $h ) = document_ui($sample);
	my $first = $h->{views}[0];
	is [ $first->top, $first->section, $first->percent ], [ 0, 0, 0 ], 'the first frame is reported';
	my $count = @{ $h->{views} };
	$h->{ui}->invalidate;
	$h->{ui}->step;
	is scalar @{ $h->{views} }, $count, 'a frame that shows the same is not';
	$view->show_item( $sample->find_section('Lists') );
	$h->{ui}->step;
	is [ $h->{views}[-1]->section, $h->{views}[-1]->section_title ], [ 4, 'Lists' ], 'the section follows the top item, with its title';
	like dies { Term::Fabulous::Event::ViewChange->new( section => 1 ) }, qr/section and section_title go together/, 'a section never comes without its title';
	like dies { Term::Fabulous::Event::ViewChange->new( matches => 2 ) }, qr/2 matches without a query/,             'matches never come without their query';
};

subtest 'code scrolls sideways' => sub {
	my ( $view, $h ) = document_ui( document( [ code => join ' ', ('word') x 30 ], [ paragraph => 'Text.' ] ), 40, 8 );
	press( $h, 'Right' );
	is $view->code_offset, 8, 'Right scrolls the code';
	like screen($h)->[0], qr/\A   \x{2039}/, 'and the code shows it is scrolled';
	press( $h, 'Left', 'Left' );
	is $view->code_offset, 0, 'Left scrolls back, as far as the start';
	$h->{terminal}->mouse( key => TF_KEY_MOUSE_WHEEL_RIGHT, x => 10, y => 1 );
	$h->{ui}->step;
	is $view->code_offset, 3, 'so does the horizontal wheel, three columns a notch';
};

subtest 'items added later are known at once' => sub {
	my $document = document( [ paragraph => 'First.' ] );
	my ( $view, $h ) = document_ui( $document, 40, 8 );
	$document->heading( 2, 'Later' );
	is $view->count, 2, 'count sees the new item before a frame';
	ok lives { $view->show_item( $document->find_section('Later') ) }, 'show_item reaches it';
	$document->paragraph('Last.');
	is $view->scroll_to_bottom, 1, 'scroll_to_bottom goes to the newest item';
	$h->{ui}->step;
	is $view->visible_items->{last}, 2, 'which the next frame shows';
};

subtest 'a code block added later takes the highlighter and the code offset' => sub {
	my $document = document( [ code => join ' ', ('word') x 30 ], [ paragraph => 'Text.' ] );
	my ( $view, $h ) = document_ui( $document, 40, 8 );
	my $highlighter = sub ( $code, $language ) { [] };
	$view->highlighter($highlighter);
	press( $h, 'Right' );
	my $late = $document->code('say 1;');
	$view->show_item(2);
	$h->{ui}->step;
	ref_is $late->highlighter, $highlighter, 'the new block has the highlighter of the view';
	is $late->offset, 8, 'and is scrolled sideways like the others';
};

subtest 'theme switch' => sub {
	my ( $view, $h ) = document_ui( sample_document() );
	$h->{ui}->theme('light');
	$h->{ui}->step;
	my $light = Term::Fabulous::Document::Look->new( theme => $h->{ui}->theme );
	is cell_of( $h, 'NAME' )->[1] & 0xFFFFFF, attr_of( $light->style('heading1')->{color} ) & 0xFFFFFF, 'headings are drawn in the new theme';
	press( $h, 'End' );
	$h->{ui}->theme('dark');
	$h->{ui}->step;
	press( $h, 'Home' );
	my $dark = Term::Fabulous::Document::Look->new( theme => $h->{ui}->theme );
	is cell_of( $h, 'NAME' )->[1] & 0xFFFFFF, attr_of( $dark->style('heading1')->{color} ) & 0xFFFFFF, 'also the items that were out of view';
};

subtest 'the border is dropped at runtime' => sub {
	my ( $view, $h ) = document_ui( long_document() );
	$view->bordered(0);
	$h->{ui}->step;
	my @lines = $h->{terminal}->lines;
	like $lines[0], qr/\A NAME/, 'the content moves into the rows of the border';
	is scalar( grep { substr( $_, -1 ) ne ' ' } @lines ), scalar @lines, 'and the scrollbar into the last column, on every row';
};

subtest 'a match deep inside a tall item' => sub {
	my $code = join "\n", map { $_ == 38 ? "line $_ needle" : "line $_" } 1 .. 45;
	my ( $view, $h ) = document_ui( document( [ paragraph => 'Intro.' ], [ code => $code ] ) );
	$view->search('needle');
	steps( $h, 2 );
	ok defined row_of( $h, 'line 38 needle' ), 'search shows the line of the match, not the top of its item';

	my $long = join ' ', map { "word$_" } 1 .. 400;
	my ( $prose_view, $h2 ) = document_ui( document( [ paragraph => "$long target" ] ) );
	$prose_view->search('target');
	steps( $h2, 4 );
	ok defined row_of( $h2, 'target' ), 'and the line of a match in a long paragraph, past the lines Clay left out';
};

subtest 'a match deep inside a tall item far below' => sub {
	my $code = join "\n", map { $_ == 38 ? "line $_ needle" : "line $_" } 1 .. 45;
	my ( $view, $h ) = document_ui( document( ( map { [ paragraph => "Paragraph $_." ] } 1 .. 80 ), [ code => $code ] ) );
	$view->search('needle');
	steps( $h, 2 );
	ok defined row_of( $h, 'line 38 needle' ), 'the line shows once the item was built and measured';
};

subtest 'the horizontal wheel goes on when no code can move' => sub {
	my ( $view, $h ) = document_ui( sample_document() );
	my @notches;
	$h->{ui}->root->on( Mouse => sub ($event) { push @notches, $event->key; return } );
	$h->{terminal}->mouse( key => TF_KEY_MOUSE_WHEEL_RIGHT, x => 10, y => 3 );
	$h->{ui}->step;
	is [ $view->code_offset, scalar @notches ], [ 0, 1 ], 'the notch reaches the widgets around';
};

subtest 'another document' => sub {
	my ( $view, $h ) = document_ui( long_document() );
	$view->search('needle');
	press( $h, 'End' );
	$view->document( sample_document() );
	$h->{ui}->step;
	is [ screen($h)->[0], $view->match_count ], [ ' NAME', 0 ], 'starts at its top, without the search of the last one';

	$view->document( document( [ heading => 1, 'A' ], [ code => 'x' x 120 ] ) );
	$h->{ui}->step;
	press( $h, 'Right' );
	my $count = @{ $h->{views} };
	$view->document( document( [ heading => 1, 'A' ], [ code => 'y' x 120 ] ) );
	$h->{ui}->step;
	is $view->code_offset,      0,          'with its code not scrolled sideways';
	is scalar @{ $h->{views} }, $count + 1, 'and a ViewChange, even when the view looks the same as before';
};

# The code blocks of a document paint with the document's look.
class My::Look :isa(Term::Fabulous::Document::Look) {

	method recipes :common () {
		return ( $class->SUPER::recipes, code_block => { color => 'text', background => 'accent' } );
	}
}

subtest 'the code blocks paint with the document\'s look' => sub {
	my $document = Term::Fabulous::Document->new( look => 'My::Look' );
	$document->code('code');
	my ( $view, $h ) = document_ui( $document, 40, 8 );
	is cell_of( $h, 'code' )->[2], attr_of( My::Look->of($view)->style('code_block')->{background} ), 'the code_block style of the document\'s look class';
};

# A table of releases with two rows a page, under a paragraph.
sub table_document () {
	my $document = document( [ paragraph => 'Releases:' ] );
	my $table    = Term::Fabulous::Widget::Table->new(
		id        => 'releases',
		columns   => [ { key => 'version', title => 'Version' }, { key => 'note', title => 'Note' } ],
		rows      => [ map { { id => $_, version => "2.$_", note => $_ == 5 ? 'the needle release' : "release $_" } } 1 .. 6 ],
		page_size => 2,
		layout    => { sizing => { width => sizing_grow() } },
	);
	$document->add($table);
	$document->paragraph('After the table.');
	return ( $document, $table );
}

subtest 'any widget is an item, and its text is searched' => sub {
	my ( $document, $table ) = table_document();
	my ( $view,     $h )     = document_ui( $document, 60, 14 );
	ok defined row_of( $h, 'release 1' ), 'the table shows its first page in the document';
	is $view->search('needle'), 1, 'a search finds the cell on another page';
	steps( $h, 3 );
	is $table->page, 3, 'the table turned to its page';
	ok defined row_of( $h, 'the needle release' ), 'and the cell is on the screen';
	my $cell = $table->cell_widget( 5, 'note' );
	is $cell->highlights->[0][2]{background}, 'warning', 'drawn as the current match';

	$table->update_row( 5, { note => 'renamed' } );
	$h->{ui}->step;
	is [ $view->next_match, $view->match_count ], [ 0, 0 ], 'a changed row makes the search run again, which finds nothing now';
};

subtest 'a search runs again when a part of a container was replaced' => sub {
	my $tabs  = Term::Fabulous::Widget::Tabs->new( layout => { sizing => { height => sizing_fixed(6) } } );
	my @pages = map { Term::Fabulous::Widget::Tabs::Page->new( title => $_ ) } qw(First Second);
	$pages[0]->add_child( Term::Fabulous::Widget::Text->new( text => 'alpha beta gamma' ) );
	$pages[1]->add_child( Term::Fabulous::Widget::Text->new( text => 'beta' ) );
	$tabs->add_child(@pages);
	my $document = document( [ paragraph => 'Above.' ] );
	$document->add($tabs);
	my ( $view, $h ) = document_ui( $document, 40, 12 );
	is $view->search('gamma'), 1, 'the match on the first page';
	$h->{ui}->step;
	$tabs->remove_child( $pages[0] );
	$h->{ui}->step;
	is [ $view->next_match, $view->match_count ], [ 0, 0 ], 'with its page gone, the next match runs the search again instead of highlighting the text that took its place';
};

subtest 'a link in a caption' => sub {
	my $document = document( [ paragraph => 'Above.' ] );
	my $figure   = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow() } } );
	$figure->add_child( Term::Fabulous::Widget::Divider->new, Term::Fabulous::Widget::Text->new( markup => 'Figure 1, from [link=source]the source[/].' ) );
	$document->add($figure);
	my ( $view, $h ) = document_ui( $document, 40, 8 );
	press( $h, 'l' );
	is $view->selected_link, 'source', 'l reaches a link inside any widget';
	press( $h, 'Enter' );
	is $h->{activated}[0]->link, 'source', 'and Enter follows it';
};

subtest 'Tab walks the interactive widgets of the document' => sub {
	my $document = document( map { [ paragraph => "Paragraph $_." ] } 1 .. 3 );
	my $near     = $document->add( button('Near') );
	$document->paragraph("Paragraph $_.") foreach 4 .. 60;
	my $far = $document->add( button('Far') );
	my ( $before, $after ) = ( button('Before'), button('After') );
	my ( $view,   $h )     = document_ui( $document, 40, 12, before => [$before], after => [$after] );

	press( $h, 'Tab' );
	ref_is focused($h), $near, 'Tab from the view goes to the first button in view';
	press( $h, 'Tab' );
	steps( $h, 3 );
	ref_is focused($h), $far, 'then to the one far below, once its item is built';
	ok defined row_of( $h, 'Far' ), 'which is scrolled into view';
	press( $h, 'Tab' );
	ref_is focused($h), $after, 'past the last widget, Tab leaves the view';
	press( $h, 'BackTab' );
	ref_is focused($h), $view, 'Shift+Tab from below lands on the view';
	press( $h, 'BackTab' );
	ref_is focused($h), $before, 'and Shift+Tab from the view leaves it upward';
	press( $h, 'Tab' );
	ref_is focused($h), $view, 'Tab from above lands on the view too';

	press( $h, 'Home' );
	press( $h, 'Tab' );
	ref_is focused($h), $near, 'Tab into the document again';
	press( $h, 'Escape' );
	ref_is focused($h), $view, 'Escape in a widget gives the focus back to the view';
	press( $h, 'Tab', 'BackTab' );
	ref_is focused($h), $view, 'and Shift+Tab from the first widget goes to the view';

	press( $h, 'Tab', 'End' );
	steps( $h, 2 );
	ref_is focused($h), $view, 'when the window drops the focused widget, the view takes the focus';
};

subtest 'Tab stays inside a dialog that holds the view' => sub {
	my $document = document( [ paragraph => 'Read this.' ] );
	my $inside   = $document->add( button('Inside') );
	my $view     = Term::Fabulous::Widget::DocumentView->new( id => 'help', document => $document, layout => { sizing => { width => sizing_grow(), height => sizing_fixed(6) } } );
	my $ok       = button('OK');
	my $dialog   = Term::Fabulous::Widget::Dialog->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_fixed(30) } } );
	$dialog->add_child( $view, $ok );
	my $outside = button('Outside');
	my $root    = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow(), height => sizing_grow() } } );
	$root->add_child($outside);
	my $terminal = Term::Fabulous::Terminal::Memory->new( width => 40, height => 12 );
	my $ui       = Term::Fabulous->new( root => $root, width => 40, height => 12, terminal => $terminal );
	$ui->step;
	$dialog->open($ui);
	$ui->interaction->set_focused_widget($view);
	$ui->step;
	my @seen;

	foreach ( 1 .. 4 ) {
		$terminal->press_key('Tab');
		$ui->step;
		push @seen, $ui->interaction->get_focused_widget;
	}
	is [ map { refaddr($_) } @seen ], [ map { refaddr($_) } $inside, $ok, $view, $inside ], 'view, its button, the dialog\'s button, around, never outside';
};

done_testing;
