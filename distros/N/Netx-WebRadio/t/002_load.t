# -*- perl -*-

# t/002_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Netx::WebRadio::Station::Shoutcast' ); }

my $object = Netx::WebRadio::Station::Shoutcast->new ();
isa_ok ($object, 'Netx::WebRadio::Station::Shoutcast');


