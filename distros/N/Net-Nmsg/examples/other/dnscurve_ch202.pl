#!/usr/bin/perl

use strict;
use warnings;

use Net::Nmsg::IO;

use Net::DNS::Codes qw( T_NS );
use Net::WDNS qw(:all);
use Encode::Escape;

my $io = Net::Nmsg::IO->new;

sub data_escape { encode('unicode-escape', shift) }

sub process_dnsqr_msg {
  my $m = shift || return;
  return unless $m->get_rcode == WDNS_R_NOERROR;
  my $r = parse_message($m->get_response_packet);
  return unless ($r->answer)[0]->rrtype == T_NS;
  for my $ans ($r->answer) {
    next unless $ans->name =~ /uz5/;
    # could also just print $ans->as_str
    printf("rrname: %s\nrrclass: %s\nrrtype: %s\n",
           $ans->name, $ans->rrclass, $ans->rrtype);
    for my $rd ($ans->rdata) {
      print "rdata: ", data_escape($rd->as_str), "\n";
    }
  }
}

$io->add_input_channel('ch202');
$io->set_filter_msgtype( base => 'dnsqr' );
$io->add_output_cb(\&process_dnsqr_msg);
$io->loop;
