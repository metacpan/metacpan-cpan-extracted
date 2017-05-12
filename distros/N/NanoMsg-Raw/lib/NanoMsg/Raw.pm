package NanoMsg::Raw;
# ABSTRACT: Low-level interface to the nanomsg scalability protocols library
$NanoMsg::Raw::VERSION = '0.10';
use strict;
use warnings;
use XSLoader;
use NanoMsg::Raw::Message;

XSLoader::load(
    'NanoMsg::Raw',
    exists $NanoMsg::Raw::{VERSION} ? ${ $NanoMsg::Raw::{VERSION} } : (),
);

use Exporter 'import';

my @constants = (_symbols(), 'NN_MSG');
my @functions = (
    map { "nn_$_" } qw(
        socket close setsockopt getsockopt bind connect shutdown
        send recv sendmsg recvmsg allocmsg strerror device term errno
    )
);

our @EXPORT_OK = (@constants, @functions);
our @EXPORT = @EXPORT_OK;
our %EXPORT_TAGS = (
    all       => \@EXPORT_OK,
    constants => \@constants,
    functions => \@functions,
);

=head1 NAME

NanoMsg::Raw - Low-level interface to the nanomsg scalability protocols library

=head1 SYNOPSIS

    use Test::More;
    use NanoMsg::Raw;

    my $sb = nn_socket(AF_SP, NN_PAIR);
    nn_bind($sb, 'inproc://foo');

    my $sc = nn_socket(AF_SP, NN_PAIR);
    nn_connect($sc, 'inproc://foo');

    nn_send($sb, 'bar');
    nn_recv($sc, my $buf);
    is $buf, 'bar';

=head1 WARNING

B<nanomsg, the c library this module is based on, is still in beta stage!>

=head1 DESCRIPTION

C<NanoMsg::Raw> is a binding to the C<nanomsg> C library. The goal of this
module is to provide a very low-level and manual interface to all the
functionality of the nanomsg library. It doesn't intend to provide a convenient
high-level API, integration with event loops, or the like. Those are intended to
be implemented as separate abstractions on top of C<NanoMsg::Raw>.

The nanomsg C library is a high-performance implementation of several
"scalability protocols". Scalability protocol's job is to define how multiple
applications communicate to form a single distributed
application. Implementation of following scalability protocols is available at
the moment:

=over

=item *

C<PAIR>
simple one-to-one communication

=item *

C<BUS>
simple many-to-many communication

=item *

C<REQREP>
allows one to build clusters of stateless services to process user requests

=item *

C<PUBSUB>
distributes messages to large sets of interested subscribers

=item *

C<PIPELINE>
aggregates messages from multiple sources and load balances them among many
destinations

=item *

C<SURVEY>
allows one to query state of multiple applications in a single go

=back

Scalability protocols are layered on top of transport layer in the network
stack. At the moment, nanomsg library supports following transports:

=over

=item *

C<INPROC>
transport within a process (between threads, modules etc.)

=item *

C<IPC>
transport between processes on a single machine

=item *

C<TCP>
network transport via TCP

=back

=over

=item nn_socket($domain, $protocol)

    my $s = nn_socket(AF_SP, NN_PAIR);
    die nn_errno unless defined $s;

Creates a nanomsg socket with specified C<$domain> and C<$protocol>. Returns a
file descriptor for the newly created socket.

Following domains are defined at the moment:

=over

=item *

C<AF_SP>
Standard full-blown SP socket.

=item *

C<AF_SP_RAW>
Raw SP socket. Raw sockets omit the end-to-end functionality found in C<AF_SP>
sockets and thus can be used to implement intermediary devices in SP topologies.

=back

The C<$protocol> parameter defines the type of the socket, which in turn
determines the exact semantics of the socket. See L</Protocols> to get the list
of available protocols and their socket types.

The newly created socket is initially not associated with any endpoints. In
order to establish a message flow at least one endpoint has to be added to the
socket using C<nn_bind> or C<nn_connect>.

Also note that type argument as found in standard C<socket> function is omitted
from C<nn_socket>. All the SP sockets are message-based and thus of
C<SOCK_SEQPACKET> type.

If the function succeeds file descriptor of the new socket is
returned. Otherwise, C<undef> is returned and C<nn_errno> is set to to one of
the values defined below.

=over

=item *

C<EAFNOSUPPORT>
Specified address family is not supported.

=item *

C<EINVAL>
Unknown protocol.

=item *

