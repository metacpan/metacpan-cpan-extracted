#!/usr/bin/perl

=head1 NAME

Net::TCP::PtyServer - Serves pseudo-terminals. Opens a listening
connection on a port, waits for network connections on that port, and
serves each one in a seperate PTY.

=begin maintenance

This is based on example code from both IO::Pty and
Net::TCP::Server.

Lots of head-scratching has gone into getting this to work; it seems
okay to mebut your mileage may vary. I've tried to comment it where I
understand what it's doing, but networking code always seems to look
just like someone's hit random keys on the keyboard. Feedback from
anyone who understands this peoperly would be most welcome
(pause@rjlee.dyndns.org).

=end maintenance

=head1 HACKING

=head2 ALGORITHM

The actual algorithm is simple, although the implementation looks a
bit ickey.

=over

=item 1 Create a listening socket

=item 2 Wait for the next connection on the socket (by calling B<accept>).

=item 3 Fork.

=over

=item 3.1 Parent process closes its copy of the handle (by calling
B<stopio>) then goes back to B<1>.

=item 3.2 In the child process, we create a pseudo-TTY and fork

=over

=item 3.2.1 The child process runs the command by re-opening STDOUT,
STDERR and STDIN to the pseudo-TTY's slave terminal and then calling
B<exec>; this does not return

This is necessary because the filehandles need to be exactly the same,
and we get buffering/crashing issues if we try an open3()

=item 3.2.2 The parent process closes its copy of the pseudo-TTY's
slave terminal (using B<close>).

=item 3.2.3 The parent then repeatedly pipes the data between the
pseudo-TTY and the networked filehandle until the exec()ed process
completes.

=item 3.2.4 The parent process then closes the pseudo-TTY (by implicit
destruction) and the networked filehandle (by B<close>), and exits.

=back

=back

=back

=head2 Coping with terminal size changes

To set the size of a terminal, you need to call ioctl(), and pass the
pseudo-TTY handle, the constant TIOCSWINSZ (defined in termio.h or
termios.h - or on my system, defined in the asm includes and imported
by one of them), and a winsize{} C-structure.

The TIOCGWINSZ (G instead of S) can also be used to get the size of a
terminal. This is used to generate the structure passed to ioctl in
the case of the pseudo-TTY running on a real terminal; see this code
from IOS::TTY (referenced by IOS::PTY):

   sub clone_winsize_from {
     my ($self, $fh) = @_;
     my $winsize = "";
     croak "Given filehandle is not a tty in clone_winsize_from, called"
       if not POSIX::isatty($fh);  
     return 1 if not POSIX::isatty($self);  # ignored for master ptys
     ioctl($fh, &IO::Tty::Constant::TIOCGWINSZ, $winsize)
       and ioctl($self, &IO::Tty::Constant::TIOCSWINSZ, $winsize)
         and return 1;
     warn "clone_winsize_from: error: $!" if $^W;
     return undef;
   }

The structrure of winsize is defined in termios.h as follows:

   struct winsize {
           unsigned short ws_row;
           unsigned short ws_col;
           unsigned short ws_xpixel;
           unsigned short ws_ypixel;
   };

And the Internet tells me that ws_row is the number of rows, ws_col
the number of columns, ws_xpixel the number of horizontal pixels
across the terminal, and ws_ypixel the number of vertical pixels
across the terminal.

After a little experiementing, this seems to work to create the
struct, although it should be noted that this assumes that the struct
has the same memory alignment as an array of unsigned shorts:

    my $winsize = pack("S*",$ws_row,$ws_col,$ws_xpixel,$ws_ypixel);

So that's what I'm trying to use (thus saving an XS C function)

=cut

=head1 BUGS

The module still has to handle the TELNET protocol properly. In
particular, the remapping of IAC and handling of TELNET escapes.

For now, we just send the command to turn off echo and linemode, which
otherwise interferes with the UI (we also ignore the response, but
this seems to have no ill effects so far).

Control characters (ctrl+q, ctrl+x) are coming in as 0x11 (17) and
0x18 (24); these seem to need translating into \C and the keycode for
some reason; the translation is not being picked up through the
pseudo-TTY. (For now I'll just use character codes in the code that
uses this; they seem simpler to me anyway).

