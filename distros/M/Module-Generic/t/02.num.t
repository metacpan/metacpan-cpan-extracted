# -*- perl -*-

# t/02.num.t - check for number object

use Test::More qw( no_plan );
use strict;
use warnings;
use utf8;

BEGIN { use_ok( 'Module::Generic' ) || BAIL_OUT( "Unable to load Module::Generic" ); }

my $n = Module::Generic::Number->new( 10 );
my $n2 = $n->clone;

no warnings;
my $n_fail = Module::Generic::Number->new( 'USD One' );
use warnings;
# diag( Module::Generic::Number->error );
is( $n_fail, undef, 'Invalid number' );

# Creating object from locale
my $n_loc = Module::Generic::Number->new( 100, { lang => 'fr_FR', precede => 1 });
isa_ok( $n_loc, 'Module::Generic::Number', 'Object with locale language string' );
is( $n_loc->precision, 2, 'French precision => 2' );
is( $n_loc->thousand, ' ', 'French thousand separator => space' );
is( $n_loc->decimal, ',', 'French decimal separator => comma' );

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
isa_ok( $bool, 'Module::Generic::Boolean', 'Returning boolean object' );
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

is( $n2->decimal, '.', 'Decimal separator' );
is( $n2->thousand, ',', 'Thousand separator' );
is( $n2->precision, 2, 'Precision' );
is( $n2->currency, '€', 'Currency symbol' );
isa_ok( $n2->currency, 'Module::Generic::Scalar', 'Returns property as string object' );
my $n3 = $n2->unformat( $n );
# diag( "Unformatting \"$n\"." );
isa_ok( $n3, 'Module::Generic::Number', 'Unformat result in new object using unformat()' );
is( $n3, 1281284, 'Unformat resulting value' );
is( $n3->precision, 2, 'New object precision' );
is( $n3->format, '1,281,284.00', 'Formatting number using format()' );
is( $n3->currency, '€', 'Currency symbol' );
# $n3->debug( 3 );
my $n_money = $n3->format_money;
is( "$n_money", '€1,281,284.00', 'Formatting money using format_money()' );
isa_ok( $n_money, 'Module::Generic::Scalar', 'Returns string object upon formatting' );
$n3 *= -1;
is( $n3, -1281284, 'Negative number' );
is( $n3->format_negative( '(x)' ), '(1,281,284.00)', 'Formatting negative number => (1,281,284.00)' );
my $n4 = $n3->abs;
is( $n4, 1281284, 'abs' );
is( $n4->atan, 1.5707955463278, 'atan' );
# $n4->debug( 3 );
is( $n4->atan2(12), 1.57078696118977, 'atan2' );
my $n5 = $n4->cbrt;
is( $n5, 108.612997866582, 'cbrt' );
is( $n5->ceil, 109, 'ceil' );
is( $n5->floor, 108, 'floor' );
is( $n4->cos, -0.413777602170324, 'cos' );
is( $n4->clone( 3 )->exp, 20.0855369231877, 'exp' );
is( $n5->int, 108, 'int' );
ok( !$n5->is_negative, 'Not negative' );
ok( $n3->is_negative, 'Is Negative' );
ok( $n5->is_positive, 'Is positive' );
ok( !$n3->is_positive, 'Is not positive' );
is( $n4->log, 14.0633732581021, 'log' );
is( $n4->log2, 20.2891588576344, 'log2' );
is( $n4->log10, 6.10764540293951, 'log10' );
is( $n4->max( 1281285 ), 1281285, 'max' );
is( $n4->min( 1281285 ), 1281284, 'min' );
is( $n4->mod( 3 ), 2, 'mod' );
# diag( "\$n4 = $n4" );
# $n4->debug( 3 );
is( $n4->oct, 10, 'oct' );
is( $n4->clone( 3.14159265358979323846 )->round( 4 ), 3.1416, 'Rounding' );
is( $n4->sin, -0.910377996187395, 'sin' );
is( $n4->sqrt, 1131.93816085509, 'sqrt' );
is( $n4->tan, 2.20016257867108, 'tan' );
is( $n4->clone( 3.14159265358979323846 )->length, 16, 'Number length' );
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
is( $n4->format_bytes, '1.22M', 'Formatting as bytes' );
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

