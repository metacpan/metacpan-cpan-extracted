package MySQL::Packet;

our $VERSION = qw(0.2007054);

# todo: check all unpack calls for possibility of fatal exceptions

=head1 NAME

MySQL::Packet - encode and decode the MySQL binary protocol

=head1 VERSION

Version 0.2007054

=head1 SYNOPSIS

Sorry for the absurdly verbose synopsis.  I don't have a proper example
script for you at the moment.

    use MySQL::Packet qw(:debug);           # dumping packet contents etc.
    use MySQL::Packet qw(:test :decode);    # decoding subs
    use MySQL::Packet qw(:encode);          # encoding subs

    use MySQL::Packet qw(:COM :CLIENT :SERVER);     # constants

    my $packet;
    my $greeting;
    my $result;
    my $field_end;

    my $mysql_socket = whatever_i_do_to_connect();

    while (read $mysql_socket, $_, 1000, length) {
        if (not $packet) {
            my $_packet = {};
            my $rc = mysql_decode_header $_packet;
            if ($rc < 0) {
                die 'bad header';
            }
            elsif ($rc > 0) {
                $packet = $_packet;
                redo;
            }
        }
        elsif (not $greeting) {
            my $rc = mysql_decode_greeting $_packet;
            if ($rc < 0) {
                die 'bad greeting';
            }
            elsif ($rc > 0) {
                mysql_debug_packet $packet;
                $greeting = $packet;
                undef $packet;
                send_client_auth();
                redo;
            }
        }
        elsif (not $result) {
            my $rc = mysql_decode_result $packet;
            if ($rc < 0) {
                die 'bad result';
            }
            elsif ($rc > 0) {
                mysql_debug_packet $packet;
                if ($packet->{error}) {
                    die 'the server hates me';
                }
                elsif ($packet->{end}) {
                    die 'this should never happen';
                }
                else {
                    if ($packet->{field_count}) {
                        $result = $packet;
                        # fields and rows to come
                    }
                    elsif (not $packet->{server_status} & SERVER_MORE_RESULTS_EXISTS) {
                        # that's that..
                        send_some_query();
                    }
                }
                undef $packet;
                redo;
            }
        }
        elsif (not $field_end) {
            my $rc = do {
                (mysql_test_var $packet}) ? (mysql_decode_field $packet)
                                          : (mysql_decode_result $packet)
            };
            if ($rc < 0) {
                die 'bad field packet';
            }
            elsif ($rc > 0) {
                mysql_debug_packet $packet;
                if ($packet->{error}) {
                    die 'the server hates me';
                }
                elsif ($packet->{end}) {
                    $field_end = $packet;
                }
                else {
                    do_something_with_field_metadata($packet);
                }
                undef $packet;
                redo;
            }
        }
        else {
            my $rc = do {
                (mysql_test_var $packet ? (mysql_decode_row $packet)
                                        : (mysql_decode_result $packet)
            };
            if ($rc < 0) {
                die 'bad row packet';
            }
            elsif ($rc > 0) {
                mysql_debug_packet $packet;
                if ($packet->{error}) {
                    die 'the server hates me';
                }
                elsif ($packet->{end}) {
                    undef $result;
                    undef $field_end;
                    unless ($packet->{server_status} & SERVER_MORE_RESULTS_EXISTS) {
                        # that's that..
                        send_some_query();
                    }
                }
                else {
                    my @row = @{ $packet->{row} };
                    do_something_with_row_data(@row);
                }
                undef $packet;
                redo;
            }
        }
    }

    sub send_client_auth {
        my $flags = CLIENT_LONG_PASSWORD | CLIENT_LONG_FLAG | CLIENT_PROTOCOL_41 | CLIENT_TRANSACTIONS | CLIENT_SECURE_CONNECTION;
        $flags |= CLIENT_CONNECT_WITH_DB if $i_want_to;
        my $pw_crypt = mysql_crypt 'my_password', $greeting->{crypt_seed};
        my $packet_body = mysql_encode_client_auth (
            $flags,                                 # $client_flags
            0x01000000,                             # $max_packet_size
            $greeting->{server_lang},               # $charset_no
            'my_username',                          # $username
            $pw_crypt,                              # $pw_crypt
            'my_database',                          # $database
        );
        my $packet_head = mysql_encode_header $packet_body, 1;
        print $mysql_socket $packet_head, $packet_body;
    }

    sub send_some_query {
        my $packet_body = mysql_encode_com_query 'SELECT * FROM foo';
        my $packet_head = mysql_encode_header $packet_body;
        print $mysql_socket $packet_head, $packet_body;
    }

