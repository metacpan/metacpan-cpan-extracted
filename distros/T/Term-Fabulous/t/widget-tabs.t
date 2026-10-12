use v5.32;
use warnings;
use utf8;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use FindBin;
use lib "$FindBin::Bin/lib";

use Clay::XS qw(sizing_grow sizing_fixed CLAY_TOP_TO_BOTTOM);
use Term::Fabulous;
use Term::Fabulous::Enum::BorderStyle;
use Term::Fabulous::Layout;
use Term::Fabulous::Terminal::Memory;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Tabs;
use Term::Fabulous::Widget::Tabs::Bar;
use Term::Fabulous::Widget::Tabs::Button;
use Term::Fabulous::Widget::Tabs::Page;
use Term::Fabulous::Widget::Text;
use Term::Fabulous::Widget::TextField;

# A Tabs of three pages on a memory terminal, the first with a text
# field, the third disabled; returns it, the terminal, the UI and the
# Select events as [ index, title ].
sub tabs (%args) {
	my ( $width, $height ) = ( delete $args{width} // 40, delete $args{height} // 10 );
	my $tabs  = Term::Fabulous::Widget::Tabs->new(%args);
	my @pages = map { Term::Fabulous::Widget::Tabs::Page->new( title => $_ ) } qw(General Network Users);
	$pages[0]->add_child( Term::Fabulous::Widget::Text->new( text => 'Language: en' ), Term::Fabulous::Widget::TextField->new( value => 'field', preferred_columns => 10 ) );
	$pages[1]->add_child( Term::Fabulous::Widget::Text->new( text => 'Hostname: example.org' ) );
	$pages[2]->disabled(1);
	$tabs->add_child(@pages);

	my $root = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow(), height => sizing_grow() } } );
	$root->add_child($tabs);
	my $terminal = Term::Fabulous::Terminal::Memory->new( width => $width, height => $height );
	my $ui       = Term::Fabulous->new( root => $root, width => $width, height => $height, terminal => $terminal );
	my @events;
	$tabs->on( Select => sub ($event) { push @events, [ $event->index, $event->item->title ]; return } );
	$ui->step;
	return ( $tabs, $terminal, $ui, \@events );
}

