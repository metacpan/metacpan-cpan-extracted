####################################################################
#
#     This file was generated using XDR::Parse version v0.3.1,
#        XDR::Gen version 0.0.2 and LibVirt version v10.3.0
#
#      Don't edit this file, use the source template instead
#
#                 ANY CHANGES HERE WILL BE LOST !
#
####################################################################

package Protocol::Sys::Virt::Transport::XDR v10.3.4;

use v5.14;
use warnings FATAL => 'uninitialized';
use Config;
use Carp qw(croak);
use constant INITIAL => 65536; # 65536
use constant LEGACY_PAYLOAD_MAX => 262120; # 262120
use constant MAX => 33554432; # 33554432
use constant HEADER_MAX => 24; # 24
use constant PAYLOAD_MAX => 33554408; # 33554408
use constant LEN_MAX => 4; # 4
use constant STRING_MAX => 4194304; # 4194304
use constant NUM_FDS_MAX => 32; # 32
# Define elements from enum 'Type'
use constant {
    CALL           => 0,
    REPLY          => 1,
    MESSAGE        => 2,
    STREAM         => 3,
    CALL_WITH_FDS  => 4,
    REPLY_WITH_FDS => 5,
    STREAM_HOLE    => 6,
};
# @_: ($class, $value, $index, $input) = @_;
sub deserialize_Type {
    my $input_length = length $_[3];
    # my ($class, $value, $index, $input) = @_;
    die "Input buffer too short"
        if ($input_length - $_[2]) < 4;
    $_[1] = unpack("l>", substr( $_[3], $_[2] ) );
    die "Out of range enum value supplied: $_[1]"
        unless vec(state $m = pack('H*', '7f'),
                   $_[1], 1);
    $_[2] += 4;
}
# @_: ($class, $value, $index, $output) = @_;
sub serialize_Type {
    # my ($class, $value, $index, $output) = @_;
    croak "Missing required input 'enum' value"
        unless defined $_[1];
    die "Out of range enum value: $_[1]"
        unless vec(state $m = pack('H*', '7f'),
                   $_[1], 1);
    substr( $_[3], $_[2] ) = pack("l>", $_[1]);
    $_[2] += 4;
}
# Define elements from enum 'Status'
use constant {
    OK       => 0,
    ERROR    => 1,
    CONTINUE => 2,
};
# @_: ($class, $value, $index, $input) = @_;
sub deserialize_Status {
    my $input_length = length $_[3];
    # my ($class, $value, $index, $input) = @_;
    die "Input buffer too short"
        if ($input_length - $_[2]) < 4;
    $_[1] = unpack("l>", substr( $_[3], $_[2] ) );
    die "Out of range enum value supplied: $_[1]"
        unless vec(state $m = pack('H*', '07'),
                   $_[1], 1);
    $_[2] += 4;
}
# @_: ($class, $value, $index, $output) = @_;
sub serialize_Status {
    # my ($class, $value, $index, $output) = @_;
    croak "Missing required input 'enum' value"
        unless defined $_[1];
    die "Out of range enum value: $_[1]"
        unless vec(state $m = pack('H*', '07'),
                   $_[1], 1);
    substr( $_[3], $_[2] ) = pack("l>", $_[1]);
    $_[2] += 4;
}
use constant HEADER_XDR_LEN => 4; # 4
# @_: ($class, $value, $index, $input) = @_;
sub deserialize_Header {
    my $input_length = length $_[3];
    $_[1] = {};
    # Deserializing field: 'prog'
    # my ($class, $value, $index, $input) = @_;
    die "Input buffer too short"
        if ($input_length - $_[2]) < 4;
    $_[1]->{prog} = unpack("L>", substr( $_[3], $_[2] ));
    $_[2] += 4;
    die "Out of bounds 'unsigned int': $_[1]->{prog}"
        unless (0 <= $_[1]->{prog} and $_[1]->{prog} <= 4294967295);

    # Deserializing field: 'vers'
    # my ($class, $value, $index, $input) = @_;
    die "Input buffer too short"
        if ($input_length - $_[2]) < 4;
    $_[1]->{vers} = unpack("L>", substr( $_[3], $_[2] ));
    $_[2] += 4;
    die "Out of bounds 'unsigned int': $_[1]->{vers}"
        unless (0 <= $_[1]->{vers} and $_[1]->{vers} <= 4294967295);

    # Deserializing field: 'proc'
    # my ($class, $value, $index, $input) = @_;
    die "Input buffer too short"
        if ($input_length - $_[2]) < 4;
    $_[1]->{proc} = unpack("l>", substr( $_[3], $_[2] ));
    $_[2] += 4;
    die "Out of bounds 'int': $_[1]->{proc}"
        unless (-2147483648 <= $_[1]->{proc} and $_[1]->{proc} < 2147483648);

    # Deserializing field: 'type'
    # my ($class, $value, $index, $input) = @_;
    $_[0]->deserialize_Type( $_[1]->{type}, $_[2], $_[3] );

    # Deserializing field: 'serial'
    # my ($class, $value, $index, $input) = @_;
    die "Input buffer too short"
        if ($input_length - $_[2]) < 4;
    $_[1]->{serial} = unpack("L>", substr( $_[3], $_[2] ));
    $_[2] += 4;
    die "Out of bounds 'unsigned int': $_[1]->{serial}"
        unless (0 <= $_[1]->{serial} and $_[1]->{serial} <= 4294967295);

    # Deserializing field: 'status'
    # my ($class, $value, $index, $input) = @_;
    $_[0]->deserialize_Status( $_[1]->{status}, $_[2], $_[3] );
}
# @_: ($class, $value, $index, $output) = @_;
sub serialize_Header {
    croak "Missing required input 'struct' value"
        unless defined $_[1];

    # Serializing field: 'prog'
    # my ($class, $value, $index, $output) = @_;
    croak "Missing required input 'unsigned int' value"
        unless defined $_[1]->{prog};
    die "Out of bounds 'unsigned int': $_[1]->{prog}"
        unless (0 <= $_[1]->{prog} and $_[1]->{prog} <= 4294967295);
    die "Non-integer 'int' value given: $_[1]->{prog}"
        unless int($_[1]->{prog}) == $_[1]->{prog};
    substr( $_[3], $_[2] ) = pack("L>", $_[1]->{prog});
    $_[2] += 4;

    # Serializing field: 'vers'
    # my ($class, $value, $index, $output) = @_;
    croak "Missing required input 'unsigned int' value"
        unless defined $_[1]->{vers};
    die "Out of bounds 'unsigned int': $_[1]->{vers}"
        unless (0 <= $_[1]->{vers} and $_[1]->{vers} <= 4294967295);
    die "Non-integer 'int' value given: $_[1]->{vers}"
        unless int($_[1]->{vers}) == $_[1]->{vers};
    substr( $_[3], $_[2] ) = pack("L>", $_[1]->{vers});
    $_[2] += 4;

    # Serializing field: 'proc'
    # my ($class, $value, $index, $output) = @_;
    croak "Missing required input 'int' value"
        unless defined $_[1]->{proc};
    die "Out of bounds 'int': $_[1]->{proc}"
        unless (-2147483648 <= $_[1]->{proc} and $_[1]->{proc} < 2147483648);
    die "Non-integer 'int' value given: $_[1]->{proc}"
        unless int($_[1]->{proc}) == $_[1]->{proc};
    substr( $_[3], $_[2] ) = pack("l>", $_[1]->{proc});
    $_[2] += 4;

    # Serializing field: 'type'
    # my ($class, $value, $index, $output) = @_;
    croak "Missing required input 'Type' value"
        unless defined $_[1]->{type};
    $_[0]->serialize_Type( $_[1]->{type}, $_[2], $_[3] );

    # Serializing field: 'serial'
    # my ($class, $value, $index, $output) = @_;
    croak "Missing required input 'unsigned int' value"
        unless defined $_[1]->{serial};
    die "Out of bounds 'unsigned int': $_[1]->{serial}"
        unless (0 <= $_[1]->{serial} and $_[1]->{serial} <= 4294967295);
    die "Non-integer 'int' value given: $_[1]->{serial}"
        unless int($_[1]->{serial}) == $_[1]->{serial};
    substr( $_[3], $_[2] ) = pack("L>", $_[1]->{serial});
    $_[2] += 4;

    # Serializing field: 'status'
    # my ($class, $value, $index, $output) = @_;
    croak "Missing required input 'Status' value"
        unless defined $_[1]->{status};
    $_[0]->serialize_Status( $_[1]->{status}, $_[2], $_[3] );
}
# @_: ($class, $value, $index, $input) = @_;
sub deserialize_UUID {
    my $input_length = length $_[3];
    # my ($class, $value, $index, $input) = @_;
    die "Input buffer too short"
        if ($input_length - $_[2]) < 16;
    $_[1] = substr( $_[3], $_[2], 16 );
    $_[2] += 16;
}
# @_: ($class, $value, $index, $output) = @_;
sub serialize_UUID {
    # my ($class, $value, $index, $output) = @_;
    croak "Missing required input 'opaque' value"
        unless defined $_[1];
    do {
        my $len = length $_[1];
        die "Opaque value length mismatch (defined: 16): $len"
            if not $len  == 16;

        substr( $_[3], $_[2] ) = $_[1];
        $_[2] += $len;
    };
}
# @_: ($class, $value, $index, $input) = @_;
sub deserialize_NonnullString {
    my $input_length = length $_[3];
    # my ($class, $value, $index, $input) = @_;
    do {
        die "Input buffer too short"
            if ($input_length - $_[2]) < 4;
        my $len = unpack("L>", substr( $_[3], $_[2] ));
        $_[2] += 4;
        die "String too long (max: 4194304): $len"
            unless ($len <= 4194304);
        die "Input buffer too short"
            if ($input_length - $_[2]) < $len;
        $_[1] = substr( $_[3], $_[2], $len );
        $_[2] += $len + ((4 - ($len % 4)) % 4); # skip padding too
    };
}
# @_: ($class, $value, $index, $output) = @_;
sub serialize_NonnullString {
    # my ($class, $value, $index, $output) = @_;
    do {
        my $len = length $_[1];
        croak "Missing required input 'string' value"
            unless defined $_[1];
        die "String too long (max: 4194304): $len"
            unless ($len <= 4194304);

        substr( $_[3], $_[2] ) = pack("L>", $len);
        $_[2] += 4;
        substr( $_[3], $_[2] ) = $_[1];
        $_[2] += $len;
        if (my $pad = ((4 - ($len % 4)) % 4)) {
            substr( $_[3], $_[2] ) = ("\0" x $pad);
            $_[2] += $pad;
        }
    };
}
# @_: ($class, $value, $index, $input) = @_;
sub deserialize_String {
    my $input_length = length $_[3];
    # my ($class, $value, $index, $input) = @_;
    do {
        my $b;
        # my ($class, $value, $index, $input) = @_;
        die "Input buffer too short"
            if ($input_length - $_[2]) < 4;
        $b = unpack("L>", substr( $_[3], $_[2] ));
        die "Incorrect bool value $b (must be 0 or 1)"
            unless $b == 0 or $b == 1;
        $_[2] += 4;
        if ($b) {
            # my ($class, $value, $index, $input) = @_;
            $_[0]->deserialize_NonnullString( $_[1], $_[2], $_[3] );
        }
        else {
            $_[1] = undef;
        }
    };
}
# @_: ($class, $value, $index, $output) = @_;
sub serialize_String {
    # my ($class, $value, $index, $output) = @_;
    if (defined $_[1]) {
        # my ($class, $value, $index, $output) = @_;
        # Allow <undef> to model a <false> value
        substr( $_[3], $_[2] ) = pack("L>", 1);
        $_[2] += 4;
        # my ($class, $value, $index, $output) = @_;
        croak "Missing required input 'NonnullString' value"
            unless defined $_[1];
        $_[0]->serialize_NonnullString( $_[1], $_[2], $_[3] );
    }
    else {
        # my ($class, $value, $index, $output) = @_;
        # Allow <undef> to model a <false> value
        substr( $_[3], $_[2] ) = pack("L>", 0);
        $_[2] += 4;
    }
}
# @_: ($class, $value, $index, $input) = @_;
sub deserialize_NonnullDomain {
    my $input_length = length $_[3];
    $_[1] = {};
    # Deserializing field: 'name'
    # my ($class, $value, $index, $input) = @_;
    $_[0]->deserialize_NonnullString( $_[1]->{name}, $_[2], $_[3] );

    # Deserializing field: 'uuid'
    # my ($class, $value, $index, $input) = @_;
    $_[0]->deserialize_UUID( $_[1]->{uuid}, $_[2], $_[3] );

    # Deserializing field: 'id'
    # my ($class, $value, $index, $input) = @_;
    die "Input buffer too short"
        if ($input_length - $_[2]) < 4;
    $_[1]->{id} = unpack("l>", substr( $_[3], $_[2] ));
    $_[2] += 4;
    die "Out of bounds 'int': $_[1]->{id}"
        unless (-2147483648 <= $_[1]->{id} and $_[1]->{id} < 2147483648);
}
# @_: ($class, $value, $index, $output) = @_;
sub serialize_NonnullDomain {
    croak "Missing required input 'struct' value"
        unless defined $_[1];

    # Serializing field: 'name'
    # my ($class, $value, $index, $output) = @_;
    croak "Missing required input 'NonnullString' value"
        unless defined $_[1]->{name};
    $_[0]->serialize_NonnullString( $_[1]->{name}, $_[2], $_[3] );

    # Serializing field: 'uuid'
    # my ($class, $value, $index, $output) = @_;
    croak "Missing required input 'UUID' value"
        unless defined $_[1]->{uuid};
    $_[0]->serialize_UUID( $_[1]->{uuid}, $_[2], $_[3] );

    # Serializing field: 'id'
    # my ($class, $value, $index, $output) = @_;
    croak "Missing required input 'int' value"
        unless defined $_[1]->{id};
    die "Out of bounds 'int': $_[1]->{id}"
        unless (-2147483648 <= $_[1]->{id} and $_[1]->{id} < 2147483648);
    die "Non-integer 'int' value given: $_[1]->{id}"
        unless int($_[1]->{id}) == $_[1]->{id};
    substr( $_[3], $_[2] ) = pack("l>", $_[1]->{id});
    $_[2] += 4;
}
# @_: ($class, $value, $index, $input) = @_;
sub deserialize_NonnullNetwork {
    my $input_length = length $_[3];
    $_[1] = {};
    # Deserializing field: 'name'
    # my ($class, $value, $index, $input) = @_;
    $_[0]->deserialize_NonnullString( $_[1]->{name}, $_[2], $_[3] );

    # Deserializing field: 'uuid'
    # my ($class, $value, $index, $input) = @_;
    $_[0]->deserialize_UUID( $_[1]->{uuid}, $_[2], $_[3] );
}
# @_: ($class, $value, $index, $output) = @_;
sub serialize_NonnullNetwork {
    croak "Missing required input 'struct' value"
        unless defined $_[1];

    # Serializing field: 'name'
    # my ($class, $value, $index, $output) = @_;
    croak "Missing required input 'NonnullString' value"
        unless defined $_[1]->{name};
    $_[0]->serialize_NonnullString( $_[1]->{name}, $_[2], $_[3] );

    # Serializing field: 'uuid'
    # my ($class, $value, $index, $output) = @_;
    croak "Missing required input 'UUID' value"
        unless defined $_[1]->{uuid};
    $_[0]->serialize_UUID( $_[1]->{uuid}, $_[2], $_[3] );
}
# @_: ($class, $value, $index, $input) = @_;
sub deserialize_Domain {
    my $input_length = length $_[3];
    # my ($class, $value, $index, $input) = @_;
    do {
        my $b;
        # my ($class, $value, $index, $input) = @_;
        die "Input buffer too short"
            if ($input_length - $_[2]) < 4;
        $b = unpack("L>", substr( $_[3], $_[2] ));
        die "Incorrect bool value $b (must be 0 or 1)"
            unless $b == 0 or $b == 1;
        $_[2] += 4;
        if ($b) {
            # my ($class, $value, $index, $input) = @_;
            $_[0]->deserialize_NonnullDomain( $_[1], $_[2], $_[3] );
        }
        else {
            $_[1] = undef;
        }
    };
}
# @_: ($class, $value, $index, $output) = @_;
sub serialize_Domain {
    # my ($class, $value, $index, $output) = @_;
    if (defined $_[1]) {
        # my ($class, $value, $index, $output) = @_;
        # Allow <undef> to model a <false> value
        substr( $_[3], $_[2] ) = pack("L>", 1);
        $_[2] += 4;
        # my ($class, $value, $index, $output) = @_;
        croak "Missing required input 'NonnullDomain' value"
            unless defined $_[1];
        $_[0]->serialize_NonnullDomain( $_[1], $_[2], $_[3] );
    }
    else {
        # my ($class, $value, $index, $output) = @_;
        # Allow <undef> to model a <false> value
        substr( $_[3], $_[2] ) = pack("L>", 0);
        $_[2] += 4;
    }
}
# @_: ($class, $value, $index, $input) = @_;
sub deserialize_Network {
    my $input_length = length $_[3];
    # my ($class, $value, $index, $input) = @_;
    do {
        my $b;
        # my ($class, $value, $index, $input) = @_;
        die "Input buffer too short"
            if ($input_length - $_[2]) < 4;
        $b = unpack("L>", substr( $_[3], $_[2] ));
        die "Incorrect bool value $b (must be 0 or 1)"
            unless $b == 0 or $b == 1;
        $_[2] += 4;
        if ($b) {
            # my ($class, $value, $index, $input) = @_;
            $_[0]->deserialize_NonnullNetwork( $_[1], $_[2], $_[3] );
        }
        else {
            $_[1] = undef;
        }
    };
}
# @_: ($class, $value, $index, $output) = @_;
sub serialize_Network {
    # my ($class, $value, $index, $output) = @_;
    if (defined $_[1]) {
        # my ($class, $value, $index, $output) = @_;
        # Allow <undef> to model a <false> value
        substr( $_[3], $_[2] ) = pack("L>", 1);
        $_[2] += 4;
        # my ($class, $value, $index, $output) = @_;
        croak "Missing required input 'NonnullNetwork' value"
            unless defined $_[1];
        $_[0]->serialize_NonnullNetwork( $_[1], $_[2], $_[3] );
    }
    else {
        # my ($class, $value, $index, $output) = @_;
        # Allow <undef> to model a <false> value
        substr( $_[3], $_[2] ) = pack("L>", 0);
        $_[2] += 4;
    }
}
# @_: ($class, $value, $index, $input) = @_;
sub deserialize_Error {
    my $input_length = length $_[3];
    $_[1] = {};
    # Deserializing field: 'code'
    # my ($class, $value, $index, $input) = @_;
    die "Input buffer too short"
        if ($input_length - $_[2]) < 4;
    $_[1]->{code} = unpack("l>", substr( $_[3], $_[2] ));
    $_[2] += 4;
    die "Out of bounds 'int': $_[1]->{code}"
        unless (-2147483648 <= $_[1]->{code} and $_[1]->{code} < 2147483648);

    # Deserializing field: 'domain'
    # my ($class, $value, $index, $input) = @_;
    die "Input buffer too short"
        if ($input_length - $_[2]) < 4;
    $_[1]->{domain} = unpack("l>", substr( $_[3], $_[2] ));
    $_[2] += 4;
    die "Out of bounds 'int': $_[1]->{domain}"
        unless (-2147483648 <= $_[1]->{domain} and $_[1]->{domain} < 2147483648);

    # Deserializing field: 'message'
    # my ($class, $value, $index, $input) = @_;
    $_[0]->deserialize_String( $_[1]->{message}, $_[2], $_[3] );

    # Deserializing field: 'level'
    # my ($class, $value, $index, $input) = @_;
    die "Input buffer too short"
        if ($input_length - $_[2]) < 4;
    $_[1]->{level} = unpack("l>", substr( $_[3], $_[2] ));
    $_[2] += 4;
    die "Out of bounds 'int': $_[1]->{level}"
        unless (-2147483648 <= $_[1]->{level} and $_[1]->{level} < 2147483648);

    # Deserializing field: 'dom'
    # my ($class, $value, $index, $input) = @_;
    $_[0]->deserialize_Domain( $_[1]->{dom}, $_[2], $_[3] );

    # Deserializing field: 'str1'
    # my ($class, $value, $index, $input) = @_;
    $_[0]->deserialize_String( $_[1]->{str1}, $_[2], $_[3] );

    # Deserializing field: 'str2'
    # my ($class, $value, $index, $input) = @_;
    $_[0]->deserialize_String( $_[1]->{str2}, $_[2], $_[3] );

    # Deserializing field: 'str3'
    # my ($class, $value, $index, $input) = @_;
    $_[0]->deserialize_String( $_[1]->{str3}, $_[2], $_[3] );

    # Deserializing field: 'int1'
    # my ($class, $value, $index, $input) = @_;
    die "Input buffer too short"
        if ($input_length - $_[2]) < 4;
    $_[1]->{int1} = unpack("l>", substr( $_[3], $_[2] ));
    $_[2] += 4;
    die "Out of bounds 'int': $_[1]->{int1}"
        unless (-2147483648 <= $_[1]->{int1} and $_[1]->{int1} < 2147483648);

    # Deserializing field: 'int2'
    # my ($class, $value, $index, $input) = @_;
    die "Input buffer too short"
        if ($input_length - $_[2]) < 4;
    $_[1]->{int2} = unpack("l>", substr( $_[3], $_[2] ));
    $_[2] += 4;
    die "Out of bounds 'int': $_[1]->{int2}"
        unless (-2147483648 <= $_[1]->{int2} and $_[1]->{int2} < 2147483648);

    # Deserializing field: 'net'
    # my ($class, $value, $index, $input) = @_;
    $_[0]->deserialize_Network( $_[1]->{net}, $_[2], $_[3] );
}
# @_: ($class, $value, $index, $output) = @_;
sub serialize_Error {
    croak "Missing required input 'struct' value"
        unless defined $_[1];

    # Serializing field: 'code'
    # my ($class, $value, $index, $output) = @_;
    croak "Missing required input 'int' value"
        unless defined $_[1]->{code};
    die "Out of bounds 'int': $_[1]->{code}"
        unless (-2147483648 <= $_[1]->{code} and $_[1]->{code} < 2147483648);
    die "Non-integer 'int' value given: $_[1]->{code}"
        unless int($_[1]->{code}) == $_[1]->{code};
    substr( $_[3], $_[2] ) = pack("l>", $_[1]->{code});
    $_[2] += 4;

    # Serializing field: 'domain'
    # my ($class, $value, $index, $output) = @_;
    croak "Missing required input 'int' value"
        unless defined $_[1]->{domain};
    die "Out of bounds 'int': $_[1]->{domain}"
        unless (-2147483648 <= $_[1]->{domain} and $_[1]->{domain} < 2147483648);
    die "Non-integer 'int' value given: $_[1]->{domain}"
        unless int($_[1]->{domain}) == $_[1]->{domain};
    substr( $_[3], $_[2] ) = pack("l>", $_[1]->{domain});
    $_[2] += 4;

    # Serializing field: 'message'
    # my ($class, $value, $index, $output) = @_;
    croak "Missing required input 'String' value"
        unless defined $_[1]->{message};
    $_[0]->serialize_String( $_[1]->{message}, $_[2], $_[3] );

    # Serializing field: 'level'
    # my ($class, $value, $index, $output) = @_;
    croak "Missing required input 'int' value"
        unless defined $_[1]->{level};
    die "Out of bounds 'int': $_[1]->{level}"
        unless (-2147483648 <= $_[1]->{level} and $_[1]->{level} < 2147483648);
    die "Non-integer 'int' value given: $_[1]->{level}"
        unless int($_[1]->{level}) == $_[1]->{level};
    substr( $_[3], $_[2] ) = pack("l>", $_[1]->{level});
    $_[2] += 4;

    # Serializing field: 'dom'
    # my ($class, $value, $index, $output) = @_;
    croak "Missing required input 'Domain' value"
        unless defined $_[1]->{dom};
    $_[0]->serialize_Domain( $_[1]->{dom}, $_[2], $_[3] );

    # Serializing field: 'str1'
    # my ($class, $value, $index, $output) = @_;
    croak "Missing required input 'String' value"
        unless defined $_[1]->{str1};
    $_[0]->serialize_String( $_[1]->{str1}, $_[2], $_[3] );

    # Serializing field: 'str2'
    # my ($class, $value, $index, $output) = @_;
    croak "Missing required input 'String' value"
        unless defined $_[1]->{str2};
    $_[0]->serialize_String( $_[1]->{str2}, $_[2], $_[3] );

    # Serializing field: 'str3'
    # my ($class, $value, $index, $output) = @_;
    croak "Missing required input 'String' value"
        unless defined $_[1]->{str3};
    $_[0]->serialize_String( $_[1]->{str3}, $_[2], $_[3] );

    # Serializing field: 'int1'
    # my ($class, $value, $index, $output) = @_;
    croak "Missing required input 'int' value"
        unless defined $_[1]->{int1};
    die "Out of bounds 'int': $_[1]->{int1}"
        unless (-2147483648 <= $_[1]->{int1} and $_[1]->{int1} < 2147483648);
    die "Non-integer 'int' value given: $_[1]->{int1}"
        unless int($_[1]->{int1}) == $_[1]->{int1};
    substr( $_[3], $_[2] ) = pack("l>", $_[1]->{int1});
    $_[2] += 4;

    # Serializing field: 'int2'
    # my ($class, $value, $index, $output) = @_;
    croak "Missing required input 'int' value"
        unless defined $_[1]->{int2};
    die "Out of bounds 'int': $_[1]->{int2}"
        unless (-2147483648 <= $_[1]->{int2} and $_[1]->{int2} < 2147483648);
    die "Non-integer 'int' value given: $_[1]->{int2}"
        unless int($_[1]->{int2}) == $_[1]->{int2};
    substr( $_[3], $_[2] ) = pack("l>", $_[1]->{int2});
    $_[2] += 4;

    # Serializing field: 'net'
    # my ($class, $value, $index, $output) = @_;
    croak "Missing required input 'Network' value"
        unless defined $_[1]->{net};
    $_[0]->serialize_Network( $_[1]->{net}, $_[2], $_[3] );
}
# @_: ($class, $value, $index, $input) = @_;
sub deserialize_StreamHole {
    my $input_length = length $_[3];
    $_[1] = {};
    # Deserializing field: 'length'
    # my ($class, $value, $index, $input) = @_;
    die "Input buffer too short"
        if ($input_length - $_[2]) < 8;
    $_[1]->{length} = unpack("q>", substr( $_[3], $_[2] ));
    $_[2] += 8;
    die "Out of bounds 'hyper': $_[1]->{length}"
        unless (-9223372036854775808 <= $_[1]->{length}
                and $_[1]->{length} < 9223372036854775808);

    # Deserializing field: 'flags'
    # my ($class, $value, $index, $input) = @_;
    die "Input buffer too short"
        if ($input_length - $_[2]) < 4;
    $_[1]->{flags} = unpack("L>", substr( $_[3], $_[2] ));
    $_[2] += 4;
    die "Out of bounds 'unsigned int': $_[1]->{flags}"
        unless (0 <= $_[1]->{flags} and $_[1]->{flags} <= 4294967295);
}
# @_: ($class, $value, $index, $output) = @_;
sub serialize_StreamHole {
    croak "Missing required input 'struct' value"
        unless defined $_[1];

    # Serializing field: 'length'
    # my ($class, $value, $index, $output) = @_;
    croak "Missing required input 'long' value"
        unless defined $_[1]->{length};
    die "Out of bounds 'hyper': $_[1]->{length}"
        unless (-9223372036854775808 <= $_[1]->{length}
                and $_[1]->{length} < 9223372036854775808);
    die "Non-integer 'long' value given: $_[1]->{length}"
        unless int($_[1]->{length}) == $_[1]->{length};
    substr( $_[3], $_[2] ) = pack("q>", $_[1]->{length});
    $_[2] += 8;

    # Serializing field: 'flags'
    # my ($class, $value, $index, $output) = @_;
    croak "Missing required input 'unsigned int' value"
        unless defined $_[1]->{flags};
    die "Out of bounds 'unsigned int': $_[1]->{flags}"
        unless (0 <= $_[1]->{flags} and $_[1]->{flags} <= 4294967295);
    die "Non-integer 'int' value given: $_[1]->{flags}"
        unless int($_[1]->{flags}) == $_[1]->{flags};
    substr( $_[3], $_[2] ) = pack("L>", $_[1]->{flags});
    $_[2] += 4;
}