C<EMFILE>
The limit on the total number of open SP sockets or OS limit for file
descriptors has been reached.

=item *

C<ETERM>
The library is terminating.

Note that file descriptors returned by C<nn_socket> function are not standard
file descriptors and will exhibit undefined behaviour when used with system
functions. Moreover, it may happen that a system file descriptor and file
descriptor of an SP socket will incidentally collide (be equal).

=back

=item nn_close($s)

    nn_close($s) or die nn_errno;

Closes the socket C<$s>. Any buffered inbound messages that were not yet
received by the application will be discarded. The library will try to deliver
any outstanding outbound messages for the time specified by C<NN_LINGER> socket
option. The call will block in the meantime.

If the function succeeds, a true value is returned. Otherwise, C<undef> is
returned and C<nn_errno> is set to to one of the values defined below.

=over

=item *

C<EBADF>
The provided socket is invalid.

=item *

C<EINTR>
Operation was interrupted by a signal. The socket is not fully closed
yet. Operation can be re-started by calling C<nn_close> again.

=back

=item nn_setsockopt($s, $level, $option, $value)

    nn_setsockopt($s, NN_SOL_SOCKET, NN_LINGER, 1000) or die nn_errno;
    nn_setsockopt($s, NN_SOL_SOCKET, NN_SUB_SUBSCRIBE, 'ABC') or die nn_errno;

Sets the C<$value> of the socket option C<$option>. The C<$level> argument
specifies the protocol level at which the option resides. For generic
socket-level options use the C<NN_SOL_SOCKET> level. For socket-type-specific
options use the socket type for the C<$level> argument (e.g. C<NN_SUB>). For
transport-specific options use the ID of the transport as the C<$level> argument
(e.g. C<NN_TCP>).

If the function succeeds a true value is returned. Otherwise, C<undef> is
returned and C<nn_errno> is set to to one of the values defined below.

=over

=item *

C<EBADF>
The provided socket is invalid.

=item *

C<ENOPROTOOPT>
The option is unknown at the level indicated.

=item *

C<EINVAL>
The specified option value is invalid.

=item *

C<ETERM>
The library is terminating.

=back

These are the generic socket-level (C<NN_SOL_SOCKET> level) options:

=over


=item *

C<NN_LINGER>
Specifies how long the socket should try to send pending outbound messages after
C<nn_close> has been called, in milliseconds. Negative values mean infinite
linger. The type of the option is int. The default value is 1000 (1 second).

=item *

C<NN_SNDBUF>
Size of the send buffer, in bytes. To prevent blocking for messages larger than
the buffer, exactly one message may be buffered in addition to the data in the
send buffer. The type of this option is int. The default value is 128kB.

=item *

C<NN_RCVBUF>
Size of the receive buffer, in bytes. To prevent blocking for messages larger
than the buffer, exactly one message may be buffered in addition to the data in
the receive buffer. The type of this option is int. The default value is 128kB.

=item *

C<NN_SNDTIMEO>
The timeout for send operation on the socket, in milliseconds. If a message
cannot be sent within the specified timeout, an C<EAGAIN> error is
returned. Negative values mean infinite timeout. The type of the option is
int. The default value is -1.

=item *

C<NN_RCVTIMEO>
The timeout for recv operation on the socket, in milliseconds. If a message
cannot be received within the specified timeout, an C<EAGAIN> error is
returned. Negative values mean infinite timeout. The type of the option is
int. The default value is -1.

=item *

C<NN_RECONNECT_IVL>
For connection-based transports such as TCP, this option specifies how long to
wait, in milliseconds, when connection is broken before trying to re-establish
it. Note that actual reconnect interval may be randomised to some extent to
prevent severe reconnection storms. The type of the option is int. The default
value is 100 (0.1 second).

=item *

C<NN_RECONNECT_IVL_MAX>
This option is to be used only in addition to C<NN_RECONNECT_IVL> option. It
specifies maximum reconnection interval. On each reconnect attempt, the previous
interval is doubled until C<NN_RECONNECT_IVL_MAX> is reached. A value of zero
means that no exponential backoff is performed and reconnect interval is based
only on C<NN_RECONNECT_IVL>. If C<NN_RECONNECT_IVL_MAX> is less than
C<NN_RECONNECT_IVL>, it is ignored. The type of the option is int. The default
value is 0.

=item *

