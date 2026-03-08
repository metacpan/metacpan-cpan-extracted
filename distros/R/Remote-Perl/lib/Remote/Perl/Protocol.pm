use v5.36;
package Remote::Perl::Protocol;
our $VERSION = '0.002';

use Exporter 'import';

our @EXPORT_OK = qw(
    HEADER_LEN PROTOCOL_VERSION
    MSG_HELLO MSG_READY MSG_RUN MSG_DATA MSG_EOF
    MSG_CREDIT MSG_MOD_REQ MSG_MOD_MISSING MSG_RETURN
    MSG_SIGNAL MSG_SIGNAL_ACK
    MSG_ERROR MSG_BYE
    STREAM_CONTROL STREAM_STDIN STREAM_STDOUT STREAM_STDERR
    TMPFILE_NONE TMPFILE_AUTO TMPFILE_LINUX TMPFILE_PERL TMPFILE_NAMED
    encode_message
    encode_hello decode_hello
    encode_credit decode_credit
    encode_return decode_return
    encode_run decode_run
);

use constant {
    PROTOCOL_VERSION => 2,
    HEADER_LEN       => 6,   # type(1) + stream(1) + length(4)

    # Tmpfile strategies (carried in the flags byte of RUN messages)
    TMPFILE_NONE  => 0,   # default: eval $source directly
    TMPFILE_AUTO  => 1,   # try linux, fall back to perl
    TMPFILE_LINUX => 2,   # O_TMPFILE (anonymous inode, no directory entry)
    TMPFILE_PERL  => 3,   # open('+>', undef) -- anon fd, unlinked on creation
    TMPFILE_NAMED => 4,   # File::Temp -- named file, kept until executor exits

    # Message types
    MSG_HELLO        => 0x00,
    MSG_READY        => 0x01,
    MSG_RUN          => 0x10,
    MSG_DATA         => 0x20,
    MSG_EOF          => 0x21,
    MSG_CREDIT       => 0x30,
    MSG_MOD_REQ      => 0x40,
    MSG_MOD_MISSING  => 0x41,
    MSG_RETURN       => 0x50,
    MSG_SIGNAL       => 0x60,
    MSG_SIGNAL_ACK   => 0x61,
    MSG_ERROR        => 0xE0,
    MSG_BYE          => 0xF0,

    # Predefined stream IDs
    STREAM_CONTROL   => 0,
    STREAM_STDIN     => 1,
    STREAM_STDOUT    => 2,
    STREAM_STDERR    => 3,
};

# encode_message($type, $stream, $body) -> bytes
sub encode_message($type, $stream, $body = '') {
    return pack('CCN', $type, $stream, length($body)) . $body;
}

# HELLO body: version(u8) + window_size(u32 BE)
sub encode_hello($version, $window_size) {
    return pack('CN', $version, $window_size);
}
sub decode_hello($body) {
    return unpack('CN', $body);
}

# CREDIT body: grant(u32 BE)
sub encode_credit($n) {
    return pack('N', $n);
}
sub decode_credit($body) {
    return unpack('N', $body);
}

# RETURN body: exit_code(u8) + optional message bytes
sub encode_return($exit_code, $message = '') {
    return pack('C', $exit_code) . $message;
}
sub decode_return($body) {
    my $exit_code = unpack('C', $body);
    my $message   = length($body) > 1 ? substr($body, 1) : '';
    return ($exit_code, $message);
}

# RUN body: flags(u8) + argc(u32) + [len(u32) + bytes]... + source(rest)
sub encode_run($flags, $source, @argv) {
    my $buf = pack('CN', $flags, scalar @argv);
    for my $arg (@argv) {
        $buf .= pack('N', length($arg)) . $arg;
    }
    return $buf . $source;
}
sub decode_run($body) {
    my $off   = 0;
    my $flags = unpack('C', substr($body, $off, 1)); $off += 1;
    my $argc  = unpack('N', substr($body, $off, 4)); $off += 4;
    my @argv;
    for (1 .. $argc) {
        my $len = unpack('N', substr($body, $off, 4)); $off += 4;
        push @argv, substr($body, $off, $len); $off += $len;
    }
    my $source = substr($body, $off);
    return ($flags, $source, @argv);
}

# ------------------------------------------------------------------------------
# Remote::Perl::Protocol::Parser -- stateful incremental decoder
# ------------------------------------------------------------------------------
package Remote::Perl::Protocol::Parser;

use constant HEADER_LEN => Remote::Perl::Protocol::HEADER_LEN;

sub new($class) {
    return bless { buf => '' }, $class;
}

# Feed raw bytes; returns list of decoded message hashrefs:
#   { type => $t, stream => $s, body => $b }
sub feed($self, $data) {
    $self->{buf} .= $data;
    return $self->_drain;
}

sub _drain($self) {
    my @msgs;
    while (length($self->{buf}) >= HEADER_LEN) {
        my ($type, $stream, $len) = unpack('CCN', $self->{buf});
        last if length($self->{buf}) < HEADER_LEN + $len;
        substr($self->{buf}, 0, HEADER_LEN, '');
        my $body = $len ? substr($self->{buf}, 0, $len, '') : '';
        push @msgs, { type => $type, stream => $stream, body => $body };
    }
    return @msgs;
}

