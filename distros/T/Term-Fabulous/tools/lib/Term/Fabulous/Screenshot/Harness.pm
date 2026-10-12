package Term::Fabulous::Screenshot::Harness;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use JSON::PP ();
use MIME::Base64 qw(encode_base64);
use Term::Fabulous::Screenshot::Clock;

# The configuration, written by Term::Fabulous::Screenshot::Runner.
use constant CONFIG_VARIABLE => 'TF_SCREENSHOT_HARNESS';

my $config;

BEGIN {
	my $json = $ENV{ CONFIG_VARIABLE() } // die "Term::Fabulous::Screenshot::Harness: " . CONFIG_VARIABLE() . " is not set; the harness runs only under Term::Fabulous::Screenshot::Runner\n";
	$config = JSON::PP->new->utf8->decode($json);
	Term::Fabulous::Screenshot::Clock::install( $config->{epoch} );
}

use IO::Async::Loop;
use Term::Fabulous::Screenshot::VirtualLoop;
use Term::Fabulous::Termbox qw(tb_width tb_height tb_get_cell TB_DEFAULT TB_OK);
use Term::Fabulous::Terminal::Termbox::Cells;
use Term::Fabulous::Unicode qw(cluster_columns grapheme_clusters);

# Virtual seconds the program gets after each input before the next step,
# enough for several frames at Term::Fabulous's 30 frames per second.
use constant INPUT_PAUSE_SECONDS => 0.1;

# Real seconds the terminal may take to deliver input before the harness
# gives up.
use constant INPUT_DELIVERY_TIMEOUT => 5;

# A terminal holds at most 4095 unread input bytes; a step must fit.
use constant MAX_SEND_BYTES => 4095;

# Created before the program runs, so IO::Async::Loop->new returns it to
# the program and to Term::Fabulous.
my $loop = Term::Fabulous::Screenshot::VirtualLoop->new;
die "Term::Fabulous::Screenshot::Harness: IO::Async::Loop->new does not return the virtual loop\n"
	unless IO::Async::Loop->new == $loop;

my $input = _open_input( $config->{input_fd} );

