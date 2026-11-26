# ABSTRACT: SSH exec channel for Net::LibSSH

package Net::LibSSH::Channel;
our $VERSION = '0.005';
use strict;
use warnings;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::LibSSH::Channel - SSH exec channel for Net::LibSSH

=head1 VERSION

version 0.005

=head1 SYNOPSIS

  my $ch = $ssh->channel;

  $ch->exec('uname -r') or die "exec failed";
  my $out = $ch->read;
  print "kernel: $out";
  print "exit: ", $ch->exit_status, "\n";
  $ch->close;

=head1 DESCRIPTION

L<Net::LibSSH::Channel> represents an open SSH session channel. Instances
are created via L<Net::LibSSH/channel> and must not be constructed directly.

A channel keeps its session alive on its own: it holds its own reference to
the session object it was opened on, so letting the C<$ssh> variable it
came from go out of scope, assigning C<undef> to it, or reassigning it to
something else does not invalidate the channel. That guarantee is about the
Perl variable, not about the session's connection — it does not protect a
channel from C<< $ssh->disconnect >>; see below.

Calling C<< $ssh->disconnect >> on the originating session invalidates
every channel already opened on it — libssh frees them as part of
disconnecting. From that point every channel method but C<close> croaks
with C<"Net::LibSSH::Channel::E<lt>methodE<gt>: session was disconnected">,
a message distinct from C<"channel is closed"> so a caller can tell its own
teardown from libssh's. A channel that was closed with C<close> I<before>
its session disconnected keeps reporting C<"channel is closed">
afterwards — whichever happened to the channel first is what it reports.
Calling C<close> on a channel invalidated by disconnect is a harmless
no-op, not an error, and so is simply dropping the channel (letting it go
out of scope, or assigning C<undef> to it) — teardown that has already
happened is not a failure.

A channel runs one command per lifetime; an interactive shell
(L</"request_pty([$cols, $rows [, $term]])">, L</request_shell>) counts as that one command. After C<exec> completes you can
read stdout and stderr independently, then retrieve the exit status. Call
C<close> (or let the object go out of scope) to free the underlying libssh
channel. C<close> is idempotent; every I<other> channel method croaks once
the channel has been closed, with C<"Net::LibSSH::Channel::E<lt>methodE<gt>:
channel is closed">.

=head1 METHODS

=head2 exec($command)

  $ch->exec('uname -r') or die "exec failed";

Execute a command on the remote host. Returns 1 on success, 0 on failure.
Must be called exactly once per channel.

Croaks if the channel has already been closed (see L</close>), or if its
session has been disconnected (see L<Net::LibSSH/disconnect>).

=head2 read([$length [, $is_stderr]])

  my $stdout = $ch->read;         # slurp all stdout until EOF
  my $chunk  = $ch->read(4096);   # read up to 4096 bytes from stdout
  my $stderr = $ch->read(-1, 1);  # slurp all stderr

Read output from the channel. Without arguments (or with C<-1> length),
reads until the remote side closes the stream. With a positive C<$length>,
reads at most that many bytes. Pass a true C<$is_stderr> as the second
argument to read from stderr instead of stdout.

B<Note:> Do not pass C<undef> as the length — it evaluates to 0 and reads
nothing. Use C<-1> or omit the argument entirely to slurp all output.
Nothing is consumed from the channel by a zero-length read, so the data is
not lost — a later C<read> call still returns it in full.

B<Note:> C<read> has no way to tell a clean end-of-stream apart from a read
error. Both end the same underlying loop and come back as a (possibly
empty) string; C<read> never returns C<undef> and never croaks over a read
failure itself.

Returns a string (possibly empty). Croaks if the channel has already been
closed (see L</close>), or if its session has been disconnected (see
L<Net::LibSSH/disconnect>).

=head2 request_pty([$cols, $rows [, $term]])

  $ch->request_pty or die "no pty";               # xterm, 80x24
  $ch->request_pty(132, 50, 'vt100') or die "no pty";

