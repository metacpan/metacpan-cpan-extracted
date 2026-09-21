# ABSTRACT: Rex connection backend using Net::LibSSH (no SFTP required)

package Rex::LibSSH;
our $VERSION = '0.004';
use strict;
use warnings;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rex::LibSSH - Rex connection backend using Net::LibSSH (no SFTP required)

=head1 VERSION

version 0.004

=head1 SYNOPSIS

  # In your Rexfile
  use Rex -feature => ['1.4'];
  use Rex::LibSSH;

  set connection => 'LibSSH';

  task 'deploy', 'myserver', sub {
      my $kernel = run 'uname -r';
      say "kernel: $kernel";
  };

=head1 DESCRIPTION

L<Rex::LibSSH> provides Rex connection, exec, filesystem, and file interfaces
backed by L<Net::LibSSH> — the XS binding for libssh.

Unlike Rex's built-in C<SSH> and C<OpenSSH> connection types, this backend
performs all file operations (C<is_file>, C<stat>, C<ls>, C<upload>,
C<download>, etc.) over plain SSH exec channels. No SFTP subsystem is required
on the remote host.

This makes it suitable for minimal containers, embedded systems, and any host
where Rex would otherwise crash with:

  Can't call method "stat" on an undefined value

=head2 Activating

Set the connection type in your Rexfile before connecting:

  set connection => 'LibSSH';

Rex's interface dispatch will automatically load
L<Rex::Interface::Connection::LibSSH>,
L<Rex::Interface::Exec::LibSSH>,
L<Rex::Interface::Fs::LibSSH>, and
L<Rex::Interface::File::LibSSH>.

=head2 Authentication

Supports public key authentication:

  Rex::Config->set_private_key('/home/user/.ssh/id_ed25519');
  Rex::Config->set_public_key('/home/user/.ssh/id_ed25519.pub');

Or pass keys directly to C<Rex::connect>:

  Rex::connect(
      server      => '10.0.0.1',
      user        => 'root',
      private_key => '/path/to/key',
      public_key  => '/path/to/key.pub',
      auth_type   => 'key',
  );

=head2 Host key verification

The server's host key is verified against C<known_hosts> by default, exactly
like an interactive C<ssh> client but without the prompt: an unknown or
changed key makes the connection fail before any authentication is
attempted. Requires L<Net::LibSSH> 0.004 or later — earlier versions of
Rex::LibSSH never verified the host key regardless of what was passed
(CWE-322).

Precedence: a C<strict_hostkeycheck> option passed to C<Rex::connect> wins
(C<0> or C<1>); otherwise C<< Rex::Config->get_openssh_opt() >>'s
C<StrictHostKeyChecking> is consulted — C<no> or C<off> (case-insensitive)
turns verification off, anything else or unset leaves it on. C<< use Rex
-feature => ['disable_strict_host_key_checking'] >> sets exactly that
C<openssh_opt>, so the Rexfile-wide flag the C<OpenSSH> backend honours
works here too.

The C<known_hosts> file is, in order: the C<knownhosts> connect option, then
C<openssh_opt>'s C<UserKnownHostsFile>, then libssh's own default
(F<~/.ssh/known_hosts>). A host reached on a non-standard port needs the
C<[host]:port> form in C<known_hosts>. Nothing is ever written to
C<known_hosts> by this backend — add a host out of band first
(C<ssh-keyscan>), or turn verification off explicitly:

  # Rexfile-wide, same flag the OpenSSH backend honours
  use Rex -feature => ['1.4', 'disable_strict_host_key_checking'];

  # or per connection
  Rex::connect(
      server              => '10.0.0.1',
      strict_hostkeycheck => 0,
      knownhosts          => '/path/to/known_hosts',   # optional
  );

An unknown or changed key makes C<Rex::connect> die with C<"Connection error
or refused.">; inside a task Rex reports C<"Couldn't connect to
$server.">. The underlying reason from L<Net::LibSSH> (e.g. C<"host key is
not in known_hosts and strict_hostkeycheck is on">, or C<"host key has
changed from the known_hosts entry -- possible man-in-the-middle attack">)
is logged as a C<warn>-level line that also names the opt-out.

=head1 SEE ALSO

L<Net::LibSSH>, L<Rex::Interface::Connection::LibSSH>,
L<Rex::Interface::Fs::LibSSH>, L<Rex::Interface::File::LibSSH>,
L<Rex::Interface::Exec::LibSSH>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/rex-libssh/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
