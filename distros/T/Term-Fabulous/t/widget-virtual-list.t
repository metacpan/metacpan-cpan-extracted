use v5.32;
use warnings;
use utf8;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use Clay::UI::Enum::Result;
use Clay::XS qw(sizing_grow);
use Scalar::Util qw(refaddr);
use Term::Fabulous;
use Term::Fabulous::Terminal::Memory;
use Term::Fabulous::Termbox qw(TB_KEY_MOUSE_WHEEL_DOWN TB_KEY_MOUSE_WHEEL_UP);
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Text;
use Term::Fabulous::Widget::VirtualList;

# A 30 x 8 memory terminal showing a list of $count items without a
# border; item $i is a text "Item $i" of $rows lines. Returns the list and
# a harness with the terminal, the UI and how often each item was built.
sub list_ui ( $count, %args ) {
	my $rows = delete $args{rows} // 1;
	my @built;
	my $list = Term::Fabulous::Widget::VirtualList->new(
		id    => 'list',
		count => $count,
		build => sub ($index) {
			$built[$index]++;
			return Term::Fabulous::Widget::Text->new( text => join "\n", "Item $index", map { "Item $index ($_)" } 2 .. $rows );
		},
		layout => { sizing => { width => sizing_grow(), height => sizing_grow() } },
		%args,
	);
	my $root = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow(), height => sizing_grow() } } );
	$root->add_child($list);
	my $terminal = Term::Fabulous::Terminal::Memory->new( width => 30, height => 8 );
	my $ui       = Term::Fabulous->new( root => $root, width => 30, height => 8, terminal => $terminal );
	$ui->step;
	return ( $list, { terminal => $terminal, ui => $ui, built => \@built } );
}

