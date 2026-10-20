use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use Clay::XS qw(sizing_fixed sizing_grow CLAY_TOP_TO_BOTTOM CLAY_TEXT_WRAP_NONE);
use Term::Fabulous;
use Term::Fabulous::Scrolling qw(
	inner_rows page_rows reveal_rows scroll_by_columns scroll_by_key scroll_by_pages scroll_by_rows
	scroll_to_end scroll_to_start scroll_offset max_scroll_offset scrolled_percent
);
use Term::Fabulous::Terminal::Memory;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::ScrollBox;
use Term::Fabulous::Widget::Text;
use Term::Fabulous::Widget::VirtualList;

# A ScrollBox of $lines lines, 10 rows tall from row 2 of the screen,
# with a border and a padding of a row above and below: its content
# shows in the 6 rows from row 4 to row 9. 30 lines and the 4 rows of
# border and padding scroll by up to 24 rows.
sub scroll_box_ui ( $lines = 30 ) {
	my $box = Term::Fabulous::Widget::ScrollBox->new(
		id       => 'box',
		vertical => 1,
		bordered => 1,
		layout   => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_fixed(10) }, padding => { top => 1, bottom => 1 } },
	);
	$box->add_child( Term::Fabulous::Widget::Text->new( text => "line $_" ) ) foreach 0 .. $lines - 1;
	my $root = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() }, padding => { top => 2 } } );
	$root->add_child($box);
	my $terminal = Term::Fabulous::Terminal::Memory->new( width => 20, height => 14 );
	my $ui       = Term::Fabulous->new( root => $root, width => 20, height => 14, terminal => $terminal );
	return ( $ui, $box );
}

sub offset ( $ui, $box ) {
	return scroll_offset( $ui, $box );
}

# Each move, then the offset after it.
sub moves ( $ui, $box, @moves ) {
	return [ map { ( $_->(), offset( $ui, $box ) ) } @moves ];
}

subtest 'before the first frame' => sub {
	my ( $ui, $box ) = scroll_box_ui();
	is [ scroll_by_rows( $ui, $box, 1 ), scroll_by_pages( $ui, $box, 1 ), scroll_to_end( $ui, $box ) ], [ 0, 0, 0 ], 'nothing scrolls';
	is [ inner_rows( $ui, $box ), page_rows( $ui, $box ), scrolled_percent( $ui, $box ) ], [ undef, undef ], 'and nothing is measured';
};

subtest 'rows' => sub {
	my ( $ui, $box ) = scroll_box_ui();
	$ui->step;
	is moves( $ui, $box, sub { scroll_by_rows( $ui, $box, 3 ) }, sub { scroll_by_rows( $ui, $box, -1 ) }, sub { scroll_by_rows( $ui, $box, -5 ) } ), [ 1, 3, 1, 2, 1, 0 ],
		'scroll down and up, as far as the top';
	is scroll_by_rows( $ui, $box, -1 ), 0, 'and return 0 at the top';
	like dies { scroll_by_rows( $ui,   $box, 1.5 ) }, qr/scroll_by_rows needs a number of rows, got '1\.5'/, 'a row is whole';
	like dies { scroll_by_rows( undef, $box, 1 ) },   qr/scroll_by_rows needs a UI, got undef/,              'and needs a UI';
};

subtest 'pages' => sub {
	my ( $ui, $box ) = scroll_box_ui();
	$ui->step;
	is [ inner_rows( $ui, $box ) ], [ 4, 10 ], 'the content shows inside the border and the padding';
	is page_rows( $ui, $box ),      5,         'a page is those rows less one';
	is moves( $ui, $box, sub { scroll_by_pages( $ui, $box, 2 ) }, sub { scroll_by_pages( $ui, $box, -1 ) }, sub { scroll_by_pages( $ui, $box, 9 ) } ), [ 1, 10, 1, 5, 1, 24 ],
		'pages go down and up, as far as the end';
	is scroll_by_pages( $ui, $box, 1 ), 0, 'and return 0 at the end';
};

subtest 'the ends' => sub {
	my ( $ui, $box ) = scroll_box_ui();
	$ui->step;
	is moves( $ui, $box, sub { scroll_to_end( $ui, $box ) }, sub { scroll_to_end( $ui, $box ) }, sub { scroll_to_start( $ui, $box ) }, sub { scroll_to_start( $ui, $box ) } ),
		[ 1, 24, 0, 24, 1, 0, 0, 0 ],
		'to the end and to the start, once';
};

subtest 'revealing rows' => sub {
	my ( $ui, $box ) = scroll_box_ui();
	$ui->step;
	is moves( $ui, $box, sub { reveal_rows( $ui, $box, 9, 10 ) }, sub { reveal_rows( $ui, $box, 12, 13 ) } ), [ 0, 0, 1, 3 ], 'a row in view stays, one below comes up to the last row';
	$ui->step;
	is moves( $ui, $box, sub { reveal_rows( $ui, $box, 2, 3 ) } ), [ 1, 1 ], 'one above comes down to the first row';
};