=head1 DESCRIPTION

This module exports various functions for encoding and decoding binary packets
pertinent to the MySQL client/server protocol.  It also exports some useful
constants.  It does NOT wrap an IO::Socket handle for you.

This is ALPHA code.  It currently groks only the new v4.1+ protocol.  It
currently handles only authentication, the COM_QUERY and COM_QUIT commands,
and the associated server responses.  In other words, just enough to send
plain SQL and get the results.

For what it does, it seems to be quite stable, by my own yardstick.

This module should eventually grow to support statement prepare and execute,
the pre-v4.1 protocol, compression, and so on.

=cut

BEGIN {
    # i am not sure whether to prefer Digest::SHA or Digest::SHA1 here
    eval 'use Digest::SHA qw(sha1); 1'      or
    eval 'use Digest::SHA1 qw(sha1); 1'     or die;
}

use Exporter qw(import);

our %EXPORT_TAGS = (
    COM => [qw/
        COM_SLEEP
        COM_QUIT
        COM_INIT_DB
        COM_QUERY
        COM_FIELD_LIST
        COM_CREATE_DB
        COM_DROP_DB
        COM_REFRESH
        COM_SHUTDOWN
        COM_STATISTICS
        COM_PROCESS_INFO
        COM_CONNECT
        COM_PROCESS_KILL
        COM_DEBUG
        COM_PING
        COM_TIME
        COM_DELAYED_INSERT
        COM_CHANGE_USER
        COM_BINLOG_DUMP
        COM_TABLE_DUMP
        COM_CONNECT_OUT
        COM_REGISTER_SLAVE
        COM_STMT_PREPARE
        COM_STMT_EXECUTE
        COM_STMT_SEND_LONG_DATA
        COM_STMT_CLOSE
        COM_STMT_RESET
        COM_SET_OPTION
        COM_STMT_FETCH
    /],
    CLIENT => [qw/
        CLIENT_LONG_PASSWORD
        CLIENT_FOUND_ROWS
        CLIENT_LONG_FLAG
        CLIENT_CONNECT_WITH_DB
        CLIENT_NO_SCHEMA
        CLIENT_COMPRESS
        CLIENT_ODBC
        CLIENT_LOCAL_FILES
        CLIENT_IGNORE_SPACE
        CLIENT_PROTOCOL_41
        CLIENT_INTERACTIVE
        CLIENT_SSL
        CLIENT_IGNORE_SIGPIPE
        CLIENT_TRANSACTIONS
        CLIENT_RESERVED
        CLIENT_SECURE_CONNECTION
        CLIENT_MULTI_STATEMENTS
        CLIENT_MULTI_RESULTS
    /],
    SERVER => [qw/
        SERVER_STATUS_IN_TRANS
        SERVER_STATUS_AUTOCOMMIT
        SERVER_MORE_RESULTS_EXISTS
        SERVER_QUERY_NO_GOOD_INDEX_USED
        SERVER_QUERY_NO_INDEX_USED
        SERVER_STATUS_CURSOR_EXISTS
        SERVER_STATUS_LAST_ROW_SENT
        SERVER_STATUS_DB_DROPPED
        SERVER_STATUS_NO_BACKSLASH_ESCAPES
    /],
    debug => [qw/
        mysql_debug_packet
    /],
    test => [qw/
        mysql_test_var
        mysql_test_end
        mysql_test_error
    /],
    decode => [qw/
        mysql_decode_header
        mysql_decode_skip
        mysql_decode_varnum
        mysql_decode_varstr
        mysql_decode_greeting
        mysql_decode_result
        mysql_decode_field
        mysql_decode_row
    /],
    encode => [qw/
        mysql_encode_header
        mysql_encode_varnum
        mysql_encode_varstr
        mysql_encode_client_auth
        mysql_encode_com_query
    /],
    crypt => [qw/
        mysql_crypt
    /],
);

