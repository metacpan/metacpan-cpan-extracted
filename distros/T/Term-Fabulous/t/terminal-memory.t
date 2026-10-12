use v5.32;
use warnings;
use utf8;

use Test2::V0;

use Clay::XS qw(sizing_fixed sizing_grow CLAY_TOP_TO_BOTTOM);
use Term::Fabulous::Termbox qw(TB_EVENT_KEY TB_EVENT_MOUSE TB_EVENT_RESIZE TB_KEY_MOUSE_LEFT TB_KEY_MOUSE_RELEASE TB_KEY_ARROW_LEFT TB_MOD_SHIFT);
use Term::Fabulous;
use Term::Fabulous::Terminal::Memory;
use Term::Fabulous::Theme;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Button;
use Term::Fabulous::Widget::Text;
use Term::Fabulous::Widget::TextField;

sub events {
	my ($terminal) = @_;
	my @events;
	while ( defined( my $event = $terminal->next_event ) ) {
		push @events, [ map { $event->$_ } qw(type key ch mod x y w h) ];
	}
	return \@events;
}

subtest 'input is queued as termbox2 reports it' => sub {
	my $terminal = Term::Fabulous::Terminal::Memory->new( width => 10, height => 3 );
	$terminal->open( inline => undef, mouse => 1, kitty_keyboard => 0 );
	ref_is $terminal->type_text('hé'), $terminal, 'the input methods return the terminal';
	$terminal->press_key('Shift+Left')->click( 2, 1 )->resize( 12, 4 );
	is events($terminal), [
		[ TB_EVENT_KEY,    0,                    ord 'h',           0,            0, 0, 0,  0 ],
		[ TB_EVENT_KEY,    0,                    ord 'é',           0,            0, 0, 0,  0 ],
		[ TB_EVENT_KEY,    TB_KEY_ARROW_LEFT,    0,                 TB_MOD_SHIFT, 0, 0, 0,  0 ],
		[ TB_EVENT_MOUSE,  TB_KEY_MOUSE_LEFT,    0,                 0,            2, 1, 0,  0 ],
		[ TB_EVENT_MOUSE,  TB_KEY_MOUSE_RELEASE, TB_KEY_MOUSE_LEFT, 0,            2, 1, 0,  0 ],
		[ TB_EVENT_RESIZE, 0,                    0,                 0,            0, 0, 12, 4 ],
		],
		'characters, a named key, a click and a resize';

SKIP: {
		skip 'select cannot watch a pipe on Windows', 2 if $^O eq 'MSWin32';
		vec( my $readable = '', fileno( ( $terminal->read_handles )[0] ), 1 ) = 1;
		is select( my $ready = $readable, undef, undef, 0 ), 0, 'the read handle is quiet once everything was read';
		$terminal->type_text('x');
		is select( $ready = $readable, undef, undef, 0 ), 1, 'and readable while input waits';
		events($terminal);
	}

	like dies { $terminal->press_key('Ctrl+w') },                            qr/no key is named 'Ctrl\+w'/,                           'press_key takes the names key_name gives';
	like dies { $terminal->push_event( type => 99 ) },                       qr/unknown event type '99'/,                             'push_event takes the three event types';
	like dies { $terminal->resize( 0, 4 ) },                                 qr/width must be a whole number of at least 1, got '0'/, 'resize takes usable sizes';
	like dies { $terminal->mouse( key => TB_KEY_MOUSE_LEFT, button => 1 ) }, qr/button/,                                              'unknown event fields die';

	$terminal->end_input;
	is [ events($terminal), $terminal->input_ended ], [ [], 1 ], 'end_input ends the input';
	like dies { $terminal->type_text('y') }, qr/no input can follow end_input/, 'and nothing can follow';
};

subtest 'the session' => sub {
	my $terminal = Term::Fabulous::Terminal::Memory->new( width => 10, height => 3, kitty_keyboard => 1 );
	$terminal->open( inline => 5, mouse => 0, kitty_keyboard => 1 );
	is [ $terminal->size, $terminal->inline_rows, $terminal->mouse_enabled, $terminal->kitty_keyboard_active ], [ 10, 3, 3, 0, 1 ],
		'an inline region no higher than the screen, no mouse, the kitty keyboard protocol';
	$terminal->click( 1, 1 );
	is events($terminal),                                                        [],             'a terminal that does not report the mouse sends no clicks';
	is [ $terminal->apply_resize( 8, 2 ), $terminal->width, $terminal->height ], [ 8, 2, 8, 2 ], 'a resize applies the new size';
	like dies { $terminal->open( inline => undef, mouse => 1, kitty_keyboard => 0 ) }, qr/the terminal is open already/, 'one session at a time';

	$terminal->close;
	is [ $terminal->is_open, $terminal->inline_rows, $terminal->kitty_keyboard_active, $terminal->session_count ], [ 0, undef, 0, 1 ], 'closed';
	like dies { $terminal->size },                                      qr/the terminal is not open/,    'size needs an open session';
	like dies { Term::Fabulous::Terminal::Memory->new( width => 10 ) }, qr/Required parameter 'height'/, 'the size is required';
};

subtest 'the screen' => sub {

	# A background token with alpha 0 leaves the screen in the terminal's
	# own background, which is what the trimming of blank cells is about.
	my $transparent = Term::Fabulous::Theme->new( name => 'transparent', palette => { background => [ 0, 0, 0, 0 ] } );
	my $root        = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow(), height => sizing_grow() } } );
	my $field       = Term::Fabulous::Widget::TextField->new( preferred_columns => 6 );
	my $button      = Term::Fabulous::Widget::Button->new( background_color => [ 0, 0, 200, 255 ], layout => { sizing => { width => sizing_fixed(4), height => sizing_fixed(1) } } );
	$button->add_child( Term::Fabulous::Widget::Text->new( text => 'OK', text_color => [ 255, 255, 255, 255 ] ) );
	$root->add_child( $field, $button );
	my $terminal  = Term::Fabulous::Terminal::Memory->new( width => 10, height => 3 );
	my $ui        = Term::Fabulous->new( root => $root, width => 1, height => 1, terminal => $terminal, theme => $transparent );
	my $activated = 0;
	$button->on( Activate => sub { $activated++; return } );

	$ui->step;
	$terminal->press_key('Tab')->type_text('héllo');
	$ui->step;
	is [ $terminal->lines ],    [ 'héllo ', 'OK  ',   '' ],       'the rows of the screen, without trailing blanks';
	is $terminal->cell( 0, 1 ), [ 'O',      0xFFFFFF, 0x0000C8 ], 'one cell';
	is [ $terminal->lines( colors => 1 ) ]->[1], "\e[38;2;255;255;255;48;2;0;0;200mOK\e[0m\e[48;2;0;0;200m  \e[0m", 'with colors';

	$terminal->click( 1, 1 );
	$ui->step;
	ref_is $ui->interaction->get_focused_widget, $button, 'a click focuses the button';
	is $activated, 1, 'and activates it';
	like dies { $terminal->lines( colour => 1 ) }, qr/lines does not accept colour/, 'lines takes only colors';
};

done_testing;
