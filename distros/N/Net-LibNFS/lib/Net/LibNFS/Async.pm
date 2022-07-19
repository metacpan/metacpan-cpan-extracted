package Net::LibNFS::Async;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Net::LibNFS::Async - Non-blocking I/O for L<Net::LibNFS>

=head1 SYNOPSIS

After creating C<$nfs_async> from a L<Net::LibNFS> instance …

    $nfs->mount("the.nfs.server", "/export-dir")->then(
        sub {
            return $nfs->stat("/");
        },
    )->then(
        sub ($stat) {
            printf "mode(/) = 0%03o\n", $stat->mode() & 0777;
            return $nfs->open('/some-file', Fcntl::O_RDONLY);
        },
    )->then(
        sub ($fh) {
            return $fh->read(120)->then(
                sub ($buf) {
                    print $buf;
                    return $fh->close();
                },
            );
        },
    )->then(
        sub {
            return $nfs->umount();
        }
    )

=head1 DESCRIPTION

This module exposes non-blocking counterparts to L<Net::LibNFS>’s blocking
I/O calls.

Its methods return promises. (Mozilla publishes
L<a nice introduction to promises|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Using_promises>
that may be of help if you’re unfamiliar with that pattern.)

=cut

#----------------------------------------------------------------------

use parent 'Net::LibNFS::LeakDetector';

#----------------------------------------------------------------------

# Constructor is only for use within Net::LibNFS.
#
sub _new {
    my ($class, $nfs, $io_class, @io_args) = @_;

    die 'Need Net::LibNFS instance' if !$nfs;

    if (!$io_class->can('store_deferred')) {
        local $@;
        die if !eval "require $io_class";
    }

    return bless {
        nfs => $nfs,
        io => $io_class->new($nfs, @io_args),
        pid => $$,
    }, $class;
}

#----------------------------------------------------------------------

=head1 NFS METHODS

The below all accept the same arguments as their equivalents in
L<Net::LibNFS>.

=head2 promise() = I<OBJ>->mount( $SERVERNAME, $EXPORTNAME )

Promise resolves empty.

=cut

sub mount {
    my ($self, $servername, $exportname) = @_;

    die "Mount already pending: $self->{'mount_pending'}" if $self->{'mount_pending'};
    my $pending_sr = \$self->{'mount_pending'};

    return $self->_async_act(
        '_async_mount',
        $servername, $exportname,
    )->finally(
        sub { undef $$pending_sr },
    );
}

=head2 promise() = I<OBJ>->umount()

Promise resolves empty.

=cut

sub umount {
    my ($self) = @_;

    return $self->_async_act( '_async_umount' );
}

=head2 promise($stat) = I<OBJ>->stat( $PATH )

Promise resolves to a L<Net::LibNFS::Stat> instance.

=cut

sub stat {
    my ($self, $path) = @_;

    return $self->_async_act( _async_stat => $path );
}

=head2 promise($stat) = I<OBJ>->lstat( $PATH )

Promise resolves to a L<Net::LibNFS::Stat> instance.

=cut

sub lstat {
    my ($self, $path) = @_;

    return $self->_async_act( _async_lstat => $path );
}

=head2 promise($fh) = I<OBJ>->open( $PATH, $FLAGS [, $MODE] )

Promise resolves to a L<Net::LibNFS::Async::Filehandle> instance.

=cut

sub open {
    my ($self, @args) = @_;

    require Net::LibNFS::Async::Filehandle;

    my $io = $self->{'io'};

    return $self->_async_act( _async_open => @args[0 .. 2] )->then(
        sub {
            my ($nfsfh) = @_;
            return Net::LibNFS::Async::Filehandle->_new($nfsfh, $io);
        },
    );
}

=head2 promise() = I<OBJ>->mkdir( $PATH [, $MODE] )

Promise resolves empty.

=cut

sub mkdir {
    my ($self, $path, $mode) = @_;

    return $self->_async_act( _async_mkdir => $path, $mode );
}

=head2 promise() = I<OBJ>->rmdir( $PATH )

Promise resolves empty.

=cut

sub rmdir {
    my ($self, $path) = @_;

    return $self->_async_act( _async_rmdir => $path );
}

