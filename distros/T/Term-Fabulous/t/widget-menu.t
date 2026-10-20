use v5.32;
use warnings;
use utf8;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use FindBin;
use lib "$FindBin::Bin/lib";

use Clay::UI::Enum::Result;
use Clay::XS qw(sizing_fixed sizing_grow CLAY_TOP_TO_BOTTOM);
use InputTest;
use Term::Fabulous;
use Term::Fabulous::Commands;
use Term::Fabulous::Terminal::Memory;
use Term::Fabulous::Termbox qw(TB_KEY_MOUSE_LEFT TB_KEY_MOUSE_RELEASE TB_KEY_MOUSE_RIGHT TF_KEY_MOUSE_MOVE);
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Menu;
use Term::Fabulous::Widget::Text;
use Term::Fabulous::Widget::TextField;

my $Menu = 'Term::Fabulous::Widget::Menu';
my @log;
my $wrap       = 0;
my $can_delete = 0;

sub items () {
	return [
		{ label => 'Open',   keys => ['Enter'], run => sub { push @log, 'open' } },
		{ label => 'Rename', keys => ['F2'],    run => sub { push @log, 'rename' } },
		'-',
		{ label => 'Wrap',   run  => sub { $wrap = !$wrap }, checked => sub { $wrap } },
		{ label => 'Delete', keys => ['Delete'], run => sub { push @log, 'delete' }, enabled => sub { $can_delete } },
	];
}

subtest 'items and how they look' => sub {
	my $menu = $Menu->new( items => items() );
	my $ui   = layout_ui($menu);
	is [ $menu->items ]->[2],                     '-',                                  'a separator reads back as -';
	is [ map { ref } grep { ref } $menu->items ], [ ('Term::Fabulous::Command') x 4 ],  'the other items are commands';
	is [ ( $menu->items )[0]->id ],               ['Open'],                             'a hash item without an id takes its label';
	is [ $menu->outer_size ],                     [ 1 + 2 + 6 + 3 + 6 + 1 + 2, 5 + 2 ], 'gutter, labels, gap, keys, padding, and the border';
	is [ map { row_text( $menu, $_ ) } 0 .. 4 ],
		[ '   Open      Enter ', '   Rename       F2 ', "\x{2500}" x 19, '   Wrap            ', '   Delete   Delete ' ],
		'labels after the gutter for the check mark, keys on the right, a line for the separator';
	$wrap = 1;
	$menu->mark_changed;
	is row_text( $menu, 3 ), " \x{2713} Wrap            ", 'a toggle that is on shows its check mark';
	is $menu->highlighted,   0,                            'the first enabled item is highlighted';
	ok $menu->bordered->{top}, 'a menu has a border from the theme';
	ok( ( !grep { !defined $menu->$_ } qw(keys_color separator_color highlight_text_color highlight_background_color) ), 'the color accessors read the theme' );
	$menu->separator_color('#ff0000');
	ok $menu->has_look_override('separator_color'), 'and set a color of their own';
};

subtest 'keys move over enabled items and choose' => sub {
	@log = ();
	my $menu = $Menu->new( items => items() );
	my $ui   = layout_ui($menu);
	my @chosen;
	$menu->on( Choose => sub ($event) { push @chosen, [ $event->command->id, $event->index ]; return } );
	press( $menu, 'Down' );
	is $menu->highlighted, 1, 'Down';
	press( $menu, 'Down' );
	is $menu->highlighted, 3, 'skips the separator';
	press( $menu, 'Down' );
	is $menu->highlighted, 0, 'skips the disabled item and goes round';
	press( $menu, 'End' );
	is $menu->highlighted, 3, 'End goes to the last enabled item';
	press( $menu, 'PageUp' );
	is $menu->highlighted, 0, 'PageUp to the first';
	press( $menu, 'r' );
	is $menu->highlighted, 1, 'a letter finds the item it starts with';
	press( $menu, 'Enter' );
	is \@chosen, [ [ 'Rename', 1 ] ], 'Enter chooses the highlighted item';
	is \@log,    ['rename'],          'and runs its command';
	$menu->choose(4);
	is \@log, ['rename'], 'choose does nothing for a disabled item';

	my $bubbled = 0;
	$menu->parent->on( KeyPress => sub ($event) { $bubbled++; return } );
	press( $menu, 'Escape' );
	is $bubbled, 1, 'an inline menu lets Escape bubble';
};

subtest 'items from a commands table' => sub {
	my $commands = Term::Fabulous::Commands->new( commands => [ { id => 'cut', label => 'Cut', keys => ['Ctrl+X'] }, { id => 'copy', label => 'Copy', keys => ['Ctrl+C'] } ] );
	my $menu     = $Menu->new( commands => $commands, items => [ 'cut', 'copy' ] );
	ref_is + ( $menu->items )[1], $commands->command('copy'), 'ids are looked up in the table';
	like dies { $Menu->new( commands => $commands, items => ['paste'] ) }, qr/there is no command 'paste'/,                                         'an unknown id dies';
	like dies { $Menu->new( items    => ['cut'] ) },                       qr/the item 'cut' is the id of a command, but the menu has no commands/, 'an id without a table dies';
	like dies {
		$Menu->new( items => [ { run => sub { 1 } } ] )
	}, qr/an item needs a label/, 'a hash item needs a label';
	like dies { $Menu->new( items => [undef] ) }, qr/an item must be a Term::Fabulous::Command, the id of a command, a hash reference or '-', got undef/, 'undef dies';
};

# A screen with a text field, for the menus that open over it.
my $root     = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() } } );
my $field    = Term::Fabulous::Widget::TextField->new( layout => { sizing => { width => sizing_fixed(20) } } );
my $terminal = Term::Fabulous::Terminal::Memory->new( width => 40, height => 12 );
my $ui       = Term::Fabulous->new( width => 40, height => 12, root => $root, terminal => $terminal );
$root->add_child($field);
$ui->step;