C<NN_SNDPRIO>
Sets outbound priority for endpoints subsequently added to the socket. This
option has no effect on socket types that send messages to all the
peers. However, if the socket type sends each message to a single peer (or a
limited set of peers), peers with high priority take precedence over peers with
low priority. The type of the option is int. The highest priority is 1, the
lowest priority is 16. The default value is 8.

=item *

C<NN_IPV4ONLY>
If set to 1, only IPv4 addresses are used. If set to 0, both IPv4 and IPv6
addresses are used. The default value is 1.

=back

=item nn_getsockopt($s, $level, $option)

    my $linger = unpack 'i', nn_getsockopt($s, NN_SOL_SOCKET, NN_LINGER) || die nn_errno;

Retrieves the value for the socket option C<$option>. The C<$level> argument
specifies the protocol level at which the option resides. For generic
socket-level options use the C<NN_SOL_SOCKET> level. For socket-type-specific
options use the socket type for the C<$level> argument (e.g. C<NN_SUB>). For
transport-specific options use ID of the transport as the C<$level> argument
(e.g. C<NN_TCP>).

The function returns a packed string representing the requested socket option,
or C<undef> on error, with one of the following reasons for the error placed in
C<nn_errno>.

=over

=item *

C<EBADF>
The provided socket is invalid.

=item *

C<ENOPROTOOPT>
The option is unknown at the C<$level> indicated.

=item *

C<ETERM>
The library is terminating.

=back

Just what is in the packed string depends on C<$level> and C<$option>; see the
list of socket options for details; A common case is that the option is an
integer, in which case the result is a packed integer, which you can decode
using C<unpack> with the C<i> (or C<I>) format.

This function can be used to retrieve the values for all the generic
socket-level (C<NN_SOL_SOCKET>) options documented in C<nn_getsockopt> and also
supports these additional generic socket-level options that can only be
retrieved but not set:

=over


=item *

C<NN_DOMAIN>
Returns the domain constant as it was passed to C<nn_socket>.

=item *

C<NN_PROTOCOL>
Returns the protocol constant as it was passed to C<nn_socket>.

=item *

C<NN_SNDFD>
Retrieves a file descriptor that is readable when a message can be sent to the
socket. The descriptor should be used only for polling and never read from or
written to. The type of the option is int. The descriptor becomes invalid and
should not be used any more once the socket is closed. This socket option is not
available for unidirectional recv-only socket types.

=item *

C<NN_RCVFD>
Retrieves a file descriptor that is readable when a message can be received from
the socket. The descriptor should be used only for polling and never read from
or written to. The type of the option is int. The descriptor becomes invalid and
should not be used any more once the socket is closed. This socket option is not
available for unidirectional send-only socket types.

=back

=item nn_bind($s, $addr)

    my $eid = nn_bind($s, 'inproc://test');
    die nn_errno unless defined $eid;

Adds a local endpoint to the socket C<$s>. The endpoint can be then used by other
applications to connect to.

The C<$addr> argument consists of two parts as follows:
C<transport://address>. The C<transport> specifies the underlying transport
protocol to use. The meaning of the C<address> part is specific to the
underlying transport protocol.

See L</Transports> for a list of available transport protocols.

The maximum length of the C<$addr> parameter is specified by C<NN_SOCKADDR_MAX>
constant.

Note that C<nn_bind> and C<nn_connect> may be called multiple times on the same
socket thus allowing the socket to communicate with multiple heterogeneous
endpoints.

If the function succeeds, an endpoint ID is returned. Endpoint ID can be later
used to remove the endpoint from the socket via C<nn_shutdown> function.

If the function fails, C<undef> is returned and C<nn_errno> is set to to one of
the values defined below.

=over

=item *

C<EBADF>
The provided socket is invalid.

=item *

C<EMFILE>
Maximum number of active endpoints was reached.

=item *

C<EINVAL>
The syntax of the supplied address is invalid.

=item *

C<ENAMETOOLONG>
The supplied address is too long.

=item *

C<EPROTONOSUPPORT>
The requested transport protocol is not supported.

=item *

C<EADDRNOTAVAIL>
The requested endpoint is not local.

=item *

C<ENODEV>
Address specifies a nonexistent interface.

=item *

C<EADDRINUSE>
The requested local endpoint is already in use.

=item *

C<ETERM>
The library is terminating.

=back

=item nn_connect($s, $addr)

    my $eid = nn_connect($s, 'inproc://test');
    die nn_errno unless defined $eid;

Adds a remote endpoint to the socket C<$s>. The library would then try to
connect to the specified remote endpoint.

