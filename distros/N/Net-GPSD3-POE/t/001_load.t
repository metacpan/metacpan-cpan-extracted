# -*- perl -*-

use Test::More tests => 6;

BEGIN { use_ok( 'Net::GPSD3' ); }
BEGIN { use_ok( 'Net::GPSD3::POE' ); }

my $object;

$object = Net::GPSD3::POE->new();
isa_ok ($object, 'Net::GPSD3::POE');
isa_ok ($object, 'Net::GPSD3');
isa_ok ($object, 'Net::GPSD3::Base');

cmp_ok($Net::GPSD3::VERSION, '>=', 0.17, "Version Required");
