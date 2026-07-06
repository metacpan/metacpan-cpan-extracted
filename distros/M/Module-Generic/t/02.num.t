#!/usr/bin/perl
# t/02.num.t - check for number object
BEGIN
{
    use Test::More qw( no_plan );
    use strict;
    use warnings;
    use utf8;
    use Cwd qw( abs_path );
    use lib abs_path( './lib' );
    use vars qw( $DEBUG );
    use Config;
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

BEGIN
{
    use_ok( 'Module::Generic::Number' ) || BAIL_OUT( "Unable to load Module::Generic::Number" );
    use_ok( 'Module::Generic::Number::Format' ) || BAIL_OUT( "Unable to load Module::Generic::Number::Format" );
};
POSIX::setlocale( &POSIX::LC_ALL, 'C.UTF-8' ) if( $DEBUG );
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
$lconv = $Module::Generic::Number::Format::DEFAULT if( !$curr_locale );
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
my( $sep_space, $tho_sep, $dec_sep, $grouping, $n );
my( $mon_tho_sep, $mon_dec_sep, $mon_grouping );

# NOTE: Mirror the normalisation done in Module::Generic::Number for
# POSIX::localeconv()->{grouping}. The first byte is the size of the first digit group;
# an empty value, a leading 0 byte, or a CHAR_MAX byte (>= 127) all mean "no grouping".
# See _normalise_lconv_grouping in Module::Generic::Number for the full rationale.
sub normalise_lconv_grouping
{
    my $value = shift( @_ );
    return(0) if( !defined( $value ) || !CORE::length( $value ) );
    my @bytes = unpack( 'C*', $value );
    return(0) if( !scalar( @bytes ) );
    my $first = $bytes[0];
    return(0) if( !defined( $first ) || $first == 0 || $first >= 127 );
    return( $first );
}

if( !scalar( keys( %$lconv ) ) || [split(/\./, $curr_locale)]->[0] eq 'C' )
{
    diag( "No locale data could be found for language \"", ( POSIX::setlocale( &POSIX::LC_ALL ) // '' ), "\"" );
    $tho_sep = ',';
    $dec_sep = '.';
    $grouping = 3;
    # NOTE: When no real locale is available we fake an en_US style numeric format. Since
    # format_money() now follows the monetary category independently, we must fake the
    # monetary trio too, otherwise it would resolve to the C locale (no grouping) and
    # diverge from the numeric expectation below.
    $mon_tho_sep = ',';
    $mon_dec_sep = '.';
    $mon_grouping = 3;
    $n = Module::Generic::Number->new( 10,
        precision    => 2,
        thousand     => $tho_sep,
        decimal      => $dec_sep,
        grouping     => $grouping,
        mon_thousand => $mon_tho_sep,
        mon_decimal  => $mon_dec_sep,
        mon_grouping => $mon_grouping,
        debug        => $DEBUG
    );
}
else
{
    # NOTE: With posix_strict (the default), the numeric trio follows LC_NUMERIC only,
    # without any fall back to the monetary category. We must mirror that here, otherwise
    # under a mixed locale such as LC_NUMERIC=C with LC_MONETARY=en_US.UTF-8 the test
    # would expect a separator that the module deliberately does not use for plain
    # numbers. The monetary expectation is computed separately, further below.
    $tho_sep = $lconv->{thousands_sep};
    $dec_sep = $lconv->{decimal_point};
    # NOTE: Plain number grouping follows the LC_NUMERIC category only, exactly as
    # Module::Generic::Number resolves it. We deliberately do not fall back to
    # mon_grouping here. The module normalises lconv->{grouping} to a defined 0 before
    # its own grouping/mon_grouping fallback runs, so a defined 0 always wins and the
    # monetary grouping is never reached for a plain number. Under a mixed locale such
    # as LC_NUMERIC=C with LC_MONETARY=en_US.UTF-8, the correct grouping for a plain
    # number is therefore 0 (no grouping), and the expectation must mirror that.
    $grouping = normalise_lconv_grouping( $lconv->{grouping} );
    # NOTE: Money follows the LC_MONETARY category. Mirror format_money(): use the
    # monetary value when present, otherwise fall back to the numeric one. mon_grouping
    # is normalised the same way as grouping.
    $mon_tho_sep = CORE::length( $lconv->{mon_thousands_sep} // '' )
        ? $lconv->{mon_thousands_sep}
        : $tho_sep;
    $mon_dec_sep = CORE::length( $lconv->{mon_decimal_point} // '' )
        ? $lconv->{mon_decimal_point}
        : $dec_sep;
    $mon_grouping = normalise_lconv_grouping( $lconv->{mon_grouping} );
    $n = Module::Generic::Number->new( 10, precision => 2, debug => $DEBUG );
}
$sep_space = int( $lconv->{p_sep_by_space} // 0 ) > 0 ? qr/[[:blank:]\h]+/ : '';

# NOTE: Diagnostic for CPAN Testers smokers. Only emitted when AUTOMATED_TESTING or
# AUTHOR_TESTING is set, so this does not pollute output for regular users.
# Helps us see what POSIX::localeconv() returns on smokers where the number formatting
# tests would otherwise just say "got X, expected Y" without context.
if( $ENV{AUTOMATED_TESTING} || $ENV{AUTHOR_TESTING} )
{
    diag( "Locale resolved to: '", ( $curr_locale // 'undef' ), "'" );
    diag( "LC_ALL env: '", ( $ENV{LC_ALL} // 'unset' ), "', LANG env: '", ( $ENV{LANG} // 'unset' ), "'" );
    diag( "Detected thousand separator: '", ( $tho_sep // 'undef' ), "'" );
    diag( "Detected decimal separator: '", ( $dec_sep // 'undef' ), "'" );
    diag( "Detected grouping size: '", ( $grouping // 'undef' ), "'" );
    diag( "Raw lconv->{grouping}: '", ( defined( $lconv->{grouping} ) ? join( ',', unpack( 'C*', $lconv->{grouping} ) ) : 'undef' ), "'" );
    diag( "Raw lconv->{mon_grouping}: '", ( defined( $lconv->{mon_grouping} ) ? join( ',', unpack( 'C*', $lconv->{mon_grouping} ) ) : 'undef' ), "'" );
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
my $new_loc = $n->locale;
## diag( "New locale is $new_loc" );
my $n2 = $n->clone;
is( $n2->locale, $new_loc, "Locale is kept with cloning" );
$n2->symbol( '€' );

{
    no warnings;
    my $n_fail = Module::Generic::Number->new( 'USD One' );
    # diag( Module::Generic::Number->error );
    is( $n_fail, undef, 'Invalid number' );
}

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
        skip( 'Unsupported language', 5 );
    }
    my $n_loc = Module::Generic::Number->new( 100, { locale => 'fr_FR', precede => 1, precision => 2, thousand => ' ', decimal => ',', debug => $DEBUG });
    isa_ok( $n_loc, 'Module::Generic::Number', 'Object with locale language string' );
    is( $n_loc->precision, 2, 'French precision => 2' );
    # RT #132667
    # https://perldoc.perl.org/5.10.1/perlrecharclass.html
    # [:blank:] does not catch non-breaking space, but horizontal space \h does
    like( $n_loc->thousand, qr/[[:blank:]\h]+/, 'French thousand separator => space' );
    is( $n_loc->decimal, ',', 'French decimal separator => comma' );
    # The locale stored may be a variant such as 'fr_FR.UTF-8' if the bare
    # 'fr_FR' name was not accepted by the system and a supported variant was
    # tried instead.
    like( $n_loc->locale, qr/^fr_FR/, 'locale is fr_FR' );
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
SKIP:
{
    if( $] < 5.034000 )
    {
        $n <<= 2;   # 32 << 2 == 128, equivalent to $n >>= -2 and keep the object
        skip( "Bitwise shift right assignment; >>= -2 does not work in perl < 5.34.", 1 );
    }
    is( $n >>= -2, 128, 'Bitwise shift right assignment' );
};
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
{
    no warnings;
    local $SIG{__WARN__} = sub{};
    ok( $n != 'Hello', 'Not equal string' );
}
ok( $n != $n2, 'Not equal number' );
ok( $n eq 1281284, 'Equal as string' );
ok( $n ne $n2, 'Not equal as string' );
{
    no warnings;
    local $SIG{__WARN__} = sub{};
    my $bool = $n != 'Bonjour';
    # isa_ok( $bool, 'Module::Generic::Boolean', 'Returning boolean object' );
}
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

is( $n2->decimal, $dec_sep, "Decimal separator -> '" . ( defined( $dec_sep ) ? $dec_sep : 'undef' ) . "'" );
# is( $n2->thousand->scalar, $tho_sep, 'Thousand separator' );
# diag( "\$tho_sep is defined? ", defined( $tho_sep ) ? 'yes' : 'no' );
# diag( "\$n2->thousand is defined? ", defined( $n2->thousand ) ? 'yes' : 'no' );
is( ( $n2->thousand // '' ), ( $tho_sep // '' ), "Thousand separator -> '" . ( defined( $tho_sep ) ? $tho_sep : 'undef' ) . "'" );
is( ( $n2->grouping // '' ), ( $grouping // '' ), "Grouping digit -> '" . ( defined( $grouping ) ? $grouping : 'undef' ) . "'" );
is( $n2->precision, 2, "Precision -> '2'" );
is( $n2->currency, '€', "Currency symbol -> '€'" );
isa_ok( $n2->currency, 'Module::Generic::Scalar', 'Returns property as string object' );

diag( "Number to unformat is '$n' and \$n2 has locale '", ( $n2->locale // 'undef' ), "', and precision '", ( $n2->precision // 'undef' ), "'" ) if( $DEBUG );
my $n3 = $n2->unformat( $n );
diag( "\$n3 has locale '", ( $n3->locale // 'undef' ), "', and precision '", ( $n3->precision // 'undef' ), "'" ) if( $DEBUG );
isa_ok( $n3, 'Module::Generic::Number', 'Unformat result in new object using unformat()' );
diag( "Error unformating $n: ", $n2->error ) if( !defined( $n3 ) && $DEBUG );
is( $n3, 1281284, 'Unformat resulting value' );
is( $n3->precision, 2, 'New object precision' );
$dec_sep = '' if( !defined( $dec_sep ) );
$tho_sep = '' if( !defined( $tho_sep ) );
$mon_dec_sep = $dec_sep if( !defined( $mon_dec_sep ) );
$mon_tho_sep = $tho_sep if( !defined( $mon_tho_sep ) );
# NOTE: Build the expected formatted string honestly based on what the system locale
# really supports. If grouping is 0 (or thousand separator is empty),
# the formatted output will not contain any group separator, and the test must reflect
# that rather than mechanically assuming 3-digit groups.
my $grouped_int = '1281284';
if( $grouping && $grouping > 0 && CORE::length( $tho_sep ) )
{
    # Group from right to left by $grouping digits, joined with $tho_sep
    $grouped_int = reverse( join( $tho_sep, unpack( "(A${grouping})*", reverse( '1281284' ) ) ) );
}
my $expected_number = "${grouped_int}${dec_sep}00";
if( $ENV{AUTOMATED_TESTING} || $ENV{AUTHOR_TESTING} )
{
    diag( "Expected formatted number: '${expected_number}' (grouping=${grouping}, tho_sep='${tho_sep}', dec_sep='${dec_sep}')" );
}
# diag( "Thousand separator is: '", $n3->thousand, "'" );
# diag( "Number::Format object is: ", Dumper( $n3->{_fmt} ) );
is( $n3->format, $expected_number, "Formatting number using format() -> ${expected_number}" );
is( $n3->currency, '€', "Currency symbol -> '€'" );
# NOTE: format_money() follows the monetary category, which can differ from the numeric
# one (e.g. LC_NUMERIC=C with a populated LC_MONETARY), so its expected value is built
# from the monetary trio rather than from $expected_number.
my $mon_grouped_int = '1281284';
if( $mon_grouping && $mon_grouping > 0 && CORE::length( $mon_tho_sep ) )
{
    $mon_grouped_int = reverse( join( $mon_tho_sep, unpack( "(A${mon_grouping})*", reverse( '1281284' ) ) ) );
}
my $expected_money = "${mon_grouped_int}${mon_dec_sep}00";
if( $ENV{AUTOMATED_TESTING} || $ENV{AUTHOR_TESTING} )
{
    diag( "Expected money: '${expected_money}' (mon_grouping=${mon_grouping}, mon_tho_sep='${mon_tho_sep}', mon_dec_sep='${mon_dec_sep}')" );
}
my $n_money = $n3->format_money;
if( $n3->precede )
{
    like( "$n_money", qr/€${sep_space}\Q${expected_money}\E/, 'Formatting money using format_money()' );
}
else
{
    like( "$n_money", qr/\Q${expected_money}\E${sep_space}€/, 'Formatting money using format_money()' );
}
isa_ok( $n_money, 'Module::Generic::Scalar', 'Returns string object upon formatting' );
$n3 *= -1;
is( $n3, -1281284, 'Negative number' );
like( $n3->format_negative( '(x)' ), qr/\(\Q${expected_number}\E\)/, "Formatting negative number => (${expected_number})" );
my $n4 = $n3->abs;
is( $n4, 1281284, 'abs' );
# 1.5707955463278
is( $n4->atan, POSIX::atan( $n4 ), 'atan' );
# 1.57078696118977
is( $n4->atan2(12), CORE::atan2( $n4, 12 ), 'atan2' );
my $n5 = $n4->cbrt;
# 108.612997866582
# Use math fallback for perl < 5.022 where POSIX::cbrt does not exist.
# my $cbrt_expected = $] >= 5.022 ? POSIX::cbrt( $n4 + 0 ) : ( $n4 ** ( 1/3 ) );
my $n4_actual = $n4->{_number};
my $cbrt_expected = $] >= 5.022 ? POSIX::cbrt( $n4 ) : ( $n4 < 0 ? -( ( -$n4 ) ** ( 1/3 ) ) : $n4 ** ( 1/3 ) );
is( $n5, $cbrt_expected, 'cbrt' );
# 109
is( $n5->ceil, POSIX::ceil( $n5 ), 'ceil' );
# 108
is( $n5->floor, POSIX::floor( $n5 ), 'floor' );
# -0.413777602170324
is( $n4->cos, CORE::cos( $n4 ), 'cos' );
# 20.0855369231877
is( $n4->clone(3)->exp, POSIX::exp(3), 'exp' );
# 108
is( $n5->int, CORE::int( $n5 ), 'int' );
ok( !$n5->is_negative, 'Not negative' );
ok( $n3->is_negative, 'Is Negative' );
ok( $n5->is_positive, 'Is positive' );
ok( !$n3->is_positive, 'Is not positive' );
# 14.0633732581021
is( $n4->log, CORE::log( $n4 ), 'log' );
# 20.2891588576344
# Ligne 313 du test
my $log2_expected = $] >= 5.022 ? POSIX::log2( $n4 ) : ( CORE::log( $n4 + 0 ) / CORE::log(2) );
is( $n4->log2, $log2_expected, 'log2' );
# 6.10764540293951
is( $n4->log10, POSIX::log10( $n4 ), 'log10' );
is( $n4->max(1281285), 1281285, 'max' );
is( $n4->min(1281285), 1281284, 'min' );
is( $n4->mod(3), 2, 'mod' );
is( $n4->oct, 10, 'oct' );
is( $n4->clone(3.14159265358979323846)->round(4), 3.1416, 'Rounding' );
# -0.910377996187395
is( $n4->sin, CORE::sin( $n4 ), 'sin' );
is( $n4->sqrt, CORE::sqrt( $n4 ), 'sqrt' );
# 2.20016257867108
is( $n4->tan, POSIX::tan( $n4 ), 'tan' );
my $pie = $n4->clone(3.14159265358979323846);
is( $pie->length, CORE::length( $pie ), 'Number length' );
ok( $n4->is_finite, 'Is finite number' );
ok( $n4->clone(3.14159265358979323846)->is_float, 'Is float' );
ok( $n4->is_int, 'Is integer' );
ok( !$n4->is_nan, 'Is NaN' );
ok( $n4->is_positive, 'Is positive number' );
ok( !$n4->is_negative, 'Is negative number' );
ok( $n4->is_normal, 'Is normal number' );

is( $n4->format_bytes( mode => 'iec60027' ), "1${dec_sep}22MiB", 'format_bytes() in IEC mode' );
is( $n4->format_bytes( mode => 'iec' ),      "1${dec_sep}22MiB", 'format_bytes() in IEC mode (alias)' );

my $inf = Module::Generic::Number->new( 9**9**9, debug => 3 );
isa_ok( $inf, 'Module::Generic::Infinity', 'Infinity Class' );
# diag( "Infinity: $inf -> ", overload::StrVal( $inf ) );
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
is( $nan->min(10), 10, 'NaN with min' );
is( $nan->max(10), 10, 'NaN with max' );
is( $nan * 10, 'NaN', 'NaN overloaded' );

# diag( "Formatting as bytes '$n4'." );
$n4->debug($DEBUG);
is( $n4->format_bytes, "1${dec_sep}22M", 'Formatting as bytes' );
# diag( "Current value is: $n4" );
is( $n4->format_hex, '0x138D04', 'Formatting as hexadecimal -> 0x138D04' );
is( $n4->format_binary, '100111000110100000100', 'Formatting as binary' );
is( $n4->from_hex( $n4->format_hex ), 1281284, 'Converting from hex' );
is( $n4->from_binary( $n4->format_binary ), 1281284, 'Converting from binary' );

ok( Module::Generic->_is_a( Module::Generic::Number->new(0)->as_boolean => 'Module::Generic::Boolean' ), 'Number to boolean object' );
ok( !Module::Generic::Number->new(0)->as_boolean, 'Number to false boolean' );
ok( Module::Generic::Number->new(2)->as_boolean, 'Number to true boolean' );
ok( Module::Generic::Number->new(2)->as_boolean == 1, 'Number to boolean, checking value' );
is( Module::Generic::Number->new(74)->chr, 'J', 'Number to character' );

my $n6 = Module::Generic::Number->new(10);
my $s6 = $n6->as_scalar;
isa_ok( $s6, 'Module::Generic::Scalar', 'as_scalar' );
ok( $n6 eq "10", "stringified value" );

my $a = $n6->as_array;
isa_ok( $a, 'Module::Generic::Array', 'as_array => Module::Generic::Array' );
is( $a->[0], 10, 'as_array' );

# NOTE: Additional functionality and edge cases
subtest 'Additional functionality and edge cases' => sub
{
    my $saved_locale = POSIX::setlocale( &POSIX::LC_ALL );
    my $num = Module::Generic::Number->new( 3.14159, debug => $DEBUG );
    is( $num->round_zero, 3, 'round_zero' );
    my $fmt = Module::Generic::Number::Format->new( 3.14159, debug => $DEBUG );

    my $lconv = POSIX::localeconv();
    my $decoded = $fmt->decode_lconv( $lconv );
    ok( defined( $decoded ), 'decode_lconv' );

    my $mult = $fmt->_get_multipliers(1000);
    is( $mult->{kilo}, 1000, '_get_multipliers kilo base 1000' );

    # Reset locale to C to ensure consistent formatting
    POSIX::setlocale( &POSIX::LC_ALL, 'C' );
    # Test a number that is already in scientific notation
    my $sci_num = Module::Generic::Number->new( "1.23e+45", debug => $DEBUG );
    is( $sci_num->format, "1.23e+45", 'Number in scientific notation is preserved' );

    {
        no warnings;
        my $round_err = $num->round(-1);
        ok( !defined( $round_err ), 'round with negative precision errors' );
    }
    POSIX::setlocale( &POSIX::LC_ALL, $saved_locale ) if( defined( $saved_locale ) );
};

# NOTE: Thread-safe operations
subtest 'Thread-safe operations' => sub
{
    SKIP:
    {
        if( !$Config{useithreads} )
        {
            skip( 'Threads not available', 2 );
        }

        require threads;
        require threads::shared;

        # Try common locales, fall back to C
        my $locale;
        for my $try (qw( en_US fr_FR de_DE C ))
        {
            my $saved_locale = POSIX::setlocale( &POSIX::LC_ALL );
            my $rv = eval{ POSIX::setlocale( &POSIX::LC_ALL, $try ) };
            POSIX::setlocale( &POSIX::LC_ALL, $saved_locale ) if( defined( $saved_locale ) );
            if( defined( $rv ) && $rv eq $try )
            {
                $locale = $try;
                last;
            }
        }
        unless( $locale )
        {
            diag( "No suitable locale found, skipping format tests" ) if( $DEBUG );
            $locale = 'C'; # Safe default
        }
        diag( "Using locale '$locale' for thread-safe operations test" ) if( $DEBUG );

        my @threads = map
        {
            threads->create(sub
            {
                my $tid = threads->tid();
                my $num = Module::Generic::Number->new( 1000, locale => $locale, debug => $DEBUG );
                if( !defined( $num ) )
                {
                    diag( "Thread $tid: Failed to create number object: ", Module::Generic::Number->error ) if( $DEBUG );
                    return(0);
                }
                $num += $tid;
                if( !defined( $num ) )
                {
                    diag( "Thread $tid: Failed to increment number: ", $num->error ) if( $DEBUG );
                    return(0);
                }
                # Only test format if locale is not C (to ensure locale-aware formatting)
                if( $locale ne 'C' )
                {
                    my $formatted = $num->format;
                    if( !defined( $formatted ) )
                    {
                        diag( "Thread $tid: Failed to format number: ", $num->error ) if( $DEBUG );
                        return(0);
                    }
                }
                return(1);
            });
        } 1..5;

        my $success = 1;
        for my $thr ( @threads )
        {
            $success &&= $thr->join();
        }

        ok( $success, 'All threads performed operations successfully' );
        if( $locale ne 'C' )
        {
            my $num = Module::Generic::Number->new( 1000, locale => $locale, debug => $DEBUG );
            my $formatted = $num->format;
            ok( defined($formatted), "Number formatted successfully in locale '$locale'" );
        }
        else
        {
            ok( 1, 'Skipped format test due to C locale' );
        }
    };
};

# NOTE: Monetary formatting must follow its own trio (mon_decimal, mon_thousand,
# mon_grouping) independently from the numeric trio used by format(). These cases are
# built with explicit values so they remain deterministic regardless of the system
# locale installed on the smoker.
subtest 'Monetary trio independent from numeric trio' => sub
{
    my $saved_locale = POSIX::setlocale( &POSIX::LC_ALL );
    POSIX::setlocale( &POSIX::LC_ALL, 'C' );

    ok( Module::Generic::Number->new( 1 )->posix_strict, 'posix_strict defaults to true' );

    # Numeric: no grouping. Monetary: grouped by 3 with a comma.
    my $n = Module::Generic::Number->new( 1281284,
        precision    => 2,
        decimal      => '.',
        thousand     => ',',
        grouping     => 0,
        mon_decimal  => '.',
        mon_thousand => ',',
        mon_grouping => 3,
        currency     => '€',
        precede      => 0,
        space_pos    => 0,
        debug        => $DEBUG,
    );
    isa_ok( $n, 'Module::Generic::Number', 'object with explicit numeric and monetary trios' );
    is( $n->grouping, 0, 'numeric grouping accessor returns 0' );
    is( $n->mon_grouping, 3, 'monetary grouping accessor returns 3' );
    is( $n->mon_decimal, '.', 'monetary decimal accessor' );
    is( $n->mon_thousand, ',', 'monetary thousand accessor' );
    is( $n->format, '1281284.00', 'format() is not grouped when numeric grouping is 0' );
    like( $n->format_money, qr/\Q1,281,284.00\E€/, 'format_money() groups using the monetary trio' );

    # The mirror image: numeric grouped, monetary not grouped.
    my $n2 = Module::Generic::Number->new( 1281284,
        precision    => 2,
        decimal      => '.',
        thousand     => ',',
        grouping     => 3,
        mon_decimal  => '.',
        mon_thousand => '',
        mon_grouping => 0,
        currency     => '€',
        precede      => 0,
        space_pos    => 0,
        debug        => $DEBUG,
    );
    if( !defined( $n2 ) )
    {
        diag( "Error instantiating the number object for 1281284: ", Module::Generic::Number->error );
    }
    is( $n2->format, '1,281,284.00', 'format() groups when numeric grouping is 3' );
    like( $n2->format_money, qr/\Q1281284.00\E€/, 'format_money() is not grouped when monetary grouping is 0' );

    # Distinct separators between the two categories.
    my $n3 = Module::Generic::Number->new( 1281284,
        precision    => 2,
        decimal      => ',',
        thousand     => '.',
        grouping     => 3,
        mon_decimal  => ',',
        mon_thousand => ' ',
        mon_grouping => 3,
        currency     => '€',
        precede      => 0,
        space_pos    => 1,
        debug        => $DEBUG,
    );
    is( $n3->format, '1.281.284,00', 'numeric format uses its own separators' );
    like( $n3->format_money, qr/\Q1 281 284,00 €\E/, 'money format uses its own separators and spacing' );

    POSIX::setlocale( &POSIX::LC_ALL, $saved_locale ) if( defined( $saved_locale ) );
};

# NOTE: Resolution path under a real mixed locale (numeric C, monetary en_US). This is
# environment-dependent, so it is skipped when the required locales are not installed or
# when localeconv does not actually expose a monetary grouping on this system.
subtest 'Mixed locale resolution (LC_NUMERIC=C, LC_MONETARY=en_US)' => sub
{
    my $saved_locale = POSIX::setlocale( &POSIX::LC_ALL );
    SKIP:
    {
        my $mon_ok = eval{ POSIX::setlocale( &POSIX::LC_MONETARY, 'en_US.UTF-8' ) };
        my $num_ok = eval{ POSIX::setlocale( &POSIX::LC_NUMERIC, 'C' ) };
        if( !defined( $mon_ok ) || !$mon_ok || !defined( $num_ok ) )
        {
            skip( 'en_US.UTF-8 monetary locale not available', 2 );
        }
        my $lconv = POSIX::localeconv();
        my $mg = normalise_lconv_grouping( $lconv->{mon_grouping} );
        if( !$mg || $mg <= 0 )
        {
            skip( 'Monetary grouping not exposed by this system', 2 );
        }
        my $n = Module::Generic::Number->new( 1281284, precision => 2, currency => '€', precede => 0, space_pos => 0, debug => $DEBUG );
        is( $n->format, '1281284.00', 'strict: plain number not grouped under LC_NUMERIC=C' );
        like( $n->format_money, qr/\Q1,281,284.00\E/, 'strict: money grouped following LC_MONETARY' );
    };
    POSIX::setlocale( &POSIX::LC_ALL, $saved_locale ) if( defined( $saved_locale ) );
};

subtest 'Formatter propagation through clone()' => sub
{
    my $src = Module::Generic::Number->new( 42, precision => 3, decimal => ',', debug => $DEBUG );
    my $c   = $src->clone(100);
    is( $c,              100,  'clone has the right number' );
    is( $c->precision,   3,    'clone propagates formatter precision' );
    is( $c->decimal,     ',',  'clone propagates formatter decimal' );
    isa_ok( $c, 'Module::Generic::Number', 'clone is a Number' );
};

subtest 'Rounding methods propagate formatter' => sub
{
    my $num = Module::Generic::Number->new( 3.14159, precision => 4, debug => $DEBUG );
    my $r   = $num->round(2);
    is( $r,            3.14, 'round() value' );
    is( $r->precision, 4,    'round() preserves formatter precision' );
    isa_ok( $r, 'Module::Generic::Number', 'round() returns a Number' );

    my $r2 = $num->round2(2);
    SKIP:
    {
        if( !defined( $r2 ) )
        {
            diag( "\$num->round2(2) returned undef: ", $num->error );
            skip( "\$num->round2(2) returned undef", 2 );
        }
        is( $r2,            3.14, 'round2() value' );
        is( $r2->precision, 4,    'round2() preserves formatter precision' );
    };

    my $rz = $num->round_zero;
    SKIP:
    {
        if( !defined( $rz ) )
        {
            diag( "\$num->round_zero returned undef: ", $num->error );
            skip( "\$num->round_zero returned undef", 2 );
        }
        is( $rz,            3, 'round_zero() value' );
        is( $rz->precision, 4, 'round_zero() preserves formatter precision' );
    };
};

subtest 'format_bytes' => sub
{
    my $nb = Module::Generic::Number->new( 1000000, precision => 2, debug => $DEBUG );
    is( $nb->format_bytes( base => 1000 ), "1${dec_sep}00M", 'format_bytes() with base 1000' );
};

subtest 'locale propagated to formatter' => sub
{
    SKIP:
    {
        my $saved_locale = POSIX::setlocale( &POSIX::LC_ALL );
        my $ok = eval{ POSIX::setlocale( &POSIX::LC_ALL, 'fr_FR.UTF-8' ) };
        # On BSDs, setlocale(LC_ALL) may return a composite string such as
        # 'C/fr_FR.UTF-8/C/C/C/C' when not all categories can be set uniformly.
        # That is not a failure per se, but it means the locale is not fully fr_FR,
        # so localeconv() will not return fr_FR values. We skip in that case.
        if( !defined( $ok ) || $ok ne 'fr_FR.UTF-8' )
        {
            POSIX::setlocale( &POSIX::LC_ALL, $saved_locale ) if( defined( $saved_locale ) );
            skip( 'fr_FR.UTF-8 not uniformly available on this system', 2 );
        }
        # The locale name may be accepted by the OS but its numeric category may still
        # carry C defaults (e.g. OpenBSD with a minimal locale table). We check
        # localeconv() directly rather than assuming a comma, so the test remains honest
        # on any platform.
        my $lconv_fr = POSIX::localeconv();
        my $expected_decimal = $lconv_fr->{decimal_point} // '';
        if( !CORE::length( $expected_decimal ) || $expected_decimal eq '.' )
        {
            POSIX::setlocale( &POSIX::LC_ALL, $saved_locale ) if( defined( $saved_locale ) );
            skip( 'fr_FR.UTF-8 locale accepted but provides no distinct numeric decimal data on this system', 2 );
        }
        my $num = Module::Generic::Number->new( 1234, precision => 2, debug => $DEBUG );
        $num->locale( 'fr_FR.UTF-8' );
        is( $num->locale, 'fr_FR.UTF-8', 'locale setter propagates to formatter' );
        is( $num->decimal, $expected_decimal, 'decimal updated after locale change' );
        POSIX::setlocale( &POSIX::LC_ALL, $saved_locale ) if( defined( $saved_locale ) );
    };
};

subtest 'unformat' => sub
{
    my $num = Module::Generic::Number->new( 0,
        precision    => 2,
        decimal      => '.',
        thousand     => ',',
        grouping     => 3,
        debug        => $DEBUG,
    );
    my $unf = $num->unformat( '1,234,567.89' );
    isa_ok( $unf, 'Module::Generic::Number', 'unformat() returns a Number' );
    is( $unf,            1234567.89, 'unformat() value' );
    is( $unf->precision, 2,          'unformat() preserves formatter precision' );
    is( $unf->decimal,   '.',        'unformat() preserves formatter decimal'   );
};

subtest 'formatter survives numeric clone' => sub
{
    my $n = Module::Generic::Number->new( 1281284, precision => 2, decimal => '.', debug => $DEBUG );
    my $n2 = $n->clone( 1.22192764282227 );

    is( $n2->precision,  2,  'cloned number keeps formatter precision' );
    is( $n2->format, '1.22', 'cloned number formats with preserved precision' );
};

subtest 'formatter state survives numeric operation' => sub
{
    my $n = Module::Generic::Number->new( 1281284, precision => 2, decimal => '.', debug => $DEBUG );
    my $n2 = $n->abs;

    is( $n2->precision, 2, 'numeric operation preserves formatter precision' );
    is( $n2->format_bytes, '1.22M', 'format_bytes uses preserved formatter precision' );
};

subtest 'clone as class method' => sub
{
    my $n = Module::Generic::Number->clone(42);

    ok( !defined( $n ) && Module::Generic::Number->error, 'cannot call clone() as a class function of Module::Generic::Number' );
};

done_testing();

__END__
