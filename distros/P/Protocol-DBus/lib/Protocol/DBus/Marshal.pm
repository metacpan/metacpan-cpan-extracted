package Protocol::DBus::Marshal;

use strict;
use warnings;

use Protocol::DBus::Pack ();
use Protocol::DBus::Signature ();

our $_ENDIAN_PACK;

# for testing
our $DICT_CANONICAL;

# data (array ref, always), sig
sub marshal_le {
    local $_ENDIAN_PACK = '<';
    return _marshal(@_[0, 1]);
}

# buf, buf offset, sig
sub unmarshal_le {
    local $_ENDIAN_PACK = '<';
    return _unmarshal(@_);
}

sub marshal_be {
    local $_ENDIAN_PACK = '>';
    return _marshal(@_[0, 1]);
}

sub unmarshal_be {
    local $_ENDIAN_PACK = '>';
    return _unmarshal(@_);
}

#----------------------------------------------------------------------

sub _marshal {
    my ($sig, $data, $buf_sr, $_data_are_not_list) = @_;

    $buf_sr ||= \do { my $v = q<> };

    my @scts = Protocol::DBus::Signature::split($sig);

    for my $si ( 0 .. $#scts ) {
        my $sct = $scts[$si];

        my $datum = $_data_are_not_list ? $data : $data->[$si];

        # Arrays
        if (index($sct, 'a') == 0) {
            _marshal_array( $sct, $datum, $buf_sr);
        }

        # Structs are given as arrays.
        elsif (index($sct, '(') == 0) {
            Protocol::DBus::Pack::align_str($$buf_sr, 8);

            my $struct_sig = substr($sig, 1, -1);

            _marshal( $struct_sig, $datum, $buf_sr );
        }

        # Variants are given as two-member arrays.
        elsif ($sct eq 'v') {
            _marshal( g => $datum->[0], $buf_sr, 1 );
            _marshal( $datum->[0], $datum->[1], $buf_sr, 1 );
        }

        # Anything else is a basic type.
        else {
            if ($sct eq 'o') {
                $datum =~ m<\A/(?:[A-Za-z0-9_]+(?:/[A-Za-z0-9_]+)*)?\z> or do {
                    die "Invalid object path: “$datum”";
                };
            }

            Protocol::DBus::Pack::align_str($$buf_sr, Protocol::DBus::Pack::ALIGNMENT()->{$sct});

            my ($pack) = _get_pack_template($sct);

            $pack = "($pack)$_ENDIAN_PACK";
            $$buf_sr .= pack( $pack, $datum );
        }
    }

    return $buf_sr;
}

sub _marshal_array {
    my ($sct, $data, $buf_sr) = @_;

    Protocol::DBus::Pack::align_str($$buf_sr, 4);

    # We’ll fill this in with the length below.
    $$buf_sr .= "\0\0\0\0";

    my $array_start = length $$buf_sr;

    # Per the spec, array lengths do NOT include alignment bytes
    # after the length. This only affects 8-byte-aligned types.
    my $compensate_align8;

    substr($sct, 0, 1, q<>);    # chop off the leading “a”

    if ($array_start % 8) {
        $compensate_align8 = (0 == index($sct, '('));
        $compensate_align8 ||= (0 == index($sct, '{'));
        $compensate_align8 ||= ((Protocol::DBus::Pack::ALIGNMENT()->{$sct} || 0) == 8);
    }

    # DICT_ENTRY arrays are given as plain Perl hashes
    if (0 == index($sct, '{')) {
        my $key_sig = substr($sct, 1, 1);
        my $value_sig = substr($sct, 2, -1);

        for my $key ( $DICT_CANONICAL ? (sort keys %$data) : keys %$data ) {
            Protocol::DBus::Pack::align_str($$buf_sr, 8);
            _marshal($key_sig, $key, $buf_sr, 1);
            _marshal( $value_sig, $data->{$key}, $buf_sr, 1);
        }
    }

    # Any other array is given as an array.
    else {
        for my $item ( @$data ) {
            _marshal($sct, $item, $buf_sr, 1);
        }
    }

    my $array_len = length($$buf_sr) - $array_start;
    $array_len -= 4 if $compensate_align8;

    substr( $$buf_sr, $array_start - 4, 4, pack("L$_ENDIAN_PACK", $array_len) );
}

#----------------------------------------------------------------------

