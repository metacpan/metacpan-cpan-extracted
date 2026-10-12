use v5.32;
use warnings;

use Test2::V0;

use Object::Pad 0.825;
use IO::Async::Loop;
use IO::Async::OS;
use IO::Async::Signal;
use Clay::XS qw(sizing_fixed sizing_grow);
use Fcntl qw(F_GETFL O_NONBLOCK);
use Scalar::Util qw(weaken);
use Term::Fabulous::Termbox qw(TB_EVENT_RESIZE);
use Term::Fabulous;
use Term::Fabulous::Terminal::Memory;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Canvas;
use Term::Fabulous::Widget::Text;

# A memory terminal whose input cannot be read, and one that cannot be
# opened.
class BrokenInput :isa(Term::Fabulous::Terminal::Memory) {
	method next_event :override () { die "Term::Fabulous::Terminal::Memory: reading terminal input failed\n" }
}

class Unopenable :isa(Term::Fabulous::Terminal::Memory) {
	method open :override (%options) { die "Unopenable: no terminal here\n" }
}

my $loop = IO::Async::Loop->new;

# IO::Async adds its own signal-pipe handle on the first signal watch and
# keeps it for the loop's lifetime; create it before taking the snapshot.
# On Windows IO::Async watches no signals at all.
if ( IO::Async::OS->HAVE_SIGNALS ) {
	my $warmup_signal = IO::Async::Signal->new( name => 'HUP', on_receipt => sub { } );
	$loop->add($warmup_signal);
	$loop->remove($warmup_signal);
}
my $notifiers_before = scalar $loop->notifiers;

# A Term::Fabulous on a 20x5 memory terminal, with a root that paints every
# cell, so the screen shows whether a frame was drawn.
sub memory_ui {
	my (%params) = @_;
	my $terminal = delete $params{terminal} // Term::Fabulous::Terminal::Memory->new( width => 20, height => 5 );
	my $root     = delete $params{root}     // Term::Fabulous::Widget::Box->new( background_color => [ 9, 9, 9, 255 ], layout => { sizing => { width => sizing_grow(), height => sizing_grow() } } );
	return ( Term::Fabulous->new( width => 20, height => 5, root => $root, terminal => $terminal, %params ), $terminal );
}

sub is_blank {
	my ($terminal) = @_;
	return !grep { length } $terminal->lines;
}

my $draw_dies = 1;
my $canvas    = Term::Fabulous::Widget::Canvas->new( layout => { sizing => { width => sizing_fixed(4), height => sizing_fixed(2) } } );
$canvas->on( CanvasResize => sub { die "draw failed\n" if $draw_dies; return } );
my $canvas_root = Term::Fabulous::Widget::Box->new;
$canvas_root->add_child($canvas);
my ( $ui, $terminal ) = memory_ui( root => $canvas_root );

subtest 'a draw that dies' => sub {
	like dies { $ui->run }, qr/^draw failed/, 'the exception propagates out of run';
	is [ $terminal->is_open, $terminal->session_count ], [ 0, 1 ],          'the terminal is restored';
	is scalar( $loop->notifiers ),                       $notifiers_before, 'no notifier is left on the loop';
};

subtest 'a second run works' => sub {
	$draw_dies = 0;
	my ( @starts, @blocking );
	my @watched_handles = $^O eq 'MSWin32' ? () : $terminal->read_handles;    # run polls on Windows and watches no handles
	$ui->root->on( Start => sub { push @starts, [ $_[0]->width, $_[0]->height, $ui->width ]; return } );
	$ui->root->on(
		KeyPress => sub {
			push @blocking, map { fcntl( $_, F_GETFL, 0 ) & O_NONBLOCK ? 0 : 1 } @watched_handles;
			return;
		}
	);
	$terminal->press_key('Ctrl+C');

	ok lives { $ui->run }, 'run returns after Ctrl+C';
	is \@blocking,                                       [ map { 1 } @watched_handles ], 'the watched terminal handles stay blocking';
	is \@starts,                                         [ [ 20, 5, 20 ] ],              'Start fires once, with the terminal size already applied';
	is [ $terminal->is_open, $terminal->session_count ], [ 0, 2 ],                       'the terminal is restored again';
	is scalar( $loop->notifiers ),                       $notifiers_before,              'no notifier is left on the loop';
};

