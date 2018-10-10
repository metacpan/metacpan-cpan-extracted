#!/usr/bin/env perl

use warnings;
use strict;

use Test::More;
use Test::Exception;
use Net::DNS::Resolver;

unless($ENV{'INTERNET_TESTING'}) {
  plan skip_all => 'No remote tests. (to enable set INTERNET_TESTING=1)';
}

plan tests => 3;

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
