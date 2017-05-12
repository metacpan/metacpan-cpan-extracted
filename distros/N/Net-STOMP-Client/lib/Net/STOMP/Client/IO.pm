#+##############################################################################
#                                                                              #
# File: Net/STOMP/Client/IO.pm                                                 #
#                                                                              #
# Description: Input/Output support for Net::STOMP::Client                     #
#                                                                              #
#-##############################################################################

#
# module definition
#

package Net::STOMP::Client::IO;
use 5.005; # need the four-argument form of substr()
use strict;
use warnings;
our $VERSION  = "2.3";
our $REVISION = sprintf("%d.%02d", q$Revision: 2.2 $ =~ /(\d+)\.(\d+)/);

#
# used modules
#

use List::Util qw(min);
use No::Worries::Die qw(dief);
use No::Worries::Log qw(log_debug);
use POSIX qw(:errno_h);
use Time::HiRes qw();

#
# constants
#

use constant READ_LENGTH  => 32_768;  # chunk size for sysread()
use constant WRITE_LENGTH => 32_768;  # minimum length for syswrite()

#+++############################################################################
#                                                                              #
# private helpers                                                              #
#                                                                              #
#---############################################################################

#
# attempt to read data from the socket to the buffer
#
# note: we read at least once even if the buffer contains enough data
#
# common scenarios:
#  - timeout=undef minlen=undef: loop until we successfully read once
#  - timeout=undef minlen=N: loop until we read at least N bytes
#  - timeout=0     minlen=undef: read only once (successful or not)
#  - timeout=0     minlen=N: loop until we read >=N bytes or fail once
#  - timeout=T     minlen=undef: loop until timeout
#  - timeout=T     minlen=N: loop until we read >=N bytes or timeout
#

sub _try_to_read ($$$) {  ## no critic 'ProhibitExcessComplexity'
    my($self, $timeout, $minlen) = @_;
    my($maxtime, $total, $count, $sleeptime, $remaining);

    $self->{incoming_buflen} = length($self->{incoming_buffer});
    # boundary conditions
    if ($timeout) {
        return(0) unless $timeout > 0;
        # timer starts now
        $maxtime = Time::HiRes::time() + $timeout;
    }
    # try to read, in a loop, until we are done
    $total = 0;
    while (1) {
        # attempt to read once
        $count = sysread($self->{socket}, $self->{incoming_buffer},
                         READ_LENGTH, $self->{incoming_buflen});
        if (defined($count)) {
            # we could read this time
            unless ($count) {
                # ... but we hit the EOF
                $self->{error} = "cannot sysread(): EOF";
                return($total);
            }
            # this is a normal successful read
            $self->{incoming_time} = Time::HiRes::time();
            $self->{incoming_buflen} += $count;
            $total += $count;
            # check if we have worked enough
            return($total) unless $minlen and $total < $minlen;
        } else {
            # we could not read this time
            if ($! != EAGAIN and $! != EWOULDBLOCK) {
                # unexpected error
                $self->{error} = "cannot sysread(): $!";
                return(undef);
            }
        }
        # check time
        if (not defined($timeout)) {
            # timeout = undef => loop forever until we are done
            $sleeptime = 0.01;
        } elsif ($timeout) {
            # timeout > 0 => try again only if not too late
            $remaining = $maxtime - Time::HiRes::time();
            return($total) unless $remaining > 0;
            $sleeptime = min($remaining, 0.01);
        } else {
            # timeout = 0 => try again unless last read failed
            return($total) unless $count;
        }
        # sleep a bit...
        Time::HiRes::sleep($sleeptime) unless $count;
    }
}

#
# attempt to write data from the queue and buffer to the socket
#
# common scenarios:
#  - timeout=undef minlen=undef: loop until we successfully write once
#  - timeout=undef minlen=N: loop until we write at least N bytes
#  - timeout=0     minlen=undef: write only once (successful or not)
#  - timeout=0     minlen=N: loop until we write >=N bytes or fail once
#  - timeout=T     minlen=undef: loop until timeout
#  - timeout=T     minlen=N: loop until we write >=N bytes or timeout
#

