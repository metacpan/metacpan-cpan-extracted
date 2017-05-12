#!/usr/bin/perl
use strict;
use warnings;

my $target = shift || die("Specify target\n");
my $dev    = shift;

use Net::Frame::Layer qw(:subs);

$target = getHostIpv6Addr($target) or die("lookup\n");

use Net::Frame::Device;

my $d;
if ($dev) {
   $d = Net::Frame::Device->new(
      dev     => $dev,
      target6 => $target,
   );
}
else {
   $d = Net::Frame::Device->new(target6 => $target);
}

print $d->cgDumper."\n";
