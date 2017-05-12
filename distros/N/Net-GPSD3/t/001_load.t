# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 54;

BEGIN { use_ok( 'Net::GPSD3' ); }
BEGIN { use_ok( 'Net::GPSD3::Base' ); }
BEGIN { use_ok( 'Net::GPSD3::Cache' ); }
BEGIN { use_ok( 'Net::GPSD3::Return::DEVICE' ); }
BEGIN { use_ok( 'Net::GPSD3::Return::DEVICES' ); }
BEGIN { use_ok( 'Net::GPSD3::Return::ERROR' ); }
BEGIN { use_ok( 'Net::GPSD3::Return::Satellite' ); }
BEGIN { use_ok( 'Net::GPSD3::Return::GST' ); }
BEGIN { use_ok( 'Net::GPSD3::Return::SKY' ); }
BEGIN { use_ok( 'Net::GPSD3::Return::TPV' ); }
BEGIN { use_ok( 'Net::GPSD3::Return::Unknown' ); }
BEGIN { use_ok( 'Net::GPSD3::Return::Unknown::Timestamp' ); }
BEGIN { use_ok( 'Net::GPSD3::Return::VERSION' ); }
BEGIN { use_ok( 'Net::GPSD3::Return::WATCH' ); }

my $object;
$object = Net::GPSD3->new();
isa_ok ($object, 'Net::GPSD3');
isa_ok ($object, 'Net::GPSD3::Base');

$object = Net::GPSD3::Base->new();
isa_ok ($object, 'Net::GPSD3::Base');

$object = Net::GPSD3::Cache->new();
isa_ok ($object, 'Net::GPSD3::Cache');
isa_ok ($object, 'Net::GPSD3::Base');

$object = Net::GPSD3::Return::DEVICE->new();
isa_ok ($object, 'Net::GPSD3::Return::DEVICE');
isa_ok ($object, 'Net::GPSD3::Return::Unknown');
isa_ok ($object, 'Net::GPSD3::Base');

$object = Net::GPSD3::Return::DEVICES->new();
isa_ok ($object, 'Net::GPSD3::Return::DEVICES');
isa_ok ($object, 'Net::GPSD3::Return::Unknown');
isa_ok ($object, 'Net::GPSD3::Base');

$object = Net::GPSD3::Return::ERROR->new();
isa_ok ($object, 'Net::GPSD3::Return::ERROR');
isa_ok ($object, 'Net::GPSD3::Return::Unknown');
isa_ok ($object, 'Net::GPSD3::Base');

$object = Net::GPSD3::Return::Satellite->new();
isa_ok ($object, 'Net::GPSD3::Return::Satellite');
isa_ok ($object, 'Net::GPSD3::Return::Unknown');
isa_ok ($object, 'Net::GPSD3::Base');

$object = Net::GPSD3::Return::GST->new();
isa_ok ($object, 'Net::GPSD3::Return::GST');
isa_ok ($object, 'Net::GPSD3::Return::Unknown::Timestamp');
isa_ok ($object, 'Net::GPSD3::Return::Unknown');
isa_ok ($object, 'Net::GPSD3::Base');

$object = Net::GPSD3::Return::SKY->new();
isa_ok ($object, 'Net::GPSD3::Return::SKY');
isa_ok ($object, 'Net::GPSD3::Return::Unknown::Timestamp');
isa_ok ($object, 'Net::GPSD3::Return::Unknown');
isa_ok ($object, 'Net::GPSD3::Base');

$object = Net::GPSD3::Return::TPV->new();
isa_ok ($object, 'Net::GPSD3::Return::TPV');
isa_ok ($object, 'Net::GPSD3::Return::Unknown::Timestamp');
isa_ok ($object, 'Net::GPSD3::Return::Unknown');
isa_ok ($object, 'Net::GPSD3::Base');

$object = Net::GPSD3::Return::Unknown->new();
isa_ok ($object, 'Net::GPSD3::Return::Unknown');
isa_ok ($object, 'Net::GPSD3::Base');

$object = Net::GPSD3::Return::Unknown::Timestamp->new();
isa_ok ($object, 'Net::GPSD3::Return::Unknown::Timestamp');
isa_ok ($object, 'Net::GPSD3::Return::Unknown');
isa_ok ($object, 'Net::GPSD3::Base');

$object = Net::GPSD3::Return::VERSION->new();
isa_ok ($object, 'Net::GPSD3::Return::VERSION');
isa_ok ($object, 'Net::GPSD3::Return::Unknown');
isa_ok ($object, 'Net::GPSD3::Base');

$object = Net::GPSD3::Return::WATCH->new();
isa_ok ($object, 'Net::GPSD3::Return::WATCH');
isa_ok ($object, 'Net::GPSD3::Return::Unknown');
isa_ok ($object, 'Net::GPSD3::Base');
