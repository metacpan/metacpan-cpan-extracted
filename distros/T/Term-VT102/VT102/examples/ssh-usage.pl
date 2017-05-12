;#!/usr/bin/perl
#
# Example script showing how to use Term::VT102 with an SSH command. SSHs to
# localhost and runs a shell, and dumps what Term::VT102 thinks should be on
# the screen.
#
# Logs all terminal output to STDERR if STDERR is redirected to a file.
#

use Term::VT102;
use IO::Handle;
use POSIX ':sys_wait_h';
use IO::Pty;
use strict;

$| = 1;

my $cmd = 'ssh -v -t localhost';

# Create the terminal object.
#
my $vt = Term::VT102->new (
  'cols' => 80,
  'rows' => 24,
);

# Convert linefeeds to linefeed + carriage return.
#
$vt->option_set ('LFTOCRLF', 1);

# Make sure line wrapping is switched on.
#
$vt->option_set ('LINEWRAP', 1);

# Create a pty for the SSH command to run on.
#
my $pty = new IO::Pty;
my $tty_name = $pty->ttyname ();
if (not defined $tty_name) {
	die "Could not assign a pty";
}
$pty->autoflush ();

# Run the SSH command in a child process.
#
my $pid = fork;
if (not defined $pid) {
	die "Cannot fork: $!";
} elsif ($pid == 0) {
	#
	# Child process - set up stdin/out/err and run the command.
	#

	# Become process group leader.
	#
	if (not POSIX::setsid ()) {
		warn "Couldn't perform setsid: $!";
	}

	# Get details of the slave side of the pty.
	#
	my $tty = $pty->slave ();
	$tty_name = $tty->ttyname();

# Linux specific - commented out, we'll just use stty below.
#
#	# Set the window size - this may only work on Linux.
#	#
#	my $winsize = pack ('SSSS', $vt->rows, $vt->cols, 0, 0);
#	ioctl ($tty, &IO::Tty::Constant::TIOCSWINSZ, $winsize);

	# File descriptor shuffling - close the pty master, then close
	# stdin/out/err and reopen them to point to the pty slave.
	#
	close ($pty);
	close (STDIN);
	close (STDOUT);
	open (STDIN, "<&" . $tty->fileno ())
	|| die "Couldn't reopen " . $tty_name . " for reading: $!";
	open (STDOUT, ">&" . $tty->fileno())
	|| die "Couldn't reopen " . $tty_name . " for writing: $!";
	close (STDERR);
	open (STDERR, ">&" . $tty->fileno())
	|| die "Couldn't redirect STDERR: $!";

	# Set sane terminal parameters.
	#
	system 'stty sane';

	# Set the terminal size with stty.
	#
	system 'stty rows ' . $vt->rows;
	system 'stty cols ' . $vt->cols;

	# Finally, run the command, and die if we can't.
	#
	exec $cmd;
	die "Cannot exec '$cmd': $!";
}

my ($cmdbuf, $stdinbuf, $iot, $eof, $prevxy, $died);

# IO::Handle for standard input - unbuffered.
#
$iot = new IO::Handle;
$iot->fdopen (fileno(STDIN), 'r');

# Removed - from Perl 5.8.0, setvbuf isn't available by default.
# $iot->setvbuf (undef, _IONBF, 0);

# Set up the callback for OUTPUT; this callback function simply sends
# whatever the Term::VT102 module wants to send back to the terminal and
# sends it to the child process - see its definition below.
#
$vt->callback_set ('OUTPUT', \&vt_output, $pty);

# Set up a callback for row changes, so we can process updates and display
# them without having to redraw the whole screen every time. We catch CLEAR,
# SCROLL_UP, and SCROLL_DOWN with another function that triggers a
# whole-screen repaint. You could process SCROLL_UP and SCROLL_DOWN more
# elegantly, but this is just an example.
#
my $changedrows = {};
$vt->callback_set ('ROWCHANGE', \&vt_rowchange, $changedrows);
$vt->callback_set ('CLEAR', \&vt_changeall, $changedrows);
$vt->callback_set ('SCROLL_UP', \&vt_changeall, $changedrows);
$vt->callback_set ('SCROLL_DOWN', \&vt_changeall, $changedrows);

