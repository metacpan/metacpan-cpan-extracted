package Net::LibNFS::Filehandle;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Net::LibNFS::Filehandle - NFS filehandle (blocking I/O)

=head1 SYNOPSIS

=head1 DESCRIPTION

This class represents a libnfs filehandle and exposes a synchronous/blocking
interface for interacting with that filehandle.

See L<Net::LibNFS> for how to create instances.

See L<Net::LibNFS::Filehandle::Async> for the async filehandle interface.

=head1 CLEANUP

When Perl garbage-collects a filehandle, it closes the underlying file
descriptor. This is a nice convenience that ideally we could do here, too.
Whereas C<close()> on a normal filehandle doesn’t block, though, the
same operation on an NFS filehandle I<does> block.

For that reason, this class B<DOES> B<NOT> B<CLEAN> B<UP> B<FILEHANDLES>
B<FOR> B<YOU>. If you neglect to C<close()> an NFS filehandle, it’ll stay
open until the NFS context itself (i.e., the L<Net::LibNFS> instance)
goes away.

=head1 METHODS

=head2 I<OBJ>->close()

Closes a filehandle. See L</CLEANUP> for why it’s important to call
this explicitly.

=head2 $buffer = I<OBJ>->read( $MAXSIZE )

Tries to read up to $MAXSIZE bytes, and returns the buffer of bytes
actually read.

=head2 $buffer = I<OBJ>->pread( $OFFSET, $MAXSIZE )

Like C<read()> above, but reads from a given $OFFSET and doesn’t alter
the file pointer’s position.

=head2 $bytecount = I<OBJ>->write( $BUFFER )

Tries to write $BUFFER.

Returns the number of bytes actually written.

=head2 $bytecount = I<OBJ>->pwrite( $OFFSET, $BUFFER )

Analogous to C<pread()> above. Tries to write $BUFFER at $OFFSET.

Returns the number of bytes actually written.

=head2 $cur_offset = I<OBJ>->seek( $OFFSET, $WHENCE )

Seeks the filehandle to $OFFSET from $WHENCE (L<Fcntl>’s C<SEEK_*>
constants).

=head2 $obj = I<OBJ>->fcntl( $COMMAND, @ARGS )

Like L<fcntl(2)>. @ARGS depends on $COMMAND. Returns I<OBJ>.

Currently recognized $COMMAND values are constants from L<Net::LibNFS>:

=over

=item * C<NFS4_F_SETLK> and C<NFS4_F_SETLKW> - @ARGS are:

=over

=item * a type (L<Net::LibNFS>’s C<*LCK> constants)

=item * “whence” (same as for C<seek()> above)

=item * OPTIONAL: the lock’s byte offset from “whence” (default is 0)

=item * OPTIONAL: the lock’s length (default is 0, which means
“until the file’s end”)

=back

=back

=head2 $stat = I<OBJ>->stat()

Like L<fstat(2)>. Returns a L<Net::LibNFS::Stat> instance.

=head2 $obj = I<OBJ>->sync()

Like L<fsync(2)>. Returns I<OBJ>.

=head2 $obj = I<OBJ>->truncate( $LENGTH )

Like L<ftruncate(2)>. Returns I<OBJ>.

=head2 $obj = I<OBJ>->chmod( $MODE )

Like L<fchmod(2)>. Returns I<OBJ>.

=head2 $obj = I<OBJ>->chown( $UID, $GID )

Like L<fchown(2)>. Returns I<OBJ>.

=cut

1;