When the TCP connection is dropped, we don't currently SIGHUP. We may
be able to do this by close()ing the master terminal, but it's
probably better to send an explicit HUP signal as well.

=cut

package Net::TCP::PtyServer;

our $VERSION = 1.0;

use IO::Pty;
use Net::TCP::Server;
require POSIX;

use Time::HiRes qw(usleep);

#use constant DOLOG => 0;	# Log network traffic (bytes and diagnostics)

use constant TIMEOUT => undef;#36600	# Idle Timeout (undef means forever)

# To find the best number here, test the response speed of multiple
# users connecting simultaneously, and watch the CPU load. Bigger
# numbers mean a faster response time for a single user, while lower
# numbers mean less CPU load and (in the limit) a faster response when
# multiple users are logged in.
use constant NSLEEP => 200;	# number of loops to go through before
				# sleeping

# Niceness priority. 20 seems to be the best way of stopping the
# process from swamping the CPU without causing serious latency (SuSE
# Linux 2.6.5-7.201-default). 20 is nicest (lowest scheduling
# priority), 0 means don't renice (normal scheduling priority)
use constant RENICE => 20;

=head1 METHODS

# Don't make zombies when we don't wait for forks (see perlipc):
$SIG{CHLD} = 'IGNORE';

=head2 setTerminalSize

Used internally in response to an incoming NAWS command

Takes the terminal as the first argument, followed by the number of
rows, then the number of columns. The number of horizontal and
vertical pixels can also be specified, but the default is to assume an
8x8 pixel character.

=cut

sub setTerminalSize {
  my $term = shift;
  my ($ws_row,$ws_col,$ws_xpixel,$ws_ypixel) = @_;
  $ws_xpixel = $ws_col * 8 unless $ws_xpixel;
  $ws_ypixel = $ws_col * 8 unless $ws_ypixel;
  my $winsize = pack("S*",$ws_row,$ws_col,$ws_xpixel,$ws_ypixel);
  return ioctl($term, &IO::Tty::Constant::TIOCSWINSZ, $winsize);
}

=head2 run

Takes a port number as the first argument, followed by a command and
its arguments.

Listens for connections on the given port. B<exec()>s the given
command on a pseudo-terminal on the given port in a child process for
each connection.

Does not return (but it could die if something really goes wrong)

=cut

