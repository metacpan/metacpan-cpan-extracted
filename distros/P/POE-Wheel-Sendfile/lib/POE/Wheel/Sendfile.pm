package POE::Wheel::Sendfile;

use strict;
use warnings;

our $VERSION = '0.0200';

use POE;
use IO::File;
use Socket;

sub DEBUG () { 0 }

use base qw( POE::Wheel::ReadWrite );

#######################################
BEGIN {
    *HANDLE_OUTPUT = \&POE::Wheel::ReadWrite::HANDLE_OUTPUT;
    *STATE_WRITE = \&POE::Wheel::ReadWrite::STATE_WRITE;
    *EVENT_FLUSHED = \&POE::Wheel::ReadWrite::EVENT_FLUSHED;
    *EVENT_ERROR = \&POE::Wheel::ReadWrite::EVENT_ERROR;
    *UNIQUE_ID = \&POE::Wheel::ReadWrite::UNIQUE_ID;
    *DRIVER_BOTH = \&POE::Wheel::ReadWrite::DRIVER_BOTH;
    *AUTOFLUSH = \&POE::Wheel::ReadWrite::AUTOFLUSH;
}

sub STATE_SENDFILE () { AUTOFLUSH+1 }

#######################################
our $HAVE_SENDFILE;
BEGIN {
    unless( defined $HAVE_SENDFILE ) {
        $HAVE_SENDFILE = 0;
        eval "use Sys::Sendfile 0.11 ();";
        $HAVE_SENDFILE = 1 unless $@;
        warn $@ if DEBUG and $@;
    }   
}

#######################################
sub sendfile
{
    my( $self, $fh ) = @_;
    # Build a [SENDFILE] hash with details
    my $S = $self->_sendfile_setup( $fh );
    $S or return;
    # Build a select write handler
    $self->_sendfile_define_write( $S ) or return;
    # Call that handler
    return $poe_kernel->call(
                       $poe_kernel->get_active_session,
                       $self->[STATE_SENDFILE], 
                       $self->[HANDLE_OUTPUT]
                     );
}

#######################################
sub _sendfile_setup
{
    my( $self, $fh ) = @_;
    my $event_error = \$self->[EVENT_ERROR];
    my $unique_id   = \$self->[UNIQUE_ID];

    if( $self->[STATE_SENDFILE] ) {
        $@ = "Already sending a file";
        return;
    }
    my $S = {};
    if( 'HASH' eq ref $fh ) {
        $S = $fh;
        $fh = delete $S->{file};
    }
    unless( ref $fh ) {
        my $io = IO::File->new;
        unless( $io->open( $fh ) ) {
            my $me = $poe_kernel->get_active_session;
            $$event_error && $poe_kernel->call(
                $me, $$event_error, 'open', ($!+0), "$fh: $!",  $unique_id
            );
            return;
        }
        $S->{file} = $fh;
        $S->{fh} = $io;
    }
    else {
        $S->{fh} = $fh;
    }

    unless( $S->{offset} ) {
        $S->{offset} = 0;
    }

    unless( $S->{size} ) {
        $S->{size} = (stat $S->{fh})[7] - $S->{offset};
    }
    else {
        $S->{size} += $S->{offset};
    }
    unless( $S->{blocksize} or $HAVE_SENDFILE ) {
        $S->{blocksize} = eval {
                    $SIG{__DIE__} = 'DEFAULT';
                    my $h = $self->[HANDLE_OUTPUT];
                    return unpack "i",
                        getsockopt($h, Socket::SOL_SOCKET(), Socket::SO_SNDBUF());
                };
        $S->{blocksize} ||= 7500;
    }

    return $S;
}