subtest 'stop_on_ctrl_c => 0 makes Ctrl+C an ordinary key' => sub {
	my ( $keeps, $keeps_terminal ) = memory_ui( stop_on_ctrl_c => 0 );
	is [ $ui->stop_on_ctrl_c, $keeps->stop_on_ctrl_c ], [ 1, 0 ], 'the reader, with its default';
	my @keys;
	$keeps->root->on(
		KeyPress => sub {
			push @keys, $_[0]->key_name;
			$keeps->loop->stop if $_[0]->key_name eq 'Ctrl+Q';
			return;
		}
	);
	$keeps_terminal->press_key($_) foreach 'Ctrl+C', 'x', 'Ctrl+Q';
	ok lives { $keeps->run }, 'run returns on the program\'s own key';
	is \@keys, [ 'Ctrl+C', 'x', 'Ctrl+Q' ], 'Ctrl+C reached the listener and did not stop the loop';
	like dies { memory_ui( stop_on_ctrl_c => [] ) }, qr/stop_on_ctrl_c must be a boolean/, 'a reference dies';
};

subtest 'Start fires inside the running loop' => sub {
	my $handler = sub { };
	local $SIG{INT} = $handler;
	local $SIG{HUP} = 'IGNORE';
	my ( $start, $start_terminal ) = memory_ui();
	my ( $loop_in_start, $blank_at_start );
	$start->root->on( Start => sub { $loop_in_start = $start->loop; $blank_at_start = is_blank($start_terminal); $start->loop->stop; return } );

	ok lives { $start->run }, 'a Start listener can stop the loop';
	ref_is $loop_in_start, $loop, 'and sees it';
	ok $blank_at_start, 'no frame is drawn before Start';
	ref_is $SIG{INT}, $handler, 'run gives back the INT handler it found';
	is $SIG{HUP},                  'IGNORE',          'and the HUP setting';
	is scalar( $loop->notifiers ), $notifiers_before, 'no notifier is left on the loop';
};

subtest 'a signal watcher of the program outlives run' => sub {
	skip_all 'IO::Async watches no signals on Windows' unless IO::Async::OS->HAVE_SIGNALS;
	my $received   = 0;
	my $watcher    = IO::Async::Signal->new( name => 'TERM', on_receipt => sub { $received++ } );
	my ($watching) = memory_ui();
	$watching->root->on( Start => sub { $watching->loop->add($watcher); $watching->loop->stop; return } );
	$watching->run;
	kill TERM => $$;
	$loop->loop_once(0.1);
	is $received, 1, 'IO::Async still handles the signal it watches';
	$loop->remove($watcher);
};

subtest 'INT, TERM and HUP end run' => sub {
	skip_all 'IO::Async watches no signals on Windows' unless IO::Async::OS->HAVE_SIGNALS;
	foreach my $signal (qw(INT TERM HUP)) {
		my ($signalled) = memory_ui();
		$signalled->root->on( Start => sub { kill $signal => $$; return } );
		ok lives { $signalled->run }, "run returns after SIG$signal";
	}
};

subtest 'a resize' => sub {
	my ( $resizing, $resizing_terminal ) = memory_ui();
	my ( @resizes, $blank_after_resize );
	$resizing->root->on(
		Resize => sub {
			my ($event) = @_;
			push @resizes, [ $event->width, $event->height, $event->is_post_event, $resizing->width ];
			return unless $event->is_post_event;
			$blank_after_resize = is_blank($resizing_terminal);
			$resizing->loop->stop;
			return;
		}
	);
	$resizing->root->on(
		Start => sub {
			$resizing_terminal->resize( 10, 3 )->push_event( type => TB_EVENT_RESIZE, w => 0, h => 0 )->resize( 30, 8 );
			return;
		}
	);
	ok lives { $resizing->run }, 'run returns';

	is \@resizes, [ [ 30, 8, 0, 20 ], [ 30, 8, 1, 30 ] ], 'one Resize pair for the last usable size, the size applied in between';
	ok $blank_after_resize, 'no frame is drawn while the size settles';
	is [ $resizing_terminal->width, $resizing_terminal->height ], [ 30, 8 ], 'the terminal has the new size';
};