sub run {
  my $port = shift;
  my @command = @_;

  $^W = 1;

  my $pid;

  # Create a listening socket
  my $socket;
  until ($socket) {		# wait for port
    $socket = Net::TCP::Server->new($port);
    sleep(1) unless $socket;
  }

  # Accept connections on each socket and process in children
  while (my $fh = $socket->accept) {
    my $ppid = fork;
    die "Cannot fork" if not defined $ppid;

    if ($ppid) {
      $fh->stopio;
    } else {
      # Create a new PTY:
      my $pty = new IO::Pty;

      # open a pair of connected pipes to get status from child to parent:
      pipe(STAT_RDR, STAT_WTR)
	or die "Cannot open pipe: $!";

      ## Allow buffering; it has no noticable effect on response times:
      #autoflush the write handle
      STAT_WTR->autoflush(1);

      # The child for the pseudoTTY
      $pid = fork();

      die "Cannot fork" if not defined $pid;
      unless ($pid) {
	# Child process, connect stdio to the slave of the psTTY and execute
	# command
	close STAT_RDR;
	$pty->make_slave_controlling_terminal();
	my $slave = $pty->slave();
	close $pty;
	#  $slave->clone_winsize_from(\*STDIN);
	setTerminalSize($slave,24,80);
	$slave->set_raw();

	open(STDIN,"<&". $slave->fileno())
	  or die "Couldn't reopen STDIN for reading, $!\n";
	open(STDOUT,">&". $slave->fileno())
	  or die "Couldn't reopen STDOUT for writing, $!\n";
	#	open(STDERR,">&". $slave->fileno())
	open STDERR, ">>log.stderr"
	  or die "Couldn't reopen STDERR for writing, $!\n";

	# Log stuff:
	print STDERR ('*'x20)."\n";
	print STDERR "$0 @ARGV [".gmtime()."]\n";

	close $slave;


	my $telneg = "";
	# Let's *try* to turn echo off on the remote side:
	$telneg .= chr(255).chr(254).chr(1); # IAC DONT ECHO
	$telneg .= chr(255).chr(251).chr(1); # IAC WILL ECHO
	# Also, we can't handle the GA signal:
	$telneg .= chr(255).chr(253).chr(3); # IAC DO SUPPRESS-GA
	$telneg .= chr(255).chr(251).chr(3); # IAC WILL SUPPRESS-GA
	# Try to turn off LINEMODE negotiation:
	$telneg .= chr(255).chr(254).chr(34); # IAC DONT LINEMODE
	$telneg .= chr(255).chr(252).chr(34); # IAC WONT LINEMODE
	# Ask for Negotiate About Window Size from the client:
	$telneg .= chr(255).chr(253).chr(31); # IAC DO NAWS

	syswrite($fh,$telneg);

	# Decrement network port's I/O count:
	$fh->stopio;

	eval {
	  exec(@command);
	};

	# An error occurred (exec only returns on error); tell the
	# parent process for pTTY:
	print STAT_WTR $!+0;
	die "Cannot exec(@command): $!";
      }

      # Parent process for pTTY:

      close STAT_WTR;		# we only want to read from the pipe
      $pty->close_slave();	# close the clone of the pTTY's slave

      # Raw mode:
      # - characters typed are passed through immediately
      # - control characters (interrupt, quit, etc.) passed without signal
      $pty->set_raw();

      # now wait for child exec (eof due to close-on-exit) or exec error
      my $errstatus = sysread(STAT_RDR, $errno, 256);
      die "Cannot sync with child: $!" if not defined $errstatus;
      close STAT_RDR;
      if ($errstatus) {
	$! = $errno+0;
	die "Cannot exec(@command): $!";
      }

#      POSIX::nice(RENICE);

      # Pump data around:
      _parent($pty,$fh,$pid);
      $fh->stopio;		# All I/O is done; stop I/O
      exit(0);
    }

  }
}

# Read a character
sub _readChar {
  my $src = shift;
  my $buf = shift;
  my $rtn = 0;
  do {
    $rtn = sysread($src,$$buf,1);
    die "HUP" if $rtn && $rtn == 0;
    vec($rin, fileno($src), 1) = 0 unless $rtn;
  } until ($rtn);
  return $rtn;
}

# Process I/O
sub _process {
  my ($rin,$src,$dst,$pid,$toPTY) = @_;
  my $buf = '';
  my $read = sysread($src, $buf, 1);
  die "HUP" unless $read;

  if ($toPTY) {
    # Filter standard input to cope with TELNET sequences

    if ($buf eq "\015") {
      $read = _readChar($src,\$buf);
      if ($buf eq "\012") {
#	print LOG " - CR for CRLF - discarding CR" if DOLOG;
      } else {
	$buf = "\015" . $buf;
	$read = 2;
      }
    }

    if ($buf eq chr(255)) {
#      print LOG " - TELNET SEQUENCE ON stdin\n" if DOLOG;
      $read = _readChar($src,\$buf);
      if ($buf eq chr(255)) {
#	print LOG " - IAC IAC => IAC" if DOLOG;
      } elsif ($buf eq chr(254) || $buf eq chr(253) || $buf eq chr(252) || $buf eq chr(251)) {
#	print LOG " - IAC WILL|WONT|DO|DONT - safely ignored\n" if DOLOG;
	_readChar($src,\$buf);
	return $rin;
      } elsif ($buf eq chr(250)) {
	_readChar($src,\$buf);
	if ($buf eq chr(31)) {
#	  print LOG " - IAC SB NAWS - reading terminal size\n" if DOLOG;
	  my ($w0,$w1,$h0,$h1);
	  _readChar($src,\$buf);
	  _readChar($src,\$buf) if $buf eq chr(255);
	  $w0 = ord($buf);
	  _readChar($src,\$buf);
	  _readChar($src,\$buf) if $buf eq chr(255);
	  $w1 = ord($buf);
	  _readChar($src,\$buf);
	  _readChar($src,\$buf) if $buf eq chr(255);
	  $h0 = ord($buf);
	  _readChar($src,\$buf);
	  _readChar($src,\$buf) if $buf eq chr(255);
	  $h1 = ord($buf);
	  my $w = ($w0 << 8) | $w1;
	  my $h = ($h0 << 8) | $h1;
	  do {
	    _readChar($src,\$buf);
	  } until $buf eq chr(240); # Discard the SE, junk out else
#	  print LOG " -- new terminal size cols=$w, rows=$h\n" if DOLOG;
	  setTerminalSize($dst,$h,$w);
	  kill WINCH => $pid if $pid;
	  return $rin;
	} else {
#	  print LOG " - IAC SB ".ord($buf)." - ignoring until SE\n" if DOLOG;
	  while ($buf ne chr(240)) {
	    _readChar($src,\$buf);
	  }
	}
	return $rin;
      } elsif ($buf eq chr(246)) {
	# AYT
	#	} elsif ($buf eq chr(245)) {
	#	  print LOG " - IAC AO - aborting output by sending SIGHUP\n" if DOLOG;
	#	  # AO, Abort Output
	#	  kill HUP => $pid, $$;
	#	  $dst->close;
	#	  return $rin;
      } elsif ($buf eq chr(244)) {
	# Interrupt Process
      } elsif ($buf eq chr(241)) {
#	print LOG " - IAC NOP - doing nothing\n" if DOLOG;
	return $rin;
      }
    }
  }

  # Write output buffer from child to parent:
  syswrite($dst,$buf,$read);
  #    syswrite(LOG,$buf,$read) if DOLOG;
#  print LOG "RIN: <$rin>; DST: <".ref($dst).">; BUFFER: <$buf>\n" if DOLOG;

  return $rin;
}

