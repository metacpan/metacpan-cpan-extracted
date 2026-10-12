use v5.32;
use warnings;
use utf8;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use FindBin;
use lib "$FindBin::Bin/lib";

use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);
use Term::Fabulous;
use Term::Fabulous::Layout;
use Term::Fabulous::Terminal::Memory;
use Term::Fabulous::Widget::Accordion;
use Term::Fabulous::Widget::Accordion::Item;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Text;
use Term::Fabulous::Widget::TextField;

# An accordion of three items on a memory terminal, the first with a
# text field in its body, the third disabled; returns it, the terminal,
# the UI and the Select events as [ index, open ].
sub accordion (%args) {
	my $accordion = Term::Fabulous::Widget::Accordion->new(%args);
	my @items     = map { Term::Fabulous::Widget::Accordion::Item->new( title => $_ ) } qw(General Network Users);
	$items[0]->add_child( Term::Fabulous::Widget::Text->new( text => 'Language: en' ), Term::Fabulous::Widget::TextField->new( value => 'field', preferred_columns => 10 ) );
	$items[1]->add_child( Term::Fabulous::Widget::Text->new( text => 'Hostname: example.org' ) );
	$items[2]->disabled(1);
	$accordion->add_child(@items);

	my $root = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() } } );
	$root->add_child($accordion);
	my $terminal = Term::Fabulous::Terminal::Memory->new( width => 30, height => 8 );
	my $ui       = Term::Fabulous->new( root => $root, width => 30, height => 8, terminal => $terminal );
	my @events;
	$accordion->on( Select => sub ($event) { push @events, [ $event->index, $event->open, $event->item->title ]; return } );
	$ui->step;
	return ( $accordion, $terminal, $ui, \@events );
}

