#!/usr/bin/perl
#
# $Id: inject.pl 24 2010-09-25 08:44:02Z gomor $
#
use strict;
use warnings;

my $interface = 'wlan1';
my $driver    = 'mac80211';

use Net::Lorcon2 qw(:subs);

my $lorcon = Net::Lorcon2->new(
   interface => $interface,
   driver    => $driver,
);

$lorcon->setInjectMode;

# Beacon
my $packet = "\x80\x00\x00\x00\xff\xff\xff\xff\xff\xff\x00\x02\x02\xe2\xc4\xef\x00\x02\x02\xe2\xc4\xef\xd0\xfe\x37\xe0\xae\x0c\x00\x00\x00\x00\x64\x00\x21\x08\x00\x0b\x4e\x65\x74\x3a\x3a\x4c\x6f\x72\x63\x6f\x6e\x01\x08\x82\x84\x8b\x96\x0c\x12\x18\x24\x03\x01\x0d\x05\x04\x00\x01\x00\x00\x2a\x01\x00\x32\x04\x30\x48\x60\x6c";

while (1) {
   my $t = $lorcon->sendBytes($packet);
   if (! $t) {
      print "[-] Unable to send bytes\n";
      exit 1;
   }
   print "T: $t\n";
   sleep(1);
}
