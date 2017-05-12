#!/usr/bin/perl
#
# Copyright (C) 2011 by Mark Hindess

use warnings;
use strict;

$|=1;

my %msg;
BEGIN {
  my $tests = 2;
  my $dir = 't/msg';
  opendir my $dh, $dir or die "Open of $dir directory: $!\n";
  foreach (sort readdir $dh) {
    next if (!/^(.*)\.txt$/);
    my $name = $1;
    my $f = $dir.'/'.$_;
    open my $fh, '<', $f or die "Failed to open $f: $!\n";
    local $/ = "\n\n";
    $msg{$name} = [ <$fh> ];
    $tests += 5;
    close $fh;
  }
  closedir $dh;
  require Test::More;
  import Test::More tests => $tests;
}

BEGIN { use_ok('Net::MQTT::Constants', qw/:all/); }
use_ok('Net::MQTT::Message');

foreach my $name (sort keys %msg) {
  my ($args_str, $packet, $string) = @{$msg{$name}};
  $packet =~ s/\s+//g;
  chomp $string;
  my $args;
  eval $args_str;
  is($@, '', $name.' - args processed w/o warnings');
  my $mqtt = Net::MQTT::Message->new_from_bytes(pack 'H*', $packet);
  is($mqtt->string, $string, $name.' - packet string');
  my $hex = unpack 'H*', $mqtt->bytes;
  is($hex, $packet, $name.' - packet bytes');

  $mqtt = Net::MQTT::Message->new(%{$args});
  is($mqtt->string, $string, $name.' - args string');
  $hex = unpack 'H*', $mqtt->bytes;
  is($hex, $packet, $name.' - args bytes');
}