1;

__END__

=head1 NAME

Protocol::Sys::Virt::Transport::XDR - Protocol header and error constants and (de)serializers

=head1 VERSION

v10.3.4

Based on LibVirt tag v10.3.0

=head1 SYNOPSYS

  use Protocol::Sys::Virt::Transport::XDR;
  my $transport = 'Protocol::Sys::Virt::Transport::XDR';

  my $out = '';
  my $idx = 0;
  my $value = {
     code => 1,
     domain => 1,
     message => 'This is my error',
     level => 1,
     int1 => 0,
     int2 => 0,
  };
  $transport->serialize_Error($value, $idx, $out);

=head1 DESCRIPTION

This module contains the constants and (de)serializers defined by LibVirt
to operate the lowest level of the protocol: the transmission frames, which
consist of a header and the payload.  The elements in this module are defined
in libvirt's source code in the file C<libvirt/src/rpc/virnetprotocol.x>.

Identifiers in this module have been transformed to strip their prefix for
brevity.  These prefixes have been stripped:

=over 8

=item * VIR_NET_MESSAGE_

=item * VIR_NET_

=item * virNetMessage

=item * virNet

=back

=head1 CONSTANTS

=head2 General

=over 8

=item * INITIAL

=item * LEGACY_PAYLOAD_MAX

