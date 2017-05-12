package String::Numeric;
use strict;
use warnings;

BEGIN {
    our $VERSION   = 0.9;
    our @EXPORT_OK = qw(
        is_numeric
        is_float
        is_decimal
        is_integer
        is_int
        is_int8
        is_int16
        is_int32
        is_int64
        is_int128
        is_uint
        is_uint8
        is_uint16
        is_uint32
        is_uint64
        is_uint128
    );

    our %EXPORT_TAGS = ( 
        all  => [ @EXPORT_OK ], 
        int  => [ grep { /^is_int/ }  @EXPORT_OK ],
        uint => [ grep { /^is_uint/ } @EXPORT_OK ],
    );

    if ( !$ENV{STRING_NUMERIC_PP} ) {

        eval {
            require String::Numeric::XS;
        };
    }

    if ( $ENV{STRING_NUMERIC_PP} || $@ ) {
        require String::Numeric::PP;
        String::Numeric::PP->import(@EXPORT_OK);
    }
    else {
        String::Numeric::XS->import(@EXPORT_OK);
    }

    require Exporter;
    *import = \&Exporter::import;
}

1;

__END__

=head1 NAME

String::Numeric - Determine whether a string represents a numeric value

=head1 SYNOPSIS

    $boolean = is_float($string);
    $boolean = is_decimal($string);
    
    $boolean = is_int($string);
    $boolean = is_int8($string);
    $boolean = is_int16($string);
    $boolean = is_int32($string);
    $boolean = is_int64($string);
    $boolean = is_int128($string);
    
    $boolean = is_uint($string);
    $boolean = is_uint8($string);
    $boolean = is_uint16($string);
    $boolean = is_uint32($string);
    $boolean = is_uint64($string);
    $boolean = is_uint128($string);

=head1 DESCRIPTION

A numeric value contains an integer part that may be prefixed with an 
optional minus sign, which may be followed by a fractional part and/or an 
exponent part.

See L</String::Numeric ABNF> for specification and L</COMPARISON> for a comparison with C<Scalar::Util::looks_like_number()>.

=head1 FUNCTIONS

=head2 is_float

Determine whether C<$string> is a floating-point number of arbitrary precision.

I<Usage>

    $boolean = is_float($string);
    $boolean = is_float('-1');     # true
    $boolean = is_float('1');      # true
    $boolean = is_float('1.0');    # true
    $boolean = is_float('1.0e6');  # true
    $boolean = is_float('1e6');    # true
    $boolean = is_float(undef);    # false

I<Arguments>

=over 4

=item C<$string>

=back

I<Returns>

=over 4

=item C<$boolean>

=back

I<Note>

=over 4

=item This function is also available as C<is_numeric()>

=back

=head2 is_decimal

Determine whether C<$string> is a decimal number of arbitrary precision.

I<Usage>

    $boolean = is_decimal($string);
    $boolean = is_decimal('-1');     # true
    $boolean = is_decimal('1');      # true
    $boolean = is_decimal('1.0');    # true
    $boolean = is_decimal('1.0e6');  # false
    $boolean = is_decimal('1e6');    # false
    $boolean = is_decimal(undef);    # false

I<Arguments>

=over 4

=item C<$string>

=back

I<Returns>

=over 4

=item C<$boolean>

=back

=head2 is_int

Determine whether C<$string> is an integer of arbitrary precision.

I<Usage>

    $boolean = is_int($string);
    $boolean = is_int('1');      # true
    $boolean = is_int('-1');     # true
    $boolean = is_int('1.0');    # false
    $boolean = is_int(undef);    # false

I<Arguments>

=over 4

=item C<$string>

=back

I<Returns>

=over 4

=item C<$boolean>

=back

I<Note>

=over 4

=item This function is also available as C<is_integer()>

=back

=head2 is_int8

Determine whether C<$string> is a 8-bit signed integer which can have any 
value in the range -128 to 127.

I<Usage>

    $boolean = is_int8($string);
    $boolean = is_int8('-128');   # true
    $boolean = is_int8('127');    # true
    $boolean = is_int8(undef);    # false

I<Arguments>

=over 4

=item C<$string>

=back

I<Returns>

=over 4

=item C<$boolean>

=back

=head2 is_int16

Determine whether C<$string> is a 16-bit signed integer which can have any 
value in the range -32,768 to 32,767.

I<Usage>

    $boolean = is_int16($string);
    $boolean = is_int16('-32768');   # true
    $boolean = is_int16('32767');    # true
    $boolean = is_int16(undef);      # false

