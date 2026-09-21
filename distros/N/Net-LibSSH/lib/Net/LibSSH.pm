# ABSTRACT: Perl binding for libssh — SSH without SFTP dependency

package Net::LibSSH;

use strict;
use warnings;

our $VERSION = '0.004';

use XSLoader;
XSLoader::load('Net::LibSSH', $VERSION);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::LibSSH - Perl binding for libssh — SSH without SFTP dependency

=head1 VERSION

version 0.004

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
use cases: what this module exposes are exec channels via
L<Net::LibSSH::Channel>, not a file transfer API. File operations are built
on top of those channels — as L<Rex::LibSSH> does — and therefore need no
SFTP subsystem on the remote host.

SFTP is supported as an optional feature via L</sftp>: it returns C<undef>
gracefully when the remote server has no SFTP subsystem, rather than
crashing.

By default, L</connect> verifies the server's host key against
C<knownhosts> the same way an interactive C<ssh> client would, and refuses
to connect — returning 0, not dying — when the key is unknown, has
changed, or cannot be verified. See L</connect> for the exact refusal
messages and L<< option()|/"option($key, $value)" >> for turning that off.

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
C<strict_hostkeycheck>.

C<strict_hostkeycheck> controls whether L</connect> verifies the server's
host key against C<knownhosts>, mirroring libssh's own default: leaving
it unset, or setting it to a true value, leaves verification on — the
secure default. Setting it to C<0> turns verification off entirely:
C<connect> then skips the known_hosts check altogether, so it will
connect through an unknown or a changed host key without complaint, and
without ever writing to C<knownhosts> either way. C<knownhosts> names the
file consulted; left unset, that is libssh's own default of
F<~/.ssh/known_hosts>.

Croaks if C<$key> is not one of the keys above, or if libssh rejects the
resulting value. C<$value> is not validated on this side of the boundary —
numeric options go through Perl's ordinary numeric conversion, so a
non-numeric string silently becomes C<0> — and whether that ends up
croaking is entirely libssh's call, not something you can rely on
uniformly. For example, C<< port => 'nonsense' >> croaks (libssh rejects
port C<0>), while C<< timeout => 'nonsense' >> or
C<< log_verbosity => 'nonsense' >> are silently accepted as C<0>. Do not
read the absence of a croak here as validation.

=head2 connect

  $ssh->connect or die $ssh->error;

Connect to the host. Returns 1 on success, 0 on failure, and never dies —
including when called on a session that has already been connected and
disconnected, see L</disconnect>.

When C<strict_hostkeycheck> is on (the default, see
L<< option()|/"option($key, $value)" >>), a successful TCP connection and
key exchange is not by itself enough: C<connect> then verifies the
server's host key against C<knownhosts> before reporting success, the
same check an interactive C<ssh> client makes before it would prompt to
trust a new key — except this module never prompts and never writes the
file, so it can only refuse. Only a
match against the key libssh already has on file for this host lets
C<connect> return 1. Every other outcome is a refusal: C<connect> returns
0, the reason is on L</error>, and the session is left exactly as spent
as if L</disconnect> had been called on it — a later C<connect> on it
returns 0 with C<"session was disconnected and cannot be reconnected">.
The refusal messages are:

=over 4

=item the host is not in C<knownhosts>

C<"host key is not in known_hosts and strict_hostkeycheck is on">

=item the host is known, but under a different key

C<"host key has changed from the known_hosts entry -- possible
man-in-the-middle attack">

=item the host is known, but under a different key type

C<"host key type differs from the known_hosts entry -- possible
man-in-the-middle attack">

=item C<knownhosts> exists but could not be read

C<"could not verify host key against known_hosts">

=back

There is no equivalent here of an interactive client's "yes, trust this
key" prompt: a host has to be added to C<knownhosts> out of band —
C<ssh-keyscan>, or letting an actual ssh client connect to it once —
before C<connect> will accept it, or verification has to be turned off
with C<< strict_hostkeycheck => 0 >>, see
L<< option()|/"option($key, $value)" >>. A host reachable on a
non-standard port needs the C<< [host]:port >> form in C<knownhosts>;
libssh looks the entry up under that form, not under the bare hostname.

With C<strict_hostkeycheck> off, none of the above runs: C<connect>
returns 1 on a successful key exchange regardless of what C<knownhosts>
says, or whether the host is in it at all.

=head2 disconnect

  $ssh->disconnect;

Disconnect from the host. Every L<Net::LibSSH::Channel> and
L<Net::LibSSH::SFTP> object already opened on this session is invalidated
by the same call — libssh frees the channels as part of disconnecting.
From that point on, every method on such an object but C<close> croaks
with C<"session was disconnected">, a message distinct from a channel's
own C<"channel is closed"> so a caller can tell its own teardown from this
one; see L<Net::LibSSH::Channel/close>. Closing such a channel, or simply
letting it or an SFTP object go out of scope, is safe and does nothing.

C<< $ssh->channel >> and C<< $ssh->sftp >> called on a session that has
already disconnected return C<undef> rather than croaking — the same
graceful-failure contract they already have for any other failure to open.

The session itself is not reusable once it has actually been connected and
then disconnected: calling L</connect> again on it returns C<0>
immediately, with C<error()> reporting
C<"session was disconnected and cannot be reconnected">. This module
refuses the call itself, without asking libssh — measured against libssh
0.10.6, C<ssh_connect()> on such a session does not fail fast, it sits out
the whole C<timeout> option and only then reports a misleading
C<"Timeout connecting to ...">. Treat C<disconnect>/C<connect> as one-way —
not a cycle you can repeat on the same session.

Calling C<disconnect> on a session that was never successfully connected
does not spend it: a later L</connect> on it still works normally. Only a
connect/disconnect pair is terminal, not the mere act of disconnecting.

=head2 error

  my $msg = $ssh->error;

Return the last error message from libssh, or C<undef> — not the empty
string — when libssh has nothing to report. A few messages are this
module's own rather than libssh's, and take precedence over whatever
libssh has to say: the spent-session refusal described in L</disconnect>,
and the host-key refusals L</connect> raises when C<strict_hostkeycheck>
rejects the server's key.

=head2 auth_password($password)

  $ssh->auth_password('s3cr3t') or die $ssh->error;

=head2 auth_publickey($privkey_path)

  $ssh->auth_publickey('/root/.ssh/id_ed25519') or die $ssh->error;

=head2 auth_agent

  $ssh->auth_agent or die $ssh->error;

Authenticate via the SSH agent, falling back to the default key files
(public-key auto-authentication) whenever the agent attempt does not
succeed — not only when no agent is running, but also when a reachable
agent's authentication is rejected. A true return therefore does not by
itself prove that the agent was used; it only means one of the two methods
succeeded.

=head2 channel

  my $ch = $ssh->channel;

Open a new session channel. Returns a L<Net::LibSSH::Channel> object, or
C<undef> on failure — including when called on a session that has already
disconnected, see L</disconnect>. The returned channel keeps this session
alive on its own; see L<Net::LibSSH::Channel> for what that guarantees and
what it does not.

=head2 sftp

  my $sftp = $ssh->sftp;  # returns undef if SFTP not available

Open an SFTP session. Returns a L<Net::LibSSH::SFTP> object, or C<undef>
if the remote server does not support SFTP. This is the documented way to
detect SFTP availability — C<sftp> never throws for that reason, on this
or any other failure to open the session, including being called on a
session that has already disconnected, see L</disconnect>. Like
L</channel>, the returned object keeps this session alive on its own.

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

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
