#!/usr/bin/perl

use strict;
use warnings;

use Net::Nmsg::IO;

my $io = Net::Nmsg::IO->new;

sub process_chaff {
  print shift->headers_as_str, "\n";
}

$io->set_filter_group('dns_parse_failure');
$io->add_input_sock('127.0.0.1', 9430);
$io->add_output_cb(\&process_chaff);
$io->loop;
