#!/usr/bin/perl
#
# This file is part of Redis
#
# This software is Copyright (c) 2015 by Pedro Melo, Damien Krotkine.
#
# This is free software, licensed under:
#
#   The Artistic License 2.0 (GPL Compatible)
#
use warnings;
use strict;

use Redis;

my $pub = Redis->new();

my $channel = $ARGV[0] || die "usage: $0 channel\n";

print "#$channel > ";
while (<STDIN>) {
  chomp;
  $channel = $1 if s/\s*\#(\w+)\s*//;    # remove channel from message
  my $nr = $pub->publish($channel, $_);
  print "#$channel $nr> ";
}

