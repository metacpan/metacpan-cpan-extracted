use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use utf8;

use Test2::V0;
use Feature::Compat::Try;
use Encode ();
use File::Spec;
use Time::HiRes ();

use Term::Fabulous::Termbox qw(:all);
use Term::Fabulous::Termbox::Event;

subtest 'compile-time options' => sub {
	is tb_version(),    '2.7.0-dev', 'the vendored termbox2 version';
	is tb_attr_width(), 64,          '64-bit attributes';
	ok tb_has_truecolor(), 'truecolor';
	ok tb_has_egc(),       'grapheme clusters';
};

subtest 'constants' => sub {
	is TB_KEY_CTRL_C,                                       0x03,                                         'ASCII control keys are exported';
	is TB_KEY_TAB,                                          0x09,                                         'TB_KEY_TAB';
	is TB_KEY_ARROW_LEFT,                                   0xFFFF - 20,                                  'terminal-dependent keys';
	is TB_HI_BLACK,                                         0x20000000,                                   'style bits above the 24-bit color';
	is TB_STRIKEOUT,                                        1 << 32,                                      '64-bit-only style bits';
	is TB_TRUECOLOR_BLACK,                                  TB_HI_BLACK,                                  'deprecated aliases still name the same bit';
	is TB_ERR_NO_EVENT,                                     -6,                                           'status codes';
	is TB_OUTPUT_TRUECOLOR,                                  5,                                           'output modes';
	is [ sort keys %Term::Fabulous::Termbox::EXPORT_TAGS ], [qw(all api colors event keys return width)], 'export tags';
	ok( ( grep { $_ eq 'TB_KEY_MOUSE_WHEEL_DOWN' } @{ $Term::Fabulous::Termbox::EXPORT_TAGS{keys} } ), 'constants are listed under their tag' );
	is [ TF_KEY_MOUSE_MOVE, TF_KEY_MOUSE_WHEEL_LEFT, TF_KEY_MOUSE_WHEEL_RIGHT ], [ 0xFFFF - 29, 0xFFFF - 30, 0xFFFF - 31 ], 'the Term::Fabulous mouse keys sit below the termbox2 ones';
	is [ TF_KEY_CAPS_LOCK, TF_KEY_MUTE_VOLUME ],                                 [ 0xFFFF - 32, 0xFFFF - 102 ],             'the kitty keys below them';
	is [ TF_MOD_SUPER, TF_MOD_HYPER, TF_MOD_META ],                              [ 16, 32, 64 ],                            'the kitty modifiers in the bits termbox2 leaves free';
};

subtest 'widths' => sub {
	is tb_wcwidth( ord 'a' ),  1, 'narrow';
	is tb_wcwidth(0x4E00),     2, 'wide';
	is tb_wcwidth(0x301),      0, 'combining mark';
	is tb_wcwidth(0x1B),      -1, 'not printable';
	ok tb_iswprint( ord 'a' ), 'printable';
	ok !tb_iswprint(0x1B),     'control character';
	is tb_cluster_width("\x{2764}\x{FE0F}"), 2, 'VS16 cluster';
	is tb_cluster_width("\x{2764}\x{FE0E}"), 1, 'VS15 cluster';
	is tb_cluster_width("e\x{301}"),         1, 'combining sequence';
	like dies { tb_cluster_width('') }, qr/tb_cluster_width needs a non-empty string/, 'empty cluster dies';
};

subtest 'before tb_init' => sub {
	is tb_width(),                                           TB_ERR_NOT_INIT,           'tb_width reports the status';
	is tb_strerror(TB_ERR_NOT_INIT),                         'Termbox not initialized', 'tb_strerror names it';
	is tb_set_cell( 0, 0, 'a', TB_DEFAULT, TB_DEFAULT ),     TB_ERR_NOT_INIT,           'a character string';
	is tb_set_cell( 0, 0, ord 'a', TB_DEFAULT, TB_DEFAULT ), TB_ERR_NOT_INIT,           'an integer codepoint';
	like dies { tb_set_cell( 0, 0, '', TB_DEFAULT, TB_DEFAULT ) }, qr/tb_set_cell needs a non-empty character/, 'an empty string dies';
	like dies { tb_get_fds( 1, 2 ) },                              qr/tb_get_fds needs a scalar reference/,     'tb_get_fds wants references';

	my $event = Term::Fabulous::Termbox::Event->new;
	is tb_peek_event( $event, 0 ), TB_ERR_NOT_INIT, 'tb_peek_event reports the status';
	is $event->type,               0,               'and leaves the event untouched';
};

