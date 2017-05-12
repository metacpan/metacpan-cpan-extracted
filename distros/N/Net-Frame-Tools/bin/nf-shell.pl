#!/usr/bin/perl
#
# $Id: nf-shell.pl 349 2015-01-23 06:44:44Z gomor $
#
package Net::Frame::Shell;
use strict;
use warnings;

our $VERSION = '0.10';

my @subList = qw(
   F sr sd sd2 sd3 sniff dsniff read
);

my @layerList = qw(
   ETH RAW SLL NULL ARP IPv4 IPv6 TCP UDP VLAN ICMPv4 PPPoE PPP PPPLCP LLC CDP
   STP OSPF IGMPv4
);

use Net::Frame::Device;
use Net::Frame::Simple;
use Net::Frame::Dump::Online;
use Net::Frame::Dump::Offline;
use Net::Write::Layer2;
use Net::Write::Layer3;
use Data::Dumper;
use Term::ReadLine;

my $oDevice = Net::Frame::Device->new;
my $oDump;

{
   no strict 'refs';
   for my $l (@layerList) {
      *$l = sub {
         (my $module = "Net::Frame::Layer::$l") =~ s/::/\//g;
         require $module.'.pm';
         my $r = "Net::Frame::Layer::$l"->new(@_);
         $r->pack;
         $r;
      };
   }
}

sub F {
   my @layers = @_;
   Net::Frame::Simple->new(
      firstLayer => $layers[0]->layer,
      layers     => \@layers,
   );
}

sub sr {
   do { print "Nothing to send\n"; return } unless $_[0];

   my $oWrite = Net::Write::Layer2->new(dev => $oDevice->dev);
   $oWrite->open;
   $oWrite->send(shift());
   $oWrite->close;
}

sub sd {
   do { print "Nothing to send\n"; return } unless $_[0];

   return sd2(@_) if $_[0]->getLayer('ETH') || $_[0]->getLayer('RAW'); # XXX
   return sd3(@_) if $_[0]->l3;
}

sub sd2 {
   my ($f) = @_;

   do { print "Nothing to send\n"; return } unless $f;

   my $oWrite = Net::Write::Layer2->new(dev => $oDevice->dev);
   $oWrite->open;
   $oWrite->send($f->raw);
   $oWrite->close;
}

sub sd3 {
   my ($f) = @_;

   do { print "Nothing to send\n"; return } unless $f;

   do { print "We can only send IPv4 frames at layer 3\n"; return }
      if (! $f->getLayer('IPv4') || $f->getLayer('ETH')); # XXX, RAW, ...

   my $ip  = $f->getLayer('IPv4');
   my $dst = $ip->dst;

   my $oWrite = Net::Write::Layer3->new(dev => $oDevice->dev, dst => $dst);
   $oWrite->open;
   $oWrite->send($f->raw);
   $oWrite->close;
}

sub sniff {
   my ($filter) = @_;
   $oDump = Net::Frame::Dump::Online->new(dev => $oDevice->dev);
   $oDump->filter($filter) if $filter;
   $oDump->start;
   while (1) {
      if (my $h = $oDump->next) {
         my $f = Net::Frame::Simple->newFromDump($h);
         print $f->print."\n";
      }
   }
}

sub dsniff {
   my ($filter) = @_;
   $oDump = Net::Frame::Dump::Online->new(dev => $oDevice->dev);
   $oDump->filter($filter) if $filter;
   $oDump->start;
   while (1) {
      if (my $h = $oDump->next) {
         my $f = Net::Frame::Simple->newFromDump($h);
         my $ip = $f->getLayer('IPv4');
         next unless $ip;
         my $l;
         if (($l = $f->getLayer('UDP')) || ($l = $f->getLayer('TCP'))) {
            my $data = $l->payload;
            next unless $data =~ /^user\s+|^pass\s+/i;
            print $ip->src.':'.$ip->dst.'> '.$data."\n";
         }
      }
   }
}

sub read {
   my ($file) = @_;
   do { print "Please specify a pcap file to read\n"; return } unless $file;

   $oDump = Net::Packet::Dump::Offline->new(file => $file);
   $oDump->start;

   my $n = 0;
   while (my $h = $oDump->next) {
      ++$n;
      my $f = Net::Frame::Simple->newFromDump($h);
      my $len = length($h->{raw});
      print 'Frame number: '.$n." (length: $len)\n";
      print $f->print."\n";
   }

   $oDump->stop;
}

sub nfShell {
   my $prompt = 'nf-shell> ';
   my $name   = 'NF-Shell';
   my $term   = Term::ReadLine->new($name);
   $term->ornaments(0);

   $term->Attribs->{completion_function} = sub {
      ( @subList, @layerList )
   };

   {
      no strict;

      while (my $line = $term->readline($prompt)) {
         $line =~ s/s*read/Net::Frame::Shell::read/;
         eval($line);
         warn($@) if $@;
         print "\n";
      }
   }

   print "\n";
}

END {
   if ($oDump && $oDump->isRunning) {
      $oDump->stop;
   }
}

1;

package main;

Net::Frame::Shell::nfShell();

1;

__END__

=head1 NAME

nf-shell - Net::Frame Shell tool

=head1 SYNOPSIS

   None for now.

=head1 DESCRIPTION

This tool is in its very early stages. It tries to mimic the well-known Scapy tool.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
