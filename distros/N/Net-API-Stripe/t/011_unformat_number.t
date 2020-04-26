# -*- perl -*-

use Test::More qw( no_plan );
use strict;
use warnings;

use POSIX;
setlocale( &LC_ALL, 'C' );

BEGIN { use_ok( 'Net::API::Stripe::Number::Format' ) }

my $fmt = Net::API::Stripe::Number::Format->new;
isa_ok( $fmt, 'Net::API::Stripe::Number::Format' );

cmp_ok( $fmt->unformat_number( '123,456.51' ),        '==', 123456.51,   'num' );
cmp_ok( $fmt->unformat_number( 'US$ 12,345,678.51' ), '==', 12345678.51, 'curr' );

{
    no warnings;
    ok( !defined( $fmt->unformat_number( 'US$###,###,###.##' ) ), 'overflow picture' );
}

cmp_ok( $fmt->unformat_number( '-123,456,789.51' ), '==', -123456789.51,'neg' );

cmp_ok( $fmt->unformat_number( '1.5K' ), '==', 1536,      'kilo' );
cmp_ok( $fmt->unformat_number( '1.3M' ), '==', 1363148.8, 'mega' );

my $x = Net::API::Stripe::Number::Format->new;
my $neg_default = $x->neg_format;
$x->neg_format( '(x)' );
cmp_ok( $x->unformat_number( '(123,456,789.51)'), '==', -123456789.51, 'neg paren' );

$x->neg_format( "(${neg_default})" );
cmp_ok( $x->unformat_number( '(123,456,789.51)'), '==', 123456789.51, 'neg default' );

cmp_ok( $fmt->unformat_number( '4K', base => 1024 ), '==', 4096, '4x1024' );
cmp_ok( $fmt->unformat_number( '4K', base => 1000 ), '==', 4000, '4x1000' );
cmp_ok( $fmt->unformat_number( '4KiB', base => 1024 ), '==', 4096, '4x1024 KiB' );
cmp_ok( $fmt->unformat_number( '4KiB', base => 1000 ), '==', 4000, '4x1000 KiB' );
cmp_ok( $fmt->unformat_number( '4G' ), '==', 4294967296, '4G' );
cmp_ok( $fmt->unformat_number( '4G', base => 1 ), '==', 4, 'base 1' );

## eval { $fmt->unformat_number( '4G', base => 1000000 ) };
## like( $@, qr/^\Qbase overflow/, "base overflow" );
{
    no warnings;
    my $res = $fmt->unformat_number( '4G', base => 1000000 );
    ok( !defined( $res ), 'Error from base overlow' );
    like( $fmt->error, qr/^\Qbase overflow/, "base overflow" );
}

{
    no warnings;
    my $res = $fmt->unformat_number( '4G', base => 0 );
    ok( !defined( $res ), 'Error from non-positive number for base' );
    like( $fmt->error, qr/^\Qbase must be a positive integer/, "base 0" );
}

{
    no warnings;
    my $res = $fmt->unformat_number( '4G', base => .5 );
    ok( !defined( $res ), 'Error from non-positive number for decimal base' );
    like( $fmt->error, qr/^\Qbase must be a positive integer/, "base .5" );
}

{
    no warnings;
    my $res = $fmt->unformat_number( '4G', base => -1 );
    ok( !defined( $res ), 'Error from non-positive number for decimal base' );
    like( $fmt->error, qr/^\Qbase must be a positive integer/, "base neg" );
}

{
    my @warnings;
    local $SIG{__WARN__} = sub { @warnings = @_ };
    is( $fmt->unformat_number( undef ), undef );
    like( "@warnings", qr{No format was provided to format number} );
}
