# SYNOPSIS

    use Test::More;
    use NanoMsg::Raw;

    my $sb = nn_socket(AF_SP, NN_PAIR);
    nn_bind($sb, 'inproc://foo');

    my $sc = nn_socket(AF_SP, NN_PAIR);
    nn_connect($sc, 'inproc://foo');

    nn_send($sb, 'bar');
    nn_recv($sc, my $buf);
    is $buf, 'bar';

# WARNING

**nanomsg, the c library this module is based on, is still in beta stage!**

# DESCRIPTION

`NanoMsg::Raw` is a binding to the `nanomsg` C library. The goal of this
module is to provide a very low-level and manual interface to all the
functionality of the nanomsg library. It doesn't intend to provide a convenient
high-level API, integration with event loops, or the like. Those are intended to
be implemented as separate abstractions on top of `NanoMsg::Raw`.

The nanomsg C library is a high-performance implementation of several
"scalability protocols". Scalability protocol's job is to define how multiple
applications communicate to form a single distributed
application. Implementation of following scalability protocols is available at
the moment:

### 
* `PAIR`
simple one-to-one communication
* `BUS`
simple many-to-many communication
* `REQREP`
allows one to build clusters of stateless services to process user requests
* `PUBSUB`
distributes messages to large sets of interested subscribers
* `PIPELINE`
aggregates messages from multiple sources and load balances them among many
destinations
* `SURVEY`
allows one to query state of multiple applications in a single go

Scalability protocols are layered on top of transport layer in the network
stack. At the moment, nanomsg library supports following transports:

### 
* `INPROC`
transport within a process (between threads, modules etc.)
* `IPC`
transport between processes on a single machine
* `TCP`
network transport via TCP

### nn\_socket($domain, $protocol)

    my $s = nn_socket(AF_SP, NN_PAIR);
    die nn_errno unless defined $s;

Creates a nanomsg socket with specified `$domain` and `$protocol`. Returns a
file descriptor for the newly created socket.

Following domains are defined at the moment:

### 
* `AF_SP`
Standard full-blown SP socket.
* `AF_SP_RAW`
Raw SP socket. Raw sockets omit the end-to-end functionality found in `AF_SP`
sockets and thus can be used to implement intermediary devices in SP topologies.

