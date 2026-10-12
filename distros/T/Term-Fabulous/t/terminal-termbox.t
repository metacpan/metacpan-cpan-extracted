use v5.32;
use warnings;

use Test2::V0;
use Feature::Compat::Try;

use Fcntl qw(F_GETFL O_NONBLOCK);
use Term::Fabulous;
use Term::Fabulous::Terminal::Termbox;
use Term::Fabulous::Widget::Box;

# termbox2 runs on the slave side of a pseudo terminal, which gives it a
# size; the input comes from a pipe the test writes the terminal's answers
# into, and the output is read back from the master side.
try { require IO::Pty }
catch ($error) { skip_all 'IO::Pty is not installed' }

# termbox2 refuses to start without TERM, which CI runners do not set
$ENV{TERM} //= 'xterm';

sub pseudo_terminal {
	my ( $columns, $rows ) = @_;
	my $pty = IO::Pty->new;
	$pty->slave->set_winsize( $rows, $columns );
	pipe my $input, my $answers or die "pipe: $!";
	$answers->autoflush(1);
	return ( $pty, $input, $answers );
}

sub written {
	my ($pty) = @_;
	my $written = '';
	vec( my $readable = '', fileno $pty, 1 ) = 1;
	while ( select( my $ready = $readable, undef, undef, 0.2 ) > 0 ) {
		sysread( $pty, my $chunk, 65536 ) or last;
		$written .= $chunk;
	}
	return $written;
}