subtest 'a resize that ends at the old size repaints the canvases' => sub {
	my $box  = Term::Fabulous::Widget::Canvas->new( layout => { sizing => { width => sizing_fixed(3), height => sizing_fixed(1) } } );
	my $root = Term::Fabulous::Widget::Box->new;
	$root->add_child($box);
	my ( $resizing, $resizing_terminal ) = memory_ui( root => $root );
	$resizing->step;
	$box->put_text( 0, 0, 'abc' );
	$resizing->step;
	$resizing->invalidate->step;    # now the canvas keeps its cells
	$resizing_terminal->cell_target->set_cell( 1, 0, 'Z', 0, 0 );    # a stand-in for what is on the screen

	$resizing_terminal->resize( 10, 3 )->resize( 20, 5 );
	$resizing->step;
	is [ $resizing_terminal->lines ]->[0] =~ s/\s+\z//r, 'abc', 'every reported size makes the terminal lose its cells, so no canvas is kept';
};

subtest 'inline mode' => sub {
	my $box = sub { Term::Fabulous::Widget::Box->new };
	like dies { Term::Fabulous->new( width => 20, height => 5, root => $box->(), inline => 0 ) }, qr/inline must be a whole number of rows of at least 1, got '0'/, 'inline needs rows';
	like dies { Term::Fabulous->new( width => 20, height => 5, root => $box->(), inline => 3, mouse => 1 ) }, qr/inline mode has no mouse support/, 'and has no mouse';

	my $text = Term::Fabulous::Widget::Text->new( text => 'asking' );
	my $root = $box->();
	$root->add_child($text);
	my ( $inline, $inline_terminal ) = memory_ui( root => $root, inline => 3 );
	is $inline->mouse, 0, 'the mouse is off by default';

	my @seen;
	$inline->root->on(
		Start => sub {
			push @seen, [ $_[0]->height, $inline_terminal->inline_rows, $inline_terminal->mouse_enabled ];
			$text->text('done');
			$inline->loop->stop;
			return;
		}
	);
	ok lives { $inline->run }, 'run returns';
	is \@seen,                                         [ [ 3, 3, 0 ] ],    'Start reports the rows of the region; the terminal reports no mouse';
	is [ map { s/\s+\z//r } $inline_terminal->lines ], [ 'done', '', '' ], 'the state the loop stopped in is drawn before run returns';
	is $inline_terminal->inline_rows,                  undef,              'the region is given back after run';

	my ( $resizing, $resizing_terminal ) = memory_ui( root => $box->(), inline => 3 );
	$resizing->root->on( Start => sub { $resizing_terminal->resize( 30, 8 ); return } );
	$resizing->root->on(
		Resize => sub {
			return unless $_[0]->is_post_event;
			push @seen, [ $_[0]->width, $_[0]->height ];
			$resizing->loop->stop;
			return;
		}
	);
	ok lives { $resizing->run }, 'run returns after a resize';
	is $seen[-1], [ 30, 3 ], 'the region keeps its rows on a resize';
};

subtest 'kitty keyboard protocol' => sub {
	my @active_at_start;
	my $speaking = Term::Fabulous::Terminal::Memory->new( width => 20, height => 5, kitty_keyboard => 1 );
	my ($kitty) = memory_ui( terminal => $speaking, mouse => 0 );
	$kitty->root->on( Start => sub { push @active_at_start, $kitty->kitty_keyboard_active; $kitty->loop->stop; return } );
	ok lives { $kitty->run }, 'run returns';
	is \@active_at_start,             [1], 'a terminal that speaks the protocol gets it';
	is $kitty->kitty_keyboard_active, 0,   'and run no longer uses it';

	my $also_speaking = Term::Fabulous::Terminal::Memory->new( width => 20, height => 5, kitty_keyboard => 1 );
	my ($legacy) = memory_ui( terminal => $also_speaking, kitty_keyboard => 0 );
	$legacy->root->on( Start => sub { push @active_at_start, $legacy->kitty_keyboard_active; $legacy->loop->stop; return } );
	ok lives { $legacy->run }, 'run returns with kitty_keyboard => 0';
	is \@active_at_start, [ 1, 0 ], 'the protocol is not asked for';
};

subtest 'terminal input errors' => sub {
	my ($reading) = memory_ui( terminal => BrokenInput->new( width => 20, height => 5 ) );
	$reading->root->on( Start => sub { $reading->terminal->type_text('x'); return } );
	like dies { $reading->run }, qr/^Term::Fabulous::Terminal::Memory: reading terminal input failed/, 'a terminal that cannot read its input ends run';
	is $reading->terminal->is_open, 0, 'and is restored';

	my ( $ending, $ending_terminal ) = memory_ui();
	$ending->root->on( Start => sub { $ending_terminal->end_input; return } );
	like dies { $ending->run }, qr/^Term::Fabulous: the terminal was closed/, 'the end of the terminal input ends run';
	is scalar( $loop->notifiers ), $notifiers_before, 'no notifier is left on the loop';
};

subtest 'a terminal that cannot be opened' => sub {
	my ($failing) = memory_ui( terminal => Unopenable->new( width => 20, height => 5 ) );
	like dies { $failing->run }, qr/^Unopenable: no terminal here/, 'run dies with the error of the terminal';
	is scalar( $loop->notifiers ), $notifiers_before, 'nothing was added to the loop';
	like dies { $failing->step }, qr/^Unopenable: no terminal here/, 'so does step';
};

subtest 'step outside run' => sub {
	my ( $stepping, $stepping_terminal ) = memory_ui();
	my @starts;
	$stepping->root->on( Start => sub { push @starts, $stepping->loop; return } );
	$stepping->step;
	is [ scalar @starts, $stepping_terminal->is_open ], [ 1, 1 ], 'the first step opens the terminal and fires Start';
	$stepping_terminal->press_key('Ctrl+C');
	ok lives { $stepping->step }, 'Ctrl+C has no loop to stop';
	is scalar @starts, 1, 'Start fires once per opening';

	$stepping_terminal->press_key('Ctrl+C');
	ok lives { $stepping->run }, 'run uses the terminal step opened';
	is [ scalar @starts, $stepping_terminal->is_open ], [ 1, 0 ], 'without firing Start again, and closes it';

	my ($nested) = memory_ui();
	$nested->root->on( Start => sub { $nested->step; return } );
	like dies { $nested->run }, qr/step cannot be called while run is active/, 'step inside run dies';
};

subtest 'run inside run' => sub {
	my $handler = sub { };
	local $SIG{INT} = $handler;
	my ( $outer, $outer_terminal ) = memory_ui();
	my ( $nested_error, $open_after_nested );
	$outer->root->on(
		Start => sub {
			$outer_terminal->press_key('Ctrl+C');    # ends the nested run, should one start
			$nested_error      = dies { $outer->run };
			$open_after_nested = $outer_terminal->is_open;
			$outer->loop->stop;
			return;
		}
	);

	ok lives { $outer->run }, 'the outer run returns';
	like $nested_error, qr/^Term::Fabulous: run is active already; it cannot be called again until it returns/, 'run inside run dies';
	ok $open_after_nested, 'and leaves the terminal of the outer run open';
	is [ $outer_terminal->is_open, $outer_terminal->session_count ], [ 0, 1 ], 'the outer run closes the terminal';
	ref_is $SIG{INT}, $handler, 'and gives back the INT handler it found';
	is scalar( $loop->notifiers ), $notifiers_before, 'no notifier is left on the loop';
};

subtest 'nothing pins the object after run' => sub {
	weaken( my $weak = $ui );
	undef $ui;
	ok !defined $weak, 'Term::Fabulous is freed';
};

done_testing;