subtest 'malformed UTF-8' => sub {
	my $malformed = "\xC3A";
	Encode::_utf8_on($malformed);
	like dies { tb_cluster_width($malformed) },                               qr/tb_cluster_width needs well-formed UTF-8/, 'tb_cluster_width dies';
	like dies { tb_set_cell_ex( 0, 0, $malformed, TB_DEFAULT, TB_DEFAULT ) }, qr/tb_set_cell_ex needs well-formed UTF-8/,   'tb_set_cell_ex dies';
	like dies { tb_set_cell( 0, 0, $malformed, TB_DEFAULT, TB_DEFAULT ) },    qr/tb_set_cell needs well-formed UTF-8/,      'tb_set_cell dies';
	like dies { tb_extend_cell( 0, 0, $malformed ) },                         qr/tb_extend_cell needs well-formed UTF-8/,   'tb_extend_cell dies';
};

subtest 'event object' => sub {
	my $event = Term::Fabulous::Termbox::Event->new( type => TB_EVENT_MOUSE, key => TB_KEY_MOUSE_LEFT, x => 3, y => 1 );
	is [ $event->type, $event->key, $event->x, $event->y, $event->mod, $event->ch, $event->w, $event->h ], [ TB_EVENT_MOUSE, TB_KEY_MOUSE_LEFT, 3, 1, 0, 0, 0, 0 ],
		'fields from the constructor, the rest 0';
	$event->key(TB_KEY_MOUSE_RELEASE);
	is $event->key, TB_KEY_MOUSE_RELEASE, 'accessors also set';
	like dies { Term::Fabulous::Termbox::Event->new( button => 1 ) }, qr/button/, 'unknown fields die';
};