our @EXPORT_OK = map {@$_} values %EXPORT_TAGS;

=head1 EXPORTABLE CONSTANTS

=cut

#### constants ####

=head2 Commands (Tag :COM)

    COM_SLEEP
    COM_QUIT
    COM_INIT_DB
    COM_QUERY
    COM_FIELD_LIST
    COM_CREATE_DB
    COM_DROP_DB
    COM_REFRESH
    COM_SHUTDOWN
    COM_STATISTICS
    COM_PROCESS_INFO
    COM_CONNECT
    COM_PROCESS_KILL
    COM_DEBUG
    COM_PING
    COM_TIME
    COM_DELAYED_INSERT
    COM_CHANGE_USER
    COM_BINLOG_DUMP
    COM_TABLE_DUMP
    COM_CONNECT_OUT
    COM_REGISTER_SLAVE
    COM_STMT_PREPARE
    COM_STMT_EXECUTE
    COM_STMT_SEND_LONG_DATA
    COM_STMT_CLOSE
    COM_STMT_RESET
    COM_SET_OPTION
    COM_STMT_FETCH

=cut

use constant {
    COM_SLEEP                   => 0x00,
    COM_QUIT                    => 0x01,
    COM_INIT_DB                 => 0x02,
    COM_QUERY                   => 0x03,
    COM_FIELD_LIST              => 0x04,
    COM_CREATE_DB               => 0x05,
    COM_DROP_DB                 => 0x06,
    COM_REFRESH                 => 0x07,
    COM_SHUTDOWN                => 0x08,
    COM_STATISTICS              => 0x09,
    COM_PROCESS_INFO            => 0x0a,
    COM_CONNECT                 => 0x0b,
    COM_PROCESS_KILL            => 0x0c,
    COM_DEBUG                   => 0x0d,
    COM_PING                    => 0x0e,
    COM_TIME                    => 0x0f,
    COM_DELAYED_INSERT          => 0x10,
    COM_CHANGE_USER             => 0x11,
    COM_BINLOG_DUMP             => 0x12,
    COM_TABLE_DUMP              => 0x13,
    COM_CONNECT_OUT             => 0x14,
    COM_REGISTER_SLAVE          => 0x15,
    COM_STMT_PREPARE            => 0x16,
    COM_STMT_EXECUTE            => 0x17,
    COM_STMT_SEND_LONG_DATA     => 0x18,
    COM_STMT_CLOSE              => 0x19,
    COM_STMT_RESET              => 0x1a,
    COM_SET_OPTION              => 0x1b,
    COM_STMT_FETCH              => 0x1c,
};

=head2 Client Flags / Server Capabilities (Tag :CLIENT)

    CLIENT_LONG_PASSWORD
    CLIENT_FOUND_ROWS
    CLIENT_LONG_FLAG
    CLIENT_CONNECT_WITH_DB
    CLIENT_NO_SCHEMA
    CLIENT_COMPRESS
    CLIENT_ODBC
    CLIENT_LOCAL_FILES
    CLIENT_IGNORE_SPACE
    CLIENT_PROTOCOL_41
    CLIENT_INTERACTIVE
    CLIENT_SSL
    CLIENT_IGNORE_SIGPIPE
    CLIENT_TRANSACTIONS
    CLIENT_RESERVED
    CLIENT_SECURE_CONNECTION
    CLIENT_MULTI_STATEMENTS
    CLIENT_MULTI_RESULTS

