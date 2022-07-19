package Net::LibNFS::DirEnt;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Net::LibNFS::DirEnt - NFS directory entry

=head1 SYNOPSIS

=head1 DESCRIPTION

This class represents a directory node.

See L<Net::LibNFS::Dirhandle> for how to create instances.

=head1 ACCESSORS

As per F<libnfs.h>:

=over

=item * C<name>

=item * C<inode>

=item * C<size>

=item * C<type>

=item * C<mode>

=item * C<uid>

=item * C<gid>

=item * C<nlink>

=item * C<dev>

=item * C<rdev>

=item * C<blksize>

=item * C<blocks>

=item * C<used>

=item * C<atime>

=item * C<mtime>

=item * C<ntime>

=item * C<atime_nsec>

=item * C<mtime_nsec>

=item * C<ntime_nsec>

=item * C<next> - The next directory entity, or undef.

=back

=cut

1;