subtest 'input parser' => sub {
	pipe my $read, my $write or die "pipe: $!";
	open my $sink, '>', File::Spec->devnull or die 'cannot open the null device: ' . $!;    ## no critic (InputOutput::RequireBriefOpen) termbox2 writes to it until the test ends
	my $rc = tb_init_rwfd( fileno $read, fileno $sink );
	skip_all "termbox2 cannot start on a pipe here: " . tb_strerror($rc) unless $rc == TB_OK;
	tb_set_input_mode( TB_INPUT_ESC | TB_INPUT_MOUSE );
	is tf_install_input_parser(), TB_OK, 'the parser installs';

	# Writes the bytes and returns every event they produce as [type, key, ch, mod, x, y].
	my $feed = sub ($bytes) {
		syswrite $write, $bytes;
		my @events;
		while (1) {
			my $event = Term::Fabulous::Termbox::Event->new;
			last unless tb_peek_event( $event, 100 ) == TB_OK;
			push @events, [ map { $event->$_ } qw(type key ch mod x y) ];
		}
		return \@events;
	};

	is $feed->("\x1bx"),                [ [ TB_EVENT_KEY, 0, ord('x'), TB_MOD_ALT, 0, 0 ] ],                      'Alt+x';
	is $feed->("\x1b\xc3\xa9"),         [ [ TB_EVENT_KEY, 0, 0xE9, TB_MOD_ALT, 0, 0 ] ],                          'Alt plus a two-byte character';
	is $feed->("\x1b\r"),               [ [ TB_EVENT_KEY, TB_KEY_ENTER, 0, TB_MOD_ALT | TB_MOD_CTRL, 0, 0 ] ],    'Alt+Enter keeps the control byte as its key';
	is $feed->("\x1b"),                 [ [ TB_EVENT_KEY, TB_KEY_ESC, 0, 0, 0, 0 ] ],                             'a lone Escape is still Escape';
	is $feed->("\x1b[A")->[0][1],       TB_KEY_ARROW_UP,                                                          'CSI sequences are left to termbox2';
	is $feed->("\x1b[<35;10;5M"),       [ [ TB_EVENT_MOUSE, TF_KEY_MOUSE_MOVE, 0, TB_MOD_MOTION, 9, 4 ] ],        'plain motion';
	is $feed->("\x1b[<32;2;1M"),        [ [ TB_EVENT_MOUSE, TB_KEY_MOUSE_LEFT, 0, TB_MOD_MOTION, 1, 0 ] ],        'a drag with the left button';
	is $feed->("\x1b[<0;2;1m"),         [ [ TB_EVENT_MOUSE, TB_KEY_MOUSE_RELEASE, TB_KEY_MOUSE_LEFT, 0, 1, 0 ] ], 'a release names its button in ch';
	is $feed->("\x1b[<2;2;1m")->[0][2], TB_KEY_MOUSE_RIGHT,                                                       'a release of the right button';
	is $feed->("\x1b[<3;2;1M"),         [ [ TB_EVENT_MOUSE, TB_KEY_MOUSE_RELEASE, 0, 0, 1, 0 ] ],                 'the button-3 form names no button';
	is [ map { $_->[1] } @{ $feed->("\x1b[<64;3;3M\x1b[<65;3;3M\x1b[<66;3;3M\x1b[<67;3;3M") } ],
		[ TB_KEY_MOUSE_WHEEL_UP, TB_KEY_MOUSE_WHEEL_DOWN, TF_KEY_MOUSE_WHEEL_LEFT, TF_KEY_MOUSE_WHEEL_RIGHT ], 'four wheel directions, queued in one write';
	is $feed->("\x1b[<20;300;40M"), [ [ TB_EVENT_MOUSE, TB_KEY_MOUSE_LEFT, 0, TB_MOD_SHIFT | TB_MOD_CTRL, 299, 39 ] ], 'modifier bits and coordinates beyond 255';
	is $feed->("\x1b[<0;1"),        [],                                                                                'a partial report waits';
	is $feed->(";1M"),              [ [ TB_EVENT_MOUSE, TB_KEY_MOUSE_LEFT, 0, 0, 0, 0 ] ],                             'until the rest arrives';

	# kitty keyboard protocol key reports, as [key, ch, mod].
	my $key = sub ($bytes) {
		[ map { [ @$_[ 1 .. 3 ] ] } @{ $feed->($bytes) } ]
	};
	is $key->("\x1b[27u"),      [ [ TB_KEY_ESC,    0, 0 ] ],                          'Escape';
	is $key->("\x1b[99;5u"),    [ [ TB_KEY_CTRL_C, 0, TB_MOD_CTRL ] ],                'Ctrl plus a letter is its control byte';
	is $key->("\x1b[119;6u"),   [ [ TB_KEY_CTRL_W, 0, TB_MOD_CTRL | TB_MOD_SHIFT ] ], 'and keeps Shift';
	is $key->("\x1b[105;5u"),   [ [ 0, ord 'i', TB_MOD_CTRL ] ], 'Ctrl+I is not Tab';
	is $key->("\x1b[13;5u"),    [ [ 0, TB_KEY_ENTER, TB_MOD_CTRL ] ], 'Ctrl+Enter has the byte in ch';
	is $key->("\x1b[13;2u"),    [ [ TB_KEY_ENTER,    0, TB_MOD_SHIFT | TB_MOD_CTRL ] ], 'Shift+Enter is the byte, as termbox2 reports it';
	is $key->("\x1b[9;2u"),     [ [ TB_KEY_BACK_TAB, 0, 0 ] ],                          'Shift+Tab is BackTab';
	is $key->("\x1b[49:33;4u"), [ [ 0, ord '!', TB_MOD_ALT ] ],   'Alt+Shift takes the shifted key';
	is $key->("\x1b[97;67u"),   [ [ 0, ord 'a', TB_MOD_ALT ] ],   'Caps Lock is dropped';
	is $key->("\x1b[97;9u"),    [ [ 0, ord 'a', TF_MOD_SUPER ] ], 'Super';
	is $key->("\x1b[57376u\x1b[57414;5u\x1b[57440u"),
		[ [ TF_KEY_F13, 0, 0 ], [ TF_KEY_KP_ENTER, 0, TB_MOD_CTRL ], [ TF_KEY_MUTE_VOLUME, 0, 0 ] ], 'keys without a legacy encoding';
	is $key->("\x1b[1;9A\x1b[3;5~"), [ [ TB_KEY_ARROW_UP, 0, TF_MOD_SUPER ], [ TB_KEY_DELETE, 0, TB_MOD_CTRL ] ], 'legacy function keys with any modifier';
	is $key->("\x1b[E"),             [ [ TF_KEY_KP_BEGIN, 0, 0 ] ],                                               'the keypad Begin key';
	is $key->("\x1b[99;"),           [],                                                                          'a partial report waits';
	is $key->("5u"),                 [ [ TB_KEY_CTRL_C, 0, TB_MOD_CTRL ] ],                                       'until the rest arrives';
	tb_shutdown();
};

