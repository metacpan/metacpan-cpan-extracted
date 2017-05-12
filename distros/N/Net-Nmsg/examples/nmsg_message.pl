#!/usr/bin/perl

use strict;
use warnings;

use Net::Nmsg::Output;
use Net::Nmsg::Msg;

my $o = Net::Nmsg::Output->open('127.0.0.1/9430');

my $m = Net::Nmsg::Msg::base::ipconn->new();

for my $i (0 .. 100) {
  $m->set_srcip("127.0.0.$i");
  $m->set_dstip("127.1.0.$i");
  $m->set_srcport($i);
  $m->set_dstport(65535 - $i);
  $o->write($m);
}
