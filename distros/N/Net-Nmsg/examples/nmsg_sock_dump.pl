#!/usr/bin/perl

use strict;
use warnings;

use Net::Nmsg::Input;

@ARGV || die "socket spec required";

my $i = Net::Nmsg::Input->open_sock(@ARGV);

while (my $msg = <$i>) {
  print $msg->as_str, "\n\n";
}
