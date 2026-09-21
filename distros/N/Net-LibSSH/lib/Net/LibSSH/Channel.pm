# ABSTRACT: SSH exec channel for Net::LibSSH

package Net::LibSSH::Channel;
our $VERSION = '0.004';
use strict;
use warnings;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::LibSSH::Channel - SSH exec channel for Net::LibSSH

=head1 VERSION

version 0.004

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

A channel runs one command per lifetime. After C<exec> completes you can
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

=head2 write($data)

  my $n = $ch->write("input\n");

Write C<$data> to the channel's standard input. Returns the number of
bytes written, or a negative value on error.

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

Returns the exit status of the executed command. The supported order is to
read all output first; called before that, this returns C<-1> until the
remote process has exited.

Measured against libssh 0.10.6: C<ssh_channel_get_exit_status> pumps the
session's own packet loop while it waits, so calling C<exit_status> before
draining the output still returns the correct exit code there, and does not
discard what has not been read yet — a later C<read> still returns it in
full. That is behaviour of the libssh build under test, not a portable
guarantee; a build that blocks instead of pumping the loop would hang here
rather than return C<-1>. Keep reading output before checking
C<exit_status> as the supported order regardless.

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

Please report bugs and feature requests on GitHub at
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
