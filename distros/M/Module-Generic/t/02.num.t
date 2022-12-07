#!/usr/bin/perl
# t/02.num.t - check for number object
BEGIN
{
    use Test::More qw( no_plan );
    use strict;
    use warnings;
    use utf8;
    use lib './lib';
    use vars qw( $DEBUG );
    use File::Which;
    use POSIX ();
    use open ':std' => ':utf8';

    my %old = %ENV;
    my @rem = qw( LANG LANGUAGE LC_ADDRESS LC_ALL LC_COLLATE LC_CTYPE LC_IDENTIFICATION LC_MEASUREMENT LC_MESSAGES LC_MONETARY LC_NAME LC_NUMERIC LC_PAPER LC_TELEPHONE LC_TIME );
    no warnings 'uninitialized';
    for( @rem )
    {
        #$ENV{$_} = undef();
        delete( $ENV{$_} );
        next if( $_ eq 'LC_NAME' || $_ eq 'LC_TYPE' );
        # no strict 'refs';
        # POSIX::setlocale( &{"POSIX\::$_"}, undef ) if( substr( $_, 0, 3 ) eq 'LC_' );
    }
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

# diag( "Environment variables: ", Dumper( \%ENV ) );

BEGIN { use_ok( 'Module::Generic::Number' ) || BAIL_OUT( "Unable to load Module::Generic::Number" ); }
my $curr_locale = POSIX::setlocale( &POSIX::LC_ALL );
diag( "Current locale is '$curr_locale'" ) if( $DEBUG );
# require Data::Dump;
# diag( "Environement variables: ", Data::Dump::dump( \%ENV ) );

# RT #132674
# Stupid me. I should compare the result to the locale variables unless they are explicitely set
# my $prev_locale = POSIX::setlocale( &POSIX::LC_ALL );
# my $new_loc = POSIX::setlocale( &POSIX::LC_ALL, 'de_DE' );
my $lconv = POSIX::localeconv();
# $lconv = $Module::Generic::Number::DEFAULT if( !scalar( keys( %$lconv ) ) || ( scalar( keys( %$lconv ) ) == 1 && CORE::exists( $lconv->{decimal_point} ) ) );
$lconv = $Module::Generic::Number::DEFAULT if( !$curr_locale );
# diag( "localeconv contains: ", Data::Dump::dump( $lconv ), "\n" ) if( $DEBUG );
# $lconv->{mon_thousands_sep} = $lconv->{thousands_sep} = undef();
#         my $fail = [qw(
# frac_digits
# int_frac_digits
# n_cs_precedes
# n_sep_by_space
# n_sign_posn
# p_cs_precedes
# p_sep_by_space
# p_sign_posn
#         )];
#         @$lconv{ @$fail } = ( -1 ) x scalar( @$fail );
# POSIX::setlocale( &POSIX::LC_ALL, $prev_locale );
my( $sep_space, $tho_sep, $dec_sep, $n );
if( scalar( keys( %$lconv ) ) )
{
    $sep_space = int( $lconv->{p_sep_by_space} // '' ) > 0 ? qr/[[:blank:]\h]+/ : '';
    $tho_sep = CORE::length( $lconv->{thousands_sep} )
        ? $lconv->{thousands_sep} 
        : $lconv->{mon_thousands_sep};
    $dec_sep = CORE::length( $lconv->{decimal_point} )
        ? $lconv->{decimal_point}
        : $lconv->{mon_decimal_point};
    $n = Module::Generic::Number->new( 10, precision => 2, debug => $DEBUG );
}
else
{
    diag( "No locale could be found for language \"$ENV{LANG}\"" );
    $tho_sep = ',';
    $dec_sep = '.';
    $n = Module::Generic::Number->new( 10, precision => 2, thousand => $tho_sep, decimal => $dec_sep, debug => $DEBUG );
}
if( !defined( $n ) )
{
    diag( "Error: '", Module::Generic::Number->error, "'" );
    BAIL_OUT( Module::Generic::Number->error );
}
# diag( "Space between symbol and number is '", $n->space, "'." );
# my $lconv_debug = '';
# foreach my $property (qw(
#         decimal_point
#         thousands_sep
#         grouping
#         int_curr_symbol
#         currency_symbol
#         mon_decimal_point
#         mon_thousands_sep
#         mon_grouping
#         positive_sign
#         negative_sign
#         int_frac_digits
#         frac_digits
#         p_cs_precedes
#         p_sep_by_space
#         n_cs_precedes
#         n_sep_by_space
#         p_sign_posn
#         n_sign_posn
#         int_p_cs_precedes
#         int_p_sep_by_space
#         int_n_cs_precedes
#         int_n_sep_by_space
#         int_p_sign_posn
#         int_n_sign_posn
# ))
# {
#     my $dots = ( '.' x ( 20 - length( $property ) ) );
#     $lconv_debug .= sprintf( qq(%s ${dots}: "%s" (%s) (%d bytes),\n),
#         $property, $lconv->{$property}, defined( $lconv->{$property} ) ? 'defined' : 'undefined', length( $lconv->{$property} ) );
# }
# diag( "Locale formatting properties are:\n$lconv_debug" );
my $new_loc = $n->lang;
## diag( "New locale is $new_loc" );
my $n2 = $n->clone;
is( $n2->locale, $new_loc, "Locale is kept with cloning" );
$n2->symbol( '€' );

no warnings;
my $n_fail = Module::Generic::Number->new( 'USD One' );
use warnings;
# diag( Module::Generic::Number->error );
is( $n_fail, undef, 'Invalid number' );

# Creating object from locale
SKIP:
{
    my( @paths ) = File::Which::which( 'locale' );
    # diag( sprintf( "%d locale executable found", scalar( @paths ) ) );
    my @ok_langs;
    foreach my $p ( @paths )
    {
        ( @ok_langs ) = eval
        {
            qx( $p -a );
        };
        last if( !$@ );
    }
    # diag( sprintf( "Found %d languages available on the system.", scalar( @ok_langs ) ) );
    if( !scalar( @ok_langs ) || !scalar( grep( /^fr_FR/, @ok_langs ) ) )
    {
        skip( 'Unsupported language', 4 );
    }
    my $n_loc = Module::Generic::Number->new( 100, { lang => 'fr_FR', precede => 1, precision => 2, thousand => ' ', decimal => ',', debug => 0 });
    isa_ok( $n_loc, 'Module::Generic::Number', 'Object with locale language string' );
    is( $n_loc->precision, 2, 'French precision => 2' );
    ## RT #132667
    ## https://perldoc.perl.org/5.10.1/perlrecharclass.html
    ## [:blank:] does not catch non-breaking space, but horizontal space \h does
    like( $n_loc->thousand, qr/[[:blank:]\h]+/, 'French thousand separator => space' );
    is( $n_loc->decimal, ',', 'French decimal separator => comma' );
};
isa_ok( $n, 'Module::Generic::Number', 'Number Class Object' );
isa_ok( $n2, 'Module::Generic::Number', 'Cloning object' );
is( "$n", 10, 'Stringification' );
isa_ok( ( $n / 2 ), 'Module::Generic::Number', 'Product blessed in Module::Generic::Number' );
is( 4 - $n, -6, 'Subtracting with swap' );
is( $n * 20, 200, 'Multiplication' );
is( ( $n + 100 ) / 2, 55, 'Division' );
is( $n + 100, 110, 'Addition' );
is( $n - 2, 8, 'Subtracting' );
is( $n % 3, 1, 'Modulus with remainder' );
is( $n % 2, 0, 'Modulus without remainder' );
is( $n *= 3, 30, 'Multiplication assignment' );
is( $n /= 5, 6, 'Division assignment' );
is( $n += 2, 8, 'Addition assignment' );
is( $n -= 4, 4, 'Subtraction assignment' );
is( $n %= 2, 0, 'Modulus assignment' );

is( ( $n + 2 ) ** 3, 8, 'Exponent' );
$n += 2;
is( $n **= 3, 8, 'Exponent assignment' );
is( $n & 11, 8, 'Bitwise AND' );
# isa_ok( $n & 11, 'Module::Generic::Number', 'Blessed after Bitwise AND' );
is( $n | 11, 11, 'Bitwise OR' );
# Bitwise XOR
is( $n ^ 11, 3, 'Bitwise XOR' );
is( $n << 2, 32, 'Bitwise shift left' );
is( $n >> 2, 2, 'Bitwise shift right' );
is( $n <<= 2, 32, 'Bitwise shift left assignment' );
is( $n >>= -2, 128, 'Bitwise shift right assignment' );
is( $n x 2, 128128, 'String multiplication' );
is( $n x= 2, 128128, 'String multiplication assignment' );
is( $n .= 4, 1281284, 'String concatenation with numbers' );
ok( $n < 1281285, 'Lower than' );
ok( 10 < $n, 'Lower than (bis)' );
ok( $n lt 1281285, 'Lower than (lt)' );
ok( $n <= 1281284, 'Lower than or equal' );
ok( $n le 1281284, 'Lower than or equal (le)' );
ok( !( $n <= 1281283 ), 'Not lower than or equal' );
ok( $n > 10, 'Higher than' );
ok( $n gt 10, 'Higher than (gt)' );
ok( $n >= 1281284, 'Higher than or equal' );
ok( $n ge 1281284, 'Higher than or equal (ge)' );
is( 10 <=> $n, -1, 'Numerical comparison lower' );
is( 1281284 <=> $n, 0, 'Numerical comparison equal' );
is( 1281285 <=> $n, 1, 'Numerical comparison higher' );
ok( 1281284 == $n, 'Equal' );
ok( $n != 'Hello', 'Not equal string' );
ok( $n != $n2, 'Not equal number' );
ok( $n eq 1281284, 'Equal as string' );
ok( $n ne $n2, 'Not equal as string' );
my $bool = $n != 'Bonjour';
# isa_ok( $bool, 'Module::Generic::Boolean', 'Returning boolean object' );
is( ++$n, 1281285, 'Incrementing' );
is( $n++, 1281286, 'Incrementing (bis)' );
is( $n--, 1281285, 'Decrementing' );
is( --$n, 1281284, 'Decrementing (bis)' );
isa_ok( $n, 'Module::Generic::Number', 'Class object check' );
is( $n . 2, 12812842, 'Concatenation' );
isa_ok( $n, 'Module::Generic::Number', 'Class object check (bis)' );

isa_ok( $n, 'Module::Generic::Number', 'Number regexp check after concatenation' );
is( $n .= 'X', '1281284X', 'String concatenation with non-number' );
isa_ok( $n, 'Module::Generic::Scalar', 'Regexp check after concatenation and class -> Module::Generic::Scalar' );

is( $n2->decimal, $dec_sep, 'Decimal separator' );
# is( $n2->thousand->scalar, $tho_sep, 'Thousand separator' );
# diag( "\$tho_sep is defined? ", defined( $tho_sep ) ? 'yes' : 'no' );
# diag( "\$n2->thousand is defined? ", defined( $n2->thousand ) ? 'yes' : 'no' );
is( $n2->thousand, $tho_sep, 'Thousand separator' );
is( $n2->precision, 2, 'Precision' );
is( $n2->currency, '€', 'Currency symbol' );
isa_ok( $n2->currency, 'Module::Generic::Scalar', 'Returns property as string object' );

diag( "Number to unformat is '$n'" ) if( $DEBUG );
my $n3 = $n2->unformat( $n );
isa_ok( $n3, 'Module::Generic::Number', 'Unformat result in new object using unformat()' );
diag( "Error unformating $n: ", $n2->error ) if( !defined( $n3 ) && $DEBUG );
is( $n3, 1281284, 'Unformat resulting value' );
is( $n3->precision, 2, 'New object precision' );
$dec_sep = '' if( !defined( $dec_sep ) );
$tho_sep = '' if( !defined( $tho_sep ) );
# diag( "Thousand separator is: '", $n3->thousand, "'" );
# diag( "Number::Format object is: ", Dumper( $n3->{_fmt} ) );
is( $n3->format, "1${tho_sep}281${tho_sep}284${dec_sep}00", 'Formatting number using format()' );
is( $n3->currency, '€', 'Currency symbol' );
my $n_money = $n3->format_money;
if( $n3->precede )
{
    like( "$n_money", qr/€${sep_space}1${tho_sep}281${tho_sep}284${dec_sep}00/, 'Formatting money using format_money()' );
}
else
{
    like( "$n_money", qr/1${tho_sep}281${tho_sep}284${dec_sep}00${sep_space}€/, 'Formatting money using format_money()' );
}
isa_ok( $n_money, 'Module::Generic::Scalar', 'Returns string object upon formatting' );
$n3 *= -1;
is( $n3, -1281284, 'Negative number' );
like( $n3->format_negative( '(x)' ), qr/\(1${tho_sep}281${tho_sep}284${dec_sep}00\)/, "Formatting negative number => (1${tho_sep}281${tho_sep}284${dec_sep}00)" );
my $n4 = $n3->abs;
is( $n4, 1281284, 'abs' );
# 1.5707955463278
is( $n4->atan, POSIX::atan( $n4 ), 'atan' );
# 1.57078696118977
is( $n4->atan2(12), CORE::atan2( $n4, 12 ), 'atan2' );
my $n5 = $n4->cbrt;
# 108.612997866582
is( $n5, POSIX::cbrt( $n4 ), 'cbrt' );
# 109
is( $n5->ceil, POSIX::ceil( $n5 ), 'ceil' );
# 108
is( $n5->floor, POSIX::floor( $n5 ), 'floor' );
# -0.413777602170324
is( $n4->cos, CORE::cos( $n4 ), 'cos' );
# 20.0855369231877
is( $n4->clone( 3 )->exp, POSIX::exp( 3 ), 'exp' );
# 108
is( $n5->int, CORE::int( $n5 ), 'int' );
ok( !$n5->is_negative, 'Not negative' );
ok( $n3->is_negative, 'Is Negative' );
ok( $n5->is_positive, 'Is positive' );
ok( !$n3->is_positive, 'Is not positive' );
# 14.0633732581021
is( $n4->log, CORE::log( $n4 ), 'log' );
# 20.2891588576344
is( $n4->log2, POSIX::log2( $n4 ), 'log2' );
# 6.10764540293951
is( $n4->log10, POSIX::log10( $n4 ), 'log10' );
is( $n4->max( 1281285 ), 1281285, 'max' );
is( $n4->min( 1281285 ), 1281284, 'min' );
is( $n4->mod( 3 ), 2, 'mod' );
is( $n4->oct, 10, 'oct' );
is( $n4->clone( 3.14159265358979323846 )->round( 4 ), 3.1416, 'Rounding' );
# -0.910377996187395
is( $n4->sin, CORE::sin( $n4 ), 'sin' );
is( $n4->sqrt, CORE::sqrt( $n4 ), 'sqrt' );
# 2.20016257867108
is( $n4->tan, POSIX::tan( $n4 ), 'tan' );
my $pie = $n4->clone( 3.14159265358979323846 );
is( $pie->length, CORE::length( $pie ), 'Number length' );
ok( $n4->is_finite, 'Is finite number' );
ok( $n4->clone( 3.14159265358979323846 )->is_float, 'Is float' );
ok( $n4->is_int, 'Is integer' );
ok( !$n4->is_nan, 'Is NaN' );
ok( $n4->is_positive, 'Is positive number' );
ok( !$n4->is_negative, 'Is negative number' );
ok( $n4->is_normal, 'Is normal number' );

my $inf = Module::Generic::Number->new( 9**9**9, debug => 3 );
isa_ok( $inf, 'Module::Generic::Infinity', 'Infinity Class' );
# diag( "Infinity: $inf" );
# diag( "Is finite? " . $inf->is_finite );
is( "$inf", "Inf", 'Infinity stringified' );
ok( $inf->is_infinite, 'Is infinite' );
ok( !$inf->is_normal, 'Is not normal number' );
is( $inf * 10, 'Inf', 'Infinity overloaded' );
$inf *= -10;
is( $inf, '-Inf', 'Negative infinity overloaded' );
ok( $inf->is_negative, 'Is negative infinity' );
$inf++;
my $inf_p = $inf->clone( 'Inf' );
# diag( "$inf_p + $inf = ", $inf_p + $inf );
is( $inf_p + $inf, 'NaN', 'Infinity to NaN' );
isa_ok( $inf_p + $inf, 'Module::Generic::Nan', 'Infinity to NaN' );
isa_ok( $inf ** 9 / 1000 - $inf, 'Module::Generic::Nan', 'Infinity multiple operations' );
isa_ok( $inf ** 9 / 1000, 'Module::Generic::Infinity', 'Infinity multiple operations (bis)' );

my $v = $inf->abs;
# diag( "Returning value is: $v" );
# diag( "Resulting object class: " . ref( $inf->abs ) . "(" . ref( $v ) . ")" );
# diag( "Return for \$inf->abs->max(10) is " . $inf->abs->max(10) );
# diag( "Return for \$inf->abs->max(10)->floor is " . $inf->abs->max(10)->floor );
isa_ok( $inf->abs->max(10)->floor, 'Module::Generic::Infinity', 'Infinity chaining' );

my $nan = Module::Generic::Number->new( 'NaN' );
isa_ok( $nan, 'Module::Generic::Nan', 'NaN Class' );
is( "$nan", "NaN", 'NaN stringified' );
ok( $nan->is_nan, 'NaN is NaN' );
# diag( "NaN normal: " . $nan->is_normal );
ok( !$nan->is_normal, 'NaN is not normal number' );
# diag( "Min NaN and 10: " . $nan->min( 10 ) );
# diag( POSIX::fmax( 'NaN', 10 ) );
is( $nan->min( 10 ), 10, 'NaN with min' );
is( $nan->max( 10 ), 10, 'NaN with max' );
is( $nan * 10, 'NaN', 'NaN overloaded' );

# diag( "Formatting as bytes '$n4'." );
$n4->debug($DEBUG);
is( $n4->format_bytes, "1${dec_sep}22M", 'Formatting as bytes' );
# diag( "Current value is: $n4" );
is( $n4->format_hex, '0x138D04', 'Formatting as hexadecimal -> 0x138D04' );
is( $n4->format_binary, '100111000110100000100', 'Formatting as binary' );
is( $n4->from_hex( $n4->format_hex ), 1281284, 'Converting from hex' );
is( $n4->from_binary( $n4->format_binary ), 1281284, 'Converting from binary' );

isa_ok( Module::Generic::Number->new( 0 )->as_boolean, 'Module::Generic::Boolean', 'Number to boolean object' );
ok( !Module::Generic::Number->new( 0 )->as_boolean, 'Number to false boolean' );
ok( Module::Generic::Number->new( 2 )->as_boolean, 'Number to true boolean' );
ok( Module::Generic::Number->new( 2 )->as_boolean == 1, 'Number to boolean, checking value' );
is( Module::Generic::Number->new( 74 )->chr, 'J', 'Number to character' );

my $n6 = Module::Generic::Number->new( 10 );
my $s6 = $n6->as_scalar;
isa_ok( $s6, 'Module::Generic::Scalar', 'as_scalar' );
ok( $n6 eq "10", "stringified value" );

my $a = $n6->as_array;
isa_ok( $a, 'Module::Generic::Array', 'as_array => Module::Generic::Array' );
is( $a->[0], 10, 'as_array' );

done_testing();
