# -*- perl -*-

use Test::More qw( no_plan );
use strict;
use warnings;

use POSIX;
setlocale(&LC_ALL, 'C');

BEGIN { use_ok( 'Net::API::Stripe::Number::Format' ) }

my $fmt = Net::API::Stripe::Number::Format->new;
isa_ok( $fmt, 'Net::API::Stripe::Number::Format' );

is( $fmt->format_number( 123456.51 ),       '123,456.51',     'thousands' );
is( $fmt->format_number( 1234567.509, 2 ),  '1,234,567.51',   'rounding' );
is( $fmt->format_number( 12345678.5, 2 ),   '12,345,678.5',   'one digit' );
is( $fmt->format_number( 123456789.51, 2 ), '123,456,789.51', 'hundreds of millions' );
is( $fmt->format_number( 1.23456789, 6 ),   '1.234568',       'six digit rounding' );
is( $fmt->format_number( '1.2300', 7, 1 ),  '1.2300000',      'extra zeroes' );
is( $fmt->format_number( .23, 7, 1 ),       '0.2300000',      'leading zero' );
is( $fmt->format_number( -100, 7, 1 ),      '-100.0000000',   'negative with zeros' );

# The test should fail because 20 digits is too big to correctly store
# in a scalar variable without using Math::BigFloat.
{
    no warnings;
eval { $fmt->format_number(97, 20) };
like( $fmt->error->message,
     qr/^round\(\) overflow for '[^\']+'\. Try smaller precision or use Math\:\:BigFloat/,
     "round overflow" );
}

# Test with warnings enabled - expect a warning when called with undef
{
    my @warnings;
    local $SIG{__WARN__} = sub { @warnings = @_ };
    is( $fmt->format_number( undef ), "0" );
    my $file = __FILE__;
    like( "@warnings", qr{No number was provided to format} );
}

# Test again with warnings disabled to see if we do NOT get the warning
{
    # no warnings "uninitialized";
    no warnings;
    my @warnings;
    local $SIG{__WARN__} = sub { @warnings = @_ };
    is( $fmt->format_number(undef), "0" );
    is( "@warnings", '' );
}