# Set stdin's terminal to raw mode so we can pass all keypresses straight
# through immediately.
#
system 'stty raw -echo';

$eof = 0;
$prevxy = '';
$died = 0;

while (not $eof) {
	my ($rin, $win, $ein, $rout, $wout, $eout, $nr, $didout);

	($rin, $win, $ein) = ('', '', '');
	vec ($rin, $pty->fileno, 1) = 1;
	vec ($rin, $iot->fileno, 1) = 1;

	select ($rout=$rin, $wout=$win, $eout=$ein, 1);

	# Read from the SSH command if there is anything coming in, and
	# pass any data on to the Term::VT102 object.
	#
	$cmdbuf = '';
	$nr = 0;
	if (vec ($rout, $pty->fileno, 1)) {
		$nr = $pty->sysread ($cmdbuf, 1024);
		$eof = 1 if ((defined $nr) && ($nr == 0));
		if ((defined $nr) && ($nr > 0)) {
			$vt->process ($cmdbuf);
			syswrite STDERR, $cmdbuf if (! -t STDERR);
		}
	}

	# End processing if we've gone 1 round after SSH died with no
	# output.
	#
	$eof = 1 if ($died && $cmdbuf eq '');

# Do your stuff here - use $vt->row_plaintext() to see what's on various
# rows of the screen, for instance, or before this main loop you could set
# up a ROWCHANGE callback which checks the changed row, or whatever.
#
# In this example, we just pass standard input to the SSH command, and we
# take the data coming back from SSH and pass it to the Term::VT102 object,
# and then we repeatedly dump the Term::VT102 screen.

	# Read key presses from standard input and pass them to the command
	# running in the child process.
	#
	$stdinbuf = '';
	if (vec ($rout, $iot->fileno, 1)) {
		$nr = $iot->sysread ($stdinbuf, 16);
		$eof = 1 if ((defined $nr) && ($nr == 0));
		$pty->syswrite ($stdinbuf, $nr) if ((defined $nr) && ($nr > 0));
	}

	# Dump what Term::VT102 thinks is on the screen. We only output rows
	# we know have changed, to avoid generating too much output.
	#
	$didout = 0;
	foreach my $row (sort keys %$changedrows) {
		printf "\e[%dH%s\r", $row, $vt->row_sgrtext ($row);
		delete $changedrows->{$row};
		$didout ++;
	}
	if (($didout > 0) || ($prevxy != ''.$vt->x.','.$vt->y)) {
		printf "\e[%d;%dH", $vt->y, ($vt->x > $vt->cols ? $vt->cols : $vt->x);
	}

	# Make sure the child process has not died.
	#
	$died = 1 if (waitpid ($pid, &WNOHANG) > 0);
}

print "\e[24H\r\n";
$pty->close;

# Reset the terminal parameters.
#
system 'stty sane';


# Callback for OUTPUT events - for Term::VT102.
#
sub vt_output {
	my ($vtobject, $type, $arg1, $arg2, $private) = @_;

	if ($type eq 'OUTPUT') {
		$pty->syswrite ($arg1, length $arg1);
	}
}


# Callback for ROWCHANGE events. This just sets a time value for the changed
# row using the private data as a hash reference - the time represents the
# earliest that row was changed since the last screen update.
#
sub vt_rowchange {
	my ($vtobject, $type, $arg1, $arg2, $private) = @_;
	$private->{$arg1} = time if (not exists $private->{$arg1});
}


# Callback to trigger a full-screen repaint.
#
sub vt_changeall {
	my ($vtobject, $type, $arg1, $arg2, $private) = @_;
	for (my $row = 1; $row <= $vtobject->rows; $row++) {
		$private->{$row} = 0;
	}
}

# EOF
