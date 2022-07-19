package Net::LibNFS::IO::Contextual;

use strict;
use warnings;

use Carp ();

use parent 'Net::LibNFS::IO';

sub _create_fh {
    my $self = shift;

    my $fd = $self->_fd();

    # Normally we want to prevent Perl from close()ing the file descriptor
    # so that libnfs doesn’t get upset over its file descriptor being
    # “taken away”. As it happens, though, libnfs doesn’t seem to “mind”,
    # and it simplifies the code here a bit. (The POSIX::dup() trick
    # actually breaks it .. ??)

    open my $fh, "+>>&=$fd" or do {
        Carp::croak "Falied to adopt FD $fd: $!";
    };

    return $fh;
}

sub DESTROY {
    my $self = shift;

    $self->_stop();

    return $self->SUPER::DESTROY();
}

1;
