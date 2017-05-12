# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More qw(no_plan);

BEGIN { use_ok( 'Net::BitTorrent::File' ); }

my $object = Net::BitTorrent::File->new ();
isa_ok ($object, 'Net::BitTorrent::File', 'empty object');