sub step_keys (@names) {
	$terminal->press_key($_) foreach @names;
	$ui->step;
	return;
}

sub focused () { return $ui->interaction->get_focused_widget }

subtest 'a popup opens at a point, closes on Escape and gives the focus back' => sub {
	$ui->interaction->set_focused_widget($field);
	my $menu   = $Menu->new( items => items() );
	my $closes = 0;
	$menu->on( Close => sub { $closes++; return } );
	ref_is $menu->open( $ui, x => 3, y => 2 ), $menu, 'open returns the menu';
	$ui->step;
	ok $menu->is_open, 'open';
	ref_is focused(), $menu, 'the menu has the focus';
	is $ui->bounding_box($menu), { x => 3, y => 2, width => 21, height => 7 }, 'its corner at the point';
	step_keys('Tab');
	is $menu->highlighted, 1, 'Tab moves the highlight in a popup';
	step_keys('Escape');
	ok !$menu->is_open, 'Escape closes it';
	ref_is focused(), $field, 'the focus is back on the field';
	is $closes, 1, 'Close fired';
	ok !defined $menu->parent, 'the menu left the tree';
};

subtest 'a popup stays on the screen' => sub {
	my $menu = $Menu->new( items => items() );
	$menu->open( $ui, x => 35, y => 10 );
	$ui->step;
	is $ui->bounding_box($menu), { x => 19, y => 5, width => 21, height => 7 }, 'moved left and up to fit';
	$terminal->resize( 30, 8 );
	$ui->step;
	is $ui->bounding_box($menu), { x => 9, y => 1, width => 21, height => 7 }, 'and again after the terminal shrank';
	$menu->close;
	$terminal->resize( 40, 12 );
	$ui->step;

	$menu->open( $ui, below => $field );
	$ui->step;
	is [ @{ $ui->bounding_box($menu) }{qw(x y)} ], [ 0, 1 ], 'below a widget';
	$menu->close;
};

subtest 'choosing closes first, then Choose, then the command' => sub {
	@log = ();
	$ui->interaction->set_focused_widget($field);
	my $menu = $Menu->new( items => [ { label => 'Go', run => sub { push @log, [ 'run', focused() ] } } ] );
	$menu->on( Choose => sub ($event) { push @log, [ 'choose', $menu->is_open, focused() ]; return } );
	$menu->open( $ui, x => 0, y => 0 );
	step_keys('Enter');
	is \@log, [ [ 'choose', 0, exact_ref($field) ], [ 'run', exact_ref($field) ] ], 'the menu was closed and the focus back before Choose and the command';
};

subtest 'a popup keeps the keys and closes when the focus goes' => sub {
	my $menu    = $Menu->new( items => items() );
	my $reached = 0;
	$root->on( KeyPress => sub { $reached++; return Clay::UI::Enum::Result->CONTINUE } );
	$menu->open( $ui, x => 0, y => 3 );
	step_keys( 'Ctrl+S', 'x' );
	is $reached, 0, 'no key gets past an open popup';
	$ui->interaction->set_focused_widget($field);
	$ui->step;
	ok !$menu->is_open, 'losing the focus closes it';
	ref_is focused(), $field, 'and the focus stays where it went';
};

subtest 'the mouse' => sub {
	@log = ();
	my $menu = $Menu->new( items => items() );
	$menu->open( $ui, x => 39, y => 11 );    # clamped: an item ends up under the pointer
	$ui->step;
	$terminal->mouse( key => TB_KEY_MOUSE_RELEASE, x => 39, y => 11, ch => TB_KEY_MOUSE_RIGHT );
	$ui->step;
	ok $menu->is_open, 'the release of the right click that opened the menu chooses nothing';
	is \@log, [], 'and runs nothing';

	my $box = $ui->bounding_box($menu);
	$terminal->mouse( key => TF_KEY_MOUSE_MOVE, x => $box->{x} + 2, y => $box->{y} + 2 );
	$ui->step;
	is $menu->highlighted, 1, 'moving over an item highlights it';
	$terminal->click( $box->{x} + 2, $box->{y} + 2 );
	$ui->step;
	is \@log, ['rename'], 'a click chooses it';
	ok !$menu->is_open, 'and closes the menu';
};

subtest 'checks' => sub {
	my $menu = $Menu->new( items => items() );
	like dies { $menu->open( $ui, x     => 1 ) },       qr/open takes x and y, or below, got x/, 'x needs y';
	like dies { $menu->open( $ui, below => 'field' ) }, qr/below must be a widget, got 'field'/, 'below needs a widget';
	like dies { $menu->open('ui') }, qr/open needs the Term::Fabulous object, got 'ui'/, 'open needs the UI';
	my $label = Term::Fabulous::Widget::Text->new( text => 'a label' );
	$root->add_child($label);
	$ui->step;
	ok lives { $menu->open( $ui, below => $label ) }, 'a text is a widget the frame drew, so a menu opens below it';
	$menu->close;
	$root->remove_child($label);
	like dies { $menu->open( $ui, below => Term::Fabulous::Widget::Text->new( text => 'never drawn' ) ) }, qr/below needs a widget that the last frame drew/,
		'a widget the frame did not draw has no box';
	like dies { $menu->highlight(9) }, qr/there is no item 9/, 'highlight past the end dies';
	my $box = Term::Fabulous::Widget::Box->new;
	$box->add_child($menu);
	like dies { $menu->open( $ui, x => 0, y => 0 ) }, qr/a menu that is a child of another widget cannot open/, 'an inline menu cannot open';
};

done_testing;
