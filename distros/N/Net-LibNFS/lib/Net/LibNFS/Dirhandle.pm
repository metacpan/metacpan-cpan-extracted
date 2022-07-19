package Net::LibNFS::Dirhandle;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Net::LibNFS::Dirhandle - NFS directory handle

=head1 SYNOPSIS

=head1 DESCRIPTION

This class represents a libnfs directory handle. Its methods never block,
so this class suits both blocking and non-blocking I/O.

See L<Net::LibNFS> for how to create instances.

=head1 CLEANUP

Unlike with L<Net::LibNFS::Filehandle>, instances of this module
automatically clean up after themselves. Thus, C<close()> on instances
of this class is generally unnecessary.

=head1 METHODS

(NB: C<read()> is listed twice below: once for scalar context, and again
for list context.)

=head2 $dirent = I<OBJ>->read()

Returns a single L<Net::LibNFS::DirEnt> instance to represent a directory
entry.

=head2 @dirents = I<OBJ>->read()

Returns as many L<Net::LibNFS::DirEnt> instances as are needed to finish
reading the directory.

=head2 $loc = I<OBJ>->tell( )

Like L<telldir(3)>.

=head2 $obj = I<OBJ>->rewind()

Like L<rewinddir(3)>.

=cut

1;
