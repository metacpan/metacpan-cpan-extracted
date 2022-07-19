package Net::LibNFS::Async::Filehandle;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Net::LibNFS::Async::Filehandle - NFS filehandle (non-blocking I/O)

=head1 DESCRIPTION

This class implements methods that mirror their counterparts in
L<Net::LibNFS::Filehandle>. The methods return promises whose resolution
(or rejection) indicates the result of a given request on the filehandle.

=head1 CLEANUP

The same issue as affects L<Net::LibNFS::Filehandle> applies to this
class.

=cut

#----------------------------------------------------------------------

use parent 'Net::LibNFS::LeakDetector';

#----------------------------------------------------------------------

# Not called publicly:
sub _new {
    my ($class, $nfsfh, $io) = @_;

    return bless {
        nfsfh => $nfsfh,
        io => $io,
        pid => $$,
    }, $class;
}

#----------------------------------------------------------------------

=head1 METHODS

Unless otherwise noted, the following all take the same inputs as their
L<Net::LibNFS::Filehandle> counterparts, and they return a promise whose
resolution is:

=over

=item * If the L<Net::LibNFS::Filehandle> method returns the
L<Net::LibNFS::Filehandle> instance, the promise resolves empty.

=item * Otherwise, the promise resolves with whatever value the
L<Net::LibNFS::Filehandle> method returns.

=back

The methods are:

=over

=item * I<OBJ>->close()

=cut

sub close {
    my ($self) = @_;

    return $self->_io_act( '_async_close' );
}

=item * I<OBJ>->read( $SIZE )

=cut

sub read {
    my ($self, $size) = @_;

    return $self->_io_act( _async_read => $size );
}

=item * I<OBJ>->pread( $OFFSET, $SIZE )

=cut

sub pread {
    my ($self, $offset, $size) = @_;

    return $self->_io_act( _async_pread => $offset, $size );
}

=item * I<OBJ>->write( $BUFFER )

=cut

sub write {
    my ($self, $buf) = @_;

    return $self->_io_act( _async_write => $buf );
}

=item * I<OBJ>->pwrite( $OFFSET, $BUFFER )

=cut

sub pwrite {
    my ($self, $offset, $buf) = @_;

    return $self->_io_act( _async_pwrite => $offset, $buf );
}

=item * I<OBJ>->chmod( $MODE )

=cut

sub chmod {
    my ($self, $mode) = @_;

    return $self->_io_act( _async_chmod => $mode );
}

=item * I<OBJ>->chown( $UID, $GID )

=cut

sub chown {
    my ($self, $uid, $gid) = @_;

    return $self->_io_act( '_async_chown', $uid, $gid );
}

=item * I<OBJ>->stat()

=cut

sub stat {
    my ($self) = @_;

    return $self->_io_act( '_async_stat' );
}

=item * I<OBJ>->fcntl( $CMD, @ARGS )

(NB: Even if $CMD == NFS4_F_SETLK, the returned promise won’t resolve until
we receive the NFS server’s response.)

=cut

sub fcntl {
    my ($self, @args) = @_;

    return $self->_io_act( '_async_fcntl', @args );
}

=item * I<OBJ>->seek()

=cut

sub seek {
    my ($self, $offset, $whence) = @_;

    return $self->_io_act( '_async_seek', $offset, $whence );
}

=item * I<OBJ>->sync()

=cut

sub sync {
    my ($self) = @_;

    return $self->_io_act( '_async_sync' );
}

=item * I<OBJ>->truncate( $LENGTH )

=cut

sub truncate {
    my ($self, $len) = @_;

    return $self->_io_act( _async_truncate => $len );
}

#----------------------------------------------------------------------

sub _io_act {
    my $self = shift;

    return $self->{'io'}->act( $self->{'nfsfh'}, @_ );
}

1;