The C<$addr> argument consists of two parts as follows:
C<transport://address>. The C<transport> specifies the underlying transport
protocol to use. The meaning of the C<address> part is specific to the
underlying transport protocol.

See L</Protocols> for a list of available transport protocols.

The maximum length of the C<$addr> parameter is specified by C<NN_SOCKADDR_MAX>
constant.

Note that C<nn_connect> and C<nn_bind> may be called multiple times on the same
socket thus allowing the socket to communicate with multiple heterogeneous
endpoints.

If the function succeeds, an endpoint ID is returned. Endpoint ID can be later
used to remove the endpoint from the socket via C<nn_shutdown> function.

If the function fails, C<undef> is returned and C<nn_errno> is set to to one of
the values defined below.

=over

=item *

C<EBADF>
The provided socket is invalid.

=item *

C<EMFILE>
Maximum number of active endpoints was reached.

=item *

C<EINVAL>
The syntax of the supplied address is invalid.

=item *

C<ENAMETOOLONG>
The supplied address is too long.

=item *

C<EPROTONOSUPPORT>
The requested transport protocol is not supported.

=item *

C<ENODEV>
Address specifies a nonexistent interface.

=item *

C<ETERM>
The library is terminating.

=back

=item nn_shutdown($s, $eid)

    nn_shutdown($s, $eid) or die nn_errno;

Removes an endpoint from socket C<$s>. The C<eid> parameter specifies the ID of
the endpoint to remove as returned by prior call to C<nn_bind> or
C<nn_connect>.

The C<nn_shutdown> call will return immediately. However, the library will try
to deliver any outstanding outbound messages to the endpoint for the time
specified by the C<NN_LINGER> socket option.

If the function succeeds, a true value is returned. Otherwise, C<undef> is
returned and C<nn_errno> is set to to one of the values defined below.

=over

=item *

C<EBADF>
The provided socket is invalid.

=item *

C<EINVAL>
The how parameter doesn't correspond to an active endpoint.

=item *

C<EINTR>
Operation was interrupted by a signal. The endpoint is not fully closed
yet. Operation can be re-started by calling C<nn_shutdown> again.

=item *

C<ETERM>
The library is terminating.

=back

=item nn_send($s, $data, $flags=0)

    my $bytes_sent = nn_send($s, 'foo');
    die nn_errno unless defined $bytes_sent;

This function will send a message containing the provided C<$data> to the socket
C<$s>.

C<$data> can either be anything that can be used as a byte string in perl or a
message buffer instance allocated by C<nn_allocmsg>. In case of a message buffer
instance the instance will be deallocated and invalidated by the C<nn_send>
function. The buffer will be an instance of C<NanoMsg::Raw::Message::Freed>
after the call to C<nn_send>.

Which of the peers the message will be sent to is determined by the particular
socket type.

The C<$flags> argument, which defaults to C<0>, is a combination of the flags
defined below:

=over

=item *

C<NN_DONTWAIT>
Specifies that the operation should be performed in non-blocking mode. If the
message cannot be sent straight away, the function will fail with C<nn_errno>
set to C<EAGAIN>.

=back

If the function succeeds, the number of bytes in the message is
returned. Otherwise, a C<undef> is returned and C<nn_errno> is set to to one of
the values defined below.

=over

=item *

C<EBADF>
The provided socket is invalid.

=item *

C<ENOTSUP>
The operation is not supported by this socket type.

=item *

C<EFSM>
The operation cannot be performed on this socket at the moment because the
socket is not in the appropriate state. This error may occur with socket types
that switch between several states.

=item *

C<EAGAIN>
Non-blocking mode was requested and the message cannot be sent at the moment.

=item *

C<EINTR>
The operation was interrupted by delivery of a signal before the message was
sent.

=item *

C<ETIMEDOUT>
Individual socket types may define their own specific timeouts. If such timeout
is hit, this error will be returned.

=item *

C<ETERM>
The library is terminating.

=back

=item nn_recv($s, $data, $length=NN_MSG, $flags=0)

    my $bytes_received = nn_recv($s, my $buf, 256);
    die nn_errno unless defined $bytes_received;

Receive a message from the socket C<$s> and store it in the buffer C<$buf>. Any
bytes exceeding the length specified by the C<$length> argument will be
truncated.

Alternatively, C<nn_recv> can allocate a message buffer instance for you. To do
so, set the C<$length> parameter to C<NN_MSG> (the default).

The C<$flags> argument, which defaults to C<0>, is a combination of the flags
defined below:

=over

=item *