#######################################
sub _sendfile_define_write
{
    my( $self, $S ) = @_;

    my @need = (
            \$self->[EVENT_ERROR],      # $event_error
            \$self->[EVENT_FLUSHED],    # $event_flush
            \$self->[STATE_WRITE],      # $state_write
            \$self->[STATE_SENDFILE],   # $state_sendfile
            $self->[UNIQUE_ID],         # $unique_id
            $self->[DRIVER_BOTH],       # $driver
            \$S,                        # $sendfile
            1                           # $first
        );

    my $state;
    if( $HAVE_SENDFILE ) {
        $state = _mk_sendfile( \@need );
    }
    else {
        $state = _mk_fallback( \@need );
    }
    die unless $state;
    $self->[STATE_SENDFILE] = ref( $self ) . " ($self->[UNIQUE_ID]) -> sendfile write",
    $poe_kernel->state( $self->[STATE_SENDFILE], $state );
    $poe_kernel->select_write($self->[HANDLE_OUTPUT]);
    $poe_kernel->select_write( $self->[HANDLE_OUTPUT], 
                               $self->[STATE_SENDFILE]
                             );
    return 1;
}

# This is where all the work happens
# We call sendfile(), check it's return, update the offset, then
# wait for the flushed-event to happen.
# If we are at the end of the file, we let the flushed-event go to the 
# OutputEvent handler       
sub _mk_sendfile
{
    my( 
        $event_error,                   # \$self->[EVENT_ERROR];
        $event_flushed,                 # \$self->[EVENT_FLUSHED];
        $state_write,                   # \$self->[STATE_WRITE];
        $state_sendfile,                # \$self->[STATE_SENDFILE];
        $unique_id,                     # $self->[UNIQUE_ID];
        $driver,                        # $self->[DRIVER_BOTH];
        $sendfile,                      # \$S;
        $first                          # 1;
    ) = @{ $_[0] };

    return sub {
        0 && CRIMSON_SCOPE_HACK('<');
        my ($k, $me, $handle) = @_[KERNEL, SESSION, ARG0];

        my $need = $$sendfile->{size} - $$sendfile->{offset};
        DEBUG and warn "sendfile #$unique_id, offset=$$sendfile->{offset}, need=$need, size=$$sendfile->{size}";
        my $rv = Sys::Sendfile::sendfile( 
                    $handle, $$sendfile->{fh}, $need, $$sendfile->{offset} );

        DEBUG and warn "sendfile #$unique_id, rv=$rv";

        # sendfile(2) - Applications may wish to fall back to
        # read(2)/write(2) in the case where sendfile() fails with EINVAL or
        # ENOSYS.

        unless( defined $rv and $rv >= 0 ) {
            $$event_error && $k->call(
                  $me, $$event_error, 'sendfile', ($!+0), "$!", $unique_id
            );
            return;
        }

        $$sendfile->{offset} += $rv;
        if( $rv == 0 or $$sendfile->{offset} >= $$sendfile->{size} ) {
            DEBUG and warn "sendfile #$unique_id, done";
            # We want the last flush to do to the session
            $k->select_write( $handle );
            $k->select_write( $handle, $$state_write );
            # Remove this state
            $k->state( $$state_sendfile );
            # Nothing more to send
            $$state_sendfile = undef();
            return 1;
        }

        if( $first ) {
            # Turn the select on 
            $k->select_resume_write( $handle );
            $first = 0;
        }
        return 1;
    };
} 


