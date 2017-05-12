use Test;
BEGIN { plan(tests => 3) }

use Net::Frame::Layer::CDP::SoftwareVersion;

my $l = Net::Frame::Layer::CDP::SoftwareVersion->new;
$l->pack;
$l->unpack;

print $l->print."\n";

my $encap = $l->encapsulate;
$encap ? print "[$encap]\n" : print "[none]\n";

ok(1);

my $NO_HAVE_NetFrameSimple = 0;
eval "use Net::Frame::Simple 1.05";
if($@) {
    $NO_HAVE_NetFrameSimple = "Net::Frame::Simple 1.05 required";
}

use Net::Frame::Layer::CDP qw(:consts);

my ($cdp, $softwareVersion, $packet, $decode, $expectedOutput);

$cdp = Net::Frame::Layer::CDP->new;
$softwareVersion = Net::Frame::Layer::CDP::SoftwareVersion->new;

$expectedOutput = 'CDP: version:2  ttl:180  checksum:0x0000
CDP::SoftwareVersion: type:0x0005  length:4  softwareVersion:';

print $cdp->print . "\n";
print $softwareVersion->print . "\n";
print "\n";

ok(($cdp->print . "\n" . $softwareVersion->print) eq $expectedOutput);

skip ($NO_HAVE_NetFrameSimple,
sub {
$packet = pack "H*", "02b42f70000500fd436973636f20494f5320536f6674776172652c203337303020536f667477617265202843333732352d414456495053455256494345534b392d4d292c2056657273696f6e2031322e34283135295431342c2052454c4541534520534f4654574152452028666332290a546563686e6963616c20537570706f72743a20687474703a2f2f7777772e636973636f2e636f6d2f74656368737570706f72740a436f707972696768742028632920313938362d3230313020627920436973636f2053797374656d732c20496e632e0a436f6d70696c6564205475652031372d4175672d31302031323a30382062792070726f645f72656c5f7465616d";

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'CDP'
);

$expectedOutput = 'CDP: version:2  ttl:180  checksum:0x2f70
CDP::SoftwareVersion: type:0x0005  length:253  softwareVersion:Cisco IOS Software, 3700 Software (C3725-ADVIPSERVICESK9-M), Version 12.4(15)T14, RELEASE SOFTWARE (fc2)
Technical Support: http://www.cisco.com/techsupport
Copyright (c) 1986-2010 by Cisco Systems, Inc.
Compiled Tue 17-Aug-10 12:08 by prod_rel_team';

print $decode->print;
print "\n";

$decode->print eq $expectedOutput;
});