sub _unmarshal {
    my ($buf_sr, $buf_offset, $sig) = @_;

    my @items;

    my $buf_start = $buf_offset;
    my $sig_offset = 0;

    while ($sig_offset < length($sig)) {
        my $next_sct_len = Protocol::DBus::Signature::get_sct_length($sig, $sig_offset);

        my ($item, $item_length) = _unmarshal_sct(
            $buf_sr,
            $buf_offset,
            substr( $sig, $sig_offset, $next_sct_len ),
        );

        push @items, $item;

        $buf_offset += $item_length;
        $sig_offset += $next_sct_len;
    }

    return (\@items, $buf_offset - $buf_start);
}

sub unmarshal_sct_le {
    return _unmarshal_sct(@_);
}

sub unmarshal_sct_be {
    return _unmarshal_sct(@_);
}

# SCT = “single complete type”.
# Returns the value plus its marshaled length.
sub _unmarshal_sct {
    my ($buf_sr, $buf_offset, $sct_sig) = @_;

    my $buf_start = $buf_offset;

    if (substr($sct_sig, 0, 1) eq 'a') {
        Protocol::DBus::Pack::align($buf_offset, 4);

        my $array_len = unpack "\@$buf_offset L$_ENDIAN_PACK", $$buf_sr;
        $buf_offset += 4;   #uint32 length

        my $obj;

        # We parse arrays of DICT_ENTRY into a hash.
        if (substr($sct_sig, 1, 1) eq '{') {

            # The key is always a basic type, so just one letter.
            my $key_type = substr($sct_sig, 2, 1);

            # The value can be any SCT.
            my $value_type = substr( $sct_sig, 3, Protocol::DBus::Signature::get_sct_length($sct_sig, 3) );

            $obj = _unmarshal_to_hashref($buf_sr, $buf_offset, $array_len, $key_type, $value_type);
            $buf_offset += $array_len;
        }

        # Anything else we parse normally.
        else {
            my $array_sig = substr( $sct_sig, 1, Protocol::DBus::Signature::get_sct_length($sct_sig, 1) );

            my @array_items;
            $obj = bless \@array_items, 'Protocol::DBus::Type::Array';

            # If the array contents are 8-byte-aligned, then the array will
            # actually be 4 bytes longer than this. But it doesn’t appear we
            # need to care about that since _unmarshal_sct() accounts for that.
            my $array_end = $buf_offset + $array_len;

            while ($buf_offset < $array_end) {
                my ($item, $item_length) = _unmarshal_sct($buf_sr, $buf_offset, $array_sig);

                $buf_offset += $item_length;

                push @array_items, $item;
            }
        }

        return ($obj, $buf_offset - $buf_start);
    }
    elsif (substr($sct_sig, 0, 1) eq '(') {
        return _unmarshal_struct(@_);
    }
    elsif (substr($sct_sig, 0, 1) eq 'v') {
        return _unmarshal_variant(@_);
    }

    my ($pack_tmpl, $is_string) = _get_pack_template($sct_sig);

    Protocol::DBus::Pack::align($buf_offset, Protocol::DBus::Pack::ALIGNMENT()->{$sct_sig});

    my $val = unpack("\@$buf_offset ($pack_tmpl)$_ENDIAN_PACK", $$buf_sr);

    return ($val, $buf_offset - $buf_start + Protocol::DBus::Pack::WIDTH()->{$sct_sig} + ($is_string ? length($val) : 0));
}

sub _unmarshal_variant {
    my ($buf_sr, $buf_offset) = @_;

    my $buf_start = $buf_offset;

    my ($sig, $len) = _unmarshal_sct( $buf_sr, $buf_offset, 'g' );

    die sprintf("No sig ($len bytes?) from “%s”?", substr($$buf_sr, $buf_offset)) if !length $sig;

    $buf_offset += $len;

    (my $val, $len) = _unmarshal_sct( $buf_sr, $buf_offset, $sig );

    return( $val, $len + $buf_offset - $buf_start );
}

sub _get_pack_template {
    my ($sct_sig) = @_;

    my ($is_string, $pack_tmpl);
    if ( $pack_tmpl = Protocol::DBus::Pack::STRING()->{$sct_sig} ) {
        $is_string = 1;
    }
    else {
        $pack_tmpl = Protocol::DBus::Pack::NUMERIC()->{$sct_sig} or do {
            die "No basic type template for type “$sct_sig”!";
        };

        if (!Protocol::DBus::Pack::CAN_64()) {
            if ($pack_tmpl eq 'q') {
                $pack_tmpl = ( $_ENDIAN_PACK eq '>' ) ? 'x4 l' : 'l x4';
            }
            elsif ($pack_tmpl eq 'Q') {
                $pack_tmpl = ( $_ENDIAN_PACK eq '>' ) ? 'x4 L' : 'L x4';
            }
        }
    }

    return ($pack_tmpl, $is_string);
}

