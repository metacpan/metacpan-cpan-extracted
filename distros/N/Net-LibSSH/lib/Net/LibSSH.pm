# ABSTRACT: Perl binding for libssh — SSH without SFTP dependency

package Net::LibSSH;

use strict;
use warnings;

our $VERSION = '0.002';

use XSLoader;
XSLoader::load('Net::LibSSH', $VERSION);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::LibSSH - Perl binding for libssh — SSH without SFTP dependency

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use Net::LibSSH;

  my $ssh = Net::LibSSH->new;
  $ssh->option(host => 'server.example.com');
  $ssh->option(user => 'root');
  $ssh->option(port => 22);

  $ssh->connect or die "connect failed: " . $ssh->error;
  $ssh->auth_agent or die "auth failed: " . $ssh->error;

  my $ch = $ssh->channel;
  $ch->exec("uname -r");
  my $out = $ch->read;
  print "Kernel: $out";
  print "Exit: ", $ch->exit_status, "\n";

  # Optional SFTP (returns undef if SFTP subsystem not available)
  if (my $sftp = $ssh->sftp) {
    my $attr = $sftp->stat('/etc/hostname');
    print "size: $attr->{size}\n" if $attr;
  }

=head1 DESCRIPTION

L<Net::LibSSH> is a Perl XS binding for L<libssh|https://www.libssh.org/>.

Unlike L<Net::SSH2> (which wraps libssh2) and L<Net::OpenSSH> (which wraps
the system C<ssh> binary), this module links directly against B<libssh> — a
separate, actively maintained C library. The key difference for automation
use cases: file operations via L<Net::LibSSH::Channel> use SSH exec channels
and require no SFTP subsystem on the remote host.

SFTP is supported as an optional feature via L</sftp>: it returns C<undef>
gracefully when the remote server has no SFTP subsystem, rather than
crashing.

B<Note:> This module is not thread-safe and does not support fork. Use one
connection per process.

=head1 METHODS

=head2 new

  my $ssh = Net::LibSSH->new;

Creates a new session object.

=head2 option($key, $value)

  $ssh->option(host => 'server.example.com');
  $ssh->option(port => 22);
  $ssh->option(user => 'root');

Set a session option before connecting. Supported keys: C<host>, C<port>,
C<user>, C<knownhosts>, C<timeout>, C<compression>, C<log_verbosity>,
C<strict_hostkeycheck> (set to 0 to disable host key verification).

=head2 connect

  $ssh->connect or die $ssh->error;

Connect to the host. Returns 1 on success, 0 on failure.

=head2 disconnect

  $ssh->disconnect;

Disconnect and free the underlying connection.

=head2 error

  my $msg = $ssh->error;

Return the last error message from libssh.

=head2 auth_password($password)

  $ssh->auth_password('s3cr3t') or die $ssh->error;

=head2 auth_publickey($privkey_path)

  $ssh->auth_publickey('/root/.ssh/id_ed25519') or die $ssh->error;

=head2 auth_agent

  $ssh->auth_agent or die $ssh->error;

Authenticate via the SSH agent, falling back to default key files if the
agent is not available.

=head2 channel

  my $ch = $ssh->channel;

Open a new session channel. Returns a L<Net::LibSSH::Channel> object or
C<undef> on failure.

=head2 sftp

  my $sftp = $ssh->sftp;  # returns undef if SFTP not available

Open an SFTP session. Returns a L<Net::LibSSH::SFTP> object, or C<undef>
if the remote server does not support SFTP. Never throws.

=head1 SEE ALSO

L<Net::LibSSH::Channel>, L<Net::LibSSH::SFTP>,
L<Alien::libssh>, L<Net::SSH2>

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