sub lines ($terminal) {
	return [ grep { length } map { s/\s+\z//r } $terminal->lines ];
}

subtest 'items open and close' => sub {
	my ( $accordion, $terminal, $ui, $events ) = accordion();
	is lines($terminal), [ "\x{25B8} General", "\x{25B8} Network", "\x{25B8} Users" ], 'all closed: a header per item';
	is [ scalar $accordion->items, $accordion->selected ], [ 3, undef ], 'three items, none open';

	$accordion->open(0);
	$ui->step;
	is lines($terminal),                          [ "\x{25BE} General", '  Language: en', '  field', "\x{25B8} Network", "\x{25B8} Users" ], 'an open item shows its body, indented';
	is $accordion->open(1)->selected->title,      'Network',                                                                                 'opening another closes the first';
	is [ map { $_->is_open } $accordion->items ], [ 0, 1, 0 ],                                                                               'one open item at a time';
	$accordion->close(1);
	is [ $accordion->open_items ], [], 'close';
	like dies { $accordion->open_all }, qr/open_all needs multiple/, 'open_all needs multiple';
	is $events, [], 'programmatic changes fire nothing';

	$accordion->multiple(1);
	$accordion->open_all;
	is [ map { $_->is_open } $accordion->items ], [ 1, 1, 1 ], 'with multiple, all can be open';
	$accordion->multiple(0);
	is [ map { $_->is_open } $accordion->items ], [ 1, 0, 0 ], 'back to one: the first stays';
	like dies { $accordion->add_child( Term::Fabulous::Widget::Text->new( text => 'x' ) ) }, qr/holds only Term::Fabulous::Widget::Accordion::Item/, 'only items';
};

subtest 'keys and clicks' => sub {
	my ( $accordion, $terminal, $ui, $events ) = accordion();
	$terminal->press_key('Tab');
	$ui->step;
	ok $accordion->item(0)->is_focused, 'Tab focuses the first header';
	$terminal->press_key('Enter');
	$ui->step;
	is [ $accordion->item(0)->is_open, $events ], [ 1, [ [ 0, 1, 'General' ] ] ], 'Enter opens it and fires Select';
	$terminal->press_key('Tab');
	$ui->step;
	ok $accordion->item(0)->body->children->[1]->is_focused, 'Tab goes on into the open body';
	$terminal->press_key('Tab');
	$ui->step;
	ok $accordion->item(1)->is_focused, 'and then to the next header';
	$terminal->press_key('Tab');
	$ui->step;
	ok !$accordion->item(2)->is_focused, 'a disabled item is skipped';

	$accordion->item(1)->focus;
	$terminal->press_key('Space');
	$ui->step;
	is [ map { $_->is_open } $accordion->items ], [ 0, 1, 0 ],         'Space opens the second and closes the first';
	is $events->[-1],                             [ 1, 1, 'Network' ], 'only the item acted on fires';
	$terminal->press_key('Space');
	$ui->step;
	is [ $accordion->item(1)->is_open, $events->[-1] ], [ 0, [ 1, 0, 'Network' ] ], 'Space again closes it';

	$terminal->press_key('Up');
	$ui->step;
	ok $accordion->item(0)->is_focused, 'Up moves to the previous header';
	$terminal->press_key('End');
	$ui->step;
	ok $accordion->item(1)->is_focused, 'End to the last enabled one';
	$terminal->press_key('Down');
	$ui->step;
	ok $accordion->item(0)->is_focused, 'Down wraps around';

	$terminal->click( 3, 1 );
	$ui->step;
	is [ $accordion->item(1)->is_open, $accordion->item(1)->is_focused, $events->[-1] ], [ 1, 1, [ 1, 1, 'Network' ] ], 'a click on a header opens it and focuses it';
	$terminal->click( 3, 3 );
	$ui->step;
	is $accordion->item(2)->is_open, 0, 'a click on a disabled header does nothing';
	$accordion->choose(2);
	is scalar @$events, 4, 'choose on a disabled item fires nothing';
	$accordion->choose(0);
	is $events->[-1], [ 0, 1, 'General' ], 'choose acts as the user does';
};

subtest 'looks' => sub {
	my ( $accordion, $terminal, $ui ) = accordion( toggle_position => 'end', open_glyph => '-', closed_glyph => '+', item_borders => 1, body_indent => 0 );
	$accordion->open(1);
	$ui->step;
	is lines($terminal), [
		"\x{256D}" . ( "\x{2500}" x 28 ) . "\x{256E}",
		"\x{2502}General" . ( ' ' x 20 ) . "+\x{2502}",
		"\x{2570}" .        ( "\x{2500}" x 28 ) . "\x{256F}",
		"\x{256D}" .        ( "\x{2500}" x 28 ) . "\x{256E}",
		"\x{2502}Network" . ( ' ' x 20 ) . "-\x{2502}",
		"\x{2502}Hostname: example.org       \x{2502}",
		"\x{2570}" . ( "\x{2500}" x 28 ) . "\x{256F}",
		"\x{256D}" . ( "\x{2500}" x 28 ) . "\x{256E}",
		],
		'borders, the toggles at the end, no indent (the terminal cuts the last item off)';
	$accordion->item_borders(0);
	$accordion->toggle_position('start');
	$ui->step;
	is lines($terminal)->[0], '+ General', 'restyled at once';
	like dies { $accordion->toggle_position('middle') }, qr/toggle_position must be one of end, start, got 'middle'/, 'an unknown position dies';
};

subtest 'a layout builds items into the accordion' => sub {
	my $built = Term::Fabulous::Layout->new( string => <<'KDL' )->build;
use Term::Fabulous::Widget::Accordion as Accordion
use Term::Fabulous::Widget::Accordion::Item as Item
use Term::Fabulous::Widget::Text as Text
Accordion "settings" {
	multiple #true
	title_bold #true
	Item "general" { title "General"; open #true; Text { text "a"; } }
	Item "network" { title "Network"; icon "#"; disabled #true; Text { text "b"; } }
}
KDL
	is [ $built->multiple, $built->title_bold, map { [ $_->title, $_->is_open, $_->disabled, scalar $_->body->children->@* ] } $built->items ],
		[ 1, 1, [ 'General', 1, 0, 1 ], [ 'Network', 0, 1, 1 ] ], 'the items with their bodies';
};

done_testing;