The `$protocol` parameter defines the type of the socket, which in turn
determines the exact semantics of the socket. See ["Protocols"](#protocols) to get the list
of available protocols and their socket types.

The newly created socket is initially not associated with any endpoints. In
order to establish a message flow at least one endpoint has to be added to the
socket using `nn_bind` or `nn_connect`.

Also note that type argument as found in standard `socket` function is omitted
from `nn_socket`. All the SP sockets are message-based and thus of
`SOCK_SEQPACKET` type.

If the function succeeds file descriptor of the new socket is
returned. Otherwise, `undef` is returned and `nn_errno` is set to to one of
the values defined below.

### 
* `EAFNOSUPPORT`
Specified address family is not supported.
* `EINVAL`
Unknown protocol.
* `EMFILE`
The limit on the total number of open SP sockets or OS limit for file
descriptors has been reached.
* `ETERM`
The library is terminating.

Note that file descriptors returned by `nn_socket` function are not standard
file descriptors and will exhibit undefined behaviour when used with system
functions. Moreover, it may happen that a system file descriptor and file
descriptor of an SP socket will incidentally collide (be equal).

### nn\_close($s)

    nn_close($s) or die nn_errno;

Closes the socket `$s`. Any buffered inbound messages that were not yet
received by the application will be discarded. The library will try to deliver
any outstanding outbound messages for the time specified by `NN_LINGER` socket
option. The call will block in the meantime.

If the function succeeds, a true value is returned. Otherwise, `undef` is
returned and `nn_errno` is set to to one of the values defined below.

### 
* `EBADF`
The provided socket is invalid.
* `EINTR`
Operation was interrupted by a signal. The socket is not fully closed
yet. Operation can be re-started by calling `nn_close` again.

### nn\_setsockopt($s, $level, $option, $value)

    nn_setsockopt($s, NN_SOL_SOCKET, NN_LINGER, 1000) or die nn_errno;
    nn_setsockopt($s, NN_SOL_SOCKET, NN_SUB_SUBSCRIBE, 'ABC') or die nn_errno;

Sets the `$value` of the socket option `$option`. The `$level` argument
specifies the protocol level at which the option resides. For generic
socket-level options use the `NN_SOL_SOCKET` level. For socket-type-specific
options use the socket type for the `$level` argument (e.g. `NN_SUB`). For
transport-specific options use the ID of the transport as the `$level` argument
(e.g. `NN_TCP`).

If the function succeeds a true value is returned. Otherwise, `undef` is
returned and `nn_errno` is set to to one of the values defined below.

### 
* `EBADF`
The provided socket is invalid.
* `ENOPROTOOPT`
The option is unknown at the level indicated.
* `EINVAL`
The specified option value is invalid.
* `ETERM`
The library is terminating.

These are the generic socket-level (`NN_SOL_SOCKET` level) options:

### 
* `NN_LINGER`
Specifies how long the socket should try to send pending outbound messages after
`nn_close` has been called, in milliseconds. Negative values mean infinite
linger. The type of the option is int. The default value is 1000 (1 second).
* `NN_SNDBUF`
Size of the send buffer, in bytes. To prevent blocking for messages larger than
the buffer, exactly one message may be buffered in addition to the data in the
send buffer. The type of this option is int. The default value is 128kB.
* `NN_RCVBUF`
Size of the receive buffer, in bytes. To prevent blocking for messages larger
than the buffer, exactly one message may be buffered in addition to the data in
the receive buffer. The type of this option is int. The default value is 128kB.
* `NN_SNDTIMEO`
The timeout for send operation on the socket, in milliseconds. If a message
cannot be sent within the specified timeout, an `EAGAIN` error is
returned. Negative values mean infinite timeout. The type of the option is
int. The default value is -1.
* `NN_RCVTIMEO`
The timeout for recv operation on the socket, in milliseconds. If a message
cannot be received within the specified timeout, an `EAGAIN` error is
returned. Negative values mean infinite timeout. The type of the option is
int. The default value is -1.
* `NN_RECONNECT_IVL`
For connection-based transports such as TCP, this option specifies how long to
wait, in milliseconds, when connection is broken before trying to re-establish
it. Note that actual reconnect interval may be randomised to some extent to
prevent severe reconnection storms. The type of the option is int. The default
value is 100 (0.1 second).
* `NN_RECONNECT_IVL_MAX`
This option is to be used only in addition to `NN_RECONNECT_IVL` option. It
specifies maximum reconnection interval. On each reconnect attempt, the previous
interval is doubled until `NN_RECONNECT_IVL_MAX` is reached. A value of zero
means that no exponential backoff is performed and reconnect interval is based
only on `NN_RECONNECT_IVL`. If `NN_RECONNECT_IVL_MAX` is less than
`NN_RECONNECT_IVL`, it is ignored. The type of the option is int. The default
value is 0.
* `NN_SNDPRIO`
Sets outbound priority for endpoints subsequently added to the socket. This
option has no effect on socket types that send messages to all the
peers. However, if the socket type sends each message to a single peer (or a
limited set of peers), peers with high priority take precedence over peers with
low priority. The type of the option is int. The highest priority is 1, the
lowest priority is 16. The default value is 8.
* `NN_IPV4ONLY`
If set to 1, only IPv4 addresses are used. If set to 0, both IPv4 and IPv6
addresses are used. The default value is 1.

### nn\_getsockopt($s, $level, $option)

    my $linger = unpack 'i', nn_getsockopt($s, NN_SOL_SOCKET, NN_LINGER) || die nn_errno;

Retrieves the value for the socket option `$option`. The `$level` argument
specifies the protocol level at which the option resides. For generic
socket-level options use the `NN_SOL_SOCKET` level. For socket-type-specific
options use the socket type for the `$level` argument (e.g. `NN_SUB`). For
transport-specific options use ID of the transport as the `$level` argument
(e.g. `NN_TCP`).

The function returns a packed string representing the requested socket option,
or `undef` on error, with one of the following reasons for the error placed in
`nn_errno`.

### 
* `EBADF`
The provided socket is invalid.
* `ENOPROTOOPT`
The option is unknown at the `$level` indicated.
* `ETERM`
The library is terminating.

Just what is in the packed string depends on `$level` and `$option`; see the
list of socket options for details; A common case is that the option is an
integer, in which case the result is a packed integer, which you can decode
using `unpack` with the `i` (or `I`) format.

This function can be used to retrieve the values for all the generic
socket-level (`NN_SOL_SOCKET`) options documented in `nn_getsockopt` and also
supports these additional generic socket-level options that can only be
retrieved but not set:

### 
* `NN_DOMAIN`
Returns the domain constant as it was passed to `nn_socket`.
* `NN_PROTOCOL`
Returns the protocol constant as it was passed to `nn_socket`.
* `NN_SNDFD`
Retrieves a file descriptor that is readable when a message can be sent to the
socket. The descriptor should be used only for polling and never read from or
written to. The type of the option is int. The descriptor becomes invalid and
should not be used any more once the socket is closed. This socket option is not
available for unidirectional recv-only socket types.
* `NN_RCVFD`
Retrieves a file descriptor that is readable when a message can be received from
the socket. The descriptor should be used only for polling and never read from
or written to. The type of the option is int. The descriptor becomes invalid and
should not be used any more once the socket is closed. This socket option is not
available for unidirectional send-only socket types.

### nn\_bind($s, $addr)

    my $eid = nn_bind($s, 'inproc://test');
    die nn_errno unless defined $eid;

Adds a local endpoint to the socket `$s`. The endpoint can be then used by other
applications to connect to.

The `$addr` argument consists of two parts as follows:
`transport://address`. The `transport` specifies the underlying transport
protocol to use. The meaning of the `address` part is specific to the
underlying transport protocol.

See ["Transports"](#transports) for a list of available transport protocols.

The maximum length of the `$addr` parameter is specified by `NN_SOCKADDR_MAX`
constant.

Note that `nn_bind` and `nn_connect` may be called multiple times on the same
socket thus allowing the socket to communicate with multiple heterogeneous
endpoints.

If the function succeeds, an endpoint ID is returned. Endpoint ID can be later
used to remove the endpoint from the socket via `nn_shutdown` function.

If the function fails, `undef` is returned and `nn_errno` is set to to one of
the values defined below.

### 
* `EBADF`
The provided socket is invalid.
* `EMFILE`
Maximum number of active endpoints was reached.
* `EINVAL`
The syntax of the supplied address is invalid.
* `ENAMETOOLONG`
The supplied address is too long.
* `EPROTONOSUPPORT`
The requested transport protocol is not supported.
* `EADDRNOTAVAIL`
The requested endpoint is not local.
* `ENODEV`
Address specifies a nonexistent interface.
* `EADDRINUSE`
The requested local endpoint is already in use.
* `ETERM`
The library is terminating.

### nn\_connect($s, $addr)

    my $eid = nn_connect($s, 'inproc://test');
    die nn_errno unless defined $eid;

Adds a remote endpoint to the socket `$s`. The library would then try to
connect to the specified remote endpoint.

The `$addr` argument consists of two parts as follows:
`transport://address`. The `transport` specifies the underlying transport
protocol to use. The meaning of the `address` part is specific to the
underlying transport protocol.

See ["Protocols"](#protocols) for a list of available transport protocols.

The maximum length of the `$addr` parameter is specified by `NN_SOCKADDR_MAX`
constant.

Note that `nn_connect` and `nn_bind` may be called multiple times on the same
socket thus allowing the socket to communicate with multiple heterogeneous
endpoints.

If the function succeeds, an endpoint ID is returned. Endpoint ID can be later
used to remove the endpoint from the socket via `nn_shutdown` function.

If the function fails, `undef` is returned and `nn_errno` is set to to one of
the values defined below.

### 
* `EBADF`
The provided socket is invalid.
* `EMFILE`
Maximum number of active endpoints was reached.
* `EINVAL`
The syntax of the supplied address is invalid.
* `ENAMETOOLONG`
The supplied address is too long.
* `EPROTONOSUPPORT`
The requested transport protocol is not supported.
* `ENODEV`
Address specifies a nonexistent interface.
* `ETERM`
The library is terminating.

### nn\_shutdown($s, $eid)

    nn_shutdown($s, $eid) or die nn_errno;

Removes an endpoint from socket `$s`. The `eid` parameter specifies the ID of
the endpoint to remove as returned by prior call to `nn_bind` or
`nn_connect`.

The `nn_shutdown` call will return immediately. However, the library will try
to deliver any outstanding outbound messages to the endpoint for the time
specified by the `NN_LINGER` socket option.

If the function succeeds, a true value is returned. Otherwise, `undef` is
returned and `nn_errno` is set to to one of the values defined below.

### 
* `EBADF`
The provided socket is invalid.
* `EINVAL`
The how parameter doesn't correspond to an active endpoint.
* `EINTR`
Operation was interrupted by a signal. The endpoint is not fully closed
yet. Operation can be re-started by calling `nn_shutdown` again.
* `ETERM`
The library is terminating.

### nn\_send($s, $data, $flags=0)

    my $bytes_sent = nn_send($s, 'foo');
    die nn_errno unless defined $bytes_sent;

This function will send a message containing the provided `$data` to the socket
`$s`.

`$data` can either be anything that can be used as a byte string in perl or a
message buffer instance allocated by `nn_allocmsg`. In case of a message buffer
instance the instance will be deallocated and invalidated by the `nn_send`
function. The buffer will be an instance of `NanoMsg::Raw::Message::Freed`
after the call to `nn_send`.

Which of the peers the message will be sent to is determined by the particular
socket type.

The `$flags` argument, which defaults to `0`, is a combination of the flags
defined below:

### 
* `NN_DONTWAIT`
Specifies that the operation should be performed in non-blocking mode. If the
message cannot be sent straight away, the function will fail with `nn_errno`
set to `EAGAIN`.

If the function succeeds, the number of bytes in the message is
returned. Otherwise, a `undef` is returned and `nn_errno` is set to to one of
the values defined below.

### 
* `EBADF`
The provided socket is invalid.
* `ENOTSUP`
The operation is not supported by this socket type.
* `EFSM`
The operation cannot be performed on this socket at the moment because the
socket is not in the appropriate state. This error may occur with socket types
that switch between several states.
* `EAGAIN`
Non-blocking mode was requested and the message cannot be sent at the moment.
* `EINTR`
The operation was interrupted by delivery of a signal before the message was
sent.
* `ETIMEDOUT`
Individual socket types may define their own specific timeouts. If such timeout
is hit, this error will be returned.
* `ETERM`
The library is terminating.

### nn\_recv($s, $data, $length=NN\_MSG, $flags=0)

    my $bytes_received = nn_recv($s, my $buf, 256);
    die nn_errno unless defined $bytes_received;

Receive a message from the socket `$s` and store it in the buffer `$buf`. Any
bytes exceeding the length specified by the `$length` argument will be
truncated.

Alternatively, `nn_recv` can allocate a message buffer instance for you. To do
so, set the `$length` parameter to `NN_MSG` (the default).

The `$flags` argument, which defaults to `0`, is a combination of the flags
defined below:

### 
* `NN_DONTWAIT`
Specifies that the operation should be performed in non-blocking mode. If the
message cannot be received straight away, the function will fail with
`nn_errno` set to `EAGAIN`.

If the function succeeds number of bytes in the message is returned. Otherwise,
`undef` is returned and `nn_errno` is set to to one of the values defined
below.

### 
* `EBADF`
The provided socket is invalid.
* `ENOTSUP`
The operation is not supported by this socket type.
* `EFSM`
The operation cannot be performed on this socket at the moment because socket is
not in the appropriate state. This error may occur with socket types that switch
between several states.
* `EAGAIN`
Non-blocking mode was requested and there's no message to receive at the moment.
* `EINTR`
The operation was interrupted by delivery of a signal before the message was
received.
* `ETIMEDOUT`
Individual socket types may define their own specific timeouts. If such timeout
is hit this error will be returned.
* `ETERM`
The library is terminating.

### nn\_sendmsg($s, $flags, $data1, $data2, ..., $dataN)

    my $bytes_sent = nn_sendmsg($s, 0, 'foo', 'bar');
    die nn_errno unless defined $bytes_sent;

This function is a fine-grained alternative to `nn_send`. It allows sending
multiple data buffers that make up a single message without having to create
another temporary buffer to hold the concatenation of the different message
parts.

The scalars containing the data to be sent (`$data1`, `$data2`, ...,
`$dataN`) can either be anything that can be used as a byte string in perl or a
message buffer instance allocated by `nn_allocmsg`. In case of a message buffer
instance the instance will be deallocated and invalidated by the `nn_sendmsg`
function. The buffers will be a instances of `NanoMsg::Raw::Message::Freed`
after the call to `nn_sendmsg`.

When using message buffer instances, only one buffer may be provided.

To which of the peers will the message be sent to is determined by the
particular socket type.

The `$flags` argument is a combination of the flags defined below:

### 
* `NN_DONTWAIT`
Specifies that the operation should be performed in non-blocking mode. If the
message cannot be sent straight away, the function will fail with `nn_errno`
set to `EAGAIN`.

If the function succeeds number of bytes in the message is returned. Otherwise,
`undef` is returned and `nn_errno` is set to to one of the values defined
below.

### 
* `EBADF`
The provided socket is invalid.
* `ENOTSUP`
The operation is not supported by this socket type.
* `EFSM`
The operation cannot be performed on this socket at the moment because socket is
not in the appropriate state. This error may occur with socket types that switch
between several states.
* `EAGAIN`
Non-blocking mode was requested and the message cannot be sent at the moment.
* `EINTR`
The operation was interrupted by delivery of a signal before the message was
sent.
* `ETIMEDOUT`
Individual socket types may define their own specific timeouts. If such timeout
is hit this error will be returned.
* `ETERM`
The library is terminating.

In the future, `nn_sendmsg` might allow for sending along additional control
data.

### nn\_recvmsg($s, $flags, $data1 => $len1, $data2 => $len2, ..., $dataN => $lenN)

    my $bytes_received = nn_recvmsg($s, 0, my $buf1 => 256, my $buf2 => 1024);
    die nn_errno unless defined $bytes_received;

This function is a fine-grained alternative to `nn_recv`. It allows receiving a
single message into multiple data buffers of different sizes, eliminating the
need to create copies of part of the received message in some cases.

The scalars in which to receive the message data (`$buf1`, `$buf2`, ...,
`$bufN`) will be filled with as many bytes of data as is specified by the
length parameter following them in the argument list (`$len1`, `$len2`, ...,
`$lenN`).

Alternatively, `nn_recvmsg` can allocate a message buffer instance for you. To
do so, set the length parameter of a buffer to to `NN_MSG`. In this case, only
one receive buffer can be provided.

The `$flags` argument is a combination of the flags defined below:

### 
* `NN_DONTWAIT`
Specifies that the operation should be performed in non-blocking mode. If the
message cannot be received straight away, the function will fail with
`nn_errno` set to `EAGAIN`.

In the future, `nn_recvmsg` might allow for receiving additional control data.

### nn\_allocmsg($size, $type)

    my $msg = nn_allocmsg(3, 0) or die nn_errno;
    $msg->copy('foo');
    nn_send($s, $msg);

Allocate a message of the specified `$size` to be sent in zero-copy
fashion. The content of the message is undefined after allocation and it should
be filled in by the user. While `nn_send` and `nn_sendmsg` allow to send
arbitrary buffers, buffers allocated using `nn_allocmsg` can be more efficient
for large messages as they allow for using zero-copy techniques.

The `$type` parameter specifies type of allocation mechanism to use. Zero is
the default one. However, individual transport mechanisms may define their own
allocation mechanisms, such as allocating in shared memory or allocating a
memory block pinned down to a physical memory address. Such allocation, when
used with the transport that defines them, should be more efficient than the
default allocation mechanism.

If the function succeeds a newly allocated message buffer instance (an object
instance of the class [NanoMsg::Raw::Message](https://metacpan.org/pod/NanoMsg::Raw::Message)) is returned. Otherwise, `undef`
is returned and `nn_errno` is set to to one of the values defined below.

### 
* `EINVAL`
Supplied allocation type is invalid.
* `ENOMEM`
Not enough memory to allocate the message.

### nn\_errno()

Returns value of `errno` after the last call to any nanomsg function in the
current thread. This function can be used in the same way the `$!` global
variable is be used for many other system and library calls.

The return value can be used in numeric context, for example to compare it with
error code constants such as `EAGAIN`, or in a string context, to retrieve a
textual message describing the error.

### nn\_strerror($errno)

Returns a textual representation of the error described by the nummeric
`$errno` provided. It shouldn't normally be necessary to ever call this
function, as using `nn_errno` in string context is basically equivalent to
`nn_strerror(nn_errno)`.

### nn\_device($s1, $s2)

    nn_device($s1, $s2) or die;

Starts a device to forward messages between two sockets. If both sockets are
valid, the `nn_device` function loops and sends and messages received from
`$s1` to `$s2` and vice versa. If only one socket is valid and the other is
`undef`, `nn_device` works in a loopback mode - it loops and sends any
messages received from the socket back to itself.

The function loops until it hits an error. In such case it returns `undef` and
sets `nn_errno` to one of the values defined below.

### 
* `EBADF`
One of the provided sockets is invalid.
* `EINVAL`
Either one of the socket is not an `AF_SP_RAW` socket; or the two sockets don't
belong to the same protocol; or the directionality of the sockets doesn't fit
(e.g. attempt to join two SINK sockets to form a device).
* `EINTR`
The operation was interrupted by delivery of a signal.
* `ETERM`
The library is terminating.

### nn\_term()

    nn_term();

To help with shutdown of multi-threaded programs the `nn_term` function is
provided. It informs all the open sockets that process termination is underway.

If a socket is blocked inside a blocking function, such as `nn_recv`, it will
be unblocked and the `ETERM` error will be returned to the user. Similarly, any
subsequent attempt to invoke a socket function other than `nn_close` after
`nn_term` was called will result in an `ETERM` error.

If waiting for `NN_SNDFD` or `NN_RCVFD` using a polling function, such as
`poll` or `select`, the call will unblock with both `NN_SNDFD` and
`NN_RCVFD` signaled.

The `nn_term` function itself is non-blocking.

# Protocols

## One-to-one protocol

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

### Socket Types

### 
* `NN_PAIR`
Socket for communication with exactly one peer. Each party can send messages at
any time. If the peer is not available or send buffer is full subsequent calls
to `nn_send` will block until it's possible to send the message.

### Socket Options

No protocol-specific socket options are defined at the moment.

## Request/reply protocol

This protocol is used to distribute the workload among multiple stateless workers.

### Socket Types

### 
* `NN_REQ`
Used to implement the client application that sends requests and receives
replies.
* `NN_REP`
Used to implement the stateless worker that receives requests and sends replies.

### Socket Options

### 
* `NN_REQ_RESEND_IVL`
This option is defined on the full REQ socket. If a reply is not received in
specified amount of milliseconds, the request will be automatically resent. The
type of this option is int. Default value is 60000 (1 minute).

## Publish/subscribe protocol

Broadcasts messages to multiple destinations.

### Socket Types

### 
* `NN_PUB`
This socket is used to distribute messages to multiple destinations. Receive
operation is not defined.
* `NN_SUB`
Receives messages from the publisher. Only messages that the socket is
subscribed to are received. When the socket is created there are no
subscriptions and thus no messages will be received. Send operation is not
defined on this socket.

### Socket Options

### 
* `NN_SUB_SUBSCRIBE`
Defined on full SUB socket. Subscribes for a particular topic. Type of the
option is string.
* `NN_SUB_UNSUBSCRIBE`
Defined on full SUB socket. Unsubscribes from a particular topic. Type of the
option is string.

## Survey protocol

Allows one to broadcast a survey to multiple locations and gather the responses.

### Socket Types

### 
* `NN_SURVEYOR`
Used to send the survey. The survey is delivered to all the connected
respondents. Once the query is sent, the socket can be used to receive the
responses. When the survey deadline expires, receive will return the
`ETIMEDOUT` error.
* `NN_RESPONDENT`
Use to respond to the survey. Survey is received using receive function,
response is sent using send function. This socket can be connected to at most
one peer.

### Socket Options

### 
* `NN_SURVEYOR_DEADLINE`
Specifies how long to wait for responses to the survey. Once the deadline
expires, receive function will return the `ETIMEDOUT` error and all subsequent
responses to the survey will be silently dropped. The deadline is measured in
milliseconds. Option type is int. Default value is 1000 (1 second).

## Pipeline protocol

Fair queues messages from the previous processing step and load balances them
among instances of the next processing step.

### Socket Types

### 
* `NN_PUSH`
This socket is used to send messages to a cluster of load-balanced
nodes. Receive operation is not implemented on this socket type.
* `NN_PULL`
This socket is used to receive a message from a cluster of nodes. Send operation
is not implemented on this socket type.

### Socket Options

No protocol-specific socket options are defined at the moment.

## Message bus protocol

Broadcasts messages from any node to all other nodes in the topology. The socket
should never receives messages that it sent itself.

This pattern scales only to local level (within a single machine or within a
single LAN). Trying to scale it further can result in overloading individual
nodes with messages.

**WARNING**: For bus topology to function correctly, the user is responsible for
ensuring that path from each node to any other node exists within the topology.

Raw (`AF_SP_RAW`) BUS socket never send the message to the peer it was received
from.

### Socket Types

### 
* `NN_BUS`
Sent messages are distributed to all nodes in the topology. Incoming messages
from all other nodes in the topology are fair-queued in the socket.

### Socket Options

There are no options defined at the moment.

# Transports

## In-process transport

The in-process transport allows one to send messages between threads or modules inside a
process. In-process address is an arbitrary case-sensitive string preceded by
`inproc://` protocol specifier. All in-process addresses are visible from any
module within the process. They are not visible from outside of the process.

The overall buffer size for an inproc connection is determined by the
`NN_RCVBUF` socket option on the receiving end of the connection. The
`NN_SNDBUF` socket option is ignored. In addition to the buffer, one message of
arbitrary size will fit into the buffer. That way, even messages larger than the
buffer can be transferred via inproc connection.

This transport's ID is `NN_INPROC`.

## Inter-process transport

The inter-process transport allows for sending messages between processes within
a single box. The implementation uses native IPC mechanism provided by the local
operating system and the IPC addresses are thus OS-specific.

On POSIX-compliant systems, UNIX domain sockets are used and IPC addresses are
file references. Note that both relative (`ipc://test.ipc`) and absolute
(`ipc:///tmp/test.ipc`) paths may be used. Also note that access rights on the
IPC files must be set in such a way that the appropriate applications can
actually use them.

On Windows, named pipes are used for IPC. IPC address is an arbitrary
case-insensitive string containing any character except for
backslash. Internally, address `ipc://test` means that named pipe
`\\.\pipe\test` will be used.

This transport's ID is `NN_IPC`.

## TCP transport

The TCP transport allows for passing message over the network using simple
reliable one-to-one connections. TCP is the most widely used transport protocol,
it is virtually ubiquitous and thus the transport of choice for communication
over the network.

When binding a TCP socket address of the form `tcp://interface:port` should be
used. Port is the TCP port number to use. Interface is one of the following
(optionally placed within square brackets):

### 
* Asterisk character (\*) meaning all local network interfaces.
* IPv4 address of a local network interface in numeric form (192.168.0.111).
* IPv6 address of a local network interface in numeric form (::1).
* Interface name, as defined by operating system.

When connecting a TCP socket address of the form `tcp://interface;address:port`
should be used. Port is the TCP port number to use. Interface is optional and
specifies which local network interface to use. If not specified, OS will select
an appropriate interface itself. If specified it can be one of the following
(optionally placed within square brackets):

### 
* IPv4 address of a local network interface in numeric form (192.168.0.111).
* IPv6 address of a local network interface in numeric form (::1).
* Interface name, as defined by operating system (eth0).

Finally, address specifies the remote address to connect to. It can be one of
the following (optionally placed within square brackets):

### 
* IPv4 address of a remote network interface in numeric form (192.168.0.111).
* IPv6 address of a remote network interface in numeric form (::1).
* The DNS name of the remote box.

This transport's ID is `NN_TCP`.

### Socket Options

### 
* `NN_TCP_NODELAY`
This option, when set to 1, disables Nagle's algorithm. It also disables
delaying of TCP acknowledgments. Using this option improves latency at the
expense of throughput. Type of this option is int. The default value is 0.

# Constants

In addition to all the error constants and `NN_` constants used in the
documentation of the individual functions, protocols, and transports, the
following constants are available:

### 
* `NN_VERSION_CURRENT`
The current interface version.
* `NN_VERSION_REVISION`
The latest revision of the current interface.
* `NN_VERSION_AGE`
How many past interface versions are still supported.

# SEE ALSO

### 
* The nanomsg C library documentation at [http://nanomsg.org/v0.1/nanomsg.7.html](http://nanomsg.org/v0.1/nanomsg.7.html)
The API this module provides is very close to the C library's interface, so the
C documentation is likely to be useful to developers using Perl,
too. Additionally, most of this module's documentation is copied from the C
library documentation, so the upstream documentation might be somewhat more
recent.
* [NanoMsg::Raw::Message](https://metacpan.org/pod/NanoMsg::Raw::Message)
