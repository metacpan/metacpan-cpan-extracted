# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Net::SMS::Mollie' ); }

my $object = Net::SMS::Mollie->new ();
isa_ok ($object, 'Net::SMS::Mollie');