=cut

use constant {
    CLIENT_LONG_PASSWORD        =>  1,
    CLIENT_FOUND_ROWS           =>  2,
    CLIENT_LONG_FLAG            =>  4,
    CLIENT_CONNECT_WITH_DB      =>  8,
    CLIENT_NO_SCHEMA            =>  16,
    CLIENT_COMPRESS             =>  32,
    CLIENT_ODBC                 =>  64,
    CLIENT_LOCAL_FILES          =>  128,
    CLIENT_IGNORE_SPACE         =>  256,
    CLIENT_PROTOCOL_41          =>  512,
    CLIENT_INTERACTIVE          =>  1024,
    CLIENT_SSL                  =>  2048,
    CLIENT_IGNORE_SIGPIPE       =>  4096,
    CLIENT_TRANSACTIONS         =>  8192,
    CLIENT_RESERVED             =>  16384,
    CLIENT_SECURE_CONNECTION    =>  32768,
    CLIENT_MULTI_STATEMENTS     =>  65536,
    CLIENT_MULTI_RESULTS        =>  131072,
};

=head2 Server Status Flags (Tag :SERVER)

    SERVER_STATUS_IN_TRANS
    SERVER_STATUS_AUTOCOMMIT
    SERVER_MORE_RESULTS_EXISTS
    SERVER_QUERY_NO_GOOD_INDEX_USED
    SERVER_QUERY_NO_INDEX_USED
    SERVER_STATUS_CURSOR_EXISTS
    SERVER_STATUS_LAST_ROW_SENT
    SERVER_STATUS_DB_DROPPED
    SERVER_STATUS_NO_BACKSLASH_ESCAPES

=cut

use constant {
    SERVER_STATUS_IN_TRANS              => 1,
    SERVER_STATUS_AUTOCOMMIT            => 2,
    SERVER_MORE_RESULTS_EXISTS          => 8,
    SERVER_QUERY_NO_GOOD_INDEX_USED     => 16,
    SERVER_QUERY_NO_INDEX_USED          => 32,
    SERVER_STATUS_CURSOR_EXISTS         => 64,
    SERVER_STATUS_LAST_ROW_SENT         => 128,
    SERVER_STATUS_DB_DROPPED            => 256,
    SERVER_STATUS_NO_BACKSLASH_ESCAPES  => 512,
};

=head1 EXPORTABLE FUNCTIONS

=head2 Debugging (Tag :debug)

=cut

#### debug subs ####

=over

=item mysql_debug_packet \%packet

=item mysql_debug_packet \%packet, $file_handle

Dumps a textual representation of the packet to STDERR or the given handle.

=cut

sub mysql_debug_packet {
    my $packet = $_[0];
    my $stream = $_[1] || \*STDERR;
    while (my ($k, $v) = each %$packet) {
        if ($k eq 'row') {
            $v = "@$v";
        }
        elsif ($k eq 'server_capa') {
            $v = sprintf('%16b', $v) . ' = ' . join ' | ', grep { $v & eval } @{ $EXPORT_TAGS{CLIENT} };
        }
        elsif ($k eq 'crypt_seed') {
            $v = unpack 'H*', $v;
        }
        print $stream "$k\t=>\t$v\n";
    }
    return;
}

=back

=head2 Packet Type Tests (Tag :test)

These functions operate on $_ if no data argument is given.  They must be used
only after L</mysql_decode_header> has succeeded.

=cut

#### packet testing subs ####

=over

=item $bool = mysql_test_var \%packet;

=item $bool = mysql_test_var \%packet, $data

Returns true if the data encodes a variable-length binary number or string.

=cut

sub mysql_test_var {
    local $_ = $_[1] if exists $_[1];
    length && do {
        my $x = ord;
        $x <= 0xfd ||
        $x == 0xfe && $_[0]{packet_size} >= 9
    };
}

