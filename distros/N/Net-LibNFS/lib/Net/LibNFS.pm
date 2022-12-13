package Net::LibNFS;

use strict;
use warnings;

our $VERSION = '0.05';

=encoding utf-8

=head1 NAME

Net::LibNFS - User-land NFS in Perl via L<libnfs|https://github.com/sahlberg/libnfs>

=head1 SYNOPSIS

Create an NFS context and configure it:

    my $nfs = Net::LibNFS->new()->set(
        version => 4,
        client_name => 'my-nfs-client-name',
    );

Blocking I/O:

    # Connect to the NFS server:
    #
    $nfs->mount('some.server.name', '/the-mount-path');

    # Open a directory:
    #
    my $dh = $nfs->opendir('path/to/dir');

    # Print the names of directory members.
    #
    while (my $dir_obj = $dh->read()) {   # NB: read() returns an object!
        print "Name: ", $dir_obj->name(), $/;
    }

    $nfs->umount();

Non-blocking I/O, using L<IO::Async>:

    my $loop = IO::Async::Loop->new();

    my $nfsa = $nfs->io_async($loop);

    $nfsa->mount('some.server.name', '/the-mount-path')->then( sub {
         return $nfsa->opendir('path/to/dir');
    } )->then( sub ($dh) {
        while (my $dir_obj = $dh->read()) {
            print "Name: ", $dir_obj->name(), $/;
        }
    } )->then( sub {
        $nfsa->umount();
    } )->finally( sub { $loop->stop() } );

    $loop->run();

(L<AnyEvent> and L<Mojolicious> are also supported.)

=head1 DESCRIPTION

L<libnfs|https://github.com/sahlberg/libnfs> allows you to access NFS
shares in user-space. Thus you can read & write files via NFS even if you
can’t (or just would rather not) L<mount(8)> them locally.

=head1 LINKING

If a shared libnfs is available and is version 5.0.0 or later we’ll
link (dynamically) against that.
Otherwise we try to compile our own libnfs and bundle it (statically).

A shared libnfs is usually preferable because it can receive updates on its
own; a static libnfs locks you into that version of the library until you
rebuild Net::LibNFS.

If you have a usable shared libnfs but for some reason still want
to bundle a custom-built static one, set C<NET_LIBNFS_LINK_STATIC> to a
truthy value in the environment as you run this distribution’s
F<Makefile.PL>.

=head1 CHARACTER ENCODING

All strings for Net::LibNFS are byte strings. Take care to decode/encode
appropriately, and be sure to test with non-ASCII text (like C<thîß>).

Of note:
L<NFSv4’s official specification|https://datatracker.ietf.org/doc/html/rfc7530>
stipulates that filesystem paths should be valid UTF-8, which suggests that
this library might express paths as character strings rather than byte strings.
(This assumedly facilitates better interoperability with Windows and other
OSes whose filesystems are conceptually Unicode.)
In practice, however, some NFS servers appear not to care about UTF-8
validity. In that light, and for consistency with general POSIX practice,
we stick to byte strings.

Nonetheless, for best results, ensure all filesystem paths are valid UTF-8.

=cut

#----------------------------------------------------------------------

use XSLoader;

use Net::LibNFS::Async;

XSLoader::load( __PACKAGE__, $VERSION );

#----------------------------------------------------------------------

=head1 STATIC FUNCTIONS

=head2 @exports = mount_getexports( $SERVERNAME [, $TIMEOUT] )

Returns a list of hashrefs. Each hashref has C<dir> (string) and
C<groups> (array of strings).

=head2 @addresses = find_local_servers()

Returns a list of addresses (as strings).

=cut

#----------------------------------------------------------------------

=head1 METHODS: GENERAL

=head2 $obj = I<CLASS>->new()

Instantiates this class.

=head2 $obj = I<OBJ>->set( @OPTS_KV )

A setter for multiple settings; e.g., where libnfs exposes
C<nfs_set_version()>, here you pass C<version> with the appropriate
value.

Recognized options are as follows. (Some may be unavailable if you
use an older, shared libnfs.)

