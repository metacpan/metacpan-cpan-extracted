package Net::LibNFS::Stat;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Net::LibNFS::Stat - NFS filesystem node

=head1 SYNOPSIS

=head1 DESCRIPTION

This class represents the result of an NFS L<stat(2)>-like operation.

See L<Net::LibNFS> for how to create instances.

=head1 ACCESSORS

As per F<libnfs.h>:

=over

=item * C<ino>

=item * C<mode>

=item * C<nlink>

=item * C<uid>

=item * C<gid>

=item * C<rdev>

=item * C<size>

=item * C<blksize>

=item * C<blocks>

=item * C<atime>

=item * C<mtime>

=item * C<ctime>

=item * C<atime_nsec>

=item * C<mtime_nsec>

=item * C<ctime_nsec>

=item * C<nfs_used>

=back

=cut

1;