subtest 'a full-screen session' => sub {
	my ( $pty, $input, $answers ) = pseudo_terminal( 10, 3 );
	my $terminal = Term::Fabulous::Terminal::Termbox->new( input => $input, output => $pty->slave );
	print {$answers} "\e[?5u\e[?62;22c";    # the kitty keyboard flags, then the device attributes
	try { $terminal->open( inline => undef, mouse => 1, kitty_keyboard => 1 ) }
	catch ($error) { skip_all "termbox2 cannot start on a pty here: $error" }

	is [ $terminal->is_open, $terminal->size, $terminal->kitty_keyboard_active ], [ 1, 10, 3, 1 ], 'open, with the size of the terminal and the kitty keyboard protocol';
	is scalar( () = $terminal->read_handles ),                                    2,               'the input and resize descriptors to watch';
	like dies { $terminal->open( inline => undef, mouse => 1, kitty_keyboard => 1 ) }, qr/the terminal is open already/, 'a second open dies';

	print {$answers} 'a';
	my $event = $terminal->next_event;
	is [ $event->ch, $terminal->next_event ], [ ord 'a', undef ], 'next_event returns what was typed, then nothing';
	is $terminal->input_ended,                0,                  'the input goes on';

	$terminal->close;
	ok lives { $terminal->close }, 'closing twice does nothing';
	is [ $terminal->is_open, $terminal->kitty_keyboard_active ], [ 0, 0 ], 'closed';
	like written($pty), qr/\e\[\?1003h.*\e\[>5u.*\e\[\?1003l\e\[<u/s, 'mouse motion reporting and the kitty flags are switched on, then off again in reverse';
};

subtest 'an inline session' => sub {
	my ( $pty, $input, $answers ) = pseudo_terminal( 10, 6 );
	my $terminal = Term::Fabulous::Terminal::Termbox->new( input => $input, output => $pty->slave );
	print {$answers} "\e[5;3R";    # the cursor in the fifth row, after some text
	$terminal->open( inline => 3, mouse => 0, kitty_keyboard => 0 );
	is [ $terminal->size, $terminal->cell_target->region_top ], [ 10, 3, 3 ], 'the region below the cursor, moved up to fit the screen';

	print {$answers} "\e[2;1R";
	is [ $terminal->apply_resize( 12, 6 ), $terminal->cell_target->region_top ], [ 12, 3, 1 ], 'a resize finds the region where the terminal moved the cursor';
	$terminal->close;
	is $terminal->cell_target->region_top, undef, 'the region is forgotten when it closes';

	my $written = written($pty);
	like $written,   qr/\e\[6n.*\e\[6;1H\n\n\e\[4;1H\e\[J/s, 'the terminal scrolls up and the region is erased';
	like $written,   qr/\e\[2;1H\e\[J.*\e\[4;1H\n/s,         'after the resize too; the shell goes on below its last row';
	unlike $written, qr/\e\[\?1049h|\e\[\?1003h/,            'neither the alternate screen nor the mouse';

	like dies { $terminal->open( inline => 3, mouse => 0, kitty_keyboard => 0 ) }, qr/^Term::Fabulous::Terminal::Termbox: the terminal did not report its cursor position/,
		'a terminal that does not report the cursor cannot open inline';
	is $terminal->is_open, 0, 'and is closed again';
};

subtest 'the end of the input' => sub {
	my ( $pty, $input, $answers ) = pseudo_terminal( 10, 3 );
	my $terminal = Term::Fabulous::Terminal::Termbox->new( input => $input, output => $pty->slave );
	$terminal->open( inline => undef, mouse => 0, kitty_keyboard => 0 );
	print {$answers} 'a';
	is $terminal->input_ended, 0, 'a byte to read';
	$terminal->next_event;
	close $answers;
	is $terminal->input_ended, 1, 'readable with nothing to read: the end of the input';
	$terminal->close;

	my $hanging = IO::Pty->new;
	$hanging->slave->set_winsize( 3, 10 );
	my $live = Term::Fabulous::Terminal::Termbox->new( input => $hanging->slave, output => $hanging->slave );
	$live->open( inline => undef, mouse => 0, kitty_keyboard => 0 );
	is $live->input_ended, 0, 'a live terminal';
	close $hanging;
	is $live->input_ended, 1, 'a terminal that hung up';
	$live->close;
};

subtest 'an open terminal that is dropped closes itself' => sub {
	my ( $pty, $input, $answers ) = pseudo_terminal( 10, 3 );
	my $terminal = Term::Fabulous::Terminal::Termbox->new( input => $input, output => $pty->slave );
	$terminal->open( inline => undef, mouse => 1, kitty_keyboard => 0 );
	undef $terminal;
	like written($pty), qr/\e\[\?1003l.*\e\[\?1049l/s, 'mouse reporting and the alternate screen are switched off';
};

subtest 'errors' => sub {
	my ( $pty, $input ) = pseudo_terminal( 10, 3 );
	open my $write_only, '>', '/dev/null' or die "/dev/null: $!";    ## no critic (InputOutput::RequireBriefOpen) the terminal reads from it
	my $unreadable = Term::Fabulous::Terminal::Termbox->new( input => $write_only, output => $pty->slave );
	$unreadable->open( inline => undef, mouse => 0, kitty_keyboard => 0 );
	like dies { $unreadable->next_event }, qr/^Term::Fabulous::Terminal::Termbox: reading terminal input failed/, 'a read error dies';
	$unreadable->close;

	open my $read_only, '<', '/dev/null' or die "/dev/null: $!";    ## no critic (InputOutput::RequireBriefOpen) the terminal writes to it
	my $unwritable = Term::Fabulous::Terminal::Termbox->new( input => $input, output => $read_only );
	like dies { $unwritable->open( inline => undef, mouse => 0, kitty_keyboard => 0 ) }, qr/^Term::Fabulous::Terminal::Termbox: tb_init_rwfd failed/, 'termbox2 cannot start';
	is $unwritable->is_open, 0, 'and nothing is open';

	like dies { Term::Fabulous::Terminal::Termbox->new( input => $input ) },                      qr/input and output go together/, 'input needs output';
	like dies { $unwritable->open( inline => 3, mouse => 0, kitty_keyboard => 0, cursor => 1 ) }, qr/open does not accept cursor/,  'unknown open options die';
	like dies { $unwritable->size },                                                              qr/the terminal is not open/,     'size needs an open terminal';
};

subtest 'Term::Fabulous runs on it' => sub {
	my ( $pty, $input, $answers ) = pseudo_terminal( 20, 4 );
	my $terminal = Term::Fabulous::Terminal::Termbox->new( input => $input, output => $pty->slave );
	my $ui       = Term::Fabulous->new( root => Term::Fabulous::Widget::Box->new( background_color => [ 9, 9, 9, 255 ] ), width => 1, height => 1, terminal => $terminal );
	my @seen;
	$ui->root->on(
		KeyPress => sub {
			push @seen, [ $_[0]->key_name, $ui->width, $ui->height, map { fcntl( $_, F_GETFL, 0 ) & O_NONBLOCK ? 'non-blocking' : 'blocking' } $input, $pty->slave ];
			return;
		}
	);
	$ui->root->on( Start => sub { print {$answers} "x\x03"; return } );
	ok lives { $ui->run }, 'run returns after Ctrl+C';
	is \@seen, [ [ 'x', 20, 4, 'blocking', 'blocking' ], [ 'Ctrl+C', 20, 4, 'blocking', 'blocking' ] ],
		"the keys arrive, the layout has the terminal's size, and termbox's descriptors stay blocking while they are watched";
	is $terminal->is_open, 0, 'the terminal is closed when run returns';
};

subtest 'sixel pictures' => sub {
	skip_all 'Imager and Imager::File::SIXEL are not installed' unless eval { require Imager; require Imager::File::SIXEL; 1 };
	require Term::Fabulous::Widget::Sixel;
	my ( $pty, $input, $answers ) = pseudo_terminal( 6, 3 );
	my $terminal = Term::Fabulous::Terminal::Termbox->new( input => $input, output => $pty->slave );
	my $red      = Imager->new( xsize => 4, ysize => 8, channels => 4 );
	$red->box( filled => 1, color => Imager::Color->new( 255, 0, 0, 255 ) );
	$red->write( data => \my $png, type => 'png' ) or die $red->errstr;
	my $sixel = Term::Fabulous::Widget::Sixel->new( data => $png );
	my $root  = Term::Fabulous::Widget::Box->new;
	$root->add_child($sixel);
	my $ui = Term::Fabulous->new( root => $root, width => 1, height => 1, terminal => $terminal, mouse => 0, kitty_keyboard => 0 );

	print {$answers} "\e[6;4;2t\e[?62;4;22c";    # cells of 2x4 pixels, then the device attributes with sixel
	$ui->step;
	is [ $terminal->cell_target->sixel_cell_size ], [ 2, 4 ], 'the cell size the terminal reported';
	is $terminal->cell_target->sixel_area( 6, 3 ), [ 0, 0, 6, 2 ], 'pictures leave out the last row';
	like written($pty), qr/\e\[16t\e\[c.*\e\[1;1H\eP[^\e]*\e\\/s, 'the picture is sent at its cell after the cells';

	$ui->invalidate;
	$ui->step;
	unlike written($pty), qr/\eP/, 'an unchanged picture is not sent again';

	$sixel->data(undef);
	$ui->step;
	like written($pty), qr/\e\[1;1H/, 'the cells of a picture that is gone are drawn again';
	$terminal->close;
	is [ $terminal->cell_target->sixel_cell_size ], [], 'a closed terminal shows no sixel';
};

done_testing;
