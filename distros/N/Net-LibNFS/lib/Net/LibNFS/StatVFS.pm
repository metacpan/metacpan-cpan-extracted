package Net::LibNFS::StatVFS;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Net::LibNFS::StatVFS - NFS filesystem stats

=head1 SYNOPSIS

=head1 DESCRIPTION

This class represents the result of an NFS L<statvfs(2)>-like operation.

See L<Net::LibNFS> for how to create instances.

=head1 ACCESSORS

As per F<libnfs.h>:

=over

=item * C<frsize>

=item * C<blocks>

=item * C<bfree>

=item * C<bavail>

=item * C<files>

=item * C<ffree>

=item * C<favail>

=item * C<fsid>

=item * C<flag>

=item * C<namemax>

=back

=cut

1;
