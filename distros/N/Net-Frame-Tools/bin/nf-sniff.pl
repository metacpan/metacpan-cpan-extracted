#!/usr/bin/perl
#
# $Id: nf-sniff.pl 349 2015-01-23 06:44:44Z gomor $
#
use strict;
use warnings;

our $VERSION = '1.00';

use Getopt::Std;
my %opts;
getopts('F:i:w:', \%opts);

my $oDump;

die("Usage: $0\n".
    "\n".
    "   -i  network interface to sniff on\n".
    "   -F  pcap filter to use\n".
    "   -w  write to file\n".
    "") unless $opts{i};

use Net::Frame::Dump::Online;
use Net::Frame::Simple;

$oDump = Net::Frame::Dump::Online->new(
   dev    => $opts{i},
   onRecv => \&callback,
);
$oDump->filter($opts{F}) if $opts{F};
if ($opts{w}) {
   $oDump->file($opts{w});
   $oDump->unlinkOnStop(0);
}

$oDump->start;

our $count = 0;

sub callback {
   my ($h, $data) = @_;
   my $f   = Net::Frame::Simple->newFromDump($h);
   my $len = length($h->{raw});
   my $ts  = $h->{timestamp};
   print 'o Frame number: '.$count++." (length: $len, timestamp: $ts)\n";
   print $f->print."\n";
}

END { $oDump && $oDump->isRunning && $oDump->stop }

__END__

=head1 NAME

nf-sniff - Net::Frame Sniff tool

=head1 SYNOPSIS

   # nf-sniff.pl -i eth0 -F icmp
   o Frame number: 0 (length: 98, timestamp: 1175507038.523095)
   ETH: dst:00:13:d4:aa:bb:cc  src:00:13:a9:aa:bb:cc  type:0x0800
   IPv4: version:4  hlen:5  tos:0x00  length:84  id:0
   IPv4: flags:0x02  offset:0  ttl:64  protocol:0x01  checksum:0xaaaa
   IPv4: src:192.168.0.101  dst:192.168.0.69
   ICMPv4: type:8  code:0  checksum:0xaaaa
   ICMPv4::Echo: identifier:27709  sequenceNumber:1
   ICMPv4: payload:5ed010464cfb070008090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f3031323334353637
   o Frame number: 1 (length: 98, timestamp: 1175507038.523232)
   ETH: dst:00:13:a9:aa:bb:cc  src:00:13:d4:aa:bb:cc  type:0x0800
   IPv4: version:4  hlen:5  tos:0x00  length:84  id:49396
   IPv4: flags:0x00  offset:0  ttl:64  protocol:0x01  checksum:0xbbbb
   IPv4: src:192.168.0.69  dst:192.168.0.101
   ICMPv4: type:0  code:0  checksum:0xbbbb
   ICMPv4::Echo: identifier:27709  sequenceNumber:1
   ICMPv4: payload:5ed010464cfb070008090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f3031323334353637

=head1 DESCRIPTION

This tool implements a wireshark/ethereal like program. It is able to decode all layers that Net::Frame supports at the time of writing. It listen on a specified network interface and tries to understand frames, then to print them.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