sub _unmarshal_to_hashref {
    my ($buf_sr, $buf_offset, $array_len, $key_type, $value_type) = @_;

    my %items;
    my $obj = bless \%items, 'Protocol::DBus::Type::Dict';

    Protocol::DBus::Pack::align($buf_offset, 8);

    my $end_offset = $buf_offset + $array_len;

    while ($buf_offset < $end_offset) {
        Protocol::DBus::Pack::align($buf_offset, 8);

        my ($key, $len_in_buf) = _unmarshal_sct($buf_sr, $buf_offset, $key_type);

        $buf_offset += $len_in_buf;

        (my $val, $len_in_buf) = _unmarshal_sct($buf_sr, $buf_offset, $value_type);

        $buf_offset += $len_in_buf;

        $items{$key} = $val;
    }

    # We don’t need to return the length.
    return $obj;
}

sub _unmarshal_struct {
    my ($buf_sr, $buf_offset, $sct_sig) = @_;

    # Remove “()” and just parse as a series of types.
    chop $sct_sig;
    substr( $sct_sig, 0, 1, q<> );

    my $buf_start = $buf_offset;

    Protocol::DBus::Pack::align($buf_offset, 8);

    my ($items_ar, $len) = _unmarshal($buf_sr, $buf_offset, $sct_sig);
    bless $items_ar, 'Protocol::DBus::Type::Struct';

    return ($items_ar, ($buf_offset - $buf_start) + $len);
}

#----------------------------------------------------------------------
# The logic below is unused. I was under the impression that I’d need a
# way to determine if a message body’s length matches the given SIGNATURE,
# but of course we don’t because the header includes the body length.
#----------------------------------------------------------------------

sub buffer_length_satisfies_signature_le {
    local $_ENDIAN_PACK = '<';
    return (_buffer_length_satisfies_signature(@_))[0];
}

sub buffer_length_satisfies_signature_be {
    local $_ENDIAN_PACK = '>';
    return (_buffer_length_satisfies_signature(@_))[0];
}

sub _buffer_length_satisfies_signature {
    my ($buf, $buf_offset, $sig) = @_;

    my $sig_offset = 0;

    while ($buf_offset <= length($buf)) {

        # We’re good if this passes because it means the buffer is longer
        # than the passed-in signature needs it to be.
        return (1, $buf_offset) if $sig_offset == length($sig);

        my $sct_length = Protocol::DBus::Signature::get_sct_length($sig, $sig_offset);

        my $next_sct = substr(
            $sig,
            $sig_offset,
            $sct_length,
        );

        $sig_offset += $sct_length;

        if ($next_sct eq 'v') {
            my ($variant_sig, $len) = _unmarshal_sct($buf, $buf_offset, 'g');
            $buf_offset += $len;

            # This has to recurse and preserve the offset.
            my ($ok, $new_offset) = _buffer_length_satisfies_signature( $buf, $buf_offset, $variant_sig );
            return 0 if !$ok;
            $buf_offset = $new_offset;
        }

        # signatures
        elsif ($next_sct eq 'g') {
            # 2 for the length byte and the trailing NUL
            $buf_offset += 2 + unpack( "\@$buf_offset C", $buf )
        }

        # strings and object paths
        elsif ( Protocol::DBus::Pack::STRING()->{$next_sct} ) {
            _add_uint32_variant_length(\$buf, \$buf_offset);
            $buf_offset++;  #trailing NUL
        }

        # numerics
        elsif ( my $width = Protocol::DBus::Pack::WIDTH()->{$next_sct} ) {
            $buf_offset += $width;
        }

        else {
            my $char0 = substr($next_sct, 0, 1);

            if ($char0 eq 'a') {
                _add_uint32_variant_length(\$buf, \$buf_offset);
            }
            elsif ($char0 eq '(') {
                Protocol::DBus::Pack::align( $buf_offset, 8 );

                my ($ok, $new_offset) = _buffer_length_satisfies_signature( $buf, $buf_offset, substr($next_sct, 1, -1) );
                return 0 if !$ok;
                $buf_offset = $new_offset;
            }
            else {
                die "unrecognized SCT: “$next_sct”";
            }
        }
    }

    return 0;
}

sub _add_uint32_variant_length {
    my ($buf_sr, $buf_offset_sr) = @_;

    Protocol::DBus::Pack::align( $$buf_offset_sr, 4 );

    my $array_len = unpack(
        "\@$$buf_offset_sr " . ($_ENDIAN_PACK eq '<' ? 'V' : 'N'),
        $$buf_sr,
    );

    $$buf_offset_sr += 4;
    $$buf_offset_sr += $array_len;

    return;
}

1;