# The terminal row an inline region starts on, or undef: the shell's
# lines are shown above it. Recorded as Term::Fabulous places it.
my $region_top;
_watch_inline_region() if @{ $config->{shell} // [] };

# The sixel pictures of the last frame, at terminal rows.
my @pictures;
_watch_pictures();

# The steps start when the program's event loop does, which for a
# Term::Fabulous program is after the terminal has been opened.
$loop->watch_time(
	after => 0,
	code  => sub {
		_mark_started();
		_run_steps( @{ $config->{steps} } );
	}
);

# Tells the runner the event loop ran, so a program that ends before the
# screenshot is reported as such.
sub _mark_started () {
	open my $marker, '>', "$config->{capture_file}.started" or die "Term::Fabulous::Screenshot::Harness: cannot write $config->{capture_file}.started: $!\n";
	close $marker;
	return;
}

sub _watch_inline_region () {
	my $place_region = \&Term::Fabulous::Terminal::Termbox::Cells::place_region;
	no warnings 'redefine';
	*Term::Fabulous::Terminal::Termbox::Cells::place_region = sub ( $cells, $top, $rows ) {
		$region_top = $top if defined $top;
		return $cells->$place_region( $top, $rows );
	};
	return;
}

# Term::Fabulous hands the pictures of every frame to the cell target
# before presenting it; the terminal shows those of the last one.
sub _watch_pictures () {
	my $show_sixels = \&Term::Fabulous::Terminal::Termbox::Cells::show_sixels;
	no warnings 'redefine';
	*Term::Fabulous::Terminal::Termbox::Cells::show_sixels = sub ( $cells, @placements ) {
		my $top = $cells->region_top // 0;
		@pictures = map { +{ %$_, y => $_->{y} + $top } } @placements;
		return $cells->$show_sixels(@placements);
	};
	return;
}

sub _open_input ($fd) {
	open my $handle, '>&=', $fd or die "Term::Fabulous::Screenshot::Harness: cannot open the terminal input (file descriptor $fd): $!\n";
	binmode $handle;
	return $handle;
}

sub _run_steps (@steps) {
	my $step = shift @steps;
	return _capture_screen() unless defined $step;

	my $continue = sub { _run_steps(@steps) };
	if ( $step->{action} eq 'wait' ) {
		$loop->watch_time( after => $step->{seconds}, code => $continue );
		return;
	}
	if ( $step->{action} eq 'send' ) {
		_send_to_terminal( pack 'H*', $step->{bytes} );
		$loop->watch_time( after => INPUT_PAUSE_SECONDS, code => $continue );
		return;
	}
	die "Term::Fabulous::Screenshot::Harness: unknown step action '$step->{action}'\n";
}

# Writes the bytes as the terminal would, then waits in real time until
# they can be read, so the program sees them before the clock moves on.
sub _send_to_terminal ($bytes) {
	die "Term::Fabulous::Screenshot::Harness: a step sends " . length($bytes) . " bytes, more than the terminal can hold (" . MAX_SEND_BYTES . ")\n"
		if length($bytes) > MAX_SEND_BYTES;
	my $offset = 0;
	while ( $offset < length $bytes ) {
		my $written = syswrite( $input, $bytes, length($bytes) - $offset, $offset );
		die "Term::Fabulous::Screenshot::Harness: writing to the terminal failed: $!\n" unless defined $written;
		$offset += $written;
	}

	my $started = CORE::time();    # the real clock: CORE:: bypasses the virtual one
	until ( _pending_input_bytes() >= length $bytes ) {
		die "Term::Fabulous::Screenshot::Harness: the terminal did not deliver the input within " . INPUT_DELIVERY_TIMEOUT . " seconds\n"
			if CORE::time() - $started > INPUT_DELIVERY_TIMEOUT;
		select( undef, undef, undef, 0.001 );    ## no critic (BuiltinFunctions::ProhibitSleepViaSelect) sleep and Time::HiRes run on the virtual clock
	}
	return;
}

# Bytes waiting to be read on the terminal, which is the program's STDIN.
sub _pending_input_bytes () {
	require 'sys/ioctl.ph';    ## no critic (Modules::RequireBarewordIncludes) a .ph file has no module name
	my $count = pack 'L', 0;
	ioctl( STDIN, FIONREAD(), $count ) or die "Term::Fabulous::Screenshot::Harness: FIONREAD on the terminal failed: $!\n";
	return unpack 'L', $count;
}

# Reads what the terminal shows from termbox2's front buffer: the cells
# of the last frame Term::Fabulous presented.
sub _capture_screen () {
	my ( $columns, $rows ) = ( tb_width(), tb_height() );
	die "Term::Fabulous::Screenshot::Harness: the program has not opened the terminal; only Term::Fabulous programs can be captured while they run\n"
		unless $columns > 0 && $rows > 0;

	my @screen = map { _capture_row( $_, $columns ) } 0 .. $rows - 1;
	_show_shell_lines( \@screen, $columns ) if @{ $config->{shell} // [] };
	my $capture = { columns => $columns, rows => $rows, cells => \@screen, pictures => [ map { _capture_picture($_) } @pictures ] };

	open my $file, '>', $config->{capture_file} or die "Term::Fabulous::Screenshot::Harness: cannot write $config->{capture_file}: $!\n";
	print {$file} JSON::PP->new->utf8->canonical->encode($capture);
	close $file or die "Term::Fabulous::Screenshot::Harness: cannot write $config->{capture_file}: $!\n";

	$loop->stop;
	return;
}

# A sixel picture as the cells it covers and the picture as PNG, in
# base64. Only programs that show pictures need Imager.
sub _capture_picture ($placement) {
	require Imager;
	require Imager::File::SIXEL;
	my $image = Imager->new( data => $placement->{data}, type => 'sixel' ) or die "Term::Fabulous::Screenshot::Harness: cannot read a sixel picture: " . Imager->errstr . "\n";
	$image->write( data => \my $png, type => 'png' ) or die "Term::Fabulous::Screenshot::Harness: cannot write a sixel picture as PNG: " . $image->errstr . "\n";
	return { ( map { $_ => $placement->{$_} } qw(x y columns rows) ), png => encode_base64( $png, '' ) };
}

# The shell's lines go on the rows directly above the inline region, as
# far as they reach; the rest scrolled out of the terminal.
sub _show_shell_lines ( $screen, $columns ) {
	die "Term::Fabulous::Screenshot::Harness: the scenario has shell lines, but the program did not draw into an inline region\n"
		unless defined $region_top;
	my @lines = @{ $config->{shell} };
	splice @lines, 0, @lines - $region_top if @lines > $region_top;
	my $y = $region_top - @lines;
	foreach my $line (@lines) {
		$screen->[ $y++ ] = _text_row( $line, $columns );
	}
	return;
}

# A line of text in the terminal's default colors, as captured cells.
sub _text_row ( $line, $columns ) {
	my @cells = map { [ $_, cluster_columns($_), TB_DEFAULT, TB_DEFAULT ] } grapheme_clusters($line);
	my $width = 0;
	$width += $_->[1] foreach @cells;
	die "Term::Fabulous::Screenshot::Harness: the shell line '$line' is $width columns wide, the terminal only $columns\n" if $width > $columns;
	push @cells, [ ' ', 1, TB_DEFAULT, TB_DEFAULT ] foreach $width + 1 .. $columns;
	return \@cells;
}

# One row as [ glyph, columns, fg, bg ] per visible character. termbox2
# draws a wide character that does not fit at the end of a row as spaces.
sub _capture_row ( $y, $columns ) {
	my @cells;
	my $x = 0;
	while ( $x < $columns ) {
		my ( $status, $glyph, $fg, $bg ) = tb_get_cell( $x, $y, 0 );
		die "Term::Fabulous::Screenshot::Harness: tb_get_cell($x, $y) failed with status $status\n" unless $status == TB_OK;
		$glyph = ' ' unless length $glyph;

		my $width = cluster_columns($glyph);
		if ( $x + $width > $columns ) {
			push @cells, [ ' ', 1, $fg, $bg ] foreach $x .. $columns - 1;
			last;
		}
		push @cells, [ $glyph, $width, $fg, $bg ];
		$x += $width;
	}
	return \@cells;
}

1;

__END__

=head1 NAME

Term::Fabulous::Screenshot::Harness - Runs inside an example program to
replay input and capture the screen

=head1 SYNOPSIS

	# Started by Term::Fabulous::Screenshot::Runner, never by hand:
	TF_SCREENSHOT_HARNESS='{...}' perl -MTerm::Fabulous::Screenshot::Harness examples/form.pl

=head1 DESCRIPTION

Maintainer tool, not installed. L<Term::Fabulous::Screenshot::Runner>
starts every example program with this module loaded first, in a
pseudo terminal. Loading it:

=over

=item *

installs the virtual clock (L<Term::Fabulous::Screenshot::Clock>) at the
configured start time, before any other module is compiled;

=item *

creates a L<Term::Fabulous::Screenshot::VirtualLoop>, which becomes the
loop C<< IO::Async::Loop->new >> returns, so the program's timers and
Term::Fabulous's frames run in virtual time;

=item *

schedules the steps: once the program runs its event loop, they wait
or write input into the terminal, in order. After writing, the harness
waits in real time until the terminal has delivered the bytes and then
gives the program 0.1 virtual seconds before the next step.

=back

The harness records the sixel pictures of every frame (by wrapping
C<Term::Fabulous::Terminal::Termbox::Cells::show_sixels>): they are not
cells, so termbox2's buffer does not hold them. Those of the last frame
are added to the capture, on the terminal rows they cover.

When the scenario has C<shell> lines, the harness also records where
the program places its inline region (by wrapping
C<Term::Fabulous::Terminal::Termbox::Cells::place_region>): termbox2's
buffer holds only what the program drew, so the lines the shell printed
before are added to the capture, on the rows directly above the region.

After the last step it reads every cell of termbox2's front buffer
(what the terminal shows), writes them as JSON to the capture file and
stops the event loop, so the program ends as if the user had quit.

A program that never runs an event loop (one that prints a report with
L<Term::Fabulous::Static>, for example) is not affected: it prints and
ends, and the runner takes the screenshot from its output.

=head1 CONFIGURATION

The environment variable C<TF_SCREENSHOT_HARNESS> holds a JSON object:

=over

=item C<epoch>

The start time of the virtual clock, in epoch seconds.

=item C<steps>

An array of C<{ "action": "wait", "seconds": N }> and
C<{ "action": "send", "bytes": HEX }> objects.

=item C<shell>

An array of lines a shell printed before the program started, shown
above the program's inline region. Optional; a program that does not
draw into an inline region dies when there are any.

=item C<input_fd>

The file descriptor of the pseudo terminal's master side, to write
input to.

=item C<capture_file>

Where to write the captured screen (and, next to it with C<.started>
appended, an empty file once the event loop runs):
C<{ columns, rows, cells, pictures }>, with one array per row of
C<[ glyph, columns, fg, bg ]> arrays, the attributes as termbox2 stores
them, and the sixel pictures of the last frame as
C<{ x, y, columns, rows, png }> objects: the first cell (C<y> a
terminal row) and the cells each covers, and the picture as PNG in
base64.

=back

=cut
