package Net::WAMP::RawSocket::Constants;

use strict;
use warnings;

use constant {
    MAGIC_FIRST_OCTET => 0x7f,

    MAX_MESSAGE_LENGTH => 2**23,  #8 MiB

    SERIALIZERS => [
        undef,
        'json',
        'msgpack',
    ],

    HANDSHAKE_ERR_1 => 'serializer unsupported',
    HANDSHAKE_ERR_2 => 'maximum message length unacceptable',
    HANDSHAKE_ERR_3 => 'use of reserved bits (unsupported feature)',
    HANDSHAKE_ERR_4 => 'maximum connection count reached',

    HEADER_LENGTH => 4,
};

use constant DEFAULT_SERIALIZATION => SERIALIZERS()->[1];

sub get_serialization_code {
    my ($name) = @_;

    my $SERIALIZER_AR = SERIALIZERS();

    my ($serializer_code) = grep { $SERIALIZER_AR->[$_] eq $name } ( 1 .. $#$SERIALIZER_AR );
    if (!$serializer_code) {
        die "Unknown serializer: “$name”";
    }

    return $serializer_code;
}

sub get_serialization_name {
    my ($code) = @_;

    return SERIALIZERS()->[$code] || do {
        die "Unknown serialization code: [$code]";
    };
}

sub get_max_length_code {
    my ($val) = @_;

    sprintf('%b', $val) =~ m<\A1(0{9,24})\z> or do {
        die "Invalid max message length: $val";
    };

    return length($1) - 9;
}

sub get_max_length_value {
    my ($code) = @_;

    return 2 ** (9 + $code);
}

1;