=item $bool = mysql_test_end \%packet

=item $bool = mysql_test_end \%packet, $data

Returns true if the data is an end packet (often called EOF packet).

=cut

sub mysql_test_end {
    local $_ = $_[1] if exists $_[1];
    length && ord == 0xfe && $_[0]{packet_size} < 9;
}

=item $bool = mysql_test_error \%packet

=item $bool = mysql_test_error \%packet, $data

Returns true if the data is an error packet.

=cut

sub mysql_test_error {
    local $_ = $_[1] if exists $_[1];
    length && ord == 0xff;
}

=back

=head2 Decoding Packets (Tag :decode)

These functions take either a hash reference (to be populated with packet
information), or a scalar (to receive a number or string).  The optional
second argument is always the data to decode.  If omitted, $_ is used instead,
and bytes are consumed from the beginning of $_ as it is processed.

All except L</mysql_decode_skip> return the number of bytes consumed, -1 if the
data is invalid, or 0 if processing cannot continue until there is more data
available.  If the return is -1 there is no way to continue, and an unknown
number of bytes may have been consumed.

=cut

#### packet decoding subs ####

=over

=item $rc = mysql_decode_header \%packet

=item $rc = mysql_decode_header \%packet, $data

Populates %packet with header information.  This always has to be done before
any other decoding subs, or any testing subs, are used.

    packet_size         => size of packet body
    packet_serial       => packet serial number from 0 to 255

=cut

sub mysql_decode_header {
    local $_ = $_[1] if exists $_[1];
    return 0 unless 4 <= length;
    my $header = unpack 'V', substr $_, 0, 4, '';
    $_[0]{packet_size} = $header & 0xffffff;
    $_[0]{packet_serial} = $header >> 24;
    return 4;
}

=item $rc = mysql_decode_skip \%packet

=item $rc = mysql_decode_skip \%packet, $data

If the number of available bytes is equal to or greater than the packet size,
consumes that many bytes and returns them.  Otherwise, returns undef.

=cut

sub mysql_decode_skip {
    local $_ = $_[1] if exists $_[1];
    return undef unless $_[0]{packet_size} <= length;
    substr $_, 0, $_[0]{packet_size}, '';
}

=item $rc = mysql_decode_varnum $number

=item $rc = mysql_decode_varnum $number, $data

Consumes a variable-length binary number and stores it in $number.  Note that
$number is NOT passed as a reference.

=cut

sub mysql_decode_varnum {
    local $_ = $_[1] if exists $_[1];
    return 0 unless length;
    my $first = ord;
    if ($first < 251) {
        $_[0] = $first;
        substr $_, 0, 1, '';
        return 1;
    }
    elsif ($first == 251) {
        $_[0] = undef;
        substr $_, 0, 1, '';
        return 1;
    }
    elsif ($first == 252) {
        return 0 unless 3 <= length;
        substr $_, 0, 1, '';
        $_[0] = unpack 'v', substr $_, 0, 2, '';
        return 3;
    }
    elsif ($first == 253) {
        return 0 unless 5 <= length;
        substr $_, 0, 1, '';
        $_[0] = unpack 'V', substr $_, 0, 4, '';
        return 5;
    }
    elsif ($first == 254) {
        return 0 unless 9 <= length;
        substr $_, 0, 1, '';
        $_[0] = (unpack 'V', substr $_, 0, 4, '')
              | (unpack 'V', substr $_, 0, 4, '') << 32;
        return 9;
    }
    else {
        return -1;
    }
}

=item $rc = mysql_decode_varstr $string

=item $rc = mysql_decode_varstr $string, $data

Consumes a variable-length string and stores it in $string.  Note that $string
is NOT passed as a reference.

=cut

