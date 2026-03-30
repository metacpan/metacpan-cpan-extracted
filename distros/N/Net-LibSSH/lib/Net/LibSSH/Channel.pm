# ABSTRACT: SSH exec channel for Net::LibSSH

package Net::LibSSH::Channel;
our $VERSION = '0.002';
use strict;
use warnings;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::LibSSH::Channel - SSH exec channel for Net::LibSSH

=head1 VERSION

version 0.002

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

A channel runs one command per lifetime. After C<exec> completes you can
read stdout and stderr independently, then retrieve the exit status. Call
C<close> (or let the object go out of scope) to free the underlying libssh
channel.

=head1 METHODS

=head2 exec($command)

  $ch->exec('uname -r') or die "exec failed";

Execute a command on the remote host. Returns 1 on success, 0 on failure.
Must be called exactly once per channel.

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

Returns a string (possibly empty). Never throws.

=head2 write($data)

  my $n = $ch->write("input\n");

Write C<$data> to the channel's standard input. Returns the number of
bytes written, or a negative value on error.

=head2 send_eof

  $ch->send_eof;

Signal end-of-input to the remote command. Call this after all C<write>
calls so that commands reading stdin (e.g. C<cat>) know to terminate.

=head2 eof

  $ch->send_eof;
  my $out = $ch->read;
  $ch->eof and print "channel closed by remote\n";

Returns true when the remote side has sent EOF on its stdout.

=head2 exit_status

  my $rc = $ch->exit_status;

Returns the exit status of the executed command. Call this after reading
all output; returns C<-1> until the remote process has exited.

=head2 close

  $ch->close;

Close the channel and free the underlying libssh resources (send EOF, close,
free). Also called automatically when the object is garbage-collected.

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

This software is copyright (c) 2025 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