=head2 promise() = I<OBJ>->chdir( $PATH )

Promise resolves empty.

=cut

sub chdir {
    my ($self, $path) = @_;

    return $self->_async_act( _async_chdir => $path );
}

=head2 promise() = I<OBJ>->unlink( $PATH )

Promise resolves empty.

=cut

sub unlink {
    my ($self, $path) = @_;

    return $self->_async_act( _async_unlink => $path );
}

=head2 promise($dh) = I<OBJ>->opendir( $PATH )

Promise resolves to a L<Net::LibNFS::Dirhandle> instance.

=cut

sub opendir {
    my ($self, $path) = @_;

    return $self->_async_act( _async_opendir => $path );
}

=head2 promise($statvfs) = I<OBJ>->statvfs( $PATH )

Promise resolves to a L<Net::LibNFS::StatVFS> instance.

=cut

sub statvfs {
    my ($self, $path) = @_;

    return $self->_async_act( _async_statvfs => $path );
}

=head2 promise() = I<OBJ>->mknod( $PATH, $MODE, $DEV )

Promise resolves empty.

=cut

sub mknod {
    my ($self, $path, $mode, $dev) = @_;

    return $self->_async_act( _async_mknod => $path, $mode, $dev );
}

=head2 promise() = I<OBJ>->chmod( $PATH, $MODE )

Promise resolves empty.

=cut

sub chmod {
    my ($self, $path, $mode) = @_;

    return $self->_async_act( _async_chmod => $path, $mode );
}

=head2 promise() = I<OBJ>->lchmod( $PATH, $MODE )

Promise resolves empty.

=cut

sub lchmod {
    my ($self, $path, $mode) = @_;

    return $self->_async_act( _async_lchmod => $path, $mode );
}

=head2 promise() = I<OBJ>->chown( $PATH, $UID, $GID )

Promise resolves empty.

=cut

sub chown {
    my ($self, $path, $uid, $gid) = @_;

    return $self->_async_act( _async_chown => $path, $uid, $gid );
}

=head2 promise() = I<OBJ>->lchown( $PATH, $UID, $GID )

Promise resolves empty.

=cut

sub lchown {
    my ($self, $path, $uid, $gid) = @_;

    return $self->_async_act( _async_lchown => $path, $uid, $gid );
}

=head2 promise() = I<OBJ>->utime( $PATH, $ATIME, $MTIME )

Promise resolves empty.

=cut

sub utime {
    my ($self, $path, $atime, $mtime) = @_;

    return $self->_async_act( _async_utime => $path, $atime, $mtime );
}

=head2 promise() = I<OBJ>->lutime( $PATH, $ATIME, $MTIME )

Promise resolves empty.

=cut

sub lutime {
    my ($self, $path, $atime, $mtime) = @_;

    return $self->_async_act( _async_lutime => $path, $atime, $mtime );
}

=head2 promise() = I<OBJ>->truncate( $PATH, $LENGTH )

Promise resolves empty.

=cut

sub truncate {
    my ($self, $path, $length) = @_;

    return $self->_async_act( _async_truncate => $path, $length );
}

#----------------------------------------------------------------------

=head1 OTHER METHODS

=head2 promise(\@exports) = I<OBJ>->mount_getexports( $SERVERNAME )

Promise resolves to an arrayref of hashrefs such as L<Net::LibNFS>’s
corresponding static function returns.

=cut

sub mount_getexports {
    my ($self, $server) = @_;

    my $rpc = Net::LibNFS::RPC->new();

    my $io = $self->{'io'}->clone($rpc);

    return $io->act($rpc, _async_mount_getexports => $server)->finally(
        sub { undef $io },
    );
}

=head2 $obj = I<OBJ>->pause()

Pauses all reads. (Writes still continue.)

Returns I<OBJ>.

=cut

sub pause {
    $_[0]{'io'}->pause();
    return $_[0];
}

=head2 $obj = I<OBJ>->resume()

The inverse of C<pause()>.

=cut

sub resume {
    $_[0]{'io'}->resume();
    return $_[0];
}

#----------------------------------------------------------------------

sub _async_act {
    my ($self, $funcname, @args) = @_;

    return $self->{'io'}->act( $self->{'nfs'}, $funcname, @args );
}

1;
