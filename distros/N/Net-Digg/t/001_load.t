# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Net::Digg' ); }

my $object = Net::Digg->new ();
isa_ok ($object, 'Net::Digg');