subtest 'the end of the input' => sub {
	pipe my $read, my $write or die "pipe: $!";
	is tf_input_ended( fileno $read ), 0, 'a pipe with nothing to read has not ended';
	syswrite $write, 'a';
	is tf_input_ended( fileno $read ), 0, 'nor one with a byte to read';
	close $write;
	is tf_input_ended( fileno $read ), 0, 'nor one whose writer is gone while a byte waits';
	sysread $read, my $byte, 1;
	is tf_input_ended( fileno $read ), 1, 'the end: the writer is gone and nothing waits';
};

subtest 'kitty keyboard query' => sub {
	pipe my $read, my $write or die "pipe: $!";
	open my $sink, '>', File::Spec->devnull or die 'cannot open the null device: ' . $!;    ## no critic (InputOutput::RequireBriefOpen) termbox2 writes to it until the test ends
	my $rc = tb_init_rwfd( fileno $read, fileno $sink );
	skip_all "termbox2 cannot start on a pipe here: " . tb_strerror($rc) unless $rc == TB_OK;

	syswrite $write, "a\x1b[?5u\x1b[?62;22c";
	is tf_kitty_keyboard_query( 1000, \my $supported ), TB_OK, 'the terminal answers';
	is $supported,                                      1,     'with its flags: it speaks the protocol';
	my $event = Term::Fabulous::Termbox::Event->new;
	is [ tb_peek_event( $event, 100 ), $event->ch ], [ TB_OK, ord 'a' ], 'the key before the answers stays queued';
	is tb_peek_event( $event, 50 ),                  TB_ERR_NO_EVENT,    'the answers do not';

	syswrite $write, "\x1b[?62;22c";
	is [ tf_kitty_keyboard_query( 1000, \$supported ), $supported ], [ TB_OK, 0 ],    'device attributes alone: no protocol';
	is tf_kitty_keyboard_query( 50, \$supported ),                   TB_ERR_NO_EVENT, 'no answer in time';
	like dies { tf_kitty_keyboard_query( 50, 1 ) }, qr/tf_kitty_keyboard_query needs a scalar reference/, 'tf_kitty_keyboard_query wants a reference';

	close $write;
	my $asked = Time::HiRes::time();
	is tf_kitty_keyboard_query( 1000, \$supported ), TB_ERR_READ, 'a terminal that went away is a read error';
	cmp_ok Time::HiRes::time() - $asked, '<', 0.5, 'reported at once, not when the time runs out';
	tb_shutdown();
};

