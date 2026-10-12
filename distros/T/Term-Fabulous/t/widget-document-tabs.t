use v5.32;
use warnings;
use utf8;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use FindBin;
use lib "$FindBin::Bin/lib";

use Clay::XS qw(sizing_fixed);
use InputTest;
use Term::Fabulous::Event::TabAdd;
use Term::Fabulous::Event::TabClose;
use Term::Fabulous::Render::Attr qw(cell_color_attr);
use Term::Fabulous::Termbox qw(TB_BOLD TB_KEY_MOUSE_MIDDLE TB_MOD_MOTION);
use Term::Fabulous::Widget::DocumentTabs;
use Term::Fabulous::Widget::Text;

sub document_tabs (%args) {
	my $width = delete $args{width} // 40;
	return Term::Fabulous::Widget::DocumentTabs->new( %args, layout => { sizing => { width => sizing_fixed($width) } } );
}

my @three = ( { title => 'one' }, { title => 'two', modified => 1 }, { title => 'three', modified => 1, error => 1 } );

# The events a click fires, as [ name, index, title ].
sub events_of ($tabs) {
	my @events;
	$tabs->on( Select   => sub ($event) { push @events, [ 'Select',   $event->index, $event->item->{title} ]; return } );
	$tabs->on( TabClose => sub ($event) { push @events, [ 'TabClose', $event->index, $event->item->{title} ]; return } );
	$tabs->on( TabAdd   => sub ($event) { push @events, ['TabAdd']; return } );
	return \@events;
}

# The attributes of a cell of the row: foreground and background.
sub attrs_at ( $tabs, $x ) {
	shown($tabs);
	my ( undef, $fgs, $bgs ) = $tabs->cell_row(0);
	return [ $fgs->[$x], $bgs->[$x] ];
}

sub attr_of ($color) {
	return cell_color_attr( color => $color );
}

subtest 'tabs with marks and the + button' => sub {
	my $tabs = document_tabs( tabs => \@three, active => 0 );
	my $ui   = layout_ui($tabs);
	is [ $tabs->columns, $tabs->rows ], [ 40, 1 ],                                                                    'one row, as wide as the layout lets it be';
	is row_text( $tabs, 0 ),            " one   \x{00D7}  two \x{25CF} \x{00D7}  three ! \x{00D7}  + " . ( ' ' x 8 ), 'each tab with its title, mark and close mark, then +';
	is $tabs->count,                    3,                                                                            'count';
	is $tabs->tab(1), { title => 'two', modified => 1, error => 0, closable => 1 }, 'tab returns the checked tab';
	is $tabs->tab(3),                                                               undef, 'and undef past the end';
};

subtest 'an error wins over unsaved changes' => sub {
	my $tabs = document_tabs( tabs => \@three );
	my $ui   = layout_ui($tabs);
	is attrs_at( $tabs, 14 )->[0], attr_of( $tabs->modified_color ), 'the dot in modified_color';
	is attrs_at( $tabs, 25 )->[0], attr_of( $tabs->error_color ),    'a tab with both shows ! in error_color';
	is attrs_at( $tabs, 16 )->[0], attr_of( $tabs->text_color ),     'the close mark in the text color of its tab';
};

