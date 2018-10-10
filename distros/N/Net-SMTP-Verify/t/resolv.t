#!/usr/bin/env perl

use warnings;
use strict;

use Test::More tests => 3;

use_ok('Net::SMTP::Verify');
my $v = Net::SMTP::Verify->new;

isa_ok( $v, 'Net::SMTP::Verify');

SKIP: {
  skip "skipping remote tests. (set INTERNET_TESTING=1)", 1 unless $ENV{'INTERNET_TESTING'};

  cmp_ok( $v->resolve('markusbenning.de'), 'eq', 'sternschnuppe.bofh-noc.de', 'lookup markusbenning.de' );
}