C<NN_DONTWAIT>
Specifies that the operation should be performed in non-blocking mode. If the
message cannot be received straight away, the function will fail with
C<nn_errno> set to C<EAGAIN>.

=back

If the function succeeds number of bytes in the message is returned. Otherwise,
C<undef> is returned and C<nn_errno> is set to to one of the values defined
below.

=over


=item *

C<EBADF>
The provided socket is invalid.

=item *

C<ENOTSUP>
The operation is not supported by this socket type.

=item *

C<EFSM>
The operation cannot be performed on this socket at the moment because socket is
not in the appropriate state. This error may occur with socket types that switch
between several states.

=item *

C<EAGAIN>
Non-blocking mode was requested and there's no message to receive at the moment.

=item *

C<EINTR>
The operation was interrupted by delivery of a signal before the message was
received.

=item *

C<ETIMEDOUT>
Individual socket types may define their own specific timeouts. If such timeout
is hit this error will be returned.

=item *

C<ETERM>
The library is terminating.

=back

=item nn_sendmsg($s, $flags, $data1, $data2, ..., $dataN)

    my $bytes_sent = nn_sendmsg($s, 0, 'foo', 'bar');
    die nn_errno unless defined $bytes_sent;

This function is a fine-grained alternative to C<nn_send>. It allows sending
multiple data buffers that make up a single message without having to create
another temporary buffer to hold the concatenation of the different message
parts.

The scalars containing the data to be sent (C<$data1>, C<$data2>, ...,
C<$dataN>) can either be anything that can be used as a byte string in perl or a
message buffer instance allocated by C<nn_allocmsg>. In case of a message buffer
instance the instance will be deallocated and invalidated by the C<nn_sendmsg>
function. The buffers will be a instances of C<NanoMsg::Raw::Message::Freed>
after the call to C<nn_sendmsg>.

When using message buffer instances, only one buffer may be provided.

To which of the peers will the message be sent to is determined by the
particular socket type.

The C<$flags> argument is a combination of the flags defined below:

=over

=item *

C<NN_DONTWAIT>
Specifies that the operation should be performed in non-blocking mode. If the
message cannot be sent straight away, the function will fail with C<nn_errno>
set to C<EAGAIN>.

=back

If the function succeeds number of bytes in the message is returned. Otherwise,
C<undef> is returned and C<nn_errno> is set to to one of the values defined
below.

=over

=item *

C<EBADF>
The provided socket is invalid.

=item *

C<ENOTSUP>
The operation is not supported by this socket type.

=item *

C<EFSM>
The operation cannot be performed on this socket at the moment because socket is
not in the appropriate state. This error may occur with socket types that switch
between several states.

=item *

C<EAGAIN>
Non-blocking mode was requested and the message cannot be sent at the moment.

=item *

C<EINTR>
The operation was interrupted by delivery of a signal before the message was
sent.

=item *

C<ETIMEDOUT>
Individual socket types may define their own specific timeouts. If such timeout
is hit this error will be returned.

=item *

C<ETERM>
The library is terminating.

=back

In the future, C<nn_sendmsg> might allow for sending along additional control
data.

=item nn_recvmsg($s, $flags, $data1 => $len1, $data2 => $len2, ..., $dataN => $lenN)

    my $bytes_received = nn_recvmsg($s, 0, my $buf1 => 256, my $buf2 => 1024);
    die nn_errno unless defined $bytes_received;

This function is a fine-grained alternative to C<nn_recv>. It allows receiving a
single message into multiple data buffers of different sizes, eliminating the
need to create copies of part of the received message in some cases.

The scalars in which to receive the message data (C<$buf1>, C<$buf2>, ...,
C<$bufN>) will be filled with as many bytes of data as is specified by the
length parameter following them in the argument list (C<$len1>, C<$len2>, ...,
C<$lenN>).

Alternatively, C<nn_recvmsg> can allocate a message buffer instance for you. To
do so, set the length parameter of a buffer to to C<NN_MSG>. In this case, only
one receive buffer can be provided.

The C<$flags> argument is a combination of the flags defined below:

=over

=item *

C<NN_DONTWAIT>
Specifies that the operation should be performed in non-blocking mode. If the
message cannot be received straight away, the function will fail with
C<nn_errno> set to C<EAGAIN>.

=back

In the future, C<nn_recvmsg> might allow for receiving additional control data.

=item nn_allocmsg($size, $type)

    my $msg = nn_allocmsg(3, 0) or die nn_errno;
    $msg->copy('foo');
    nn_send($s, $msg);

