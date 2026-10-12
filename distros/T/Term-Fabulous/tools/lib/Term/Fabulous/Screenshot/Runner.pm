package Term::Fabulous::Screenshot::Runner;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

class Term::Fabulous::Screenshot::Runner :strict(params) {
	use Carp qw(croak);
	use Fcntl qw(F_SETFD);
	use File::Spec;
	use File::Temp ();
	use IO::Pty;
	use IO::Select;
	use JSON::PP ();
	use POSIX qw(WNOHANG _exit);
	use Time::HiRes ();
	use Term::Fabulous::Screenshot::Screen;

	use constant HARNESS         => 'Term::Fabulous::Screenshot::Harness';
	use constant CONFIG_VARIABLE => 'TF_SCREENSHOT_HARNESS';
	use constant READ_SIZE       => 65536;
	use constant POLL_SECONDS    => 0.05;

	# The terminal shows sixel graphics in cells of this many pixels.
	use constant CELL_WIDTH_PIXELS  => 10;
	use constant CELL_HEIGHT_PIXELS => 20;

	# The answers that never change, by the end of their query: the
	# primary device attributes (ESC [ c) of a VT220 that shows sixel
	# (attribute 4) and the cell size in pixels (ESC [ 16 t).
	use constant FIXED_ANSWERS => {
		'c'   => "\e[?62;4;22c",
		'16t' => sprintf( "\e[6;%d;%dt", CELL_HEIGHT_PIXELS, CELL_WIDTH_PIXELS ),
	};

	# The library directories the program is run with; the harness must be
	# found in one of them. Relative directories are made absolute, since
	# the program runs in a directory of its own.
	field $include_dirs :param = [ grep { !ref && -d } @INC ];

	# Real seconds a program may run before it is killed.
	field $timeout :param = 120;

	ADJUST {
		$include_dirs = [ map { File::Spec->rel2abs($_) } @$include_dirs ];
	}