I<Arguments>

=over 4

=item C<$string>

=back

I<Returns>

=over 4

=item C<$boolean>

=back

=head2 is_int32

Determine whether C<$string> is a 32-bit signed integer which can have any 
value in the range -2,147,483,648 to 2,147,483,647.

I<Usage>

    $boolean = is_int32($string);
    $boolean = is_int32('-2147483648');   # true
    $boolean = is_int32('2147483647');    # true
    $boolean = is_int32(undef);           # false

I<Arguments>

=over 4

=item C<$string>

=back

I<Returns>

=over 4

=item C<$boolean>

=back

=head2 is_int64

Determine whether C<$string> is a 64-bit signed integer which can have any 
value in the range -9,223,372,036,854,775,808 to 9,223,372,036,854,775,807.

I<Usage>

    $boolean = is_int64($string);
    $boolean = is_int64('-9223372036854775808');   # true
    $boolean = is_int64('9223372036854775807');    # true
    $boolean = is_int64(undef);                    # false

I<Arguments>

=over 4

=item C<$string>

=back

I<Returns>

=over 4

=item C<$boolean>

=back

=head2 is_int128

Determine whether C<$string> is a 128-bit signed integer which can have any 
value in the range -170,141,183,460,469,231,731,687,303,715,884,105,728 to 
170,141,183,460,469,231,731,687,303,715,884,105,727.

I<Usage>

    $boolean = is_int128($string);
    $boolean = is_int128('-170141183460469231731687303715884105728');   # true
    $boolean = is_int128('170141183460469231731687303715884105727');    # true
    $boolean = is_int128(undef);                                        # false

I<Arguments>

=over 4

=item C<$string>

=back

I<Returns>

=over 4

=item C<$boolean>

=back

=head2 is_uint

Determine whether C<$string> is an unsigned integer of arbitrary precision.

I<Usage>

    $boolean = is_uint($string);
    $boolean = is_uint('1');      # true
    $boolean = is_uint('-1');     # false
    $boolean = is_uint('1.0');    # false
    $boolean = is_uint(undef);    # false

I<Arguments>

=over 4

=item C<$string>

=back

I<Returns>

=over 4

=item C<$boolean>

=back

=head2 is_uint8

Determine whether C<$string> is a 8-bit unsigned integer which can have any 
value in the range 0 to 255.

I<Usage>

    $boolean = is_uint8($string);
    $boolean = is_uint8('0');      # true
    $boolean = is_uint8('255');    # true
    $boolean = is_uint8(undef);    # false

I<Arguments>

=over 4

=item C<$string>

=back

I<Returns>

=over 4

=item C<$boolean>

=back

=head2 is_uint16

Determine whether C<$string> is a 16-bit unsigned integer which can have any 
value in the range 0 to 65,535.

I<Usage>

    $boolean = is_uint16($string);
    $boolean = is_uint16('0');      # true
    $boolean = is_uint16('65535');  # true
    $boolean = is_uint16(undef);    # false

I<Arguments>

=over 4

=item C<$string>

=back

I<Returns>

=over 4

=item C<$boolean>

=back

=head2 is_uint32

Determine whether C<$string> is a 32-bit unsigned integer which can have any 
value in the range 0 to 4,294,967,295.

I<Usage>

    $boolean = is_uint32($string);
    $boolean = is_uint32('0');           # true
    $boolean = is_uint32('4294967295');  # true
    $boolean = is_uint32(undef);         # false

I<Arguments>

=over 4

=item C<$string>

=back

I<Returns>

=over 4

=item C<$boolean>

=back

=head2 is_uint64

Determine whether C<$string> is a 64-bit unsigned integer which can have any 
value in the range 0 to 18,446,744,073,709,551,615.

I<Usage>

    $boolean = is_uint64($string);
    $boolean = is_uint64('0');                     # true
    $boolean = is_uint64('18446744073709551615');  # true
    $boolean = is_uint64(undef);                   # false

I<Arguments>

=over 4

=item C<$string>

=back

I<Returns>

=over 4

=item C<$boolean>

=back

=head2 is_uint128

Determine whether C<$string> is a 128-bit unsigned integer which can have any 
value in the range 0 to 340,282,366,920,938,463,463,374,607,431,768,211,455.

I<Usage>

    $boolean = is_uint128($string);
    $boolean = is_uint128('0');                                        # true
    $boolean = is_uint128('340282366920938463463374607431768211455');  # true
    $boolean = is_uint128(undef);                                      # false