# Pump data from pseudo-terminal to network pipe:
sub _parent {
#   if (DOLOG) {
#     open(LOG,">log") || die;
#     # safely unbuffer LOG then revert to old selected filehandle:
#     my $f = select(LOG);
#     $| = 1;
#     select($f);
#   }
  my $tty = shift;
  my $fh = shift;
  my $pid = shift;
  my ($rin,$win,$ein) = ('','','');
  vec($rin, fileno($fh), 1) = 1;
  vec($rin, fileno($tty), 1) = 1;
  vec($win, fileno($tty), 1) = 1;
  vec($ein, fileno($tty), 1) = 1;
  # Do not unbuffer the filehandles as it seems to have no
  # noticable effect
  select($tty); # unbuffer $tty
  $| = 1;
  select($fh); # unbuffer $fh
  $| = 1;
  eval {
    while (1) {
      my ($rout,$wout,$eout);
      # Wait for $fh or $tty to have a non-blocking read or $tty to
      # have a non-blocking write to stdout or stderr; $nfound will be
      # the number of flags set in $rin and $win to indicate
      # non-blocking read/write status:
      $nfound = select($rout=$rin,$wout=$win,undef#$eout=$ein
		       ,TIMEOUT);

      die "select failed:$!" if ($nfound < 0);
      if ($nfound > 0) {
	#if (vec($eout, fileno($tty), 1)) {
	  #       print STDERR "Exception on $tty\n";
        #}
	if (vec($rout, fileno($tty), 1)) {
	  # input from net to PTY
	  $rin = _process($rin,$tty,$fh,$pid,0);
	  last unless (vec($rin, fileno($tty), 1)); # exit on close TTY
	} elsif (vec($rout, fileno($fh), 1) && vec($wout, fileno($tty), 1)) {
	  # output from PTY to net
	  $rin = _process($rin,$fh,$tty,$pid,1);
	} else {
	  # No I/O is waiting.

	  # Explicitly yield the thread to try and reduce load

	  # I've tried various combinations of POSIX::yield,
	  # usleep(0/1/10/100) and sleep(0), but this permitation seems
	  # best
	  usleep(0);
	}
      }
    }
  };
  if ($@ && $@ =~ /HUP/) {
    # terminal has gone away; kill the child with a HUP
#    print LOG "SENDING HUP ($!)" if DOLOG;
    kill HUP => $pid;
  } elsif ($@) {
    die;
  }
#  close(LOG) if DOLOG;
}

1;
