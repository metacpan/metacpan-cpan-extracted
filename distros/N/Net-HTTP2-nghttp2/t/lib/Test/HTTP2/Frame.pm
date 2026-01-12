package Test::HTTP2::Frame;

use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(
    CLIENT_PREFACE
    build_frame
    build_settings_frame
    build_headers_frame
    build_data_frame
    build_window_update_frame
    build_ping_frame
    build_goaway_frame
    build_rst_stream_frame
    build_priority_frame
    build_continuation_frame
    build_push_promise_frame
    build_unknown_frame
    parse_frame_header
    parse_frames
    FRAME_DATA
    FRAME_HEADERS
    FRAME_PRIORITY
    FRAME_RST_STREAM
    FRAME_SETTINGS
    FRAME_PUSH_PROMISE
    FRAME_PING
    FRAME_GOAWAY
    FRAME_WINDOW_UPDATE
    FRAME_CONTINUATION
    FLAG_END_STREAM
    FLAG_END_HEADERS
    FLAG_PADDED
    FLAG_PRIORITY
    FLAG_ACK
    SETTINGS_HEADER_TABLE_SIZE
    SETTINGS_ENABLE_PUSH
    SETTINGS_MAX_CONCURRENT_STREAMS
    SETTINGS_INITIAL_WINDOW_SIZE
    SETTINGS_MAX_FRAME_SIZE
    SETTINGS_MAX_HEADER_LIST_SIZE
    ERROR_NO_ERROR
    ERROR_PROTOCOL_ERROR
    ERROR_INTERNAL_ERROR
    ERROR_FLOW_CONTROL_ERROR
    ERROR_SETTINGS_TIMEOUT
    ERROR_STREAM_CLOSED
    ERROR_FRAME_SIZE_ERROR
    ERROR_REFUSED_STREAM
    ERROR_CANCEL
    ERROR_COMPRESSION_ERROR
    ERROR_CONNECT_ERROR
    ERROR_ENHANCE_YOUR_CALM
    ERROR_INADEQUATE_SECURITY
    ERROR_HTTP_1_1_REQUIRED
);

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
    frames => [qw(
        FRAME_DATA FRAME_HEADERS FRAME_PRIORITY FRAME_RST_STREAM
        FRAME_SETTINGS FRAME_PUSH_PROMISE FRAME_PING FRAME_GOAWAY
        FRAME_WINDOW_UPDATE FRAME_CONTINUATION
    )],
    flags => [qw(FLAG_END_STREAM FLAG_END_HEADERS FLAG_PADDED FLAG_PRIORITY FLAG_ACK)],
    settings => [qw(
        SETTINGS_HEADER_TABLE_SIZE SETTINGS_ENABLE_PUSH
        SETTINGS_MAX_CONCURRENT_STREAMS SETTINGS_INITIAL_WINDOW_SIZE
        SETTINGS_MAX_FRAME_SIZE SETTINGS_MAX_HEADER_LIST_SIZE
    )],
    errors => [qw(
        ERROR_NO_ERROR ERROR_PROTOCOL_ERROR ERROR_INTERNAL_ERROR
        ERROR_FLOW_CONTROL_ERROR ERROR_SETTINGS_TIMEOUT ERROR_STREAM_CLOSED
        ERROR_FRAME_SIZE_ERROR ERROR_REFUSED_STREAM ERROR_CANCEL
        ERROR_COMPRESSION_ERROR ERROR_CONNECT_ERROR ERROR_ENHANCE_YOUR_CALM
        ERROR_INADEQUATE_SECURITY ERROR_HTTP_1_1_REQUIRED
    )],
);

# HTTP/2 Connection Preface
use constant CLIENT_PREFACE => "PRI * HTTP/2.0\r\n\r\nSM\r\n\r\n";

# Frame Types (RFC 9113 Section 6)
use constant FRAME_DATA          => 0x0;
use constant FRAME_HEADERS       => 0x1;
use constant FRAME_PRIORITY      => 0x2;
use constant FRAME_RST_STREAM    => 0x3;
use constant FRAME_SETTINGS      => 0x4;
use constant FRAME_PUSH_PROMISE  => 0x5;
use constant FRAME_PING          => 0x6;
use constant FRAME_GOAWAY        => 0x7;
use constant FRAME_WINDOW_UPDATE => 0x8;
use constant FRAME_CONTINUATION  => 0x9;