subtest 'sixel query' => sub {
	pipe my $read, my $write or die "pipe: $!";
	open my $sink, '>', File::Spec->devnull or die 'cannot open the null device: ' . $!;    ## no critic (InputOutput::RequireBriefOpen) termbox2 writes to it until the test ends
	my $rc = tb_init_rwfd( fileno $read, fileno $sink );
	skip_all "termbox2 cannot start on a pipe here: " . tb_strerror($rc) unless $rc == TB_OK;

	syswrite $write, "a\x1b[6;20;10t\x1b[?64;1;4;22c";
	is tf_sixel_query( 1000, \my $supported, \my $width, \my $height ), TB_OK,         'the terminal answers';
	is [ $supported, $width, $height ],                                 [ 1, 10, 20 ], 'attribute 4: sixel, and the reported cell size';
	my $event = Term::Fabulous::Termbox::Event->new;
	is [ tb_peek_event( $event, 100 ), $event->ch ], [ TB_OK, ord 'a' ], 'the key before the answers stays queued';
	is tb_peek_event( $event, 50 ),                  TB_ERR_NO_EVENT,    'the answers do not';

	syswrite $write, "\x1b[?62;14;22c";
	is [ tf_sixel_query( 1000, \$supported, \$width, \$height ), $supported, $width, $height ], [ TB_OK, 0, 0, 0 ], 'no 4 (the 4 in 14 does not count), no cell size';
	is tf_sixel_query( 50, \$supported, \$width, \$height ),                                    TB_ERR_NO_EVENT,    'no answer in time';
	like dies { tf_sixel_query( 50, \$supported, 1, \$height ) }, qr/tf_sixel_query needs a scalar reference/, 'tf_sixel_query wants references';
	tb_shutdown();
};

subtest 'the cell size from the window size' => sub {
	try { require IO::Pty }
	catch ($error) { skip_all 'IO::Pty is not installed' }
	my $pty     = IO::Pty->new;
	my $display = $pty->slave;
	$display->set_winsize( 3, 10, 80, 48 );
	pipe my $read, my $write or die "pipe: $!";
	my $rc = tb_init_rwfd( fileno $read, fileno $display );
	skip_all "termbox2 cannot start on a pty here: " . tb_strerror($rc) unless $rc == TB_OK;

	syswrite $write, "\x1b[?62;4c";
	my ( $supported, $width, $height );
	is [ tf_sixel_query( 1000, \$supported, \$width, \$height ), $supported, $width, $height ], [ TB_OK, 1, 8, 16 ], 'the pixels of the window divided by its cells';
	tb_shutdown();
};

subtest 'cells tb_present would draw' => sub {
	try { require IO::Pty }
	catch ($error) { skip_all 'IO::Pty is not installed' }
	my $pty     = IO::Pty->new;
	my $display = $pty->slave;
	$display->set_winsize( 3, 10 );
	pipe my $read, my $write or die "pipe: $!";
	my $rc = tb_init_rwfd( fileno $read, fileno $display );
	skip_all "termbox2 cannot start on a pty here: " . tb_strerror($rc) unless $rc == TB_OK;

	my $differ = sub (@rect) {
		tf_cells_differ( @rect, \my $answer ) == TB_OK or die 'tf_cells_differ failed';
		return $answer;
	};
	tb_present();
	tb_set_cell( 4, 1, 'x', TB_DEFAULT, TB_DEFAULT );
	is [ $differ->( 3, 0, 2, 2 ), $differ->( 5, 0, 5, 3 ) ], [ 1, 0 ], 'a changed cell inside the rectangle, none outside';
	is $differ->( -5, -5, 100, 100 ),                        1,        'the part outside the screen is ignored';
	tb_present();
	is $differ->( 0, 0, 10, 3 ),                             0,        'none after tb_present';
	is tf_invalidate_cells( 8, 2, 5, 5 ),                    TB_OK,    'tf_invalidate_cells';
	is [ $differ->( 8, 2, 2, 1 ), $differ->( 0, 0, 8, 3 ) ], [ 1, 0 ], 'only its cells are drawn again';
	like dies { tf_cells_differ( 0, 0, 1, 1, 1 ) }, qr/tf_cells_differ needs a scalar reference/, 'tf_cells_differ wants a reference';
	tb_shutdown();
};