sub row ( $h, $y ) {
	my $text = join '', map { ( $h->{terminal}->cell( $_, $y ) // [' '] )->[0] // ' ' } 0 .. 28;    # the last column is the scrollbar
	$text =~ s/\s+\z//;
	return $text;
}

sub wheel ( $h, $notches, $direction = 'down' ) {
	$h->{terminal}->mouse( key => $direction eq 'down' ? TB_KEY_MOUSE_WHEEL_DOWN : TB_KEY_MOUSE_WHEEL_UP, x => 5, y => 3 ) foreach 1 .. $notches;
	$h->{ui}->step;
	return;
}

sub built_count ($h) {
	return scalar grep { $_ } @{ $h->{built} };
}

subtest 'parameters' => sub {
	my %minimal = ( id => 'l', build => sub { Term::Fabulous::Widget::Text->new( text => 'x' ) } );
	like dies { Term::Fabulous::Widget::VirtualList->new( id => 'l' ) },                  qr/build/,                                                       'build is required';
	like dies { Term::Fabulous::Widget::VirtualList->new( %minimal, build => 'items' ) }, qr/build must be a code reference/,                              'and must be code';
	like dies { Term::Fabulous::Widget::VirtualList->new( %minimal, count => -1 ) },      qr/count must be a non-negative integer/,                        'count is checked';
	like dies { Term::Fabulous::Widget::VirtualList->new( %minimal, estimate => {} ) },   qr/estimate must be a code reference or a non-negative integer/, 'estimate is checked';
	like dies { Term::Fabulous::Widget::VirtualList->new( %minimal, overscan => 1.5 ) },  qr/overscan must be a non-negative integer/,                     'overscan is checked';
	like dies { Term::Fabulous::Widget::VirtualList->new( build => $minimal{build} ) },   qr/requires an explicit 'id'/,                                   'an id is required, as for a ScrollBox';

	my $list = Term::Fabulous::Widget::VirtualList->new( %minimal, count => 3, estimate => 2 );
	is [ $list->count, $list->overscan, $list->estimate->( 0, 80 ) ], [ 3, undef, 2 ], 'count, overscan and an estimate given as rows';
	is $list->children,                                               [],              'a list has no children of its own';
	like dies { $list->add_child( Term::Fabulous::Widget::Text->new( text => 'x' ) ) }, qr/add_child is not supported/,                  'add_child dies';
	like dies { $list->clear_children },                                                qr/clear_children is not supported/,             'clear_children dies';
	like dies { $list->item(3) },                                                       qr/item 3 does not exist, the list has 3 items/, 'item checks the index';
	like dies { $list->scroll_to_item('x') },                                           qr/scroll_to_item needs an item index/,          'so does scroll_to_item';
	like dies { $list->item(0) }, qr/build must return a widget for item 0, got 'oops'/, 'a build that returns no widget dies'
		if $list->build( sub { 'oops' } );
};

subtest 'only the items near the viewport are attached' => sub {
	my ( $list, $h ) = list_ui(1000);
	is $list->window, { first => 0, last => 15 },        'the viewport (8 rows) and an overscan of a viewport below it';
	is built_count($h),                                  16,                     'and nothing else was built';
	is [ map { row( $h, $_ ) } 0, 7 ],                   [ 'Item 0', 'Item 7' ], 'the viewport shows the first items';
	is $h->{ui}->scroll_state($list)->{content}{height}, 1000,                   'the content is as tall as all items together';
	is $list->visible_items, { first => 0, last => 7 },  'visible_items reports the viewport';
	ok $list->item(0)->parent->isa('Term::Fabulous::Widget::Box'), 'a text item lives in a box of its own';
	is $list->item(500)->parent, undef, 'item builds an item on demand, unattached';
	is $h->{built}[500],         1,     'once';
};

subtest 'the wheel moves the window' => sub {
	my ( $list, $h ) = list_ui(1000);
	wheel( $h, 2 );
	is row( $h, 0 ), 'Item 6', 'two notches scroll six rows';
	is $list->window, { first => 0, last => 15 }, 'inside the attached items nothing is rebuilt';
	wheel( $h, 31 );
	is row( $h, 0 ), 'Item 99', 'thirty more notches';
	is $list->window, { first => 91, last => 114 }, 'the window moved with the viewport';
	ok built_count($h) < 60, 'and only the items passed were built (' . built_count($h) . ')';
	wheel( $h, 5, 'up' );
	is row( $h, 0 ), 'Item 84', 'the wheel scrolls back up';
};

subtest 'measured heights replace the estimates and the top item stays' => sub {
	my ( $list, $h ) = list_ui( 300, rows => 2 );
	is $h->{ui}->scroll_state($list)->{content}{height}, 316, 'the 16 attached items are known to be two rows tall, the rest estimated at one';
	$list->scroll_to_item(200);
	$h->{ui}->step;
	is row( $h, 0 ), 'Item 200', 'scroll_to_item puts the item at the top';
	is $list->visible_items, { first => 200, last => 203 }, 'four two-row items fit';
	my $before = $h->{ui}->scroll_state($list)->{content}{height};
	wheel( $h, 8, 'up' );
	is row( $h, 0 ), 'Item 188', 'eight notches up show the twenty-four rows above, as they really are';
	ok $h->{ui}->scroll_state($list)->{content}{height} > $before, 'now that the items that came into the window were measured';
};

subtest 'scroll_to from code is followed in the same frame' => sub {
	my ( $list, $h ) = list_ui(1000);
	$h->{ui}->scroll_to( $list, { y => -500 } );
	$h->{ui}->step;
	is [ row( $h, 0 ), row( $h, 7 ) ], [ 'Item 500', 'Item 507' ], 'the frame shows the new position';
	is $list->window, { first => 492, last => 515 }, 'with the window around it';
};

subtest 'a change of the terminal size is followed' => sub {
	my ( $list, $h ) = list_ui(1000);
	$h->{terminal}->resize( 30, 20 );
	$h->{ui}->step;
	is [ row( $h, 8 ), row( $h, 19 ) ], [ 'Item 8', 'Item 19' ], 'a taller terminal shows more items';
	is $list->window, { first => 0, last => 39 }, 'and the window grew with the viewport';
};

subtest 'the gap of the list lies between the items' => sub {
	my ( $list, $h ) = list_ui( 100, layout => { sizing => { width => sizing_grow(), height => sizing_grow() }, child_gap => 1 } );
	is [ map { row( $h, $_ ) } 0 .. 2 ],                 [ 'Item 0', '', 'Item 1' ], 'one empty row between items';
	is $h->{ui}->scroll_state($list)->{content}{height}, 199,                        'the content counts the gaps';
	$list->scroll_to_item(99);
	$h->{ui}->step;
	is row( $h, 7 ), 'Item 99', 'the last item ends at the bottom';
};

subtest 'count and rebuild' => sub {
	my ( $list, $h ) = list_ui(20);
	my $first = $list->item(0);
	$list->count(30);
	$h->{ui}->step;
	is $h->{ui}->scroll_state($list)->{content}{height}, 30,              'a larger count adds items';
	is refaddr( $list->item(0) ),                        refaddr($first), 'and keeps the widgets it has';
	$list->count(5);
	$h->{ui}->step;
	is [ $list->window, row( $h, 4 ), row( $h, 5 ) ], [ { first => 0, last => 4 }, 'Item 4', '' ], 'a smaller count drops items';
	$list->rebuild;
	$h->{ui}->step;
	isnt refaddr( $list->item(0) ), refaddr($first), 'rebuild builds the items again';
	is $h->{built}[0],              2,               'once more';
	is row( $h, 0 ),                'Item 0',        'and shows them';
};

subtest 'OnScroll bubbles to the ancestors' => sub {
	my ( $list, $h ) = list_ui(1000);
	my %scrolls = ( list => 0, root => 0 );
	$list->on( OnScroll => sub { $scrolls{list}++; return Clay::UI::Enum::Result->CONTINUE } );
	$h->{ui}->root->on( OnScroll => sub { $scrolls{root}++; return Clay::UI::Enum::Result->CONTINUE } );
	wheel( $h, 1 );
	is \%scrolls, { list => 1, root => 1 }, 'a wheel notch over the list reaches the list and the root';
};

subtest 'a smaller count forgets the heights of the dropped items' => sub {
	my $rows = 3;
	my ( $list, $h ) = list_ui( 100, build => sub ($index) { Term::Fabulous::Widget::Text->new( text => join "\n", ("Item $index") x $rows ) } );
	$list->scroll_to_item(50);
	$h->{ui}->step;
	$list->count(2);
	$h->{ui}->step;
	$rows = 1;
	$list->count(100);
	$h->{ui}->step;
	is $h->{ui}->scroll_state($list)->{content}{height}, 2 * 3 + 98, 'the two kept items are three rows tall, the 98 new ones one row';
};

done_testing;
