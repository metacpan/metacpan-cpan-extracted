use v5.32;
use warnings;
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
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Menu;
use Term::Fabulous::Widget::MenuBar;
use Term::Fabulous::Widget::Prompt;
use Term::Fabulous::Widget::TextField;

my @log;
my $commands = Term::Fabulous::Commands->new(
	commands => [
		{ id => 'new',   label => 'New',       keys => ['Ctrl+N'], run => sub { push @log, 'new' } },
		{ id => 'save',  label => 'Save',      keys => ['Ctrl+S'], run => sub { push @log, 'save' } },
		{ id => 'ask',   label => 'Rename...', run  => sub { push @log, 'ask'; Term::Fabulous::Widget::Prompt->ask( $main::ui, title => 'Rename' ) } },
		{ id => 'quit',  label => 'Quit',      keys => ['Ctrl+Q'], run => sub { push @log, 'quit' } },
		{ id => 'about', label => 'About' },
	],
);

my $root = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() } } );
my $bar  = Term::Fabulous::Widget::MenuBar->new(
	commands => $commands,
	caption  => 'Notes',
	menus    => [ { title => 'File', items => [qw(new save ask - quit)] }, { title => 'Edit', items => [ { label => 'Undo' } ] }, { title => 'Help', items => ['about'] } ],
);
my $field    = Term::Fabulous::Widget::TextField->new( layout => { sizing => { width => sizing_fixed(20) } } );
my $terminal = Term::Fabulous::Terminal::Memory->new( width => 40, height => 12 );
our $ui = Term::Fabulous->new( width => 40, height => 12, root => $root, terminal => $terminal );
$root->add_child( $bar, $field );
$commands->listen($root);
ref_is $bar->listen($root), $bar, 'listen returns the bar';
$ui->step;

sub step_keys (@names) {
	$terminal->press_key($_) foreach @names;
	$ui->step;
	return;
}

sub focused () { return $ui->interaction->get_focused_widget }

sub start () {
	@log = ();
	$bar->close;
	$ui->interaction->set_focused_widget($field);
	$ui->step;
	return;
}

subtest 'the bar' => sub {
	is [ $bar->titles ],    [qw(File Edit Help)],                           'titles';
	is row_text( $bar, 0 ), ' File  Edit  Help ' . ( ' ' x 16 ) . 'Notes ', 'the titles with a space on each side, the caption at the right end';
	is $bar->rows,          1,                                              'one row';
	ok !$ui->interaction->can_take_focus($bar), 'Tab never stops on a closed bar';
};

subtest 'F10 and Alt open, Escape gives the focus back' => sub {
	start();
	step_keys('F10');
	is $bar->open_menu, 0, 'F10 opens the first menu';
	ref_is focused(), $bar, 'the bar takes the focus';
	step_keys('Alt+h');
	is $bar->open_menu, 2, 'Alt and a letter switch to its menu';
	step_keys('Alt+E');
	is $bar->open_menu, 1, 'with Shift as well';
	step_keys('Escape');
	ok !$bar->is_open, 'Escape closes';
	ref_is focused(), $field, 'the focus is back on the field';
};

subtest 'switching menus keeps the focus to give back' => sub {
	start();
	step_keys( 'Alt+f', 'Right', 'Right', 'Right' );
	is $bar->open_menu, 0, 'Right goes round';
	step_keys('Left');
	is $bar->open_menu, 2, 'and Left the other way';
	step_keys('Tab');
	is $bar->open_menu, 0, 'Tab switches menus too';
	ref_is focused(), $bar, 'and does not move the focus';
	step_keys('Escape');
	ref_is focused(), $field, 'Escape after switching gives the focus back to the field';
};

subtest 'choosing closes the bar, then the command runs' => sub {
	start();
	my @chosen;
	$root->on( Choose => sub ($event) { push @chosen, [ $event->command->id, $bar->is_open, focused() ]; return } );
	step_keys( 'Alt+f', 'Down', 'Enter' );
	is \@log,    ['save'],                             'Down and Enter ran Save';
	is \@chosen, [ [ 'save', 0, exact_ref($field) ] ], 'Choose bubbled to the root after the bar closed and gave the focus back';
	ok !$bar->is_open, 'the bar is closed';
};

subtest 'a command that opens a prompt' => sub {
	start();
	step_keys( 'Alt+f', 's' );
	step_keys('r');
	step_keys('Enter');
	is \@log, ['ask'], 'the item ran';
	my $prompt = focused();
	$prompt = $prompt->parent until !defined $prompt || $prompt->isa('Term::Fabulous::Widget::Prompt');
	isa_ok $prompt, 'Term::Fabulous::Widget::Prompt';
	ok $prompt->is_open, 'the focus is inside the open prompt';
	step_keys('Escape');
	ref_is focused(), $field, 'the prompt gives the focus back to the field, not to the menu';
};