I<Arguments>

=over 4

=item C<$string>

=back

I<Returns>

=over 4

=item C<$boolean>

=back

=head1 LIMITATIONS

C<String::Numeric> supports numbers in decimal notation using Western Arabic
numerals and decimal fractions seperated with a dot. Other notations or numeral
systems are not supported.

=head1 COMPARISON

=head2 Scalar::Util

B<None> of the following is considered valid by C<String::Numeric>.

=over 4

=item * Fractional number without integer part or fractional part

    looks_like_number("1.") # true
    looks_like_number(".1") # true

=item * Plus prefix

    looks_like_number("+1") # true

=item * Leading zeros

    looks_like_number("01") # true

=item * Radix point other than C<.>

    looks_like_number("1,1") # true assuming locale is in effect and locale radix point is ','

=item * Leading and/or trailing whitespace, such as HT, LF, FF, CR, and SP

    looks_like_number("\n1")   # true
    looks_like_number("1\n")   # true
    looks_like_number("\n1\n") # true

=item * Numeric values that are not represented as a sequence of digits, such as 
C<Inf>, C<Infinity>, C<NaN> and C<0 but true>

    looks_like_number("Inf")        # true
    looks_like_number("Infinity")   # true
    looks_like_number("NaN")        # true
    looks_like_number("0 but true") # true

=back

=head1 GRAMMAR

=head2 String::Numeric ABNF

    ; String::Numeric ABNF Grammar
    
    is-float          = [ "-" ] FloatNumber
    is-decimal        = [ "-" ] DecimalNumber
    is-integer        = [ "-" ] DecimalInteger
    is-uint           = DecimalInteger
    
    FloatNumber       = DecimalNumber [ ExponentPart ]
    DecimalNumber     = DecimalInteger [ FractionalPart ]
    DecimalInteger    = "0" / ( NonZeroDigit *DecimalDigit )
    
    DecimalDigit      = %x30-39; 0-9
    NonZeroDigit      = %x31-39; 1-9
    FractionalPart    = "." 1*DecimalDigit
    ExponentIndicator = "e" / "E"
    ExponentPart      = ExponentIndicator [ "+" / "-" ] 1*DecimalDigit

=head2 looks_like_number ABNF

    ; ABNF Grammar based on 5.10 Perl_grok_number()
    
    looks-like-number = Number / ZeroButTrue
    
    Number            = *WS [ Sign ] ( FloatNumber / ( Infinity / NaN ) ) *WS;
    FloatNumber       = DecimalNumber [ ExponentPart ]
    DecimalNumber     = DecimalInteger [ "." *DecimalDigit ] / "." 1*DecimalDigit
    DecimalInteger    = 1*DecimalDigit
    
    WS                = %x09 ; HT
                      / %x0A ; LF 
                      / %x0C ; FF
                      / %x0D ; CR
                      / %x20 ; SP
    DecimalDigit      = %x30-39; 0-9
    Sign              = "+" / "-"
    ExponentIndicator = "e" / "E"
    ExponentPart      = ExponentIndicator [ Sign ] 1*DecimalDigit
    Infinity          = "Inf" / "Infinity"
    NaN               = "NaN"
    ZeroButTrue       = %x30.20.62.75.74.20.74.72.75.65 ; 0 but true

=head1 EXPORTS

None by default. Functions and constants can either be imported individually or
in sets grouped by tag names. The tag names are:

=over 4

=item C<:all> exports all functions.

=item C<:is_int> exports all C<is_int> functions.

=item C<:is_uint> exports all C<is_uint> functions.

=back

=head1 DIAGNOSTICS

=over 4

=item B<(F)> Usage: %s(string)

Subroutine %s invoked with wrong number of arguments.

=back

=head1 ENVIRONMENT

Set the environment variable C<STRING_NUMERIC_PP> to a true value before loading this package to disable usage of XS implementation.

=head1 PREREQUISITES

=head2 Run-Time

=over 4

=item L<perl> 5.006 or greater.

=item L<Carp>, core module.

=item L<Exporter>, core module.

=back

=head2 Build-Time

In addition to Run-Time:

=over 4

=item L<Test::More> 0.47 or greater, core module since 5.6.2.

=item L<Test::Exception>.

=back

=head1 SEE ALSO

L<String::Numeric::XS>

L<Data::Types>

L<Regexp::Common::number>

L<Scalar::Util>

L<Scalar::Util::Numeric>

=head1 AUTHOR

Christian Hansen C<chansen@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 Christian Hansen.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