=over

=item * C<version>

=item * C<client_name> and C<verifier> (NFSv4 only)

=item * C<tcp_syncnt>, C<uid>, C<gid>, C<debug>, C<auto_traverse_mounts>,
C<dircache>, C<autoreconnect>, C<timeout>, C<nfsport>, C<mountport>

=item * C<unix_authn> (arrayref) - Sets UID, GID, and auxiliary GIDs
at once. Clobbers (and is clobbered by) C<uid> and C<gid>.

=item * C<pagecache>, C<pagecache_ttl>, C<readahead>

=item * C<readmax>, C<writemax>

=item * C<readdir_buffer> - Sets the maximum buffer size for C<READDIRPLUS>
(which is used by I<OBJ>->opendir). Can be a two-element arrayref to set
C<dircount> and C<maxcount> independently or an unsigned integer to set both
to the same value.

=back

=head2 $old_umask = I<OBJ>->umask( $NEW_UMASK )

Like Perl’s built-in.

=head2 $cwd = I<OBJ>->getcwd()

Returns I<OBJ>’s current directory.

=head1 METHODS: NON-BLOCKING I/O

This library implements non-blocking I/O by deriving a separate NFS
context object from the “plain” (blocking-I/O) one.

The following methods all return a L<Net::LibNFS::Async> instance:

=cut

#----------------------------------------------------------------------

=head2 $ASYNC_OBJ = I<OBJ>->io_async( $LOOP )

$LOOP is an L<IO::Async::Loop> instance.

=cut

sub io_async {
    my ($self, $loop) = @_;

    return $self->_create_async('Net::LibNFS::IO::IOAsync', $loop);
}

=head2 $ASYNC_OBJ = I<OBJ>->anyevent()

Unlike C<io_async()>, this doesn’t require a loop object because
L<AnyEvent>’s context is a singleton.

=cut

sub anyevent {
    my ($self) = @_;

    return $self->_create_async('Net::LibNFS::IO::AnyEvent');
}

=head2 $ASYNC_OBJ = I<OBJ>->mojo( [$REACTOR] )

$REACTOR (a L<Mojo::Reactor> instance) is optional;
the default is Mojo’s default reactor.

=cut

sub mojo {
    my ($self, $reactor) = @_;

    return $self->_create_async('Net::LibNFS::IO::Mojo', $reactor);
}

sub _create_async {
    my ($self, $io_class, @io_args) = @_;

    local ($@, $!);
    require Net::LibNFS::Async;

    return Net::LibNFS::Async->_new($self, $io_class, @io_args);
}

#----------------------------------------------------------------------

=head1 METHODS: GETTERS

=over

=item * C<queue_length()>

=item * C<get_readmax()>, C<get_writemax()>

=item * C<get_version()> (i.e., the active NFS version)

=item * C<getcwd()>

=back

=head1 CONSTANTS

=over

=item * C<NFS4_F_SETLK>, C<NFS4_F_SETLKW>, C<F_RDLCK>, C<F_WRLCK>, &
C<F_UNLCK> - See L<Net::LibNFS::Filehandle>’s C<fcntl()>.

=back

=head1 METHODS: BLOCKING I/O

=head2 $obj = I<OBJ>->mount( $SERVERNAME, $EXPORTNAME )

Attempts to contact $SERVERNAME and set I<OBJ> to access $EXPORTNAME.

Returns I<OBJ>.

=head2 $obj = I<OBJ>->umount()

Releases the current NFS connection.

Returns I<OBJ>.

=head2 $stat_obj = I<OBJ>->stat( $PATH )

Like Perl’s C<stat()> but returns a L<Net::LibNFS::Stat> instance.

=head2 $stat_obj = I<OBJ>->lstat( $PATH )

Like C<stat()> above but won’t follow symbolic links.

=head2 $nfs_fh = I<OBJ>->open( $PATH, $FLAGS [, $MODE] )

Opens a file and returns a L<Net::LibNFS::Filehandle> instance to
interact with it.

