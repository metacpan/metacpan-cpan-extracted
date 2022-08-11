# NAME

Net::LibNFS - User-land NFS in Perl via [libnfs](https://github.com/sahlberg/libnfs)

# SYNOPSIS

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

    $nfs->unmount();

Non-blocking I/O, using [IO::Async](https://metacpan.org/pod/IO%3A%3AAsync):

    my $loop = IO::Async::Loop->new();

    my $nfsa = $nfs->io_async($loop);

    $nfsa->mount('some.server.name', '/the-mount-path')->then( sub {
         return $nfsa->opendir('path/to/dir');
    } )->then( sub ($dh) {
        while (my $dir_obj = $dh->read()) {
            print "Name: ", $dir_obj->name(), $/;
        }
    } )->then( sub {
        $nfsa->unmount();
    } )->finally( sub { $loop->stop() } );

    $loop->run();

([AnyEvent](https://metacpan.org/pod/AnyEvent) and [Mojolicious](https://metacpan.org/pod/Mojolicious) are also supported.)

# DESCRIPTION

[libnfs](https://github.com/sahlberg/libnfs) allows you to access NFS
shares in user-space. Thus you can read & write files via NFS even if you
can’t (or just would rather not) [mount(8)](http://man.he.net/man8/mount) them locally.

# LINKING

If a shared libnfs is available and is version 5.0.0 or later we’ll
link (dynamically) against that.
Otherwise we try to compile our own libnfs and bundle it (statically).

A shared libnfs is preferable because it can receive updates on its
own; a static libnfs locks you into that version of the library until you
rebuild Net::LibNFS.

If, though, you have a usable shared libnfs but for some reason still want
to bundle a custom-built static one, set `NET_LIBNFS_LINK_STATIC` to a
truthy value in the environment as you run this distribution’s
`Makefile.PL`.

# CHARACTER ENCODING

All strings for Net::LibNFS are byte strings. Take care to decode/encode
appropriately, and be sure to test with non-ASCII text (like `thîß`).

Of note:
[NFSv4’s official specification](https://datatracker.ietf.org/doc/html/rfc7530)
stipulates that filesystem paths should be valid UTF-8, which suggests that
this library might express paths as character strings rather than byte strings.
(This assumedly facilitates better interoperability with Windows and other
OSes whose filesystems are conceptually Unicode.)
In practice, however, some NFS servers appear not to care about UTF-8
validity. In that light, and for consistency with general POSIX practice,
we stick to byte strings.

Nonetheless, for best results, ensure all filesystem paths are valid UTF-8.

# STATIC FUNCTIONS

## @exports = mount\_getexports( $SERVERNAME \[, $TIMEOUT\] )

Returns a list of hashrefs. Each hashref has `dir` (string) and
`groups` (array of strings).

## @addresses = find\_local\_servers()

Returns a list of addresses (as strings).

# METHODS: GENERAL

## $obj = _CLASS_->new()

Instantiates this class.

## $obj = _OBJ_->set( @OPTS\_KV )

A setter for multiple settings; e.g., where libnfs exposes
`nfs_set_version()`, here you pass `version` with the appropriate
value.

Recognized options are:

- `version`
- `client_name` and `verifier` (NFSv4 only)
- `tcp_syncnt`, `uid`, `gid`, `debug`, `dircache`,
`autoreconnect`, `timeout`
- `unix_authn` (arrayref) - Sets UID, GID, and auxiliary GIDs
at once. Clobbers (and is clobbered by) `uid` and `gid`.
- `pagecache`, `pagecache_ttl`, `readahead`
- `readmax`, `writemax`

## $old\_umask = _OBJ_->umask( $NEW\_UMASK )

Like Perl’s built-in.

## $cwd = _OBJ_->getcwd()

Returns _OBJ_’s current directory.

# METHODS: NON-BLOCKING I/O

This library implements non-blocking I/O by deriving a separate NFS
context object from the “plain” (blocking-I/O) one.

The following methods all return a [Net::LibNFS::Async](https://metacpan.org/pod/Net%3A%3ALibNFS%3A%3AAsync) instance:

## $ASYNC\_OBJ = _OBJ_->io\_async( $LOOP )

$LOOP is an [IO::Async::Loop](https://metacpan.org/pod/IO%3A%3AAsync%3A%3ALoop) instance.

## $ASYNC\_OBJ = _OBJ_->anyevent()

Unlike `io_async()`, this doesn’t require a loop object because
[AnyEvent](https://metacpan.org/pod/AnyEvent)’s context is a singleton.

## $ASYNC\_OBJ = _OBJ_->mojo( \[$REACTOR\] )

$REACTOR (a [Mojo::Reactor](https://metacpan.org/pod/Mojo%3A%3AReactor) instance) is optional;
the default is Mojo’s default reactor.

# METHODS: GETTERS

- `queue_length()`
- `get_readmax()`, `get_writemax()`
- `get_version()` (i.e., the active NFS version)
- `getcwd()`

# CONSTANTS

- `NFS4_F_SETLK`, `NFS4_F_SETLKW`, `F_RDLCK`, `F_WRLCK`, &
`F_UNLCK` - See [Net::LibNFS::Filehandle](https://metacpan.org/pod/Net%3A%3ALibNFS%3A%3AFilehandle)’s `fcntl()`.

# METHODS: BLOCKING I/O

## $obj = _OBJ_->mount( $SERVERNAME, $EXPORTNAME )

Attempts to contact $SERVERNAME and set _OBJ_ to access $EXPORTNAME.

Returns _OBJ_.

## $obj = _OBJ_->umount()

Releases the current NFS connection.

Returns _OBJ_.

## $stat\_obj = _OBJ_->stat( $PATH )

Like Perl’s `stat()` but returns a [Net::LibNFS::Stat](https://metacpan.org/pod/Net%3A%3ALibNFS%3A%3AStat) instance.

## $stat\_obj = _OBJ_->lstat( $PATH )

Like `stat()` above but won’t follow symbolic links.

## $nfs\_fh = _OBJ_->open( $PATH, $FLAGS \[, $MODE\] )

Opens a file and returns a [Net::LibNFS::Filehandle](https://metacpan.org/pod/Net%3A%3ALibNFS%3A%3AFilehandle) instance to
interact with it.

## $obj = _OBJ_->mkdir( $PATH \[, $MODE\] )

Creates a directory.

Returns _OBJ_.

## $obj = _OBJ_->rmdir( $PATH )

Deletes a directory.

Returns _OBJ_.

## $obj = _OBJ_->chdir( $PATH )

Changes _OBJ_’s directory.

Returns _OBJ_.

## $obj = _OBJ_->mknod( $PATH, $MODE, $DEV )

Like [mknod(2)](http://man.he.net/man2/mknod).

Returns _OBJ_.

## $obj = _OBJ_->unlink( $PATH )

Deletes a file.

Returns _OBJ_.

## $nfs\_dh = _OBJ_->opendir( $PATH )

Opens a directory and returns a [Net::LibNFS::Dirhandle](https://metacpan.org/pod/Net%3A%3ALibNFS%3A%3ADirhandle) instance to
read from it.

## $statvfs\_obj = _OBJ_->statvfs( $PATH )

Like [statvfs(2)](http://man.he.net/man2/statvfs). Returns a [Net::LibNFS::StatVFS](https://metacpan.org/pod/Net%3A%3ALibNFS%3A%3AStatVFS) instance.

## $destination = _OBJ_->readlink( $PATH )

Reads a symlink directly.

## $obj = _OBJ_->chmod( $PATH, $MODE )

Sets a path’s mode.

Returns _OBJ_.

## $obj = _OBJ_->lchmod( $PATH, $MODE )

Like `chmod()` above but won’t follow symbolic links.

Returns _OBJ_.

## $obj = _OBJ_->chown( $PATH, $UID, $GID )

Sets a path’s ownership.

Returns _OBJ_.

## $obj = _OBJ_->utime( $PATH, $ATIME, $MTIME )

Updates $PATH’s atime & mtime. A time can be specified as either:

- A nonnegative number (not necessarily an integer).
- A reference to a 2-member array of nonnegative integers:
seconds and microseconds.

Returns _OBJ_.

## $obj = _OBJ_->lutime( $PATH, $ATIME, $MTIME )

Like `utime()` above but can operate on symlinks.

Returns _OBJ_.

## $obj = _OBJ_->lchown( $PATH, $MODE )

Like `chown()` above but won’t follow symbolic links.

Returns _OBJ_.

## $obj = _OBJ_->link( $OLDPATH, $NEWPATH )

Creates a hard link.

Returns _OBJ_.

## $obj = _OBJ_->symlink( $OLDPATH, $NEWPATH )

Creates a symbolic link.

Returns _OBJ_.

## $obj = _OBJ_->rename( $OLDPATH, $NEWPATH )

Renames a filesystem path.

Returns _OBJ_.

# UNIMPLEMENTED

The following libnfs features are unimplemented here:

- Authentication: Would be nice!
- URL parsing: Seems redundant with [URI](https://metacpan.org/pod/URI).
- `creat()` & `create()`: These are redundant with `open()`.
- `access()` & `access2()`: Merely knowing whether a given
file/directory is accessible isn’t as useful as it may seem because
by the time you actually _use_ the resource the permissions/ownership
could have changed. To prevent that race condition it’s better just to
`open()`/`opendir()` and handle errors accordingly.
- `lockf()`: Apparently redundant with `fcntl()`-based locks save
for the lock-test functionality, which is generally a misstep for the same
reason as `access()` above: by the time you use the resource—in this case,
request a lock on the file—the system state may have changed.

# SEE ALSO

[RFC 7530](https://datatracker.ietf.org/doc/html/rfc7530) is, as of this
writing, NFSv4’s official definition.

# LICENSE & COPYRIGHT

Copyright 2022 Gasper Software Consulting. All rights reserved.

Net::LibNFS is licensed under the same terms as Perl itself (cf.
[perlartistic](https://metacpan.org/pod/perlartistic)); **HOWEVER**, since Net::LibNFS links to libnfs, use of
Net::LibNFS _may_ imply acceptance of libnfs’s own copyright terms.
See `libnfs/COPYING` in this distribution for details.
