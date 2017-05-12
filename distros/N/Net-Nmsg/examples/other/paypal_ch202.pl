#!/usr/bin/perl

use strict;
use warnings;

use Net::Nmsg::IO;
use Net::WDNS qw(:func);

use Encode::Escape;

my $io = Net::Nmsg::IO->new;

sub data_escape { encode('unicode-escape', shift) }

sub process_dnsqr_msg {
  my $m = shift || return;
  my $msg = parse_message($m->get_response_packet);
  my $ans = ($msg->answer)[0];
  if ($ans->name =~ /paypal/) {
    # or could just print "$ans\n\n";
    printf("rrname: %s\nrrclass: %s\nrrtype: %s\n",
           $ans->name, $ans->rrclass, $ans->rrtype);
    for my $rdata ($ans->rdata) {
      print "rdata: ", data_escape($rdata), "\n";
    }
    print "\n";
  }
}

$io->add_input_channel('ch202');
$io->set_filter_msgtype( base => 'dnsqr' );
$io->add_output_cb(\&process_dnsqr_msg);
$io->loop;
