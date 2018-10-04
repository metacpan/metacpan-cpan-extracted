package Protocol::DBus::Message::Header;

use strict;
use warnings;

use Call::Context ();

use Protocol::DBus::Marshal ();
use Protocol::DBus::Pack ();

# This just gets us to the length of the headers array.
use constant {
    _MIN_HEADER_LENGTH => 16,

    # The spec says to parse as array of pairs, but a dict makes
    # more sense and is compatible. (The spec doesn’t proscribe
    # duplicate headers, but the reference implementation does.)
    SIGNATURE => 'yyyyuua{yv}',

    MESSAGE_TYPE => {
        METHOD_CALL => 1,
        METHOD_RETURN => 2,
        ERROR => 3,
        SIGNAL => 4,
    },

    FLAG => {
        NO_REPLY_EXPECTED => 1,
        NO_AUTO_START => 2,
        ALLOW_INTERACTIVE_AUTHORIZATION => 4,
    },

    FIELD => {
        PATH => 1,
        INTERFACE => 2,
        MEMBER => 3,
        ERROR_NAME => 4,
        REPLY_SERIAL => 5,
        DESTINATION => 6,
        SENDER => 7,
        SIGNATURE => 8,
        UNIX_FDS => 9,
    },

    FIELD_SIGNATURE => {
        PATH => 'o',
        INTERFACE => 's',
        MEMBER => 's',
        ERROR_NAME => 's',
        REPLY_SERIAL => 'u',
        DESTINATION => 's',
        SENDER => 's',
        SIGNATURE => 'g',
        UNIX_FDS => 'u',
    },
};

my ($_is_big_endian, $prot_version);

sub parse_simple {
    my ($buf_sr) = @_;

    Call::Context::must_be_list();

    if (length($$buf_sr) >= _MIN_HEADER_LENGTH()) {
        ($_is_big_endian, $prot_version) = unpack 'axxC', $$buf_sr;

        if (1 != $prot_version) {
            die "Protocol version must be 1, not “$prot_version”!";
        }

        $_is_big_endian = ($_is_big_endian eq 'B') ? 1 : ($_is_big_endian eq 'l') ? 0 : die "Invalid endian byte: “$_is_big_endian”!";

        my $array_length = unpack(
            '@12 ' . ($_is_big_endian ? 'N' : 'V'),
            $$buf_sr,
        );

        if (length($$buf_sr) >= (_MIN_HEADER_LENGTH + $array_length)) {
            my ($content, $length) = Protocol::DBus::Marshal->can(
                $_is_big_endian ? 'unmarshal_be' : 'unmarshal_le'
            )->($buf_sr, 0, SIGNATURE());

            Protocol::DBus::Pack::align( $length, 8 );

            return( $content, $length, $_is_big_endian );
        }
    }

    return;
}

1;