Allocate a message of the specified C<$size> to be sent in zero-copy
fashion. The content of the message is undefined after allocation and it should
be filled in by the user. While C<nn_send> and C<nn_sendmsg> allow one to send
arbitrary buffers, buffers allocated using C<nn_allocmsg> can be more efficient
for large messages as they allow for using zero-copy techniques.

The C<$type> parameter specifies type of allocation mechanism to use. Zero is
the default one. However, individual transport mechanisms may define their own
allocation mechanisms, such as allocating in shared memory or allocating a
memory block pinned down to a physical memory address. Such allocation, when
used with the transport that defines them, should be more efficient than the
default allocation mechanism.

If the function succeeds a newly allocated message buffer instance (an object
instance of the class L<NanoMsg::Raw::Message>) is returned. Otherwise, C<undef>
is returned and C<nn_errno> is set to to one of the values defined below.

=over

=item *

C<EINVAL>
Supplied allocation type is invalid.

=item *

C<ENOMEM>
Not enough memory to allocate the message.

=back

=item nn_errno()

Returns value of C<errno> after the last call to any nanomsg function in the
current thread. This function can be used in the same way the C<$!> global
variable is be used for many other system and library calls.

The return value can be used in numeric context, for example to compare it with
error code constants such as C<EAGAIN>, or in a string context, to retrieve a
textual message describing the error.

=item nn_strerror($errno)

Returns a textual representation of the error described by the nummeric
C<$errno> provided. It shouldn't normally be necessary to ever call this
function, as using C<nn_errno> in string context is basically equivalent to
C<nn_strerror(nn_errno)>.

=item nn_device($s1, $s2)

    nn_device($s1, $s2) or die;

Starts a device to forward messages between two sockets. If both sockets are
valid, the C<nn_device> function loops and sends and messages received from
C<$s1> to C<$s2> and vice versa. If only one socket is valid and the other is
C<undef>, C<nn_device> works in a loopback mode - it loops and sends any
messages received from the socket back to itself.

The function loops until it hits an error. In such case it returns C<undef> and
sets C<nn_errno> to one of the values defined below.

=over

=item *

C<EBADF>
One of the provided sockets is invalid.

=item *

C<EINVAL>
Either one of the socket is not an C<AF_SP_RAW> socket; or the two sockets don't
belong to the same protocol; or the directionality of the sockets doesn't fit
(e.g. attempt to join two SINK sockets to form a device).

=item *

C<EINTR>
The operation was interrupted by delivery of a signal.

=item *

C<ETERM>
The library is terminating.

=back

=item nn_term()

    nn_term();

To help with shutdown of multi-threaded programs the C<nn_term> function is
provided. It informs all the open sockets that process termination is underway.

If a socket is blocked inside a blocking function, such as C<nn_recv>, it will
be unblocked and the C<ETERM> error will be returned to the user. Similarly, any
subsequent attempt to invoke a socket function other than C<nn_close> after
C<nn_term> was called will result in an C<ETERM> error.

If waiting for C<NN_SNDFD> or C<NN_RCVFD> using a polling function, such as
C<poll> or C<select>, the call will unblock with both C<NN_SNDFD> and
C<NN_RCVFD> signaled.

The C<nn_term> function itself is non-blocking.

=back

=head1 Protocols

=head2 One-to-one protocol

Pair protocol is the simplest and least scalable scalability protocol. It allows
scaling by breaking the application in exactly two pieces. For example, if a
monolithic application handles both accounting and agenda of HR department, it
can be split into two applications (accounting vs. HR) that are run on two
separate servers. These applications can then communicate via PAIR sockets.

The downside of this protocol is that its scaling properties are very
limited. Splitting the application into two pieces allows one to scale to two
servers. To add the third server to the cluster, application has to be split
once more, say be separating HR functionality into hiring module and salary
computation module. Whenever possible, try to use one of the more scalable
protocols instead.

=head3 Socket Types

=over

=item *

C<NN_PAIR>
Socket for communication with exactly one peer. Each party can send messages at
any time. If the peer is not available or send buffer is full subsequent calls
to C<nn_send> will block until it's possible to send the message.

=back

=head3 Socket Options

No protocol-specific socket options are defined at the moment.

=head2 Request/reply protocol

This protocol is used to distribute the workload among multiple stateless workers.

=head3 Socket Types

=over

=item *

C<NN_REQ>
Used to implement the client application that sends requests and receives
replies.

