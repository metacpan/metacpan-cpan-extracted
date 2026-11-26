# NAME

Net::Tools - socket and network functions, split from Data::Tools

# SYNOPSIS

    use Net::Tools::Socket;            # socket I/O, length-prefixed messages
    use Net::Tools::Socket::Protocols; # serialized messages
    use Net::Tools::Socket::Pair;      # non-blocking messages over socketpair()
    use Net::Tools::Socket::Err;       # $SOCK_ERR, $SOCK_ERRSTR, SOCK_E_*

# DESCRIPTION

Net::Tools itself has no functions, it only holds the package version. The
functions are in the sub-modules:

    * Net::Tools::Socket               (socket I/O, length-prefixed messages)
    * Net::Tools::Socket::Protocols    (serialized messages over Net::Tools::Socket)
    * Net::Tools::Socket::Pair         (non-blocking messages over socketpair())
    * Net::Tools::Socket::Err          (error codes shared by the socket modules)

Up to version 1.55 these modules were part of Data::Tools as
Data::Tools::Socket, Data::Tools::Socket::Protocols,
Data::Tools::Socket::Pair and Data::Tools::Socket::Err. Only the package
names changed, replace "Data::Tools::Socket" with "Net::Tools::Socket".

# REQUIRED MODULES

    * Data::Tools (Net::Tools::Socket::Protocols only)

# GITHUB REPOSITORY

    git@github.com:cade-vs/perl-net-tools.git

    git clone https://github.com/cade-vs/perl-net-tools.git

# AUTHOR

    Vladi Belperchinov-Shabanski "Cade"
          <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
    http://cade.noxrun.com/
# NAME

Net::Tools::Socket - set of socket I/O functions

# SYNOPSIS

    use Net::Tools::Socket qw( :all );  # import all functions
    use Net::Tools::Socket;             # the same as :all :)
    use Net::Tools::Socket qw( :none ); # do not import anything, use full package names

    # --------------------------------------------------------------------------

    my $read_res_len  = socket_read(  $socket, $data_ref, $length, $timeout );
    my $write_res_len = socket_write( $socket, $data,     $length, $timeout );
    my $write_res_len = socket_print( $socket, $data, $timeout );

    # --------------------------------------------------------------------------

    my $read_data = socket_read_message(  $socket, $timeout, $maxlen );
    my $write_res = socket_write_message( $socket, $data, $timeout );

    # --------------------------------------------------------------------------

    # error details, see ERRORS
    use Net::Tools::Socket::Err;
    print "error: $SOCK_ERRSTR\n" unless defined $read_data;

    # --------------------------------------------------------------------------

# FUNCTIONS

## socket\_read(  $socket, $data\_ref, $length, $timeout )

Reads $length sized data from the $socket and stores it to $data\_ref scalar
reference.