=head2 $obj = I<OBJ>->mkdir( $PATH [, $MODE] )

Creates a directory.

Returns I<OBJ>.

=head2 $obj = I<OBJ>->rmdir( $PATH )

Deletes a directory.

Returns I<OBJ>.

=head2 $obj = I<OBJ>->chdir( $PATH )

Changes I<OBJ>’s directory.

Returns I<OBJ>.

=head2 $obj = I<OBJ>->mknod( $PATH, $MODE, $DEV )

Like L<mknod(2)>.

Returns I<OBJ>.

=head2 $obj = I<OBJ>->unlink( $PATH )

Deletes a file.

Returns I<OBJ>.

=head2 $nfs_dh = I<OBJ>->opendir( $PATH )

Opens a directory and returns a L<Net::LibNFS::Dirhandle> instance to
read from it.

=head2 $statvfs_obj = I<OBJ>->statvfs( $PATH )

Like L<statvfs(2)>. Returns a L<Net::LibNFS::StatVFS> instance.

=head2 $destination = I<OBJ>->readlink( $PATH )

Reads a symlink directly.

=head2 $obj = I<OBJ>->chmod( $PATH, $MODE )

Sets a path’s mode.

Returns I<OBJ>.

=head2 $obj = I<OBJ>->lchmod( $PATH, $MODE )

Like C<chmod()> above but won’t follow symbolic links.

Returns I<OBJ>.

=head2 $obj = I<OBJ>->chown( $PATH, $UID, $GID )

Sets a path’s ownership.

Returns I<OBJ>.

=head2 $obj = I<OBJ>->utime( $PATH, $ATIME, $MTIME )

Updates $PATH’s atime & mtime. A time can be specified as either:

=over

=item * A nonnegative number (not necessarily an integer).

=item * A reference to a 2-member array of nonnegative integers:
seconds and microseconds.

=back

Returns I<OBJ>.

=head2 $obj = I<OBJ>->lutime( $PATH, $ATIME, $MTIME )

Like C<utime()> above but can operate on symlinks.

Returns I<OBJ>.

=head2 $obj = I<OBJ>->lchown( $PATH, $MODE )

Like C<chown()> above but won’t follow symbolic links.

Returns I<OBJ>.

=head2 $obj = I<OBJ>->link( $OLDPATH, $NEWPATH )

Creates a hard link.

Returns I<OBJ>.

=head2 $obj = I<OBJ>->symlink( $OLDPATH, $NEWPATH )

Creates a symbolic link.

Returns I<OBJ>.

=head2 $obj = I<OBJ>->rename( $OLDPATH, $NEWPATH )

Renames a filesystem path.

Returns I<OBJ>.

=head1 UNIMPLEMENTED

The following libnfs features are unimplemented here:

=over

=item * Authentication: Would be nice!

=item * URL parsing: Seems redundant with L<URI>.

=item * C<creat()> & C<create()>: These are redundant with C<open()>.

=item * C<access()> & C<access2()>: Merely knowing whether a given
file/directory is accessible isn’t as useful as it may seem because
by the time you actually I<use> the resource the permissions/ownership
could have changed. To prevent that race condition it’s better just to
C<open()>/C<opendir()> and handle errors accordingly.

=item * C<lockf()>: Apparently redundant with C<fcntl()>-based locks save
for the lock-test functionality, which is generally a misstep for the same
reason as C<access()> above: by the time you use the resource—in this case,
request a lock on the file—the system state may have changed.

=back

=head1 SEE ALSO

L<RFC 7530|https://datatracker.ietf.org/doc/html/rfc7530> is, as of this
writing, NFSv4’s official definition.

=head1 LICENSE & COPYRIGHT

Copyright 2022 Gasper Software Consulting. All rights reserved.

Net::LibNFS is licensed under the same terms as Perl itself (cf.
L<perlartistic>); B<HOWEVER>, since Net::LibNFS links to libnfs, use of
Net::LibNFS I<may> imply acceptance of libnfs’s own copyright terms.
See F<libnfs/COPYING> in this distribution for details.

=cut

1;
