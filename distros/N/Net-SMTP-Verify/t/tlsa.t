#!/usr/bin/env perl

use warnings;
use strict;

use Test::More tests => 3;
use Test::Exception;
use Net::DNS::Resolver;

use_ok('Net::SMTP::Verify');
my $v = Net::SMTP::Verify->new(
  resolver => Net::DNS::Resolver->new(
    nameservers => [ '8.8.8.8' ],
    dnssec => 1, adflag => 1,
  ),
);

isa_ok( $v, 'Net::SMTP::Verify');

lives_ok {
  $v->check_tlsa('affenschaukel.bofh-noc.de', 25)
} 'check TLSA for affenschaukel.bofh-noc.de';
