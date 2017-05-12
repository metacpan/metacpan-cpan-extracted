#!/usr/bin/perl

use strict;
use warnings;

use Net::Nmsg::IO;
use Net::WDNS qw(:func);

use Encode::Escape;

my $io = Net::Nmsg::IO->new;

sub process_dnsdedupe_msg {
  my $m = shift || return;
  print $m->headers_as_str, "\n";
  printf("rrname: %s\nrrclass: %s\nrrtype: %s\n",
         rrname_to_str($m->get_rrname),
         rrclass_to_str($m->get_rrclass),
         rrtype_to_str($m->get_rrtype));
  for my $rdata ($m->get_rdata) {
    print "rdata: ", rdata_to_str($rdata,
                                  $m->get_rrtype,
                                  $m->get_rrclass), "\n";
  }
  print "\n";
}

$io->add_input_channel('ch204');
$io->set_filter_msgtype(SIE => 'dnsdedupe');
$io->add_output_cb(\&process_dndedupe_msg);
$io->loop;