# The terminal is a pty, so termbox2 knows its size; what it writes is read
# back from the master side.
subtest 'cells and raw output after tb_init' => sub {
	try { require IO::Pty }
	catch ($error) { skip_all 'IO::Pty is not installed' }
	my $pty     = IO::Pty->new;
	my $display = $pty->slave;
	$display->set_winsize( 3, 10 );
	pipe my $read, my $write or die "pipe: $!";
	my $rc = tb_init_rwfd( fileno $read, fileno $display );
	skip_all "termbox2 cannot start on a pty here: " . tb_strerror($rc) unless $rc == TB_OK;
	is [ tb_width(), tb_height() ], [ 10, 3 ], 'the size of the pty';

	is tb_set_cell( 1, 0, 'a', 0x112233, 0x445566 ), TB_OK,                              'tb_set_cell';
	is [ tb_get_cell( 1, 0, 1 ) ],                   [ TB_OK, 'a', 0x112233, 0x445566 ], 'tb_get_cell reads it back from the back buffer';
	tb_set_cell( 2, 0, 'e', TB_DEFAULT, TB_DEFAULT );
	is tb_extend_cell( 2, 0, "\x{301}" ), TB_OK, 'tb_extend_cell';
	is( ( tb_get_cell( 2, 0, 1 ) )[1], "e\x{301}", 'the cell holds the whole cluster' );
	is tb_set_cell_ex( 3, 0, "\x{2764}\x{FE0F}", TB_DEFAULT, TB_DEFAULT ), TB_OK, 'tb_set_cell_ex';
	is( ( tb_get_cell( 3, 0, 1 ) )[1], "\x{2764}\x{FE0F}", 'and its cluster' );
	is tb_print( 0, 1, TB_DEFAULT, TB_DEFAULT, "x\x{65E5}y" ), TB_OK,                    'tb_print';
	is [ map { ( tb_get_cell( $_, 1, 1 ) )[1] } 0, 1, 3 ],     [ 'x', "\x{65E5}", 'y' ], 'advancing by the width of each cluster';

	is tb_send("\xff\x80"), TB_OK, 'tb_send of bytes';
	my $upgraded = "\xe9";
	utf8::upgrade($upgraded);
	tb_send($upgraded);
	tb_send("\x{263A}");
	tb_shutdown();
	my $written = '';
	vec( my $readable = '', fileno $pty, 1 ) = 1;

	while ( select( my $ready = $readable, undef, undef, 0.2 ) > 0 ) {
		sysread( $pty, my $chunk, 65536 ) or last;
		$written .= $chunk;
	}
	like $written, qr/\xff\x80\xe9\xe2\x98\xba/, 'bytes go out as they are, also from an upgraded string; a wide string UTF-8 encoded';
};

subtest 'inline mode' => sub {
	try { require IO::Pty }
	catch ($error) { skip_all 'IO::Pty is not installed' }
	my $pty     = IO::Pty->new;
	my $display = $pty->slave;
	$display->set_winsize( 6, 10 );
	pipe my $read, my $write or die "pipe: $!";
	my $rc = tf_init_inline_rwfd( fileno $read, fileno $display );
	skip_all "termbox2 cannot start on a pty here: " . tb_strerror($rc) unless $rc == TB_OK;
	is [ tb_width(), tb_height() ], [ 10, 6 ], 'the buffers cover the whole terminal';

	syswrite $write, "a\x1b[5;7Rb";
	is tf_cursor_position( 1000, \my $x, \my $y ), TB_OK,    'the terminal reports the cursor';
	is [ $x, $y ],                                 [ 6, 4 ], 'counted from 0';
	my @keys;
	while ( tb_peek_event( my $event = Term::Fabulous::Termbox::Event->new, 100 ) == TB_OK ) {
		push @keys, $event->ch;
	}
	is \@keys,                             [ ord 'a', ord 'b' ], 'the keys around the report stay queued';
	is tf_cursor_position( 50, \$x, \$y ), TB_ERR_NO_EVENT,      'no report in time';
	like dies { tf_cursor_position( 50, 1, \$y ) }, qr/tf_cursor_position needs a scalar reference/, 'tf_cursor_position wants references';

	tb_set_cell( 0, 4, 'x', TB_DEFAULT, TB_DEFAULT );
	tb_present();
	tb_shutdown();
	my $written = '';
	vec( my $readable = '', fileno $pty, 1 ) = 1;
	while ( select( my $ready = $readable, undef, undef, 0.2 ) > 0 ) {
		sysread( $pty, my $chunk, 65536 ) or last;
		$written .= $chunk;
	}
	like $written,   qr/\x1b\[6n/,              'the question was sent';
	like $written,   qr/\x1b\[5;1Hx/,           'cells go to their absolute position';
	unlike $written, qr/\x1b\[\?1049|\x1b\[2J/, 'neither the alternate screen nor a clear, not even at tb_shutdown';
};

done_testing;