# Frame Flags
use constant FLAG_END_STREAM  => 0x1;
use constant FLAG_END_HEADERS => 0x4;
use constant FLAG_PADDED      => 0x8;
use constant FLAG_PRIORITY    => 0x20;
use constant FLAG_ACK         => 0x1;  # For SETTINGS and PING

# Settings Parameters (RFC 9113 Section 6.5.2)
use constant SETTINGS_HEADER_TABLE_SIZE      => 0x1;
use constant SETTINGS_ENABLE_PUSH            => 0x2;
use constant SETTINGS_MAX_CONCURRENT_STREAMS => 0x3;
use constant SETTINGS_INITIAL_WINDOW_SIZE    => 0x4;
use constant SETTINGS_MAX_FRAME_SIZE         => 0x5;
use constant SETTINGS_MAX_HEADER_LIST_SIZE   => 0x6;

# Error Codes (RFC 9113 Section 7)
use constant ERROR_NO_ERROR            => 0x0;
use constant ERROR_PROTOCOL_ERROR      => 0x1;
use constant ERROR_INTERNAL_ERROR      => 0x2;
use constant ERROR_FLOW_CONTROL_ERROR  => 0x3;
use constant ERROR_SETTINGS_TIMEOUT    => 0x4;
use constant ERROR_STREAM_CLOSED       => 0x5;
use constant ERROR_FRAME_SIZE_ERROR    => 0x6;
use constant ERROR_REFUSED_STREAM      => 0x7;
use constant ERROR_CANCEL              => 0x8;
use constant ERROR_COMPRESSION_ERROR   => 0x9;
use constant ERROR_CONNECT_ERROR       => 0xa;
use constant ERROR_ENHANCE_YOUR_CALM   => 0xb;
use constant ERROR_INADEQUATE_SECURITY => 0xc;
use constant ERROR_HTTP_1_1_REQUIRED   => 0xd;

# Build a raw HTTP/2 frame
# Frame header is 9 bytes:
#   - Length: 3 bytes (24 bits)
#   - Type: 1 byte
#   - Flags: 1 byte
#   - Reserved: 1 bit (must be 0)
#   - Stream ID: 31 bits
sub build_frame {
    my %args = @_;
    my $type      = $args{type}      // 0;
    my $flags     = $args{flags}     // 0;
    my $stream_id = $args{stream_id} // 0;
    my $payload   = $args{payload}   // '';

    my $length = length($payload);

    # Pack frame header (9 bytes)
    # Length is 3 bytes big-endian, then type, flags, stream_id (4 bytes with R bit)
    my $header = pack("CCC C C N",
        ($length >> 16) & 0xFF,
        ($length >> 8) & 0xFF,
        $length & 0xFF,
        $type,
        $flags,
        $stream_id & 0x7FFFFFFF,  # Clear reserved bit
    );

    return $header . $payload;
}

# Build SETTINGS frame
sub build_settings_frame {
    my %args = @_;
    my $ack      = $args{ack}      // 0;
    my $settings = $args{settings} // {};

    my $flags = $ack ? FLAG_ACK : 0;
    my $payload = '';

    # Each setting is 6 bytes: 2 byte identifier + 4 byte value
    for my $id (sort keys %$settings) {
        $payload .= pack("n N", $id, $settings->{$id});
    }

    return build_frame(
        type      => FRAME_SETTINGS,
        flags     => $flags,
        stream_id => 0,
        payload   => $payload,
    );
}

