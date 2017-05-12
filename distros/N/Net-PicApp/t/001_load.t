# -*- perl -*-

# t/001_load.t - check module loading

use lib './t/';
use Test::More tests => 2;
use TestUtil qw(apikey);

my $key = apikey();

BEGIN {
    use_ok( 'Net::PicApp' );
}

my $pa = Net::PicApp->new(
    {
        apikey     => $key,
    }
);
isa_ok( $pa, 'Net::PicApp' );
