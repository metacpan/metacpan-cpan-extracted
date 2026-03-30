# ABSTRACT: Optional SFTP session for Net::LibSSH

package Net::LibSSH::SFTP;
our $VERSION = '0.002';
use strict;
use warnings;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::LibSSH::SFTP - Optional SFTP session for Net::LibSSH

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  if (my $sftp = $ssh->sftp) {
      my $attr = $sftp->stat('/etc/hostname');
      printf "size=%d mode=%04o\n", $attr->{size}, $attr->{mode} & 07777
          if $attr;
  }

=head1 DESCRIPTION

L<Net::LibSSH::SFTP> wraps an SFTP session opened over an existing SSH
connection. Instances are created via L<Net::LibSSH/sftp>.

If the remote server has no SFTP subsystem, L<Net::LibSSH/sftp> returns
C<undef> instead of throwing — callers should always check the return value
before using the object.

=head1 METHODS

=head2 stat($path)

  my $attr = $sftp->stat('/etc/hostname');
  if ($attr) {
      printf "size=%d  uid=%d  mode=%04o\n",
          $attr->{size}, $attr->{uid}, $attr->{mode} & 07777;
  }

Returns a hashref describing the remote path, or C<undef> if the path does
not exist or cannot be accessed.

Hashref keys:

=over 4

=item C<name>

The filename component of the path (or the full path if the server did not
return a name).

=item C<size>

File size in bytes.

=item C<uid>, C<gid>

Numeric user and group IDs.

=item C<mode>

Full Unix mode word (type bits + permission bits). Use C<$attr->{mode} & 07777>
to extract just the permission bits.

=item C<atime>, C<mtime>

Access and modification times as Unix epoch seconds. Uses 64-bit timestamps
when available (libssh >= 0.9).

=back

=head1 SEE ALSO

L<Net::LibSSH>, L<Net::LibSSH::Channel>

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