# Build HEADERS frame
# Note: This builds the frame structure but requires pre-encoded HPACK headers
sub build_headers_frame {
    my %args = @_;
    my $stream_id      = $args{stream_id}      // 1;
    my $header_block   = $args{header_block}   // '';
    my $end_stream     = $args{end_stream}     // 0;
    my $end_headers    = $args{end_headers}    // 1;
    my $padding_length = $args{padding_length} // 0;
    my $priority       = $args{priority};  # { exclusive, stream_dep, weight }

    my $flags = 0;
    $flags |= FLAG_END_STREAM  if $end_stream;
    $flags |= FLAG_END_HEADERS if $end_headers;
    $flags |= FLAG_PADDED      if $padding_length > 0;
    $flags |= FLAG_PRIORITY    if $priority;

    my $payload = '';

    # Pad Length (1 byte, if PADDED)
    $payload .= pack("C", $padding_length) if $padding_length > 0;

    # Priority fields (5 bytes, if PRIORITY)
    if ($priority) {
        my $exclusive   = $priority->{exclusive}  // 0;
        my $stream_dep  = $priority->{stream_dep} // 0;
        my $weight      = $priority->{weight}     // 16;

        my $dep_field = $stream_dep;
        $dep_field |= 0x80000000 if $exclusive;
        $payload .= pack("N C", $dep_field, $weight - 1);
    }

    # Header block fragment
    $payload .= $header_block;

    # Padding
    $payload .= "\x00" x $padding_length if $padding_length > 0;

    return build_frame(
        type      => FRAME_HEADERS,
        flags     => $flags,
        stream_id => $stream_id,
        payload   => $payload,
    );
}

# Build DATA frame
sub build_data_frame {
    my %args = @_;
    my $stream_id      = $args{stream_id}      // 1;
    my $data           = $args{data}           // '';
    my $end_stream     = $args{end_stream}     // 0;
    my $padding_length = $args{padding_length} // 0;

    my $flags = 0;
    $flags |= FLAG_END_STREAM if $end_stream;
    $flags |= FLAG_PADDED     if $padding_length > 0;

    my $payload = '';
    $payload .= pack("C", $padding_length) if $padding_length > 0;
    $payload .= $data;
    $payload .= "\x00" x $padding_length if $padding_length > 0;

    return build_frame(
        type      => FRAME_DATA,
        flags     => $flags,
        stream_id => $stream_id,
        payload   => $payload,
    );
}

# Build WINDOW_UPDATE frame
sub build_window_update_frame {
    my %args = @_;
    my $stream_id  = $args{stream_id}  // 0;
    my $increment  = $args{increment}  // 1;

    my $payload = pack("N", $increment & 0x7FFFFFFF);

    return build_frame(
        type      => FRAME_WINDOW_UPDATE,
        flags     => 0,
        stream_id => $stream_id,
        payload   => $payload,
    );
}

# Build PING frame
sub build_ping_frame {
    my %args = @_;
    my $ack         = $args{ack}         // 0;
    my $opaque_data = $args{opaque_data} // "\x00" x 8;

    # Opaque data must be exactly 8 bytes
    if (length($opaque_data) != 8) {
        die "PING opaque_data must be exactly 8 bytes";
    }

    return build_frame(
        type      => FRAME_PING,
        flags     => $ack ? FLAG_ACK : 0,
        stream_id => 0,
        payload   => $opaque_data,
    );
}

# Build GOAWAY frame
sub build_goaway_frame {
    my %args = @_;
    my $last_stream_id = $args{last_stream_id} // 0;
    my $error_code     = $args{error_code}     // ERROR_NO_ERROR;
    my $debug_data     = $args{debug_data}     // '';

    my $payload = pack("N N", $last_stream_id & 0x7FFFFFFF, $error_code);
    $payload .= $debug_data;

    return build_frame(
        type      => FRAME_GOAWAY,
        flags     => 0,
        stream_id => 0,
        payload   => $payload,
    );
}

# Build RST_STREAM frame
sub build_rst_stream_frame {
    my %args = @_;
    my $stream_id  = $args{stream_id}  // 1;
    my $error_code = $args{error_code} // ERROR_NO_ERROR;

    my $payload = pack("N", $error_code);

    return build_frame(
        type      => FRAME_RST_STREAM,
        flags     => 0,
        stream_id => $stream_id,
        payload   => $payload,
    );
}