=item * MAX

=item * HEADER_MAX

=item * PAYLOAD_MAX

=item * LEN_MAX

=item * STRING_MAX

=item * NUM_FDS_MAX

=item * HEADER_XDR_LEN

=back

=head2 From enums

=over 8

=item * Type

=over 8

=item * CALL

=item * REPLY

=item * MESSAGE

=item * STREAM

=item * CALL_WITH_FDS

=item * REPLY_WITH_FDS

=item * STREAM_HOLE

=back

=item * Status

=over 8

=item * OK

=item * ERROR

=item * CONTINUE

=back

=back

=head1 (DE)SERIALIZERS

  $transport->serialize_Error($value, $idx, $out);
  $transport->deserialize_Error($value, $idx, $inp);

Serializers convert the input provided in C<$value> to their corresponding XDR
representation in C<$out>, at index position C<$idx>.  Non-zero C<$idx> values
can be used to append to or overwrite parts of C<$out>.

Deserializers convert the XDR representation input provided in C<$inp> at index
position C<$idx> into their corresponding Perl representation.

=over 8

=item * Type

=item * Status

=item * Header

=item * UUID

=item * NonnullString

=item * String

=item * NonnullDomain

=item * NonnullNetwork

=item * Domain

=item * Network

=item * Error

=item * StreamHole

=back

=head1 LICENSE AND COPYRIGHT

See the LICENSE file in this distribution