Ask the server for a pseudo-terminal on this channel; call it before
L</request_shell>. Without arguments the terminal is C<xterm>, 80 columns
by 24 rows (libssh's own default). C<$cols> and C<$rows> go together and
must be integers from 1 to 65535; C<$term> defaults to C<xterm> and must
not be empty. Returns 1 on success, 0 if the server refuses.

Unlike the numeric options of L<Net::LibSSH/option>, bad arguments are not
silently turned into 0: a lone size, a zero or non-numeric size, or an
empty C<$term> croaks.

Croaks if the channel has already been closed (see L</close>), or if its
session has been disconnected (see L<Net::LibSSH/disconnect>).

=head2 request_shell

  $ch->request_shell or die "no shell";

Start the user's interactive shell on the channel, in place of L</"exec($command)">.
Returns 1 on success, 0 on failure. A shell is the channel's one command,
like an C<exec>: a channel runs one command or one shell in its lifetime,
and a second request on it is the server's to refuse. Talk to the shell
with L</"write($data)"> and L</"read_timeout($seconds [, $length [, $is_stderr]])">; L</"read([$length [, $is_stderr]])"> would block until the shell
ends. A device that runs its own dialog needs
L<Net::LibSSH/auth_none> first.

  $ssh->auth_none or die $ssh->error;
  my $ch = $ssh->channel;
  $ch->request_pty and $ch->request_shell or die "no shell";
  my $prompt = $ch->read_timeout(5);     # "User Name:"
  $ch->write("admin\r");

Croaks if the channel has already been closed (see L</close>), or if its
session has been disconnected (see L<Net::LibSSH/disconnect>).

=head2 read_timeout($seconds [, $length [, $is_stderr]])

  my $data = $ch->read_timeout(2);
  if    (!defined $data) { print "the remote side is done\n" }
  elsif ($data eq '')    { print "nothing yet\n" }
  else                   { print "got: $data" }

Wait up to C<$seconds> (a number, fractions allowed) for output and return
as soon as some has arrived, at most C<$length> bytes of it (default 4096;
must be at least 1). A true C<$is_stderr> reads stderr instead of stdout.
C<0> does not wait: it takes what has already arrived, once.

The three outcomes are told apart, which L</"read([$length [, $is_stderr]])"> cannot do:

=over 4

=item a non-empty string

Data. Call again for more.

=item the empty string

Nothing arrived within C<$seconds>; the channel is still open and may yet
produce output.

=item C<undef>

End of file: the remote side closed or sent EOF and everything it sent has
been read. Every further call returns C<undef> at once.

=back

A failing connection (the peer vanished, a protocol error) croaks with
libssh's message, so it cannot be mistaken for either an empty timeout or
the end of the stream. A negative or non-numeric C<$seconds>, or a
C<$length> below 1, croaks too; a negative timeout would otherwise mean
"wait forever" to libssh.

This is also the non-blocking read: C<< read_timeout(0) >>. The timeout is
in seconds like the C<timeout> option, whereas libssh counts milliseconds.

Croaks if the channel has already been closed (see L</close>), or if its
session has been disconnected (see L<Net::LibSSH/disconnect>).

=head2 write($data)

  my $n = $ch->write("input\n");

Write C<$data> to the channel's standard input. Returns the number of
bytes written, or a negative value on error. On a shell channel this is
what you type.

Croaks if the channel has already been closed (see L</close>), or if its
session has been disconnected (see L<Net::LibSSH/disconnect>).

=head2 send_eof

  $ch->send_eof;

Signal end-of-input to the remote command. Call this after all C<write>
calls so that commands reading stdin (e.g. C<cat>) know to terminate.

Croaks if the channel has already been closed (see L</close>), or if its
session has been disconnected (see L<Net::LibSSH/disconnect>).

=head2 eof

  $ch->send_eof;
  my $out = $ch->read;
  $ch->eof and print "channel closed by remote\n";

Returns true when the remote side has sent EOF on its stdout.

Croaks if the channel has already been closed (see L</close>), or if its
session has been disconnected (see L<Net::LibSSH/disconnect>).

=head2 exit_status

  my $rc = $ch->exit_status;

Returns the exit status of the executed command, or C<-1> when there is no
exit code to report. It does not poll and return at once: the call waits for
the remote side to report the exit status, and returns C<-1> only if that
does not happen. The supported order is to read all output first.

C<-1> has two causes, and the return value alone does not tell them apart:

=over 4

=item the process has not exited yet

The session C<timeout> option (see
L<< option|Net::LibSSH/"option($key, $value)" >>) ran out before the exit
status arrived. Without that option this module sets no timeout of its own,
so nothing bounds the wait; set one if a stuck remote command must not hold
the caller. With C<< timeout => 1 >>, a call made while the command is still
running returns C<-1> after about that second, and the C<-1> does not stick:
asking again once the process has exited returns its real code.

=item the process was killed by a signal

A command that dies from a signal (C<kill -9 $$>) never reports an exit
status, so there is no code to return and the answer is C<-1>. Waiting longer
does not turn it into a code, so a loop that retries on C<-1> needs an upper
bound of its own.

=back

Calling C<exit_status> before draining the output still returns the correct
exit code in the test suite, and does not discard what has not been read yet:
a later C<read> returns it in full, for a few bytes as for 300000. That is
observed behaviour, not a guarantee, and a libssh that blocked here would
hang instead of returning; keep reading output before checking
C<exit_status> as the supported order.

Croaks if the channel has already been closed (see L</close>), or if its
session has been disconnected (see L<Net::LibSSH/disconnect>). Note that
C<exit_status> must be read I<before> C<close> and before
C<< $ssh->disconnect >>, not after either: once the channel is closed, or
its session has disconnected, this croaks instead of returning the exit
code.

=head2 close

  $ch->close;

Close the channel and free the underlying libssh resources (send EOF, close,
free). Also called automatically when the object is garbage-collected.

C<close> is idempotent — calling it again on an already-closed channel is a
no-op, not an error. Every other channel method croaks once the channel is
closed, with C<"Net::LibSSH::Channel::E<lt>methodE<gt>: channel is
closed">.

C<close> is also a no-op, not an error, on a channel invalidated by
C<< $ssh->disconnect >> — see L<Net::LibSSH/disconnect>. It never croaks
with C<"session was disconnected">; that message is reserved for the other
methods.

=head1 SEE ALSO

L<Net::LibSSH>, L<Net::LibSSH::SFTP>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/p5-net-libssh/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
