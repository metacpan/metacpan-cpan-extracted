# -*- perl -*-

use Test::More tests => 24;

BEGIN { use_ok( 'Net::GPSD3' ); }

my $string='{
  "class":"POLL",
  "timestamp":"2011-03-20T04:12:25.64Z",
  "active":1,
  "fixes":[
    {
      "class":"TPV",
      "tag":"0x0130",
      "device":"/dev/cuaU0",
      "time":"2011-03-20T04:12:25.00Z",
      "ept":0.005,
      "lat":37.371425314,
      "lon":-122.015172578,
      "alt":25.817,
      "epx":2.436,
      "epy":2.863,
      "epv":11.040,
      "track":0.0000,
      "speed":0.000,
      "climb":0.000,
      "eps":5.73,
      "mode":3
    }
  ],
  "gst":[{
      "class":"GST","tag":"0x0130","device":"/dev/cuaU0","time":"1970-01-01T00:00:00.00Z",
      "rms":0.000,"major":0.000,"minor":0.000,"orient":0.000,"lat":0.000,"lon":0.000,"alt":0.000
  }],
  "skyviews":[
    {
      "class":"SKY",
      "tag":"0x0130",
      "device":"/dev/cuaU0",
      "xdop":0.65,
      "ydop":0.76,
      "vdop":1.30,
      "tdop":0.80,
      "hdop":1.00,
      "gdop":1.83,
      "pdop":1.64,
      "satellites":[
        {"PRN":28,"el":59,"az":248,"ss":24,"used":true},
        {"PRN":13,"el":32,"az":150,"ss":30,"used":true},
        {"PRN":7,"el":60,"az":59,"ss":28,"used":true},
        {"PRN":10,"el":19,"az":227,"ss":22,"used":false},
        {"PRN":19,"el":29,"az":57,"ss":22,"used":true},
        {"PRN":5,"el":21,"az":276,"ss":36,"used":true},
        {"PRN":3,"el":6,"az":38,"ss":15,"used":false},
        {"PRN":8,"el":62,"az":342,"ss":30,"used":true},
        {"PRN":26,"el":22,"az":318,"ss":31,"used":false},
        {"PRN":11,"el":10,"az":114,"ss":21,"used":false},
        {"PRN":138,"el":44,"az":157,"ss":41,"used":true},
        {"PRN":17,"el":10,"az":187,"ss":29,"used":false}
      ]}]}';

my $gpsd=Net::GPSD3->new;
isa_ok ($gpsd, 'Net::GPSD3');

my $object=$gpsd->constructor($gpsd->decode($string), string=>$string);
isa_ok ($object, 'Net::GPSD3::Return::POLL');
isa_ok ($object->parent, 'Net::GPSD3');
is($object->string, $string, 'string');

is($object->class, 'POLL', 'class');
is($object->active, "1", "active");
is($object->time, "1300594345.64", "time");
is($object->timestamp, "2011-03-20T04:12:25.64Z", "timestamp");

isa_ok($object->_skyviews, "ARRAY", "skyviews");
is(scalar(@{$object->_skyviews}), 1, "sizeof");
isa_ok($object->_skyviews->[0], "HASH");

isa_ok($object->_fixes, "ARRAY", "fixes");
is(scalar(@{$object->_fixes}), 1, "sizeof");
isa_ok($object->_fixes->[0], "HASH");

isa_ok($object->Skyviews, "ARRAY", "Skyviews");
is(scalar(@{$object->Skyviews}), 1, "sizeof");
isa_ok($object->Skyviews->[0], "Net::GPSD3::Return::SKY");
isa_ok($object->Skyviews->[0]->Satellites, "ARRAY");

isa_ok($object->Fixes, "ARRAY", "Fixes");
is(scalar(@{$object->Fixes}), 1, "sizeof");
isa_ok($object->Fixes->[0], "Net::GPSD3::Return::TPV");

isa_ok($object->sky, "Net::GPSD3::Return::SKY");
isa_ok($object->fix, "Net::GPSD3::Return::TPV");