# Build PRIORITY frame
sub build_priority_frame {
    my %args = @_;
    my $stream_id  = $args{stream_id}  // 1;
    my $exclusive  = $args{exclusive}  // 0;
    my $stream_dep = $args{stream_dep} // 0;
    my $weight     = $args{weight}     // 16;

    my $dep_field = $stream_dep;
    $dep_field |= 0x80000000 if $exclusive;

    my $payload = pack("N C", $dep_field, $weight - 1);

    return build_frame(
        type      => FRAME_PRIORITY,
        flags     => 0,
        stream_id => $stream_id,
        payload   => $payload,
    );
}

# Build CONTINUATION frame
sub build_continuation_frame {
    my %args = @_;
    my $stream_id    = $args{stream_id}    // 1;
    my $header_block = $args{header_block} // '';
    my $end_headers  = $args{end_headers}  // 1;

    return build_frame(
        type      => FRAME_CONTINUATION,
        flags     => $end_headers ? FLAG_END_HEADERS : 0,
        stream_id => $stream_id,
        payload   => $header_block,
    );
}

# Build PUSH_PROMISE frame
sub build_push_promise_frame {
    my %args = @_;
    my $stream_id         = $args{stream_id}         // 1;
    my $promised_stream_id = $args{promised_stream_id} // 2;
    my $header_block      = $args{header_block}      // '';
    my $end_headers       = $args{end_headers}       // 1;
    my $padding_length    = $args{padding_length}    // 0;

    my $flags = 0;
    $flags |= FLAG_END_HEADERS if $end_headers;
    $flags |= FLAG_PADDED      if $padding_length > 0;

    my $payload = '';
    $payload .= pack("C", $padding_length) if $padding_length > 0;
    $payload .= pack("N", $promised_stream_id & 0x7FFFFFFF);
    $payload .= $header_block;
    $payload .= "\x00" x $padding_length if $padding_length > 0;

    return build_frame(
        type      => FRAME_PUSH_PROMISE,
        flags     => $flags,
        stream_id => $stream_id,
        payload   => $payload,
    );
}

# Build unknown/custom frame type (for testing)
sub build_unknown_frame {
    my %args = @_;
    my $type      = $args{type}      // 0xFF;  # Unknown type
    my $flags     = $args{flags}     // 0;
    my $stream_id = $args{stream_id} // 0;
    my $payload   = $args{payload}   // '';

    return build_frame(
        type      => $type,
        flags     => $flags,
        stream_id => $stream_id,
        payload   => $payload,
    );
}

# Parse a frame header (9 bytes)
sub parse_frame_header {
    my ($data) = @_;

    return undef if length($data) < 9;

    my ($len_hi, $len_mid, $len_lo, $type, $flags, $stream_id) =
        unpack("CCC C C N", substr($data, 0, 9));

    my $length = ($len_hi << 16) | ($len_mid << 8) | $len_lo;
    $stream_id &= 0x7FFFFFFF;  # Clear reserved bit

    return {
        length    => $length,
        type      => $type,
        flags     => $flags,
        stream_id => $stream_id,
    };
}

# Parse multiple frames from a buffer
sub parse_frames {
    my ($data) = @_;
    my @frames;

    while (length($data) >= 9) {
        my $header = parse_frame_header($data);
        last unless $header;

        my $total_len = 9 + $header->{length};
        last if length($data) < $total_len;

        $header->{payload} = substr($data, 9, $header->{length});
        push @frames, $header;

        $data = substr($data, $total_len);
    }

    return (\@frames, $data);  # Return frames and remaining data
}

1;

__END__

=head1 NAME

Test::HTTP2::Frame - HTTP/2 frame building utilities for testing

=head1 SYNOPSIS

    use Test::HTTP2::Frame qw(:all);

    # Build a SETTINGS frame
    my $settings = build_settings_frame(
        settings => {
            SETTINGS_MAX_CONCURRENT_STREAMS() => 100,
            SETTINGS_INITIAL_WINDOW_SIZE()    => 65535,
        },
    );

    # Build client preface with SETTINGS
    my $preface = CLIENT_PREFACE . $settings;

    # Parse response frames
    my ($frames, $remaining) = parse_frames($response_data);

=head1 DESCRIPTION

This module provides utilities for building and parsing HTTP/2 frames
for testing purposes. It implements the frame formats defined in
RFC 9113.

=cut