subtest 'revealing rows at the top' => sub {
	my ( $ui, $box ) = scroll_box_ui();
	$ui->step;
	is moves( $ui, $box, sub { reveal_rows( $ui, $box, 6, 7, align => 'top' ) } ), [ 1, 2 ], 'a row in view moves up to the first inner row';
	$ui->step;
	is moves( $ui, $box, sub { reveal_rows( $ui, $box, 4,   5,   align => 'top' ) } ), [ 0, 2 ],  'the first inner row stays';
	is moves( $ui, $box, sub { reveal_rows( $ui, $box, 100, 101, align => 'top' ) } ), [ 1, 24 ], 'near the end the content stops at its end';
	like dies { reveal_rows( $ui, $box, 4, 5, align  => 'middle' ) }, qr/reveal_rows: align must be one of nearest, top, got 'middle'/, 'another align dies';
	like dies { reveal_rows( $ui, $box, 4, 5, center => 1 ) },        qr/reveal_rows does not take center \(known: align\)/,            'and another option';
};

subtest 'the percentage' => sub {
	my ( $ui, $box ) = scroll_box_ui();
	$ui->step;
	my @percents;
	foreach my $rows ( 0, 5, 13, 6 ) {
		scroll_by_rows( $ui, $box, $rows );
		push @percents, scrolled_percent( $ui, $box );
	}
	is \@percents, [ 0, 21, 75, 100 ], 'the share of the way down, rounded';

	my ( $short_ui, $short ) = scroll_box_ui(3);
	$short_ui->step;
	is scrolled_percent( $short_ui, $short ), 100, 'content that fits is seen whole';
};

subtest 'the offsets' => sub {
	my ( $ui, $box ) = scroll_box_ui();
	is [ scroll_offset( $ui, $box ), max_scroll_offset( $ui, $box ) ], [ undef, undef ], 'undef before the first frame';
	$ui->step;
	is [ scroll_offset( $ui, $box ), max_scroll_offset( $ui, $box ) ], [ 0, 24 ], 'rows scrolled down and the most there can be';
	scroll_by_rows( $ui, $box, 5 );
	is scroll_offset( $ui, $box ), 5, 'positive once scrolled down';
};

subtest 'columns' => sub {
	my $box = Term::Fabulous::Widget::ScrollBox->new(
		id     => 'wide', horizontal => 1,
		layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_fixed(10), height => sizing_fixed(5) } }
	);
	$box->add_child( Term::Fabulous::Widget::Text->new( text => 'x' x 30, wrap_mode => CLAY_TEXT_WRAP_NONE ) );
	my $root = Term::Fabulous::Widget::Box->new;
	$root->add_child($box);
	my $ui = Term::Fabulous->new( root => $root, width => 20, height => 6, terminal => Term::Fabulous::Terminal::Memory->new( width => 20, height => 6 ) );
	$ui->step;
	my $column = sub { -$ui->scroll_state($box)->{position}{x} };
	is [ scroll_by_columns( $ui, $box, 4 ), $column->(), scroll_by_columns( $ui, $box, -9 ), $column->(), scroll_by_columns( $ui, $box, -1 ) ], [ 1, 4, 1, 0, 0 ], 'sideways, as far as the left edge';
	like dies { scroll_by_columns( $ui, $box, 'x' ) }, qr/scroll_by_columns needs a number of columns, got 'x'/, 'a column is whole';
};

subtest 'keys' => sub {
	my ( $ui, $box ) = scroll_box_ui();
	$ui->step;
	my $press = sub ( $set, @names ) {
		return [ map { my $moved = scroll_by_key( $ui, $box, $_, keys => $set ); ( $moved, offset( $ui, $box ) ) } @names ];
	};
	is $press->( pager => qw(PageDown PageDown PageUp Ctrl+End PageDown Ctrl+Home PageUp) ),   [ 1, 5, 1, 10, 1, 5, 1, 24, 0, 24, 1, 0, 0, 0 ], 'pager: pages and both ends, stopping there';
	is [ map { scroll_by_key( $ui, $box, $_, keys => 'pager' ) } 'Down', 'Home', 'j', undef ], [ undef, undef, undef, undef ],                  'pager: other keys are not its own';
	is $press->( less => qw(Down j Up k Space b PageDown PageUp G End g Home) ), [ 1, 1, 1, 2, 1, 1, 1, 0, 1, 5, 1, 0, 1, 5, 1, 0, 1, 24, 0, 24, 1, 0, 0, 0 ], 'less: rows, pages and both ends';
	is [ map { scroll_by_key( $ui, $box, $_, keys => 'less' ) } 'Ctrl+End', 'n', 'Left' ], [ undef, undef, undef ],                                            'less: other keys are not its own';
	like dies { scroll_by_key( $ui, $box, 'Down' ) },                         qr/scroll_by_key: keys must be one of less, pager, got undef/, 'the set is required';
	like dies { scroll_by_key( $ui, $box, 'Down', keys => 'vi' ) },           qr/keys must be one of less, pager, got 'vi'/,                 'and must be known';
	like dies { scroll_by_key( $ui, $box, 'Down', keys => 'less', x => 1 ) }, qr/scroll_by_key does not take x \(known: keys\)/,             'another option dies';
	my ( $early_ui, $early ) = scroll_box_ui();
	is scroll_by_key( $early_ui, $early, 'PageDown', keys => 'pager' ), 0, 'a key of the set before the first frame is used, but moves nothing';
};