=item *

C<NN_REP>
Used to implement the stateless worker that receives requests and sends replies.

=back

=head3 Socket Options

=over

=item *

C<NN_REQ_RESEND_IVL>
This option is defined on the full REQ socket. If a reply is not received in
specified amount of milliseconds, the request will be automatically resent. The
type of this option is int. Default value is 60000 (1 minute).

=back

=head2 Publish/subscribe protocol

Broadcasts messages to multiple destinations.

=head3 Socket Types

=over

=item *

C<NN_PUB>
This socket is used to distribute messages to multiple destinations. Receive
operation is not defined.

=item *

C<NN_SUB>
Receives messages from the publisher. Only messages that the socket is
subscribed to are received. When the socket is created there are no
subscriptions and thus no messages will be received. Send operation is not
defined on this socket.

=back

=head3 Socket Options

=over

=item *

C<NN_SUB_SUBSCRIBE>
Defined on full SUB socket. Subscribes for a particular topic. Type of the
option is string.

=item *

C<NN_SUB_UNSUBSCRIBE>
Defined on full SUB socket. Unsubscribes from a particular topic. Type of the
option is string.

=back

=head2 Survey protocol

allows one to broadcast a survey to multiple locations and gather the responses.

=head3 Socket Types

=over


=item *

C<NN_SURVEYOR>
Used to send the survey. The survey is delivered to all the connected
respondents. Once the query is sent, the socket can be used to receive the
responses. When the survey deadline expires, receive will return the
C<ETIMEDOUT> error.

=item *

C<NN_RESPONDENT>
Use to respond to the survey. Survey is received using receive function,
response is sent using send function. This socket can be connected to at most
one peer.

=back

=head3 Socket Options

=over

=item *

C<NN_SURVEYOR_DEADLINE>
Specifies how long to wait for responses to the survey. Once the deadline
expires, receive function will return the C<ETIMEDOUT> error and all subsequent
responses to the survey will be silently dropped. The deadline is measured in
milliseconds. Option type is int. Default value is 1000 (1 second).

=back

=head2 Pipeline protocol

Fair queues messages from the previous processing step and load balances them
among instances of the next processing step.

=head3 Socket Types

=over

=item *

C<NN_PUSH>
This socket is used to send messages to a cluster of load-balanced
nodes. Receive operation is not implemented on this socket type.

=item *

C<NN_PULL>
This socket is used to receive a message from a cluster of nodes. Send operation
is not implemented on this socket type.

=back

=head3 Socket Options

No protocol-specific socket options are defined at the moment.

=head2 Message bus protocol

Broadcasts messages from any node to all other nodes in the topology. The socket
should never receives messages that it sent itself.

This pattern scales only to local level (within a single machine or within a
single LAN). Trying to scale it further can result in overloading individual
nodes with messages.

B<WARNING>: For bus topology to function correctly, the user is responsible for
ensuring that path from each node to any other node exists within the topology.

Raw (C<AF_SP_RAW>) BUS socket never send the message to the peer it was received
from.

=head3 Socket Types

=over

=item *

C<NN_BUS>
Sent messages are distributed to all nodes in the topology. Incoming messages
from all other nodes in the topology are fair-queued in the socket.

=back

=head3 Socket Options

There are no options defined at the moment.

=head1 Transports

=head2 In-process transport

The in-process transport allows one to send messages between threads or modules inside a
process. In-process address is an arbitrary case-sensitive string preceded by
C<inproc://> protocol specifier. All in-process addresses are visible from any
module within the process. They are not visible from outside of the process.

The overall buffer size for an inproc connection is determined by the
C<NN_RCVBUF> socket option on the receiving end of the connection. The
C<NN_SNDBUF> socket option is ignored. In addition to the buffer, one message of
arbitrary size will fit into the buffer. That way, even messages larger than the
buffer can be transferred via inproc connection.

This transport's ID is C<NN_INPROC>.

=head2 Inter-process transport

The inter-process transport allows for sending messages between processes within
a single box. The implementation uses native IPC mechanism provided by the local
operating system and the IPC addresses are thus OS-specific.

