package Net::WebSocket::Constants;

use strict;
use warnings;

use constant OPCODE => {
    continuation => 0,
    text => 1,
    binary => 2,
    close => 8,
    ping => 9,
    pong => 10,
};

use constant {
    PROTOCOL_VERSION => 13,
    REQUIRED_HTTP_METHOD => 'GET',
    REQUIRED_HTTP_STATUS => 101,
    REQUIRED_REQUEST_PROTOCOL => 'HTTP/1.1',
};

#These names are taken from:
#https://msdn.microsoft.com/en-us/library/windows/desktop/hh449350(v=vs.85).aspx
# … however, the up-to-date list of canonical codes is at:
#https://www.iana.org/assignments/websocket/websocket.xml
use constant STATUS => {
    SUCCESS                => 1000,
    ENDPOINT_UNAVAILABLE   => 1001,
    PROTOCOL_ERROR         => 1002,
    INVALID_DATA_TYPE      => 1003,

    #These are never actually sent.
    #EMPTY_CLOSE            => 1005,
    #ABORTED_CLOSE          => 1006,

    INVALID_PAYLOAD        => 1007,
    POLICY_VIOLATION       => 1008,
    MESSAGE_TOO_BIG        => 1009,
    UNSUPPORTED_EXTENSIONS => 1010,

    #Post-RFC, “server error” was changed to “internal error”.
    #We accept both names; code-to-name conversion always returns this one.
    INTERNAL_ERROR         => 1011,
    SERVER_ERROR           => 1011,

    #These are part of the IANA registry but are not in Microsoft’s enum.
    SERVICE_RESTART         => 1012,
    TRY_AGAIN_LATER         => 1013,
    BAD_GATEWAY             => 1014,

    #RFC says not to use this one,
    #but MS has it in their enum.
    #SECURE_HANDSHAKE_ERROR => 1015,
};

#----------------------------------------------------------------------

my %status_code_name;

sub status_name_to_code {
    my ($name) = @_;

    return STATUS()->{$name};
}

sub status_code_to_name {
    my ($code) = @_;

    if (!%status_code_name) {
        my %copy = %{ STATUS() };
        delete $copy{'SERVER_ERROR'};
        %status_code_name = reverse %copy;
    }

    return $status_code_name{$code};
}

#----------------------------------------------------------------------

my %opcode_type;

sub opcode_to_type {
    my ($opcode) = @_;

    %opcode_type = reverse %{ OPCODE() } if !%opcode_type;

    return $opcode_type{$opcode};
}

1;