subtest 'a VirtualList goes to its first and last item' => sub {
	my $list = Term::Fabulous::Widget::VirtualList->new(
		id     => 'list',
		count  => 200,
		build  => sub ($index) { Term::Fabulous::Widget::Text->new( text => "item $index" ) },
		layout => { sizing => { width => sizing_grow(), height => sizing_fixed(5) } },
	);
	my $root = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow(), height => sizing_grow() } } );
	$root->add_child($list);
	my $ui = Term::Fabulous->new( root => $root, width => 20, height => 8, terminal => Term::Fabulous::Terminal::Memory->new( width => 20, height => 8 ) );
	$ui->step;
	is scroll_to_start( $ui, $list ), 0, 'at the start already';
	is scroll_to_end( $ui, $list ),   1, 'sent to its last item';
	$ui->step for 1 .. 3;
	is $list->visible_items->{last},  199, 'which it shows';
	is scroll_to_end( $ui, $list ),   0,   'and then it is at the end';
	is scroll_to_start( $ui, $list ), 1,   'back to the first item';
	$ui->step for 1 .. 2;
	is [ $list->visible_items->{first}, scroll_offset( $ui, $list ) ], [ 0, 0 ], 'shown at the top';
};

subtest 'a VirtualList whose last item is taller than the view ends at its bottom' => sub {
	my $list = Term::Fabulous::Widget::VirtualList->new(
		id    => 'list',
		count => 20,
		build => sub ($index) {
			Term::Fabulous::Widget::Text->new( text => join "\n", map { "item $index line $_" } 1 .. ( $index == 19 ? 9 : 1 ) );
		},
		layout => { sizing => { width => sizing_grow(), height => sizing_fixed(5) } },
	);
	my $root = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow(), height => sizing_grow() } } );
	$root->add_child($list);
	my $ui = Term::Fabulous->new( root => $root, width => 20, height => 8, terminal => Term::Fabulous::Terminal::Memory->new( width => 20, height => 8 ) );
	$ui->step;
	is scroll_to_end( $ui, $list ), 1, 'sent to its last item';
	$ui->step for 1 .. 3;
	is scroll_to_end( $ui, $list ), 1, 'the item is in view: the list is scrolled to its end';
	$ui->step;
	is [ scroll_offset( $ui, $list ), $list->visible_items->{last} ], [ max_scroll_offset( $ui, $list ), 19 ], 'the end of the last item is at the bottom';
	is scroll_to_end( $ui, $list ),                                   0,                                       'and the list is at its end';
	$list->follow_end(1);
	$list->count(21);
	ok lives { $ui->step for 1 .. 4 }, 'following the end settles';
	is scroll_offset( $ui, $list ), max_scroll_offset( $ui, $list ), 'at the end';
};

subtest 'a ScrollBox follows its end' => sub {
	my $box
		= Term::Fabulous::Widget::ScrollBox->new( id => 'log', follow_end => 1, layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_fixed(4) } } );
	my $root = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow(), height => sizing_grow() } } );
	$root->add_child($box);
	my $ui   = Term::Fabulous->new( root => $root, width => 20, height => 6, terminal => Term::Fabulous::Terminal::Memory->new( width => 20, height => 6 ) );
	my $line = 0;
	my $add  = sub ($lines) { $box->add_child( Term::Fabulous::Widget::Text->new( text => 'line ' . $line++ ) ) for 1 .. $lines; $ui->step; $ui->step; return };
	$add->(10);
	is [ scroll_offset( $ui, $box ), max_scroll_offset( $ui, $box ) ], [ 6, 6 ], 'content added at the bottom scrolls into view';
	$add->(3);
	is scroll_offset( $ui, $box ), 9, 'and again';
	scroll_by_rows( $ui, $box, -2 );
	$ui->step;
	$add->(3);
	is [ scroll_offset( $ui, $box ), max_scroll_offset( $ui, $box ) ], [ 7, 12 ], 'scrolled up: the box stays where the user put it';
	scroll_to_end( $ui, $box );
	$ui->step;
	$add->(2);
	is [ scroll_offset( $ui, $box ), max_scroll_offset( $ui, $box ) ], [ 14, 14 ], 'back at the end, it follows again';
	$box->follow_end(0);
	$add->(2);
	is scroll_offset( $ui, $box ), 14, 'switched off, it stays';
	is $box->follow_end,           0,  'the accessor reads it';
	like dies { $box->follow_end( [] ) }, qr/follow_end must be a plain boolean value/, 'a reference dies';
};

done_testing;