subtest 'keys with Ctrl close the bar and go on' => sub {
	start();
	step_keys( 'Alt+f', 'Ctrl+N' );
	ok !$bar->is_open, 'Ctrl+N closed the bar';
	is \@log, ['new'], 'and ran its command';
	ref_is focused(), $field, 'with the focus back on the field';
	step_keys( 'Alt+f', 'z' );
	ok $bar->is_open, 'a plain key the menu has no item for is kept';
};

subtest 'the mouse' => sub {
	start();
	$terminal->click( 7, 0 );
	$ui->step;
	is $bar->open_menu, 1, 'a click on a title opens its menu';
	ref_is focused(), $bar, 'the bar has the focus while it is open';
	$terminal->click( 7, 0 );
	$ui->step;
	ok !$bar->is_open, 'a click on the open title closes it';
	ref_is focused(), $field, 'the click did not take the focus from the field';

	$terminal->click( 1, 0 );
	$ui->step;
	my $box = $ui->bounding_box( $bar->menu(0) );
	is [ @{$box}{qw(x y)} ], [ 0, 1 ], 'the menu opens below its title';
	$terminal->click( $box->{x} + 2, $box->{y} + 1 );
	$ui->step;
	is \@log, ['new'], 'a click on an item runs it';
	ref_is focused(), $field, 'and the focus is back';
};

subtest 'menus stay on the screen' => sub {
	start();
	$terminal->resize( 16, 12 );
	$ui->step;
	$bar->open(2);
	$ui->step;
	my $box = $ui->bounding_box( $bar->menu(2) );
	ok $box->{x} + $box->{width} <= 16, 'the rightmost menu moved left to stay on the screen';
	$bar->close;
	$terminal->resize( 40, 12 );
	$ui->step;
};

subtest 'a listener on a menu that stops Choose' => sub {
	start();
	my $stopped = 0;
	$bar->menu(0)->on( Choose => sub ($event) { $stopped++; return } );
	step_keys( 'Alt+f', 'Enter' );
	is [ $stopped, \@log ], [ 1, ['new'] ], 'the listener ran, and so did the command';
	ok !$bar->is_open, 'the bar closed all the same';
	ref_is focused(), $field, 'and gave the focus back';
};

subtest 'a context menu open when a title is clicked' => sub {
	start();
	my $popup = Term::Fabulous::Widget::Menu->new( items => [ { label => 'Popup item' } ] );
	$popup->open( $ui, x => 10, y => 5 );
	$ui->step;
	$terminal->click( 1, 0 );
	$ui->step;
	ok !$popup->is_open, 'the context menu closed';
	is $bar->open_menu, 0, 'the bar opened';
	step_keys('Escape');
	ref_is focused(), $field, 'the focus went back to the field, not to the closed context menu';
};

subtest 'a disabled bar' => sub {
	start();
	$bar->disabled(1);
	step_keys('F10');
	ok !$bar->is_open, 'ignores F10';
	ref_is focused(), $field, 'and leaves the focus alone';
	like dies { $bar->open(0) }, qr/a disabled menu bar cannot open its menus/, 'open dies';
	$bar->disabled(0);
};

subtest 'checks' => sub {
	my %menus = ( menus => [ { title => 'File', items => [] } ] );
	like dies { Term::Fabulous::Widget::MenuBar->new( menus => [] ) }, qr/menus must be a non-empty array reference/, 'a bar needs menus';
	like dies { Term::Fabulous::Widget::MenuBar->new( menus => [ { title => 'File' }, { title => 'Format' } ] ) },
		qr/the menus 'File' and 'Format' have the same key 'f'; give one of them another key/, 'two menus with one key';
	like dies { Term::Fabulous::Widget::MenuBar->new( menus => [ { title => 'File', key => 'x' } ] ) }, qr/the key of the menu 'File' must be one letter or digit of its title, got 'x'/,
		'a key that is not in the title';
	my $alt = Term::Fabulous::Commands->new( commands => [ { id => 'find', label => 'Find', keys => ['Alt+f'] } ] );
	like dies { Term::Fabulous::Widget::MenuBar->new( commands => $alt, %menus ) }, qr/the key Alt\+f of the menu 'File' runs the command 'find'/, 'a key that a command uses';
	like dies { Term::Fabulous::Widget::MenuBar->new(%menus)->open(0) },            qr/opens its menus only while it is in a Term::Fabulous UI/,   'open needs a UI';
	like dies { $bar->open(3) },                                                    qr/there is no menu 3 \(the bar has 3\)/,                      'an index past the last menu';
};

done_testing;
