#!/usr/bin/perl

use strict;
use warnings;

use Net::Nmsg::IO;

my $count = 0;

sub cb {
  my $msg = shift;
  ++$count;
  print STDERR '.' unless $count % 10000;
}

@ARGV || die "inputs required";

my $io = Net::Nmsg::IO->new;
$io->add_input($_) for @ARGV;
$io->add_output_cb(\&cb);
$io->loop;

print "\ncount=$count\n";