Returns read length, which is always the requested $length, or undef on
timeout, end of file or error, see ["ERRORS"](#errors). On undef, $data\_ref may hold
the partially read data.

$timeout is optional, it is in seconds and can be less than 1 second.
If $timeout is undef (not given) it waits forever, if it is 0 it does not
wait at all, only checks once if the socket is ready.

$timeout limits each wait for the socket to become ready, the total time
is checked only after each wait, so one call may take up to about twice
$timeout when the data arrives slowly in parts.

## socket\_write( $socket, $data,     $length, $timeout )

Writes $length sized data from $data scalar to the $socket. If $length is
larger than the length of $data, or $data contains wide (over 255) characters (encode it
first), nothing is written and undef is returned with SOCK\_E\_INVAL.

Returns write length, which is always the requested $length, or undef on
timeout, closed peer or error, see ["ERRORS"](#errors). On undef, part of the data may
already be sent.

WARNING! Writing to a socket closed by the peer raises SIGPIPE, which kills
the process by default. This module does not touch signals, handling them
is the caller's responsibility. Set, once at program start:

    $SIG{ 'PIPE' } = 'IGNORE';

then such writes fail with $SOCK\_ERR set to SOCK\_E\_EOF instead.

$timeout is optional, it is in seconds and can be less than 1 second.
If $timeout is undef (not given) it waits forever, if it is 0 it does not
wait at all, only checks once if the socket is ready.

$timeout limits each wait for the socket to become writable, the total time
is checked only after each wait, so one call may take up to about twice
$timeout when the peer reads slowly.

## socket\_print( $socket, $data, $timeout )

Same as socket\_write() but calculates requested length from the $data scalar.

WARNING! SIGPIPE on closed peer, see socket\_write().

$timeout is optional, it is in seconds and can be less than 1 second.
If $timeout is undef (not given) it waits forever, if it is 0 it does not
wait at all, only checks once if the socket is ready.

See socket\_write() for how $timeout is applied.

## socket\_read\_message(  $socket, $timeout, $maxlen )

Reads 32bit network-order integer, which then is used as data size to be read
from the socket (i.e. message = 32bit-integer + data ).

Returns the read data, "" for an empty message, or undef on error with
$SOCK\_ERR set (see ["ERRORS"](#errors)):

    SOCK_E_EOF       peer closed, also in the middle of a message
    SOCK_E_TIMEOUT   $timeout expired
    SOCK_E_TOOBIG    message length is over $maxlen
    errno            system call failed (EBADF, etc.)

For a closed handle, or one without a real file descriptor, it returns
undef and $SOCK\_ERR is not set, see socket\_can\_read().

On any error after the first byte of the length was read (a timeout, EOF or
system error in the middle of the 4 length bytes, SOCK\_E\_TOOBIG, or an
error while reading the message data), the rest of the message is left
unread, so the socket stream is out of sync and cannot be used anymore:
the caller must close the socket and reconnect. With $timeout 0 this happens
whenever the message has not fully arrived yet.

$timeout is optional, it is in seconds and can be less than 1 second.
If $timeout is undef (not given) it waits forever, if it is 0 it does not
wait at all, only checks once if the socket is ready.

$timeout limits each of the two socket\_read() calls (length and data)
separately, see socket\_read() for how $timeout is applied.

$maxlen is optional, if it is not given, 0 or negative, the default is used.
The default and the maximum are 2\*\*32-1 (0xFFFFFFFF).

## socket\_write\_message( $socket, $data, $timeout )

Writes 32bit network-order integer, which is the size of the given $data to be
written to the $socket and then writes the data
(i.e. message = 32bit-integer + data ).

Messages up to $Net::Tools::Socket::WRITE\_MESSAGE\_JOIN\_MAX bytes (length +
data, 64 KiB by default) are sent with one socket\_write() call. Bigger ones
are sent with two socket\_write() calls (the length and the data), so a big
$data is not copied. A separate small write of the length would stall every
small message on TCP for about 40 ms (Nagle algorithm and delayed ACK).

NOTE: messages longer than $WRITE\_MESSAGE\_JOIN\_MAX are split into two
socket\_write() calls, the 4 bytes length is written alone first. On TCP
without TCP\_NODELAY, each such message may still stall once for about 40 ms.
This is small compared to the time to send that much data, but if many long
messages are exchanged, set TCP\_NODELAY on the socket:

    use Socket qw( IPPROTO_TCP TCP_NODELAY );
    setsockopt( $socket, IPPROTO_TCP, TCP_NODELAY, 1 );

or raise $Net::Tools::Socket::WRITE\_MESSAGE\_JOIN\_MAX, at the cost of
copying the data of each message up to that size.

On any error after the first byte was written (a timeout, closed peer or
system error in the middle of the length or of the data), only part of the
message is sent, so the socket stream is out of sync and cannot be used
anymore: the caller must close the socket and reconnect. With $timeout 0
this happens whenever the peer does not read fast enough.

Returns 1 on success or undef for message or network error, see ["ERRORS"](#errors).
$data must not contain wide (over 255) characters, encode it first,
otherwise undef is returned with SOCK\_E\_INVAL. An empty or undef $data is
sent as an empty message, which socket\_read\_message() returns as "".
$data larger than 4 GiB - 1 (2\*\*32 - 1) bytes does not fit the 32bit length,
nothing is written and undef is returned with SOCK\_E\_TOOBIG.

WARNING! SIGPIPE on closed peer, see socket\_write().

$timeout is optional, it is in seconds and can be less than 1 second.
If $timeout is undef (not given) it waits forever, if it is 0 it does not
wait at all, only checks once if the socket is ready.

$timeout limits each socket\_write() call separately (one or two, see above),
see socket\_write() for how $timeout is applied.

## socket\_can\_read( $socket, $timeout ) / socket\_can\_write( $socket, $timeout )

Return 1 if the $socket is ready for reading/writing within $timeout, 0 on
timeout ($SOCK\_ERR is SOCK\_E\_TIMEOUT), undef on error ($SOCK\_ERR is errno).

If the $socket is closed or has no real file descriptor (fileno() is undef
or -1, for example an in-memory handle), they return undef at once and
$SOCK\_ERR is not set, since such a handle cannot be read from or written to.

$timeout is in seconds and can be less than 1 second. If $timeout is undef
(not given) it waits forever, if it is 0 it does not wait at all, only
checks once if the socket is ready.

# ERRORS

All functions clear $SOCK\_ERR and $SOCK\_ERRSTR on entry and set them on
failure, except for a closed handle, see socket\_can\_read(). $SOCK\_ERR is a
negative SOCK\_E\_\* code, or the positive errno value if a system call failed
(except EPIPE and ECONNRESET, which are reported as SOCK\_E\_EOF), and
$SOCK\_ERRSTR is its text:

    SOCK_E_EOF       peer closed (also EPIPE and ECONNRESET)
    SOCK_E_TIMEOUT   $timeout expired
    SOCK_E_TOOBIG    message over $maxlen, or $data over 2**32-1 bytes
    SOCK_E_INVAL     $length larger than $data, or wide characters in $data
    errno            any other system error, the positive errno value,
                     its text is in $SOCK_ERRSTR

$SOCK\_ERR and $SOCK\_ERRSTR are exported by [Net::Tools::Socket::Err](https://metacpan.org/pod/Net%3A%3ATools%3A%3ASocket%3A%3AErr),
which must be used by the caller to read them:

    use Net::Tools::Socket::Err;

    my $data = socket_read_message( $socket, $timeout );
    print "error: $SOCK_ERRSTR\n" if $SOCK_ERR;

The error state describes the last call only, read it right after the call.

# TODO

    * more docs

# REQUIRED MODULES

Net::Tools::Socket uses:

    * Time::HiRes
    * Net::Tools::Socket::Err

# GITHUB REPOSITORY

    git@github.com:cade-vs/perl-net-tools.git

    git clone https://github.com/cade-vs/perl-net-tools.git

# AUTHOR

    Vladi Belperchinov-Shabanski "Cade"
          <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
    http://cade.noxrun.com/

# COPYRIGHT AND LICENSE

Copyright (c) 2013-2026 Vladi Belperchinov-Shabanski "Cade"

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.
# NAME

Net::Tools::Socket::Protocols - transparent serialization on top of the Net::Tools::Socket message functions

# SYNOPSIS

    use Net::Tools::Socket::Protocols qw( :all );  # import all functions
    use Net::Tools::Socket::Protocols;             # the same as :all :)
    use Net::Tools::Socket::Protocols qw( :none ); # do not import anything

    # --------------------------------------------------------------------------

    # send a hash reference, serialized with the 'j'son protocol
    socket_protocol_write_message( $socket, 'j', $hash_ref, $timeout );

    # read it back, the protocol type is taken from the message itself
    my $hash_ref = socket_protocol_read_message( $socket, $timeout, $maxlen );

    # in list context the protocol type is returned too, to reply in the same type
    my ( $hash_ref, $ptype ) = socket_protocol_read_message( $socket, $timeout );

    # error details
    use Net::Tools::Socket::Err;
    print "error: $SOCK_ERRSTR\n" unless defined $hash_ref;

    # the 'b'inary protocol carries plain data instead of a hash reference
    socket_protocol_write_message( $socket, 'b', $raw_data, $timeout );

    # --------------------------------------------------------------------------

    # restrict which protocol types will be accepted and sent
    socket_protocols_allow( 'bjh' );      # only binary, json and hash
    socket_protocols_allow( 'b', 'jh' );  # the same, arguments are concatenated
    socket_protocols_allow( '*' );        # all types again, except 'p' Storable
    socket_protocols_allow( '*p' );       # really all types, including Storable

    # --------------------------------------------------------------------------

# PROTOCOL TYPES

A protocol type is a single character, sent as the first byte of every
message. The rest of the message is the payload, serialized accordingly:

    'b'  binary,        payload is plain data, not a hash reference
    'p'  Storable       (nfreeze/thaw), forbidden by default, see below
    'e'  Sereal
    's'  Data::Stacker
    'j'  JSON
    'h'  hash2str()     from Data::Tools, needs no extra module
    'H'  hash2str_url() from Data::Tools, needs no extra module

Except for 'b', the payload is always a hash reference.

The module needed by a protocol type is loaded on demand, the first time
that type is actually used, so a missing module is only a problem if the
corresponding protocol type is used. 'b', 'h' and 'H' need no extra module.

'p' Storable is not safe on untrusted input, so it is forbidden by default
and is not allowed by '\*' either. It must be allowed explicitly with
socket\_protocols\_allow(), only when both peers are trusted.

    NOTE: Storable is a core module and JSON is already required by
          Data::Tools, so those modules are always installed ('p' still
          has to be allowed first). Sereal and Data::Stacker are not
          required by this distribution and may need to be installed
          separately.

# FUNCTIONS

## socket\_protocol\_write\_message( $socket, $ptype, $data, $timeout )

Serializes $data according to the $ptype protocol type, prefixes it with the
protocol type character and sends it with socket\_write\_message().

$data must be a hash reference, unless $ptype is 'b', in which case it is
plain data (a string, not a reference).

$timeout is passed to socket\_write\_message(), see [Net::Tools::Socket](https://metacpan.org/pod/Net%3A%3ATools%3A%3ASocket).

Returns 1 on success or undef if the message could not be sent, with
$SOCK\_ERR set (see ["ERRORS"](#errors)):

    SOCK_E_PROTO   $ptype is not a single known and allowed protocol type,
                   or serializing failed (including a missing serializer
                   module), details in $SOCK_ERRSTR
    SOCK_E_INVAL   $data is not a hash reference for a non-binary protocol
                   type, or is a reference or has wide characters for 'b'
    ...            any socket_write_message() error

On a socket\_write\_message() error the stream may be out of sync, see
[Net::Tools::Socket](https://metacpan.org/pod/Net%3A%3ATools%3A%3ASocket).

WARNING! Writing to a socket closed by the peer raises SIGPIPE, which kills
the process by default. The caller must set `$SIG{ 'PIPE' } = 'IGNORE'`,
see socket\_write() in [Net::Tools::Socket](https://metacpan.org/pod/Net%3A%3ATools%3A%3ASocket).

## socket\_protocol\_read\_message( $socket, $timeout, $maxlen )

Reads a message with socket\_read\_message(), takes the protocol type from its
first byte and deserializes the rest accordingly.

$timeout and $maxlen are passed to socket\_read\_message(), see
[Net::Tools::Socket](https://metacpan.org/pod/Net%3A%3ATools%3A%3ASocket). $maxlen limits the whole message, including the
protocol type byte.

Returns the deserialized hash reference, or the plain data for 'b' ("" if
the 'b' message has no payload), or undef on error with $SOCK\_ERR set (see
["ERRORS"](#errors)):

    SOCK_E_EMPTY   the message is empty, it has no protocol type byte
    SOCK_E_PROTO   the protocol type is not known or not allowed, or the
                   payload does not deserialize into a hash reference
                   (including an empty payload and a missing deserializer
                   module), details in $SOCK_ERRSTR
    ...            any socket_read_message() error

After SOCK\_E\_EMPTY and SOCK\_E\_PROTO the socket stream is still in sync (the
whole message was read), so the socket may be used further.

In list context it returns the data and the protocol type character of the
message, for example to reply in the same protocol type:

    my ( $hash_ref, $ptype ) = socket_protocol_read_message( $socket, $timeout );
    socket_protocol_write_message( $socket, $ptype, $reply_ref, $timeout ) if $hash_ref;

On error it returns a single undef in list context too, so both $hash\_ref
and $ptype are undef.

NOTE: arguments of a function without a prototype, such as Test::More's
is\_deeply(), are evaluated in list context, use scalar() there to get the
data only.

## socket\_protocols\_allow( @protocol\_types )

Sets which protocol types will be accepted and sent, replacing the previous
set. The arguments are concatenated and then split into single characters,
so these are the same:

    socket_protocols_allow( 'bjh' );
    socket_protocols_allow( 'b', 'j', 'h' );

'\*' stands for all known protocol types except 'p'. It replaces everything
before it, so 'j\*' is the same as '\*', and types after it are added, so
'\*p' allows all types including 'p'.

Called with no arguments (or only empty strings) it forbids all protocol
types, no message can be sent or accepted until it is called again.

By default all protocol types except 'p' are allowed.

Returns 1. Confesses if an unknown protocol type is given, in which case
the allowed set is not changed.

# ERRORS

Both read and write functions clear $SOCK\_ERR and $SOCK\_ERRSTR on entry and
set them on failure. They are exported by [Net::Tools::Socket::Err](https://metacpan.org/pod/Net%3A%3ATools%3A%3ASocket%3A%3AErr), which
must be used by the caller to read them. See also [Net::Tools::Socket](https://metacpan.org/pod/Net%3A%3ATools%3A%3ASocket).

# REQUIRED MODULES

Net::Tools::Socket::Protocols uses:

    * Data::Tools
    * Net::Tools::Socket
    * Net::Tools::Socket::Err

and, on demand and only for the corresponding protocol types:

    * Storable, Sereal, Data::Stacker, JSON

# GITHUB REPOSITORY

    git@github.com:cade-vs/perl-net-tools.git

    git clone https://github.com/cade-vs/perl-net-tools.git

# AUTHOR

    Vladi Belperchinov-Shabanski "Cade"
          <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
    http://cade.noxrun.com/

# COPYRIGHT AND LICENSE

Copyright (c) 2013-2026 Vladi Belperchinov-Shabanski "Cade"

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.
# NAME

Net::Tools::Socket::Pair - non-blocking message passing over socketpair()

# SYNOPSIS

    use Net::Tools::Socket::Pair;
    use Net::Tools::Socket::Err; # only if error details are needed

    my ( $parent_sock, $child_sock ) = socketpair_create()
        or die "socketpair: $SOCK_ERRSTR\n";

    # sender
    my $res = socketpair_send( $parent_sock, $message_bytes );
    # retry later if $SOCK_ERR == SOCK_E_AGAIN

    # receiver, read all pending messages
    my $data;
    while( socketpair_recv( $child_sock, \$data ) )
      {
      # one complete message is in $data
      }
    # peer closed if $SOCK_ERR == SOCK_E_EOF

# DESCRIPTION

Message passing over `socketpair( AF_UNIX, SOCK_SEQPACKET )` or
`socketpair( AF_UNIX, SOCK_DGRAM )`, see ["SOCKET TYPES"](#socket-types). Each
`socketpair_send()` is received by exactly one `socketpair_recv()` on the
other side, always as a whole message. Messages are byte strings, data
structures must be serialized before sending.

`socketpair_send()` and `socketpair_recv()` never sleep, regardless of
the blocking mode of the handle (`MSG_DONTWAIT` is used on every call), and
never raise `SIGPIPE` (`MSG_NOSIGNAL` is used, where the system does not
have it, SIGPIPE is ignored only for the time of the send() call, the
caller's `$SIG{ 'PIPE' }` is restored). They return:

    1      one whole message sent or received successfully
    0      nothing to read or peer's queue is full (SOCK_E_AGAIN), message
           too big (SOCK_E_TOOBIG), invalid message or system error
           those are considered temporary and operation should be repeated
    undef  peer closed (SOCK_E_EOF), for recv after all queued messages
           were read, socket must be closed

So the result is true only for a message, false for "nothing now", and
undef when the peer is gone, which allows:

    while( socketpair_recv( $fh, \$data ) ) { ... }       # read all pending
    if( ! defined socketpair_recv( $fh, \$data ) ) { ... } # peer closed

The reason for 0 or undef is in `$SOCK_ERR`, see ["ERRORS"](#errors).

`socketpair_recv()` sets `$data` to undef whenever the result is not 1,
so a stale value is never left there.

Empty or undef messages are not sent, `socketpair_send()` returns 0 with
`SOCK_E_EMPTY`, because the peer would read an empty message as end of
file.

Maximum message size is `$Net::Tools::Socket::Pair::MSG_MAX` (128 KiB by
default).

All functions are exported by default.

# SOCKET TYPES

    my ( $s1, $s2 ) = socketpair_create();            # SOCK_SEQPACKET
    my ( $s1, $s2 ) = socketpair_create( 'dgram' );   # SOCK_DGRAM

The type is 'seqpacket' (the default) or 'dgram', case insensitive. An
unknown type returns an empty list with `SOCK_E_INVAL`.

Both keep message boundaries, never drop messages (a full queue returns
`SOCK_E_AGAIN` to the sender) and hold about the same count of messages.
They differ only when the peer closes:

    seqpacket  recv returns undef (SOCK_E_EOF) after all queued messages are
               read, poll() reports POLLHUP, send returns undef (SOCK_E_EOF)

    dgram      recv never returns EOF, it returns 0 (SOCK_E_AGAIN) forever,
               poll() reports nothing, only send returns undef (SOCK_E_EOF)

So with 'dgram' a receiver which never sends must find out that its peer
is gone in another way (getppid(), waitpid(), etc.). On the other hand,
a 'dgram' handle may be shared by many processes writing to one reader,
which never sees EOF while any of them is still writing.

# ERRORS

All functions clear `$SOCK_ERR` and `$SOCK_ERRSTR` on entry and set them
when the result is not 1:

    SOCK_E_AGAIN    nothing to read, or peer's queue is full
    SOCK_E_EOF      peer closed
    SOCK_E_TOOBIG   message over $MSG_MAX or the socket buffer, an incoming
                    message over $MSG_MAX is read and discarded
    SOCK_E_EMPTY    empty or undef message, not sent
    SOCK_E_INVAL    send: message is a reference or has wide (over 255)
                    characters, encode it first
                    recv: $data is not a scalar reference
    errno           any other system error, the positive errno value,
                    its text is in $SOCK_ERRSTR

`socketpair_create()` sets errno on failure, `SOCK_E_INVAL` for an
unknown socket type.

errno values are always positive, SOCK\_E\_\* codes are negative, so they never
collide. `sock_err_name()` returns 'EBADF', etc. for errno values.

They are exported by [Net::Tools::Socket::Err](https://metacpan.org/pod/Net%3A%3ATools%3A%3ASocket%3A%3AErr), which must be used by the
caller to read them. The error state describes the last call only.

# NOTES

- Both functions must be given a socket handle, undef or a value that is not
a handle will die (a closed handle returns 0 with errno). `socketpair_recv()` must be given a reference to a
writable scalar (`\$data`) for the received data: anything that is not a
scalar reference returns 0 with `SOCK_E_INVAL` and the message stays
queued, a reference to a read-only value (`\'text'`) will die.
- Tested on Linux only. `SOCK_SEQPACKET` on `AF_UNIX` sockets is not
supported on macOS, use 'dgram' there, but the system may limit 'dgram'
messages far below `$MSG_MAX` (net.local.dgram.maxdgram). Where
`MSG_NOSIGNAL` is not available (macOS), `SIGPIPE` is ignored during
send instead, see above.

# SEE ALSO

[Net::Tools::Socket](https://metacpan.org/pod/Net%3A%3ATools%3A%3ASocket), [Net::Tools::Socket::Err](https://metacpan.org/pod/Net%3A%3ATools%3A%3ASocket%3A%3AErr), [socketpair(2)](http://man.he.net/man2/socketpair), [Socket](https://metacpan.org/pod/Socket)

# AUTHOR

    Vladi Belperchinov-Shabanski "Cade"
          <cade@noxrun.com>
    http://cade.noxrun.com/

# COPYRIGHT AND LICENSE

Copyright (c) 2026 Vladi Belperchinov-Shabanski "Cade"

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.
# NAME

Net::Tools::Socket::Err - error codes and error state shared by the Net::Tools::Socket modules

# SYNOPSIS

    use Net::Tools::Socket;
    use Net::Tools::Socket::Err;

    my $data = socket_read_message( $socket, $timeout );
    if( ! defined $data )
      {
      print "error: $SOCK_ERRSTR\n" if defined $SOCK_ERR;
      reconnect() if $SOCK_ERR == SOCK_E_EOF;
      print "name: " . sock_err_name() . "\n"; # 'SOCK_E_EOF', 'EBADF', etc.
      }

# DESCRIPTION

[Net::Tools::Socket](https://metacpan.org/pod/Net%3A%3ATools%3A%3ASocket), [Net::Tools::Socket::Protocols](https://metacpan.org/pod/Net%3A%3ATools%3A%3ASocket%3A%3AProtocols) and
[Net::Tools::Socket::Pair](https://metacpan.org/pod/Net%3A%3ATools%3A%3ASocket%3A%3APair) share one error state. Every function of those
modules clears it on entry and sets it when it fails, so it describes the
last call only and must be read right after it.

# VARIABLES

- $SOCK\_ERR

    The last error code: a negative SOCK\_E\_\* constant, or the positive errno
    value when a system call failed, undef when there is no error. errno values
    are always positive and SOCK\_E\_\* codes negative, so they never collide.

- $SOCK\_ERRSTR

    The text of the last error, undef when there is no error. For errno values
    it is the system text (`"$!"`), for SOCK\_E\_\* codes it is taken from
    %SOCK\_ERRSTR and may be followed by ": " and details, for example the
    rejected protocol type.

- %SOCK\_ERRSTR

    SOCK\_E\_\* code => text map. It is locked, reading an unknown key or changing
    it dies.

# ERROR CODES

    SOCK_E_AGAIN     nothing to read or peer's queue is full, retry
    SOCK_E_EOF       end of file, peer closed
    SOCK_E_TOOBIG    message larger than allowed
    SOCK_E_EMPTY     empty or undef message
    SOCK_E_MSGLEN    invalid or unreadable message length
    SOCK_E_SHORT     short read or write below requested count
    SOCK_E_TIMEOUT   timed out
    SOCK_E_PROTO     unknown or forbidden protocol type, or invalid data
    SOCK_E_SYS       system call failed but $! is not set
    SOCK_E_INVAL     invalid argument or data (wide characters, etc.)

Which codes a function sets is documented with the function.

# FUNCTIONS

These are used by the socket modules to set the state, and by callers to
read it.

## sock\_err( $code, $ret, $xtra )

Sets $SOCK\_ERR to $code and $SOCK\_ERRSTR to its text, then returns $ret, so
it can be used as:

    return sock_err( SOCK_E_EOF, undef ) if ...;

A positive $code is an errno value and its text is the system one, $! is
not changed. An unknown negative $code gets the text
"unknown error code \[$code\]". $xtra, if given and not empty, is appended to
the text of a negative code after ": ", it is ignored for errno values.

## sock\_err\_sys( $ret )

Sets the state from the current $! after a failed system call and returns
$ret. If $! is not set, $SOCK\_ERR is SOCK\_E\_SYS. Must be called right after
the failed call, before anything else changes $!.

## sock\_err\_name( $code )

Returns the name of $code, or of $SOCK\_ERR if no $code is given:
'SOCK\_E\_EOF', 'SOCK\_E\_TIMEOUT', etc. for SOCK\_E\_\* codes, 'SOCK\_E\_UNKNOWN'
for an unknown negative code, 'EPIPE', 'EBADF', etc. for errno values
('ERRNO\_&lt;value>' if the value has no name), undef if not set.

## sock\_err\_clear()

Clears $SOCK\_ERR and $SOCK\_ERRSTR to undef, returns 1.

# EXPORTS

All variables, functions and SOCK\_E\_\* constants are exported by default.

# SEE ALSO

[Net::Tools::Socket](https://metacpan.org/pod/Net%3A%3ATools%3A%3ASocket), [Net::Tools::Socket::Protocols](https://metacpan.org/pod/Net%3A%3ATools%3A%3ASocket%3A%3AProtocols),
[Net::Tools::Socket::Pair](https://metacpan.org/pod/Net%3A%3ATools%3A%3ASocket%3A%3APair), [Errno](https://metacpan.org/pod/Errno)

# AUTHOR

    Vladi Belperchinov-Shabanski "Cade"
          <cade@noxrun.com>
    http://cade.noxrun.com/

# COPYRIGHT AND LICENSE

Copyright (c) 2026 Vladi Belperchinov-Shabanski "Cade"

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.
