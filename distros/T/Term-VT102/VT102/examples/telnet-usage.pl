#!/usr/bin/perl
#
# Example script showing how to use Term::VT102 with Net::Telnet. Telnets to
# localhost and dumps what Term::VT102 thinks should be on the screen. Or
# you can pass it a host and a port and it will telnet there instead.
#
# Note that this script doesn't pass the terminal size through to the remote
# end, so you might have to do "stty rows 24 cols 80" to make things work
# (the default is generally 80x24 anyway though).
#
# Logs all terminal output to STDERR if STDERR is redirected to a file.
#

use Net::Telnet qw(TELOPT_TTYPE);
use Term::VT102;
use IO::Handle;
use strict;

$| = 1;

my ($host, $port) = @ARGV;

$host = 'localhost' if (not defined $host);
$port = 23 if (not defined $port);

my $t = new Net::Telnet (
  'Host' => $host,
  'Port' => $port,
  'Errmode' => 'return',
  'Timeout' => 1,
  'Output_record_separator' => '',
);

die "failed to connect to $host:$port" if (not defined $t);

$t->option_callback (\&opt_callback);
$t->option_accept ('Do' => TELOPT_TTYPE);
$t->suboption_callback (\&subopt_callback);

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

# Set up the callback for OUTPUT; this callback function simply sends
# whatever the Term::VT102 module wants to send back to the terminal and
# sends it to Net::Telnet - see its definition below.
#
$vt->callback_set ('OUTPUT', \&vt_output, $t);

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

my ($telnetbuf, $io, $stdinbuf, $prevxy);

$io = new IO::Handle;
$io->fdopen (fileno(STDIN), 'r');
$io->blocking (0);

system 'stty raw -echo';

$prevxy = '';

while (1) {
	last if ($t->eof ());

	my ($rin, $win, $ein, $rout, $wout, $eout, $nr, $delay, $didout);

	($rin, $win, $ein) = ('', '', '');
	vec ($rin, fileno ($t), 1) = 1;
	vec ($rin, fileno ($io), 1) = 1;

	# If we have any changed rows on the screen still waiting to be
	# output, we only wait a short time for activity, otherwise we wait
	# a full second. This is so that batched-up screen updates get
	# processed in a timely fashion.
	#
	$delay = 1;
	$delay = 0.05 if ((scalar keys %$changedrows) > 0);

	select ($rout=$rin, $wout=$win, $eout=$ein, $delay);

	$telnetbuf = undef;

	if (vec ($rout, fileno ($t), 1)) {
		$telnetbuf = $t->get ('Timeout' => 1);
		if (defined $telnetbuf) {
			$vt->process ($telnetbuf);
			print STDERR $telnetbuf if (! -t STDERR);
		}
	}
	$telnetbuf = '' if (not defined $telnetbuf);

# Do your stuff here - use $vt->row_plaintext() to see what's on various
# rows of the screen, for instance, or before this main loop you could set
# up a ROWCHANGE callback which checks the changed row, or whatever.
#
# In this example, we just pass standard input to the telnet stream, we take
# the data coming back from Net::Telnet and pass it to the Term::VT102
# object, any changed rows of which we dump to the screen.

	# Read key presses from standard input and pass them to Net::Telnet.
	#
	$stdinbuf = '';
	if (vec ($rout, fileno ($io), 1)) {
		if (defined $io->sysread ($stdinbuf, 16)) {
			$t->print ($stdinbuf);
		}
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
}

$t->close ();
print "\e[24H\r\n";

system 'stty sane';


# Callback for "DO" handling - for Net::Telnet.
#
sub opt_callback {
	my ($obj,$opt,$is_remote,$is_enabled,$was_enabled,$buf_position) = @_;

	if ($opt == TELOPT_TTYPE and $is_enabled and !$is_remote) {
		#
		# Perhaps do something if we get TELOPT_TTYPE switched on?
		#
	}

	return 1;
}


# Callback for sub-option handling - for Net::Telnet.
#
sub subopt_callback {
	my ($obj, $opt, $parameters) = @_;
	my ($ors_old, $otm_old);

	# Respond to TELOPT_TTYPE with "I'm a VT100".
	#
	if ($opt == TELOPT_TTYPE) {
		$ors_old = $obj->output_record_separator ('');
		$otm_old = $obj->telnetmode (0);
		$obj->print (
		  "\xff\xfa",
		  pack ('CC', $opt, 0),
		  'vt100',
		  "\xff\xf0"
		);
		$obj->telnetmode ($otm_old);
		$obj->output_record_separator ($ors_old);
	} 

	return 1;
}


# Callback for OUTPUT events - for Term::VT102.
#
sub vt_output {
	my ($vtobject, $type, $arg1, $arg2, $private) = @_;

	if ($type eq 'OUTPUT') {
		$private->print ($arg1);
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