sub mysql_decode_varstr {
    local $_ = $_[1] if exists $_[1];
    my $length;
    my $i = mysql_decode_varnum $length, $_;
    if ($i <= 0) {
        $i;
    }
    elsif (not defined $length) {
        substr $_, 0, $i, '';
        $_[0] = undef;
        $i;
    }
    elsif ($i + $length <= length) {
        substr $_, 0, $i, '';
        $_[0] = substr $_, 0, $length, '';
        $i + $length;
    }
    else {
        0;
    }
}

=item $rc = mysql_decode_greeting \%packet

=item $rc = mysql_decode_greeting \%packet, $data

Consumes the greeting packet (also called handshake initialization packet)
sent by the server upon connection, and populates %packet.  After this the
client authentication may be encoded and sent.

    protocol_version    => equal to 10 for modern MySQL servers
    server_version      => e.g. "5.0.26-log"
    thread_id           => unique to each active client connection
    crypt_seed          => some random bytes for challenge/response auth
    server_capa         => flags the client may specify during auth
    server_lang         => server's charset number
    server_status       => server status flags

=cut

sub mysql_decode_greeting {
    local $_ = $_[1] if exists $_[1];
    return 0 unless $_[0]{packet_size} <= length;
    # todo: older protocol doesn't include 2nd crypt_seed fragment..
    (
        $_[0]{protocol_version},
        $_[0]{server_version},
        $_[0]{thread_id},
        my $crypt_seed1,
        $_[0]{server_capa},
        $_[0]{server_lang},
        $_[0]{server_status},
        my $crypt_seed2,
    ) = eval {
        unpack 'CZ*Va8xvCvx13a12x', substr $_, 0, $_[0]{packet_size}, ''
    };
    return -1 if $@;    # believe it or not, unpack can be fatal..
                        # todo: investigate performance penalty of eval;
                        #       this could be replaced with cautious logic
    $_[0]{crypt_seed} = $crypt_seed1 . $crypt_seed2;
    return $_[0]{packet_size};
}

=item $rc = mysql_decode_result \%packet

=item $rc = mysql_decode_result \%packet, $data

Consumes a result packet and populates %packet.  Handles OK packets, error
packets, end packets, and result-set header packets.

    Error Packet:

    error       => 1
    errno       => MySQL's errno
    message     => description of error
    sqlstate    => some sort of official 5-digit code

    End Packet:

    end             => 1
    warning_count   => a number
    server_status   => bitwise flags

    OK Packet:

    field_count     => 0
    affected_rows   => a number
    last_insert_id  => a number
    server_status   => bitwise flags
    warning_count   => a number
    message         => some text

    Result Header Packet:

    field_count     => a number greater than zero

=cut