sub lines ($terminal) {
	return [ map { s/\s+\z//r } $terminal->lines ];
}

subtest 'the picture: tabs along the top' => sub {
	my ( $tabs, $terminal, $ui ) = tabs();
	is lines($terminal), [
		" \x{256D}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{256E}",
		" \x{2502} General \x{2502} \x{256D}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{256E} \x{256D}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{256E}",
		" \x{2502}         \x{2502} \x{2502} Network \x{2502} \x{2502} Users \x{2502}",
"\x{256D}\x{256F}         \x{2570}\x{2500}\x{2534}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{2534}\x{2500}\x{2534}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{2534}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{256E}",
		"\x{2502}                                      \x{2502}",
		"\x{2502} Language: en                         \x{2502}",
		"\x{2502} field                                \x{2502}",
		"\x{2502}                                      \x{2502}",
		"\x{2502}                                      \x{2502}",
		"\x{2570}" . ( "\x{2500}" x 38 ) . "\x{256F}",
		],
		'the active tab is raised and open toward the page, the others closed by its border';
	is [ scalar $tabs->pages, $tabs->active_index, $tabs->active->title ], [ 3, 0, 'General' ], 'the first page is the active one';
	is [ map { $_->is_active } $tabs->bar->buttons ],                      [ 1, 0, 0 ],         'and its tab';

	$tabs->select(1);
	$ui->step;
	is lines($terminal)->[3],
		"\x{256D}\x{2534}" . ( "\x{2500}" x 9 ) . "\x{2534}\x{2500}\x{256F}         \x{2570}\x{2500}\x{2534}" . ( "\x{2500}" x 7 ) . "\x{2534}" . ( "\x{2500}" x 5 ) . "\x{256E}",
		'select opens another tab';
	is lines($terminal)->[5],                                                            "\x{2502} Hostname: example.org                \x{2502}", 'and shows its page';
	is [ $tabs->page(1)->is_active, $tabs->page(0)->is_active, $tabs->page(0)->parent ], [ 1, 0, undef ],                                          'a page that is not shown has no parent';
	$tabs->select(undef);
	$ui->step;
	is [ $tabs->active, lines($terminal)->[4] ], [ undef, '' ], 'undef shows no page';
};

subtest 'sides, orientations and styles' => sub {
	my ( $tabs, $terminal, $ui ) = tabs( side => 'left', width => 40, height => 12 );
	is [ @{ lines($terminal) }[ 0 .. 7 ] ], [
		"           \x{256D}" . ( "\x{2500}" x 27 ) . "\x{256E}",
		"\x{256D}" . ( "\x{2500}" x 10 ) . "\x{256F}                           \x{2502}",
		"\x{2502} General    Language: en              \x{2502}",
		"\x{2570}" . ( "\x{2500}" x 10 ) . "\x{256E} field                     \x{2502}",
		"           \x{2502}                           \x{2502}",
		" \x{256D}" . ( "\x{2500}" x 9 ) . "\x{2524}                           \x{2502}",
		" \x{2502} Network \x{2502}                           \x{2502}",
		" \x{2570}" . ( "\x{2500}" x 9 ) . "\x{2524}                           \x{2502}",
		],
		'on the left, the tabs stack and the active one is a column wider';

	$tabs->side('bottom');
	$ui->step;
	is lines($terminal)->[-1], " \x{2570}" . ( "\x{2500}" x 9 ) . "\x{256F}", 'the bottom bar hangs below the page';
	is lines($terminal)->[0],  "\x{256D}" . ( "\x{2500}" x 38 ) . "\x{256E}", 'which has its border on top now';

	( $tabs, $terminal, $ui ) = tabs( orientation => 'vertical', height => 18 );
	is [ @{ lines($terminal) }[ 0 .. 3 ] ], [
		" \x{256D}\x{2500}\x{256E}",
		" \x{2502} \x{2502} \x{256D}\x{2500}\x{256E}",
		" \x{2502}G\x{2502} \x{2502} \x{2502}",
		" \x{2502}e\x{2502} \x{2502}N\x{2502} \x{256D}\x{2500}\x{256E}",
		],
		'vertical labels are written downwards, the tabs aligned toward the page';

	$tabs->orientation('horizontal');
	$tabs->line_style('Heavy');
	$tabs->page_border(0);
	$tabs->tab_alignment('end');
	$ui->step;
	is [ @{ lines($terminal) }[ 3, 4, 5 ] ], [
		( "\x{2501}" x 6 ) . "\x{251B}         \x{2517}\x{2501}\x{253B}" . ( "\x{2501}" x 9 ) . "\x{253B}\x{2501}\x{253B}" . ( "\x{2501}" x 7 ) . "\x{253B}\x{2501}",
		'',
		' Language: en',
		],
		'another style, tabs at the end, no border around the page';
	is $tabs->line_style->name, 'Heavy', 'the style is an item';
	like dies { $tabs->line_style('Block') }, qr/line_style must be a border style with joints/,   'a style without joints dies';
	like dies { $tabs->side('middle') },      qr/side must be one of bottom, left, right, top/,    'an unknown side dies';
	like dies { $tabs->orientation('up') },   qr/orientation must be one of horizontal, vertical/, 'an unknown orientation dies';
};

subtest 'keys and clicks' => sub {
	my ( $tabs, $terminal, $ui, $events ) = tabs();
	$terminal->press_key('Tab');
	$ui->step;
	ok $tabs->bar->button(0)->is_focused, 'Tab focuses the active tab';
	ok !$tabs->bar->button(1)->can_focus, 'the inactive tabs cannot take the focus';
	$terminal->press_key('Tab');
	$ui->step;
	ok $tabs->page(0)->children->[1]->is_focused, 'Tab goes on into the page';
	$terminal->press_key('Shift+Tab');
	$terminal->press_key('Right');
	$ui->step;
	is [ $tabs->active_index, $tabs->bar->button(1)->is_focused, $events ], [ 1, 1, [ [ 1, 'Network' ] ] ], 'Right chooses the next tab, focuses it and fires Select';
	$terminal->press_key('Right');
	$ui->step;
	is $tabs->active_index, 0, 'and wraps around, skipping the disabled tab';
	$terminal->press_key('End');
	$ui->step;
	is $tabs->active_index, 1, 'End chooses the last enabled tab';
	$terminal->press_key('Home');
	$ui->step;
	is $tabs->active_index, 0, 'Home the first';
	$terminal->press_key('Enter');
	$ui->step;
	is scalar @$events, 4, 'Enter on the active tab changes nothing';

	$terminal->press_key('Tab');
	$terminal->press_key('Ctrl+PageDown');
	$ui->step;
	is [ $tabs->active_index, $events->[-1] ], [ 1, [ 1, 'Network' ] ], 'Ctrl+PageDown turns the page from inside it';
	$terminal->press_key('Ctrl+PageUp');
	$ui->step;
	is $tabs->active_index, 0, 'Ctrl+PageUp turns back';

	$terminal->click( 16, 2 );
	$ui->step;
	is [ $tabs->active_index, $tabs->bar->button(1)->is_focused, $events->[-1] ], [ 1, 1, [ 1, 'Network' ] ], 'a click on a tab chooses it and focuses it';
	$terminal->click( 28, 2 );
	$ui->step;
	is $tabs->active_index, 1, 'a click on a disabled tab does nothing';
	$tabs->choose(2);
	is scalar @$events, 7, 'choose on a disabled page fires nothing';
	$tabs->choose(0);
	is $events->[-1], [ 0, 'General' ], 'choose acts as the user does';
	$tabs->choose(0);
	is scalar @$events, 8, 'choosing the active page again fires nothing';
};

subtest 'pages' => sub {
	my ( $tabs, $terminal, $ui, $events ) = tabs();
	my $page = $tabs->page(1);
	$page->title('LAN');
	$page->icon('#');
	$ui->step;
	is lines($terminal)->[2], " \x{2502}         \x{2502} \x{2502} # LAN \x{2502} \x{2502} Users \x{2502}", 'the tab follows the title and the icon';
	$page->disabled(1);
	ok $tabs->bar->button(1)->disabled, 'and the disabled flag';
	$page->disabled(0);

	$page->active(1);
	is [ $tabs->active_index, $page->is_active, $tabs->page(0)->active ], [ 1, 1, 0 ], 'active selects the page';
	$tabs->remove_children_with( sub { $_->title eq 'LAN' } );
	is [ scalar $tabs->pages, $tabs->active_index, $page->tabs, $events ], [ 2, 0, undef, [] ], 'removing the active page shows the first enabled one, without an event';
	$tabs->add_child( Term::Fabulous::Widget::Tabs::Page->new( title => 'Audit', active => 1 ) );
	is $tabs->active->title, 'Audit', 'a page added with active => 1 is shown';
	my $audit = $tabs->active;
	$tabs->remove_child( $audit, $page );
	is [ scalar $tabs->pages, scalar $tabs->bar->buttons, $tabs->active_index, $audit->tabs ], [ 2, 2, 0, undef ], 'remove_child takes the given page and its tab, and ignores a page of no Tabs';
	like dies { $tabs->remove_child('audit') }, qr/remove_child takes pages, got 'audit'; remove a page by its id with remove_child_with_id/, 'an id dies';
	$tabs->add_child($audit);
	like dies { $tabs->add_child( $tabs->page(0) ) },                                   qr/part of a Tabs already/,                        'a page cannot join twice';
	like dies { $tabs->add_child( Term::Fabulous::Widget::Text->new( text => 'x' ) ) }, qr/holds only Term::Fabulous::Widget::Tabs::Page/, 'only pages';
	$tabs->clear_children;
	is [ scalar $tabs->pages, $tabs->active, scalar $tabs->bar->buttons ], [ 0, undef, 0 ], 'clear_children takes the pages and their tabs away';
	$ui->step;
	is lines($terminal)->[0], "\x{256D}" . ( "\x{2500}" x 38 ) . "\x{256E}", 'an empty bar is a line';
};

subtest 'a bar on its own' => sub {
	my $bar = Term::Fabulous::Widget::Tabs::Bar->new( tab_margin => 0, tab_gap => 0 );
	$bar->add_child( map { Term::Fabulous::Widget::Tabs::Button->new( title => $_ ) } qw(List Grid) );
	my $root = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() } } );
	$root->add_child($bar);
	my $terminal = Term::Fabulous::Terminal::Memory->new( width => 20, height => 5 );
	my $ui       = Term::Fabulous->new( root => $root, width => 20, height => 5, terminal => $terminal );
	my @chosen;
	$bar->on( Select => sub ($event) { push @chosen, [ $event->index, $event->item->title ]; return } );
	$ui->step;
	is lines($terminal), [
		"\x{256D}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{256E}",
		"\x{2502} List \x{2502}\x{256D}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{2500}\x{256E}",
		"\x{2502}      \x{2502}\x{2502} Grid \x{2502}",
		"\x{256F}      \x{2570}\x{2534}" . ( "\x{2500}" x 6 ) . "\x{2534}" . ( "\x{2500}" x 4 ),
		'',
		],
		'without a page border, the line ends straight';
	$bar->choose(1);
	is [ $bar->active_index, \@chosen ], [ 1, [ [ 1, 'Grid' ] ] ], 'choose fires Select with the tab';
	like dies { $bar->add_child( Term::Fabulous::Widget::Box->new ) }, qr/holds only Term::Fabulous::Widget::Tabs::Button/, 'only tabs';

	my $list = $bar->button(0);
	is [ map { $list->border_style_of($_)->name } qw(top right bottom left) ], [qw(Round Round Hidden Round)], 'a tab derives its sides from the bar';
	$list->border_style_top('Double');
	is [ $list->border_style_top->name, $list->border_style_of('right')->name ], [qw(Double Round)], 'a style given to a tab wins over the derived one (it was ignored)';
	$ui->step;
	is substr( lines($terminal)->[1], 0, 8 ), "\x{2554}" . ( "\x{2550}" x 6 ) . "\x{2557}", 'and is drawn';
};

subtest 'a layout builds pages into the Tabs' => sub {
	my $built = Term::Fabulous::Layout->new( string => <<'KDL' )->build;
use Term::Fabulous::Widget::Tabs as Tabs
use Term::Fabulous::Widget::Tabs::Page as Page
use Term::Fabulous::Widget::Text as Text
Tabs "settings" {
	side "left"
	orientation "vertical"
	line_style "Double"
	active_bold #true
	page_border #false
	Page "general" { title "General"; Text { text "a"; } }
	Page "network" { title "Network"; icon "#"; active #true; Text { text "b"; } }
	Page "users" { title "Users"; disabled #true; Text { text "c"; } }
}
KDL
	is [ $built->side, $built->orientation, $built->line_style->name, $built->active_bold, $built->page_border, $built->active_index ], [ 'left', 'vertical', 'Double', 1, 0, 1 ],
		'the look and the active page';
	is [ map { [ $_->title, $_->icon, $_->disabled, scalar $_->children->@* ] } $built->pages ], [ [ 'General', undef, 0, 1 ], [ 'Network', '#', 0, 1 ], [ 'Users', undef, 1, 1 ] ],
		'the pages with their content';
};

done_testing;