subtest 'the active tab' => sub {
	my $tabs = document_tabs( tabs => \@three, active => 1 );
	my $ui   = layout_ui($tabs);
	is attrs_at( $tabs, 10 ), [ attr_of( $tabs->active_text_color ) | TB_BOLD, attr_of( $tabs->active_background_color ) ], 'bold on the active background';
	is attrs_at( $tabs, 1 ), [ attr_of( $tabs->text_color ), attr_of( $tabs->background_color ) ], 'the others on the background';
	foreach my $none ( undef, 3 ) {
		$tabs->active($none);
		my ( undef, undef, $bgs ) = shown($tabs)->cell_row(0);
		is [ grep { $_ == attr_of( $tabs->active_background_color ) } @$bgs ], [], 'no active tab with active ' . ( $none // 'undef' );
	}
};

subtest 'many tabs scroll to the active one' => sub {
	my $tabs   = document_tabs( tabs => [ map { { title => "doc-$_.txt" } } 0 .. 9 ], active => 7 );
	my $ui     = layout_ui($tabs);
	my $events = events_of($tabs);
	is row_text( $tabs, 0 ), "\x{25C2} doc-6.txt   \x{00D7}  doc-7.txt   \x{00D7} \x{25B8} + " . ( ' ' x 5 ), 'arrows at both ends, the active tab shown';
	click( $tabs, 0,  0 );
	click( $tabs, 31, 0 );
	is $events, [ [ 'Select', 5, 'doc-5.txt' ], [ 'Select', 8, 'doc-8.txt' ] ], 'an arrow selects the next hidden tab on its side';
	$tabs->active(0);
	like row_text( $tabs, 0 ), qr/\A doc-0\.txt/, 'setting active scrolls back';
};

subtest 'clicks' => sub {
	my $tabs   = document_tabs( tabs => \@three, active => 0 );
	my $ui     = layout_ui($tabs);
	my $events = events_of($tabs);
	click( $tabs, 2,  0 );
	click( $tabs, 11, 0 );
	click( $tabs, 27, 0 );
	click( $tabs, 20, 0, key => TB_KEY_MOUSE_MIDDLE );
	click( $tabs, 30, 0 );
	is $events, [ [ 'Select', 0, 'one' ], [ 'Select', 1, 'two' ], [ 'TabClose', 2, 'three' ], [ 'TabClose', 2, 'three' ], ['TabAdd'] ],
		'a tab (the active one too) selects, its close mark and a middle click close it, + adds';
	click( $tabs, 11, 0, modifiers => TB_MOD_MOTION );
	is scalar @$events, 5, 'motion is ignored';
	is $tabs->active,   0, 'the tabs never change active themselves';
	screen_click( $tabs, 11, 0 );
	my $focused = $ui->interaction->get_focused_widget;
	ok !defined $focused || $focused != $tabs, 'and never take the focus';
};

subtest 'a tab that cannot be closed' => sub {
	my $tabs   = document_tabs( tabs => [ { title => 'log', closable => 0 }, { title => 'b' } ] );
	my $ui     = layout_ui($tabs);
	my $events = events_of($tabs);
	is row_text( $tabs, 0 ), " log    b   \x{00D7}  + " . ( ' ' x 23 ), 'no close mark';
	click( $tabs, 1, 0, key => TB_KEY_MOUSE_MIDDLE );
	click( $tabs, 6, 0 );
	is $events, [ [ 'Select', 0, 'log' ] ], 'a middle click does nothing, a click where the mark would be selects';
};

subtest 'without the + button' => sub {
	my $tabs   = document_tabs( tabs => [ { title => 'one' } ], new_button => 0 );
	my $ui     = layout_ui($tabs);
	my $events = events_of($tabs);
	is row_text( $tabs, 0 ), " one   \x{00D7} " . ( ' ' x 31 ), 'no + after the tabs';
	click( $tabs, 10, 0 );
	is $events, [], 'and nothing to click there';
};

subtest 'a long title is cut' => sub {
	my $tabs = document_tabs( tabs => [ { title => 'a-very-long-document-title.txt', modified => 1 } ], active => 0, width => 24 );
	my $ui   = layout_ui($tabs);
	is row_text( $tabs, 0 ), " a-very-long-\x{2026} \x{25CF} \x{00D7}  +   ", 'cut with an ellipsis so the tab fits before +';
};

subtest 'tabs from a code reference' => sub {
	my @titles = qw(a b);
	my $tabs   = document_tabs(
		tabs => sub {
			map { { title => $_ } } @titles;
		}
	);
	my $other = Term::Fabulous::Widget::Text->new( text => 'x' );
	my $ui    = layout_ui( $tabs, $other );
	like row_text( $tabs, 0 ), qr/\A a   \x{00D7}  b   \x{00D7}  \+ /, 'the tabs as the code returns them';
	push @titles, 'c';
	$other->text('y');
	like row_text( $tabs, 0 ), qr/ c   \x{00D7}  \+ /, 'read again whenever a frame is drawn';
	is $tabs->count, 3, 'count calls the code';
	@titles = (undef);
	like dies { $tabs->tab(0) }, qr/the title of a tab must be a string, got undef/, 'a bad tab from the code dies when it is read';
};

subtest 'checks' => sub {
	like dies { document_tabs( tabs   => 'a' ) },                               qr/tabs must be an array reference or a code reference, got 'a'/, 'tabs must be a list or code';
	like dies { document_tabs( tabs   => ['a'] ) },                             qr/a tab must be a hash reference with a title, got 'a'/,         'a tab is a hash';
	like dies { document_tabs( tabs   => [ { modified => 1 } ] ) },             qr/the title of a tab must be a string, got undef/,               'a tab needs a title';
	like dies { document_tabs( tabs   => [ { title => 'a', error => [] } ] ) }, qr/error must be a plain boolean value/,                          'flags are booleans';
	like dies { document_tabs( active => -1 ) },                                qr/active must be a non-negative integer, got '-1'/,              'active is a position or undef';
	like dies { document_tabs()->tab('x') }, qr/index must be a non-negative integer, got 'x'/, 'tab takes a position';
	is document_tabs( tabs => [ { title => "a\n b ", path => '/tmp/a' } ] )->tabs, [ { title => 'a b', path => '/tmp/a', modified => 0, error => 0, closable => 1 } ],
		'one row, keys of the program kept';
};

subtest 'events' => sub {
	my $event = Term::Fabulous::Event::TabClose->new( item => { title => 'a' }, index => 2 );
	is [ $event->name, $event->item, $event->index ], [ 'TabClose', { title => 'a' }, 2 ], 'TabClose has item and index';
	like dies { Term::Fabulous::Event::TabClose->new( item => 'a',              index =>  0 ) }, qr/item must be a hash reference, got 'a'/, 'item is a tab';
	like dies { Term::Fabulous::Event::TabClose->new( item => { title => 'a' }, index => -1 ) }, qr/index must be a non-negative integer/,   'index is a position';
	is( Term::Fabulous::Event::TabAdd->new->name, 'TabAdd', 'TabAdd' );
};

subtest 'the theme colors the tabs' => sub {
	my $tabs     = document_tabs( tabs => \@three );
	my $ui       = layout_ui($tabs);
	my %token_of = (
		background_color        => 'surface_low',
		active_background_color => 'focus_background',
		text_color              => 'text_dim',
		active_text_color       => 'text',
		modified_color          => 'accent',
		error_color             => 'danger',
		button_color            => 'accent',
	);
	is {
		map { $_ => $tabs->$_ } keys %token_of
	}, { map { $_ => $ui->theme->token( $token_of{$_} ) } keys %token_of }, 'the document_tabs family';
	$tabs->button_color('#00ff00');
	is attrs_at( $tabs, 30 )->[0], attr_of( [ 0, 255, 0, 255 ] ), 'a color of your own';
};

done_testing;