sub mysql_decode_result {
    local $_ = $_[1] if exists $_[1];
    my $n = $_[0]{packet_size};
    return 0 unless $n <= length;
    return do {
        my $type = ord;
        if ($type == 0xff) {
            return -1 unless 3 <= $n;
            substr $_, 0, 1, '';
            $_[0]{error} = 1;
            $_[0]{errno} = unpack 'v', substr $_, 0, 2, '';
            $_[0]{message} = substr $_, 0, $n - 3, '';
            $_[0]{sqlstate} = ($_[0]{message} =~ s/^#// ? substr $_[0]{message}, 0, 5, '' : '');
            $n;
        }
        elsif ($type == 0xfe && $n < 9) {
            if ($n == 1) {
                substr $_, 0, 1, '';
                $_[0]{end} = 1;
                $_[0]{warning_count} = 0;
                $_[0]{server_status} = 0;
                1;
            }
            elsif ($n == 5) {
                substr $_, 0, 1, '';
                $_[0]{end} = 1;
                $_[0]{warning_count} = unpack 'v', substr $_, 0, 2, '';
                $_[0]{server_status} = unpack 'v', substr $_, 0, 2, '';
                5;
            }
            else {
                return -1;
            }
        }
        elsif ($type > 0) {
            my $i = 0;
            my $j;
            0 >= ($j = mysql_decode_varnum $_[0]{field_count}) ? (return -1) : ($i += $j);
            0 >= ($j = mysql_decode_varnum $_[0]{extra}) ? (return -1) : ($i += $j) if $i < $n;
            $i;
        }
        else {
            substr $_, 0, 1, '';
            my $i = 1;
            my $j;
            $_[0]{field_count} = 0;
            0 >= ($j = mysql_decode_varnum $_[0]{affected_rows}) ? (return -1) : ($i += $j);
            0 >= ($j = mysql_decode_varnum $_[0]{last_insert_id}) ? (return -1) : ($i += $j);
            $_[0]{server_status} = unpack 'v', substr $_, 0, 2, ''; $i += 2;
            # todo: older protocol has no warning_count here
            $_[0]{warning_count} = unpack 'v', substr $_, 0, 2, ''; $i += 2;
            0 >= ($j = mysql_decode_varstr $_[0]{message}) ? (return -1) : ($i += $j) if $i < $n;
            $i;
        }
    } == $n ? $n : -1;
}

=item $rc = mysql_decode_field \%packet

=item $rc = mysql_decode_field \%packet, $data

Consumes a field packet and populates %packet.

    catalog         => catalog name
    db              => database name
    table           => table name after aliasing
    org_table       => original table name
    name            => field name after aliasing
    org_name        => original field name
    charset_no      => field character set number
    display_length  => suggested field display width
    field_type      => a number from 0 to 255
    flags           => bitwise flags
    scale           => number of digits after decimal point

=cut

sub mysql_decode_field {
    local $_ = $_[1] if exists $_[1];
    return 0 unless $_[0]{packet_size} <= length;
    my $i = 0;
    my $j;
    # todo: this is different in older protocol..
    0 >= ($j = mysql_decode_varstr $_[0]{catalog})      ? (return -1) : ($i += $j);
    0 >= ($j = mysql_decode_varstr $_[0]{db})           ? (return -1) : ($i += $j);
    0 >= ($j = mysql_decode_varstr $_[0]{table})        ? (return -1) : ($i += $j);
    0 >= ($j = mysql_decode_varstr $_[0]{org_table})    ? (return -1) : ($i += $j);
    0 >= ($j = mysql_decode_varstr $_[0]{name})         ? (return -1) : ($i += $j);
    0 >= ($j = mysql_decode_varstr $_[0]{org_name})     ? (return -1) : ($i += $j);
    substr $_, 0, 1, ''; $i += 1;
    $_[0]{charset_no} = unpack 'v', substr $_, 0, 2, ''; $i += 2;
    $_[0]{display_length} = unpack 'V', substr $_, 0, 4, ''; $i += 4;
    $_[0]{field_type} = ord substr $_, 0, 1, ''; $i += 1;
    $_[0]{flags} = unpack 'v', substr $_, 0, 2, ''; $i += 2;
    $_[0]{scale} = ord substr $_, 0, 1, ''; $i += 1;
    substr $_, 0, 2, ''; $i += 2;
    # when do we read "default" ?
    $i == $_[0]{packet_size} ? $i : -1;
}

=item $rc = mysql_decode_row \%packet

=item $rc = mysql_decode_row \%packet, $data

Consumes a row packet and populates %packet.

    row => ref to array of (stringified) values

=cut

sub mysql_decode_row {
    local $_ = $_[1] if exists $_[1];
    return 0 unless $_[0]{packet_size} <= length;
    my ($n, $i, $j);
    for ($n = 0, $i = 0; $i < $_[0]{packet_size}; $i += $j) {
        return -1 if 0 >= ($j = mysql_decode_varstr $_[0]{row}[$n++]);
    }
    $i == $_[0]{packet_size} ? $i : -1;
}

=back

=head2 Encoding Packets (Tag :encode)

These functions all return the encoded binary data.

=cut

#### packet encoding subs ####

=over

=item $header_data = mysql_encode_header $packet_data

=item $header_data = mysql_encode_header $packet_data, $packet_serial

Returns the header for the already encoded packet.  The serial number defaults
to 0 which is fine except for the authentication packet, for which it must be
1.

=cut

sub mysql_encode_header {
    pack 'V', length($_[0]) | (exists $_[1] ? $_[1] << 24 : 0);
}

=item $data = mysql_encode_varnum $number

Returns the variable-length binary encoding for $number.

=cut

sub mysql_encode_varnum {
    my $num = $_[0];
    $num <= 250         ? chr($num)                     :
    $num <= 0xffff      ? chr(252) . pack('v', $num)    :
    $num <= 0xffffffff  ? chr(253) . pack('V', $num)    :
    chr(254) . pack('V', $num & 0xffffffff) . pack('V', $num >> 32);
}

=item $data = mysql_encode_varnum $string

Returns the variable-length binary encoding for $string.

=cut

sub mysql_encode_varstr {
    map { mysql_encode_varnum(length) . $_ } @_;
}

=item $data = mysql_encode_client_auth @args

Returns the payload for an authentication packet where @args =
($flags, $max_packet_size, $charset_no, $username, $crypt_pw, $database).
The $database is optional.

=cut

sub mysql_encode_client_auth {
    my (
        $flags,
        $max_packet_size,
        $charset_no,
        $username,
        $crypt_pw,
        $database,
    ) = @_;
    my $packet = pack 'VVCx23Z*a*', (
        $flags,
        $max_packet_size,
        $charset_no,
        $username,
        mysql_encode_varstr($crypt_pw),
    );
    $packet .= pack 'Z*', $database if $flags & CLIENT_CONNECT_WITH_DB;
    return $packet;
}

=item $data = mysql_encode_com_quit

Encodes the QUIT command.  Takes no arguments.

=cut

sub mysql_encode_com_quit {
    chr(COM_QUIT);
}

=item $data = mysql_encode_com_query @sql

Encodes the QUERY command, using the concatenation of the arguments as the SQL
string.

=cut

sub mysql_encode_com_query {
    chr(COM_QUERY) . join '', @_;
}

=back

=head2 Password Cryption (Tag :crypt)

=cut

#### mysql challenge/response crypt ####

=over

=item $crypt_pw = mysql_crypt $password, $crypt_seed

Implements MySQL's crypt algorithm to crypt a plaintext $password using the
$crypt_seed from the greeting packet.  Returns a binary string suitable for
passing to L</mysql_encode_client_auth>.  Requires either Digest::SHA
or Digest::SHA1.

=cut

sub mysql_crypt {
    my ($pass, $salt) = @_;
    my $crypt1 = sha1 $pass;
    my $crypt2 = sha1 ($salt . sha1 $crypt1);
    return $crypt1 ^ $crypt2;
}

=back

=cut

1;

__END__

=head1 BUGS

Most client commands are unimplemented.  Does not handle the pre-v4.1 protocol
and could mess up in unpredictable ways (even fatal exceptions) if you try.
It's possible to get a fatal exception calling a decode function on the wrong
data, since Perl's unpack can barf fatally (this got me by surprise after the
code was written, so all the unpack calls need to be audited now).

And so forth.

=head1 SEE ALSO

The MySQL client/server protocol at
L<http://dev.mysql.com/doc/internals/en/client-server-protocol.html>.

=head1 ACKNOWLEDGEMENTS

Thanks to those on #poe for their help with packaging and CPAN.

Thanks to Rob for giving me a good reason to write this!

=head1 LICENSE

Copyright (c) 2007 Tavin Cole C<< <tavin at cpan.org> >>.

MySQL::Packet is free software and is licensed under the same terms as
Perl itself.

It's interesting to read this licensing notice:
L<http://dev.mysql.com/doc/internals/en/licensing-notice.html>

MySQL AB seems to think that any software which communicates with a MySQL
server must be GPL'd, because the protocol is GPL.  However, they have been
quoted in interviews saying that isn't true after all, and that in any case
they don't really care.

