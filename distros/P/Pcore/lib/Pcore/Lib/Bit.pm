package Pcore::Lib::Bit;

use Pcore;

sub set_bit {
    if ( defined wantarray ) {
        if ( defined $_[2] ) {
            return ( clear_bit( $_[0], $_[1] ) | clear_bit( $_[2], ~$_[1] ) );
        }
        else {
            return $_[0] | $_[1];
        }
    }
    else {
        if ( defined $_[2] ) {
            $_[0] = ( clear_bit( $_[0], $_[1] ) | clear_bit( $_[2], ~$_[1] ) );
        }
        else {
            $_[0] = $_[0] | $_[1];
        }
    }

    return;
}

sub clear_bit {
    if ( defined wantarray ) {
        if ( defined $_[2] ) {
            return ( set_bit( $_[0], $_[1] ) & ~clear_bit( $_[2], ~$_[1] ) );
        }
        else {
            return $_[0] & ~$_[1];
        }
    }
    else {
        if ( defined $_[2] ) {
            $_[0] = ( set_bit( $_[0], $_[1] ) & ~clear_bit( $_[2], ~$_[1] ) );
        }
        else {
            $_[0] = $_[0] & ~$_[1];
        }
    }

    return;
}

sub inverse_bit {
    if ( defined wantarray ) {
        return $_[0] ^ $_[1];
    }
    else {
        $_[0] = $_[0] ^ $_[1];
    }

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Lib::Bit - bitwise operations with mask

=head1 SYNOPSIS

    Pcore::Lib::Bit::set_bit($binary, $mask[, $bits]);
    Pcore::Lib::Bit::clear_bit($binary, $mask[, $bits]);
    Pcore::Lib::Bit::inverse_bit($binary, $mask);

    Pcore::Lib::Bit::set_bit(0b1111_0000, 0b0011_1000);           # returns 0b1111_1000
    Pcore::Lib::Bit::set_bit(0b1111_0000, 0b0011_1000, 0b101);    # returns 0b1110_1000

    Pcore::Lib::Bit::clear_bit(0b1111_0000, 0b0011_1000);         # returns 0b1100_0000
    Pcore::Lib::Bit::clear_bit(0b1111_0000, 0b0011_1000, 0b101);  # returns 0b1101_0000

    Pcore::Lib::Bit::inverse_bit(0b1111_0000, 0b0011_1000);       # returns 0b1100_1000

=head1 METHODS

=head2 set_bit, clear_bit

$mask shows which bits in $binary we would like to modify. Other bits will stay untouched.

In two-params call all corresponding bits in $binary value will be setted or cleared correspondently.

In three-params set_bit() call all corresponding bits in $binary value will be setted as it defined in $bits value.

In three-params clear_bit() call all corresponding bits in $binary value will be setted as it defined in inversed $bits value.

      76543210
    0b10101010 - $binary
    0b00110011 - $mask
    0b00110000 - $bits
    -----------
    set_bit($binary, $mask, $bits)   - bits[5, 4] - will be setted,  bits[1, 0] - will be cleared
    clear_bit($binary, $mask, $bits) - bits[5, 4] - will be cleared, bits[1, 0] - will be setted

Result returned if expected otherwise $binary value will be modified in-place.

=head2 inverse_bit

Accept only two parameters: $binary and $mask.

Inverse corresponding bits in $binary value according to $mask.

NOTE: this operation is simple XOR.

=head1 А ТЕПЕРЬ НА РУССКОМ

Маска определяет, какие биты будем модифицировать в исходном скаляре. Остальные биты не будут затронуты ни при каких условиях.

set_bit(), clear_bit() с ДВУМЯ параметрами устанавливает или обнуляет ВСЕ биты, попадающие под маску, соответственно.

Дополнительный ТРЕТИЙ параметр $bits позволяет указать как именно модифицировать биты, попадающие под маску:

=over

=item * set_bit() - устанавливает биты под маской в те значения, которые соответствуют им в $bits соответственно. Т.е. 1 биты в $bits будут 1 в $binary, 0 в $bits будут 0 в $binary. Вызов set_bit($a, $b) эквивалентен вызову set_bit($a, $b, $b), так как в обоих случаях устанавливаются все биты под маской;

=item * clear_bit() - то-же, что и clear_bit с инвертированным $bits параметром;

=back

=head1 WARNING

Bitwise operators limited to a certain number of bits (32 bits of 64 bits, depending on your architecture). If we go over this, we'll get an error.

=cut