sub _try_to_write ($$$) {  ## no critic 'ProhibitExcessComplexity'
    my($self, $timeout, $minlen) = @_;
    my($maxtime, $total, $count, $sleeptime, $remaining, $data);

    $self->{outgoing_buflen} = length($self->{outgoing_buffer});
    # boundary conditions
    return(0) unless $self->{outgoing_buflen} or @{ $self->{outgoing_queue} };
    if ($timeout) {
        return(0) unless $timeout > 0;
        # timer starts now
        $maxtime = Time::HiRes::time() + $timeout;
    }
    # try to write, in a loop, until we are done
    $total = 0;
    while (1) {
        # make sure there is enough data in the outgoing buffer
        while ($self->{outgoing_buflen} < WRITE_LENGTH
               and @{ $self->{outgoing_queue} }) {
            $data = shift(@{ $self->{outgoing_queue} });
            $self->{outgoing_buffer} .= ${ $data };
            $self->{outgoing_buflen} += length(${ $data });
        }
        return($total) unless $self->{outgoing_buflen};
        # attempt to write once
        $count = syswrite($self->{socket}, $self->{outgoing_buffer},
                          $self->{outgoing_buflen});
        if (defined($count)) {
            # we could write this time
            if ($count) {
                # this is a normal successful write
                $self->{outgoing_time} = Time::HiRes::time();
                $self->{outgoing_buflen} -= $count;
                $total += $count;
                substr($self->{outgoing_buffer}, 0, $count, "");
                $self->{outgoing_length} -= $count;
                # check if we have worked enough
                return($total) unless $self->{outgoing_buflen}
                                or @{ $self->{outgoing_queue} };
                return($total) unless $minlen and $total < $minlen;
            }
        } else {
            # we could not write this time
            if ($! != EAGAIN and $! != EWOULDBLOCK) {
                # unexpected error
                $self->{error} = "cannot syswrite(): $!";
                return(undef);
            }
        }
        # check time
        if (not defined($timeout)) {
            # timeout = undef => loop forever until we are done
            $sleeptime = 0.01;
        } elsif ($timeout) {
            # timeout > 0 => try again only if not too late
            $remaining = $maxtime - Time::HiRes::time();
            return($total) unless $remaining > 0;
            $sleeptime = min($remaining, 0.01);
        } else {
            # timeout = 0 => try again unless last write failed
            return($total) unless $count;
        }
        # sleep a bit...
        Time::HiRes::sleep($sleeptime) unless $count;
    }
}

#+++############################################################################
#                                                                              #
# object oriented interface                                                    #
#                                                                              #
#---############################################################################

#
# constructor
#

sub new : method {
    my($class, $socket) = @_;
    my($self);

    dief("missing or invalid socket")
        unless $socket and ref($socket) and $socket->isa("IO::Socket");
    $socket->blocking(0);
    $self = {};
    $self->{socket} = $socket;
    $self->{incoming_buffer} = "";
    $self->{incoming_buflen} = 0;
    $self->{outgoing_buffer} = "";
    $self->{outgoing_buflen} = 0; # buffer length only
    $self->{outgoing_queue} = [];
    $self->{outgoing_length} = 0; # buffer + queue length
    return(bless($self, $class));
}

#
# queue the given data (a scalar reference!)
#

sub queue_data : method {
    my($self, $data) = @_;
    my($length);

    dief("unexpected data: %s", $data) unless ref($data) eq "SCALAR";
    $length = length(${ $data });
    if ($length) {
        push(@{ $self->{outgoing_queue} }, $data);
        $self->{outgoing_length} += $length;
    }
    return($self->{outgoing_length});
}

#
# send the queued data
#

sub send_data : method {
    my($self, %option) = @_;
    my($minlen, $count);

    unless ($self->{error}) {
        # send some data
        $minlen = $self->{outgoing_length};
        $count = _try_to_write($self, $option{timeout}, $minlen);
    }
    dief($self->{error}) unless defined($count);
    # so far so good
    log_debug("sent %d bytes", $count)
        if $option{debug} and $option{debug} =~ /\b(io|all)\b/;
    return($count);
}

#
# receive some data
#

sub receive_data : method {
    my($self, %option) = @_;
    my($minlen, $count);

    unless ($self->{error}) {
        # receive some data
        $minlen = $option{timeout} ? 1 : undef;
        $count = _try_to_read($self, $option{timeout}, $minlen);
    }
    dief($self->{error}) unless defined($count);
    # so far so good
    log_debug("received %d bytes", $count)
        if $option{debug} and $option{debug} =~ /\b(io|all)\b/;
    return($count);
}

1;

__END__

=head1 NAME

Net::STOMP::Client::IO - Input/Output support for Net::STOMP::Client

=head1 DESCRIPTION

This module provides Input/Output (I/O) support. It is used internally by
L<Net::STOMP::Client> and should not be directly used elsewhere.

It uses non-blocking I/O: the socket is in non-blocking mode and errors like
C<EAGAIN> or C<EWOULDBLOCK> are trapped.

=head1 FUNCTIONS

This module provides the following internal methods:

=over

=item new(SOCKET)

return a new Net::STOMP::Client::IO object (class method)

=item queue_data(DATA)

queue (append to the internal outgoing buffer) the given data (a binary
string reference); return the length of DATA in bytes

=item send_data([OPTIONS])

send some queued data to the socket; return the total number of bytes
written

=item receive_data([OPTIONS])

receive some data from the socket and put it in the internal incoming
buffer; return the total number of bytes read

=back

=head1 SEE ALSO

L<Net::STOMP::Client>.

=head1 AUTHOR

Lionel Cons L<http://cern.ch/lionel.cons>

Copyright (C) CERN 2010-2017
