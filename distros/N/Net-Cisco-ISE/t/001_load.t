# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Net::Cisco::ISE' ); }

my $object = Net::Cisco::ISE->new (hostname=>"1.1.1.1", username=>"test", password=>"test");
isa_ok ($object, 'Net::Cisco::ISE');