# How many bytes are buffered but not yet forming a complete message
sub pending_bytes($self) { length($self->{buf}) }

1;

__END__

=head1 NAME

Remote::Perl::Protocol - wire protocol constants and codec (internal part of Remote::Perl)

=head1 DESCRIPTION

This module defines constants, encoding helpers, and an incremental parser for
the Remote::Perl binary wire protocol.

=head1 INTERNAL

Not public API.  This is an internal module used by L<Remote::Perl>; its interface
may change without notice.

=head1 FRAMING

Every message consists of:

=over 4

=item 1. Message type (uint8)

=item 2. Stream ID (uint8)

=item 3. Body length in bytes (uint32, big-endian)

=item 4. Body (0 or more bytes)

=back

Total header: 6 bytes.  Body may be empty.

=head1 STREAMS

Streams multiplex logical channels over the single pipe pair.  Predefined
stream IDs:

  ID   Name       Direction      Purpose
  --   ----       ---------      -------
   0   control    bidirectional  Connection lifecycle, errors
   1   stdin      local->remote  Data forwarded to the remote script's STDIN
   2   stdout     remote->local  Remote script's STDOUT
   3   stderr     remote->local  Remote script's STDERR
  4+   modules    bidirectional  One ephemeral stream per module transfer

Module transfer streams are opened by the remote side (C<MOD_REQ>) and closed
after the module source has been delivered (or refused) by the local side.

=head1 FLOW CONTROL

Each (sender, stream) pair has a B<credit> counter.  The sender may not
transmit more body bytes than it currently holds in credit for that stream.
Credits are granted by the receiver with C<CREDIT> messages as it consumes
data.

Initial credits (bytes) per stream are exchanged in the C<HELLO> handshake.
Default: B<65536 bytes> per stream, configurable via C<--window-size> / the
C<window_size> constructor argument.

A sender that exhausts its credit must block until more is granted.  A
receiver must grant credits promptly to avoid deadlock.

Both sides use a C<select>-based single-threaded event loop.  This naturally
handles concurrent and recursive module requests (multiple C<MOD_REQ> streams
in flight at once) without threads or external concurrency dependencies.

=head1 MESSAGE TYPES

  Value  Name          Direction      Body
  -----  ----          ---------      ----
  0x00   HELLO         local->remote  Protocol version (uint8) + initial credits (uint32)
  0x01   READY         remote->local  Acknowledgement of HELLO; remote client active
  0x10   RUN           local->remote  flags (uint8) + argc (uint32) + [len (uint32) + arg bytes]... + source bytes
  0x20   DATA          any direction  Payload for the named stream
  0x21   EOF           any direction  Stream has no more data (half-close)
  0x30   CREDIT        any direction  uint32 BE: additional bytes granted to sender on this stream
  0x40   MOD_REQ       remote->local  Module filename (e.g. Foo/Bar.pm); stream ID in header
  0x41   MOD_MISSING   local->remote  Module not found; body empty
  0x50   RETURN        remote->local  Exit code (uint8) + optional message bytes
  0x60   SIGNAL        local->remote  Signal name bytes (e.g. "INT", "TERM")
  0x61   SIGNAL_ACK    remote->local  Echoes signal name; signal delivered to executor
  0xE0   ERROR         any direction  Error message bytes; sender will send no more
  0xF0   BYE           any direction  Clean shutdown; no more messages expected

=head1 RUN FLAGS

The C<flags> byte in a C<RUN> message controls how the executor runs the
source on the remote side:

  Value  Name    Meaning
  -----  ----    -------
  0      NONE    eval $source directly (__DATA__/__END__ not supported)
  1      AUTO    write to anonymous tmpfile; try linux strategy, fall back to perl
  2      LINUX   O_TMPFILE anonymous inode (Linux 3.11+)
  3      PERL    open('+>', undef) -- anon fd, directory entry briefly created then unlinked
  4      NAMED   File::Temp named file, kept until executor process exits

Strategies 1-4 all use C<do "/proc/self/fd/N"> (or C<do $path> for NAMED),
which causes Perl's tokeniser to handle C<__DATA__> and C<__END__> natively.

=head1 CONNECTION SEQUENCE

  local                           remote
    |--- HELLO --------------------->|   bootstrap code already eval'd
    |<-- READY ----------------------|
    |--- RUN (stream 0) ------------>|   send script source
    |<-- DATA (stdout, stream 2) ----|   output as produced
    |--- DATA (stdin, stream 1) ---->|   forwarded on demand
    |--- CREDIT (stream 2) --------->|   grant more stdout credit
    |<-- MOD_REQ (stream 4) ---------|   require 'Foo/Bar.pm'
    |--- DATA (stream 4) ----------->|   module source bytes
    |--- EOF (stream 4) ------------>|   module transfer complete
    |<-- RETURN (stream 0) ----------|   script finished
    |--- BYE ----------------------->|
    |<-- BYE ------------------------|

=head1 SEE ALSO

L<Remote::Perl>

=cut