	# Runs $script with @$arguments in a pseudo terminal of the given size
	# and returns the screen: the cells the terminal showed after the last
	# step for a program that runs an event loop, or what it printed for
	# one that prints and ends.
	method capture (%job) {
		my @missing = grep { !defined $job{$_} } qw(script columns rows epoch steps);
		croak "Term::Fabulous::Screenshot::Runner: capture needs " . join( ', ', @missing ) if @missing;
		my $script = File::Spec->rel2abs( $job{script} );
		croak "Term::Fabulous::Screenshot::Runner: $job{script} is not a readable file" unless -f $script && -r _;

		my $work_dir     = File::Temp->newdir( 'tf-screenshot-XXXXXX', TMPDIR => 1 );
		my $capture_file = "$work_dir/.capture.json";
		my $pty          = IO::Pty->new;
		$pty->slave->set_winsize( $job{rows}, $job{columns}, $job{columns} * CELL_WIDTH_PIXELS, $job{rows} * CELL_HEIGHT_PIXELS )
			or croak "Term::Fabulous::Screenshot::Runner: cannot set the terminal size: $!";
		pipe( my $error_reader, my $error_writer ) or croak "Term::Fabulous::Screenshot::Runner: pipe failed: $!";

		my $shell  = $job{shell} // [];
		my $config = {
			epoch        => $job{epoch},
			steps        => $job{steps},
			shell        => $shell,
			input_fd     => fileno($pty),
			capture_file => $capture_file,
		};
		my @command = ( $^X, ( map { "-I$_" } @$include_dirs ), '-M' . HARNESS, $script, @{ $job{arguments} // [] } );

		my $pid = fork // croak "Term::Fabulous::Screenshot::Runner: fork failed: $!";
		if ( $pid == 0 ) {
			_start_program( $pty, $error_writer, "$work_dir", $config, \@command );
		}

		close $error_writer;
		$pty->close_slave;

		# The program runs in a session of its own and keeps the terminal's
		# master side open, so it would outlive an interrupted run, blocked
		# on output nobody reads. Take it (and whatever it started) along.
		my $stop_program = sub ($signal) {
			_kill_session($pid);
			die "Term::Fabulous::Screenshot::Runner: interrupted by SIG$signal\n";
		};
		local $SIG{INT}  = $stop_program;
		local $SIG{TERM} = $stop_program;
		local $SIG{HUP}  = $stop_program;
		my @cursor = ( @$shell < $job{rows} ? scalar @$shell : $job{rows} - 1, 0 );    # below the shell's lines
		my ( $status, $output, $errors ) = $self->_wait_for( $pid, $pty, $error_reader, $job{script}, \@cursor );

		my $command_line = join ' ', 'perl', $job{script}, @{ $job{arguments} // [] };
		croak "Term::Fabulous::Screenshot::Runner: '$command_line' wrote to STDERR:\n$errors" if length $errors;
		croak sprintf "Term::Fabulous::Screenshot::Runner: '%s' ended with exit status %d%s", $command_line, $status >> 8, ( $status & 127 ? " (signal " . ( $status & 127 ) . ")" : '' )
			if $status != 0;

		return Term::Fabulous::Screenshot::Screen->from_capture( _read_json($capture_file) ) if -e $capture_file;

		croak "Term::Fabulous::Screenshot::Runner: '$command_line' ended before the screenshot was taken (did a step make it quit?)"
			if -e "$capture_file.started";
		croak "Term::Fabulous::Screenshot::Runner: '$command_line' never ran an event loop, so its input steps were not sent"
			if grep { $_->{action} eq 'send' } @{ $job{steps} };
		return Term::Fabulous::Screenshot::Screen->from_output( $output, $job{columns} );
	}

	# In the child: make the pseudo terminal the controlling terminal and
	# STDIN and STDOUT, keep its master side open for the harness, and run
	# the program in a clean, fixed environment. Never returns.
	sub _start_program ( $pty, $error_writer, $work_dir, $config, $command ) {

		# _exit flushes no Perl buffers, so the message is written directly.
		my $failed = sub ($message) {
			syswrite $error_writer, "Term::Fabulous::Screenshot::Runner: $message\n";
			_exit(127);
		};

		open( STDERR, '>&', $error_writer ) or $failed->("cannot redirect STDERR: $!");
		$pty->make_slave_controlling_terminal;
		my $slave = $pty->slave;
		open( STDIN,  '<&', $slave ) or $failed->("cannot attach STDIN to the terminal: $!");
		open( STDOUT, '>&', $slave ) or $failed->("cannot attach STDOUT to the terminal: $!");
		fcntl( $pty, F_SETFD, 0 ) or $failed->("cannot keep the terminal's master side open: $!");
		chdir $work_dir or $failed->("cannot change to $work_dir: $!");

		%ENV = (
			PATH              => $ENV{PATH} // '/usr/bin:/bin',
			HOME              => $ENV{HOME} // $work_dir,
			TERM              => 'xterm-256color',
			COLORTERM         => 'truecolor',
			LANG              => 'C.UTF-8',
			LC_ALL            => 'C.UTF-8',
			TZ                => 'UTC',
			PERL_HASH_SEED    => 0,
			PERL_PERTURB_KEYS => 0,
			CONFIG_VARIABLE() => JSON::PP->new->utf8->canonical->encode($config),
		);
		exec { $command->[0] } @$command or $failed->("cannot run $command->[0]: $!");
	}

	# Reads the terminal's output and the program's STDERR until the
	# program ends, so the program never blocks writing to either, and
	# answers the queries in the output. $cursor is the [ row, column ]
	# the cursor starts at.
	method _wait_for ( $pid, $pty, $error_reader, $name, $cursor ) {
		my %buffer_of = ( $pty => '', $error_reader => '' );
		my $select    = IO::Select->new( $pty, $error_reader );
		my $deadline  = Time::HiRes::time() + $timeout;
		my $scanned   = 0;    # the output before this offset holds no unanswered query
		my $status;

		while (1) {
			_read_ready( $select, \%buffer_of, POLL_SECONDS );
			_answer_queries( $pty, \$buffer_of{$pty}, \$scanned, $cursor );
			my $reaped = waitpid( $pid, WNOHANG );
			if ( $reaped == $pid ) {
				$status = $?;
				last;
			}
			next if Time::HiRes::time() < $deadline;

			_kill_session($pid);
			croak "Term::Fabulous::Screenshot::Runner: $name did not end within $timeout seconds and was killed";
		}

		# Whatever is left in the pipes was written before the program ended.
		1 while $select->count && _read_ready( $select, \%buffer_of, 0 );
		return ( $status, $buffer_of{$pty}, $buffer_of{$error_reader} );
	}

	# Answers the queries in the output as a terminal that shows sixel
	# does: the cursor position query (ESC [ 6 n, which inline mode sends)
	# with where the cursor is, the others with FIXED_ANSWERS. The cursor is
	# followed through absolute moves (ESC [ row ; column H) only, which is
	# how termbox2 and inline mode place it; a sequence the output has not
	# completed yet is found on a later call.
	sub _answer_queries ( $pty, $output, $scanned, $cursor ) {
		pos($$output) = $$scanned;
		while ( $$output =~ /\e\[(?:([0-9]*)(?:;([0-9]*))?H|(6n|16t|c))/g ) {
			$$scanned = pos $$output;
			my ( $row, $column, $query ) = ( $1, $2, $3 );
			if ( !defined $query ) {
				@$cursor = map { ( $_ || 1 ) - 1 } $row, $column;
				next;
			}
			my $answer = $query eq '6n' ? sprintf( "\e[%d;%dR", $cursor->[0] + 1, $cursor->[1] + 1 ) : FIXED_ANSWERS->{$query};
			defined syswrite( $pty, $answer ) or croak "Term::Fabulous::Screenshot::Runner: cannot answer the query ESC [ $query: $!";
		}
		return;
	}

	# Kills the program and every process it started (its session is a
	# process group led by it) and reaps it.
	sub _kill_session ($pid) {
		kill 'KILL', -$pid;
		waitpid( $pid, 0 );
		return;
	}

	# Appends what the ready handles have to their buffers; a handle at its
	# end (EOF, or EIO for a terminal nobody holds open) is dropped.
	sub _read_ready ( $select, $buffer_of, $wait ) {
		my @ready = $select->can_read($wait);
		foreach my $handle (@ready) {
			my $read = sysread( $handle, my $chunk, READ_SIZE );
			if ( !$read ) {
				$select->remove($handle);
				next;
			}
			$buffer_of->{$handle} .= $chunk;
		}
		return scalar @ready;
	}

	sub _read_json ($file) {
		open my $handle, '<:raw', $file or croak "Term::Fabulous::Screenshot::Runner: cannot read $file: $!";
		my $json = do { local $/; <$handle> };
		close $handle;
		return JSON::PP->new->utf8->decode($json);
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Screenshot::Runner - Run a program in a pseudo terminal
and capture its screen

=head1 SYNOPSIS

	use Term::Fabulous::Screenshot::Runner;

	my $screen = Term::Fabulous::Screenshot::Runner->new->capture(
		script  => 'examples/form.pl',
		columns => 80,
		rows    => 24,
		epoch   => 1780306860,
		steps   => [ { action => 'wait', seconds => 0.5 } ],
	);

=head1 DESCRIPTION

Maintainer tool, not installed. Starts a Perl program in a new pseudo
terminal of a fixed size, as a separate process, with
L<Term::Fabulous::Screenshot::Harness> loaded first, and returns the
screen as a L<Term::Fabulous::Screenshot::Screen>.

The program runs in an empty temporary directory, with a fixed
environment: C<TERM=xterm-256color>, C<COLORTERM=truecolor>,
C<LC_ALL=C.UTF-8>, C<TZ=UTC>, a fixed hash seed, and only C<PATH> and
C<HOME> taken over. Together with the virtual clock, this makes every
run produce the same screen.

=over

=item *

A program that runs an event loop (every L<Term::Fabulous> program) is
captured by the harness after its steps: the screen is what the
terminal showed at that moment.

=item *

A program that prints and ends (a report printed with
L<Term::Fabulous::Static>) is captured from its output, as a terminal
would show it.

=back

The runner also plays the part of the terminal where a program asks it
something, as a terminal that shows sixel graphics in cells of 10 x 20
pixels:

=over

=item *

it answers the cursor position query C<ESC [ 6 n> that
L<Term::Fabulous/INLINE MODE> sends, so inline programs can be
captured. The cursor starts on the row below the C<shell> lines (see
L</capture>) and follows the absolute cursor moves
(C<ESC [ row ; column H>) in the program's output;

=item *

it answers the primary device attributes query C<ESC [ c> with
C<ESC [ ? 62 ; 4 ; 22 c> (attribute 4 is sixel) and the cell size query
C<ESC [ 16 t> with C<ESC [ 6 ; 20 ; 10 t>, and the terminal's window
size has the pixel size of its cells too, so
L<Term::Fabulous::Widget::Sixel> shows its pictures.

=back

Other questions (such as the kitty keyboard protocol query) get no
answer, as from a terminal that does not know them.

The capture dies when the program writes anything to STDERR (warnings
included), ends with a non-zero exit status, ends before the screenshot
was taken, runs longer than the timeout, or prints output that is not
plain text with colors. A program that runs too long, and one whose
capture is interrupted by SIGINT, SIGTERM or SIGHUP, is killed together
with the processes it started.

=head1 CONSTRUCTOR

=head2 new

=over

=item C<include_dirs>

The library directories the program is run with (as C<-I> options).
Default: the directories in C<@INC>. They must include the one that
holds the harness.

=item C<timeout>

Real seconds a program may run. Default: 120.

=back

=head1 METHODS

=head2 capture

	my $screen = $runner->capture(%job);

=over

=item C<script>

The program to run.

=item C<arguments>

An array reference of arguments for the program. Optional.

=item C<columns>, C<rows>

The size of the terminal.

=item C<epoch>

The start time of the virtual clock, in epoch seconds.

=item C<shell>

An array reference of lines a shell printed before the program started.
Optional. The cursor starts at the beginning of the row below them (on
the last row when they fill the terminal), and the harness shows them
above the program's inline region; see
L<Term::Fabulous::Screenshot::Scenario/Settings>.

=item C<steps>

The steps for the harness: C<{ action =E<gt> 'wait', seconds =E<gt> N }>
and C<{ action =E<gt> 'send', bytes =E<gt> HEX }>; see
L<Term::Fabulous::Screenshot::Harness/CONFIGURATION>.

=back

=cut