On POSIX-compliant systems, UNIX domain sockets are used and IPC addresses are
file references. Note that both relative (C<ipc://test.ipc>) and absolute
(C<ipc:///tmp/test.ipc>) paths may be used. Also note that access rights on the
IPC files must be set in such a way that the appropriate applications can
actually use them.

On Windows, named pipes are used for IPC. IPC address is an arbitrary
case-insensitive string containing any character except for
backslash. Internally, address C<ipc://test> means that named pipe
C<\\.\pipe\test> will be used.

This transport's ID is C<NN_IPC>.

=head2 TCP transport

The TCP transport allows for passing message over the network using simple
reliable one-to-one connections. TCP is the most widely used transport protocol,
it is virtually ubiquitous and thus the transport of choice for communication
over the network.

When binding a TCP socket address of the form C<tcp://interface:port> should be
used. Port is the TCP port number to use. Interface is one of the following
(optionally placed within square brackets):

=over


=item *

Asterisk character (*) meaning all local network interfaces.

=item *

IPv4 address of a local network interface in numeric form (192.168.0.111).

=item *

IPv6 address of a local network interface in numeric form (::1).

=item *

Interface name, as defined by operating system.

=back

When connecting a TCP socket address of the form C<tcp://interface;address:port>
should be used. Port is the TCP port number to use. Interface is optional and
specifies which local network interface to use. If not specified, OS will select
an appropriate interface itself. If specified it can be one of the following
(optionally placed within square brackets):

=over

=item *

IPv4 address of a local network interface in numeric form (192.168.0.111).

=item *

IPv6 address of a local network interface in numeric form (::1).

=item *

Interface name, as defined by operating system (eth0).

=back

Finally, address specifies the remote address to connect to. It can be one of
the following (optionally placed within square brackets):

=over


=item *

IPv4 address of a remote network interface in numeric form (192.168.0.111).

=item *

IPv6 address of a remote network interface in numeric form (::1).

=item *

The DNS name of the remote box.

=back

This transport's ID is C<NN_TCP>.

=head3 Socket Options

=over

=item *

C<NN_TCP_NODELAY>
This option, when set to 1, disables Nagle's algorithm. It also disables
delaying of TCP acknowledgments. Using this option improves latency at the
expense of throughput. Type of this option is int. The default value is 0.

=back

=head1 Constants

In addition to all the error constants and C<NN_> constants used in the
documentation of the individual functions, protocols, and transports, the
following constants are available:

=over

=item *

C<NN_VERSION_CURRENT>
The current interface version.

=item *

C<NN_VERSION_REVISION>
The latest revision of the current interface.

=item *

C<NN_VERSION_AGE>
How many past interface versions are still supported.

=back

=for Pod::Coverage - we document these already
AF_SP
AF_SP_RAW
EADDRINUSE
EADDRNOTAVAIL
EAFNOSUPPORT
EAGAIN
EBADF
EFSM
EINTR
EINVAL
EMFILE
ENAMETOOLONG
ENODEV
ENOMEM
ENOPROTOOPT
ENOTSUP
EPROTONOSUPPORT
ETERM
ETIMEDOUT
NN_BUS
NN_DOMAIN
NN_DONTWAIT
NN_INPROC
NN_IPC
NN_LINGER
NN_MSG
NN_PAIR
NN_PROTOCOL
NN_PUB
NN_PULL
NN_PUSH
NN_RCVBUF
NN_RCVFD
NN_RCVTIMEO
NN_RECONNECT_IVL
NN_RECONNECT_IVL_MAX
NN_REP
NN_REQ
NN_REQ_RESEND_IVL
NN_RESPONDENT
NN_SNDBUF
NN_SNDFD
NN_SNDPRIO
NN_SNDTIMEO
NN_SOCKADDR_MAX
NN_SOL_SOCKET
NN_SUB
NN_SUB_SUBSCRIBE
NN_SUB_UNSUBSCRIBE
NN_SURVEYOR
NN_SURVEYOR_DEADLINE
NN_TCP
NN_TCP_NODELAY
NN_VERSION_AGE
NN_VERSION_CURRENT
NN_VERSION_REVISION

=for Pod::Coverage - not documented by upstream and perhaps not used; see https://github.com/250bpm/nanomsg/issues/108
ECONNREFUSED
EINPROGRESS
ENETDOWN
ENOBUFS
ENOTSOCK
EPROTO

=head1 SEE ALSO

=over


=item *

The nanomsg C library documentation at L<http://nanomsg.org/v0.1/nanomsg.7.html>
The API this module provides is very close to the C library's interface, so the
C documentation is likely to be useful to developers using Perl,
too. Additionally, most of this module's documentation is copied from the C
library documentation, so the upstream documentation might be somewhat more
recent.

=item *

L<NanoMsg::Raw::Message>

=back

=cut

1;
