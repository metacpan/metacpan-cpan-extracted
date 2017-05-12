# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 1;

BEGIN { use_ok( 'Net::Twitter::Stream' ); }

#my $object = Net::Twitter::Stream->new ();
#isa_ok ($object, 'Net::Twitter::Stream');


