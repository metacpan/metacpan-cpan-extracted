#!/usr/bin/perl
#
# $Id: nf-cat.pl 349 2015-01-23 06:44:44Z gomor $
#
use strict;
use warnings;

our $VERSION = '1.00';

use Getopt::Std;
my %opts;
getopts('R234i:d:rL:v', \%opts);

my $oDump;
my $oWrite;

die("Usage: $0 [parameters]\n".
    "\n".
    " o Choose either one of these parameters:\n".
    "   -2  send at layer 2\n".
    "   -3  send at layer 3\n".
    "   -4  send at layer 4\n".
    "\n".
    " o Layer 2 specific parameters:\n".
    "   -i  network interface to use\n".
    "\n".
    " o Layer 3 and layer 4 specific parameters:\n".
    "   -d  target destination IP address\n".
    "\n".
    " o Common parameters:\n".
    "   -R  send as a raw string\n".
    "   -r  get and print frame reply\n".
    "   -L  first layer contained in raw data (example: IPv4)\n".
    "   -v  be more verbose\n".
    ""
   ) unless ($opts{2} || $opts{3} || $opts{4});

use Net::Frame::Simple;
use Net::Frame::Dump::Online;
use Net::Frame::Device;

my $oDevice = Net::Frame::Device->new;

my $data;
while (<>) {
   chomp;
   $data = $_;
}

# Try to guess first layer when -3 used
my $firstLayer = $opts{L};
if (! $opts{R} && $opts{3} && ! $firstLayer) {
   if ($data =~ /^4/) {
      $firstLayer = 'IPv4';
   }
   else {
      die("Unable to guess first layer type, you should specify -L\n");
   }
}

# If -2 used, and firstLayer not specified, and no -R, we don't know
if (! $opts{R} && $opts{2} && ! $firstLayer) {
   die("Unable to guess first layer type, you should specify -L\n");
}

# Reassemble frame
my $oSimple;
if (! $opts{R}) {
   $oSimple = Net::Frame::Simple->new(
      raw        => pack('H*', $data),
      firstLayer => $firstLayer,
   );
}

if ($oSimple && $opts{v}) {
   print $oSimple->print."\n";
}

# Try to guess destination
my $dst = $opts{d};
if (! $opts{2} && $oSimple) {
   if (! $dst) {
      if (my $l = $oSimple->ref->{IPv4}) {
         $dst = $l->dst;
      }
      else {
         die("Unable to guess destination IP address, you should specify -d\n");
      }
   }
}

# Try to guess network interface
my $int = $opts{i};
if (! $int) {
   if ($dst) {
      $oDevice->updateFromTarget($dst);
      $int = $oDevice->dev;
   }
   else {
      die("Unable to guess network interface, you should specify -i\n");
   }
}

if ($opts{2}) {
   use Net::Write::Layer2;
   $oWrite = Net::Write::Layer2->new(dev => $int);
}
elsif ($opts{3}) {
   use Net::Write::Layer3;
   $oWrite = Net::Write::Layer3->new(dst => $dst);
}
elsif ($opts{4}) {
   use Net::Write::Layer4;
   $oWrite = Net::Write::Layer4->new(dst => $dst);
}

if ($opts{r}) {
   $oDump = Net::Frame::Dump::Online->new(dev => $int);
   $oDump->start;
}

$oWrite->open;
$oWrite->send(pack('H*', $data));
$oWrite->close;

if ($opts{r} && $oSimple) {
   until ($oDump->timeout) {
      if (my $reply = $oSimple->recv($oDump)) {
         print $reply->print."\n";
         last;
      }
   }
}

END {
   $oWrite && $oWrite->close;
   $oDump  && $oDump->isRunning && $oDump->stop;
}

__END__

=head1 NAME

nf-cat - Net::Frame Cat tool

=head1 SYNOPSIS

   # printf "AAAAAAAAAAA" |nf-cat.pl -i eth0 -2R

   # printf "ffffffffffff00000000000088641100000100000021" | \
        nf-cat.pl -i eth0 -2L ETH -v
   ETH: dst:ff:ff:ff:ff:ff:ff  src:00:00:00:00:00:00  type:0x8864
   PPPoES: version:1  type:1  code:0x00  sessionId:0x0001
   PPPoES: payloadLength:0  pppProtocol:0x0021

=head1 DESCRIPTION

This tool is like well-known netcat, but works at various layers. For example, you may send a raw string at layer 2, like in the first example B<SYNOPSIS>.

You may also send fully crafted frames, like in the second example, where we inject an Ethernet frame which encapsulate a PPPoES layer.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