#
# Fallback to doing it by hand
#
sub _mk_fallback
{
    my( 
        $event_error,                   # \$self->[EVENT_ERROR];
        $event_flushed,                 # \$self->[EVENT_FLUSHED];
        $state_write,                   # \$self->[STATE_WRITE];
        $state_sendfile,                # \$self->[STATE_SENDFILE];
        $unique_id,                     # $self->[UNIQUE_ID];
        $driver,                        # $self->[DRIVER_BOTH];
        $sendfile,                      # \$S;
        $first                          # 1;
    ) = @{ $_[0] };

    my $rv = sysseek( $$sendfile->{fh}, $$sendfile->{offset}, 0 );
    unless( defined $rv ) {
        $@ = "Unable to sysseek to $$sendfile->{offset}: $!";
        return;
    }

    my $buffer = '';
    return sub {
        0 && CRIMSON_SCOPE_HACK('<');

        my ($k, $me, $handle) = @_[KERNEL, SESSION, ARG0];

        # Don't read to much if we only want a little
        my $size = $$sendfile->{blocksize};
        if( $size+$$sendfile->{offset} > $$sendfile->{size} ) {
            $size = $$sendfile->{size} - $$sendfile->{offset};
        }

        my $rv = sysread( $$sendfile->{fh}, $buffer, $size );
        unless( defined $rv ) {
            $$event_error && $k->call(
                  $me, $$event_error, 'sysread', ($!+0), $!, $unique_id
            );
            return;
        }    

        $$sendfile->{offset} += $rv;
        if( $rv == 0 || $$sendfile->{offset} >= $$sendfile->{size} ) {
            # Nothing more to send
            $$sendfile = undef();
            # We want the last flush to go to the session
            $k->select_write( $handle );
            $k->select_write( $handle, $$state_write );
            # Remove this state
            $k->state( $$state_sendfile );
            # Nothing more to send
            $$state_sendfile = undef();
        }
    
        my $err = 0;    
        if( $rv != 0 ) {
            if( $driver->put( [$buffer] ) ) {
                $driver->flush( $handle );
                if( $! ) {
                    $$event_error && $k->call(
                          $me, $$event_error, 'syswrite', ($!+0), $!, $unique_id
                    );
                    $err = 1;
                }
            }
            if( $first and not $err ) {
                # Turn the select on 
                $k->select_resume_write( $handle );
                $first = 0;
            }
        }
        return if $err;
        return 1;
    };
}

1;

__END__

=head1 NAME

POE::Wheel::Sendfile - Extend POE::Wheel::ReadWrite with sendfile

=head1 SYNOPSIS

    use POE::Wheel::Sendfile;

    my $wheel = POE::Wheel::Sendfile->new( 
                        Handle => $socket,
                        InputEvent => 'input',
                        FlushedEvent => 'flushed',
                    );
    $heap->{wheel} = $wheel;

    sub input {
        $heap->{wheel}->sendfile( $file );
    }

    sub flushed {
        delete $heap->{wheel};
    }

=head1 DESCRIPTION

POE::Wheel::Sendfile extends L<POE::Wheel::ReadWrite> and adds the
possibility of using the sendfile system call to transfer data as
efficiently.

It is created just like a POE::Wheel::ReadWrite would be.  When you want to
send a file, you call L</sendfile>.  When sendfile is done, your
FlushedEvent will be invoked.

POE::Wheel::Sendfile uses L<Sys::Sendfile> for portable sendfile.  If it is
not available, it falls back to using L<sysread> and L<syswrite>.

=head1 METHODS

POE::Wheel::Sendfile only adds one public method to the interface:

=head2 sendfile

    $wheel->sendfile( $FILE );
    $wheel->sendfile( { file => $FILE,
                        [ offset => $OFFSET, ]
                        [ size => $SIZE, ]
                        [ blocksize => $BLKSIZE ]
                    } );

Sends C<$FILE> over the wheel's socket.  Optionnaly starting at C<$OFFSET>. 
If L<Sys::Sendfile> is not available, will fall back to sending the file in
C<$BLKSIZE> chunks with L<sysread>.


=head3 file => $FILE

An open filehandle or the name of a file.

=head3 offset => $OFFSET

Byte offset from which the sending will start.  Optional, defaults to 0.

=head3 size => $SIZE

Number of bytes to send.  Defaults to the entire file.

=head3 blocksize =>  $BLKSIZE

If L<Sys::Sendfile> is not available, POE::Wheel::Sendfile will fall back to
using sysread and syswrite.  It will read and write C<$BLKSIZE> bytes at
once.  If omited, the socket's C<SO_SNDBUF> size is used.  If that is
unavailable, the block size is 7500 bytes (5 ethernet frames).


=head1 SEE ALSO

L<POE>, L<POE::Wheel::ReadWrite>.

=head1 AUTHOR

Philip Gwyn, E<lt>gwyn -at- cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010, 2011 by Philip Gwyn

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
