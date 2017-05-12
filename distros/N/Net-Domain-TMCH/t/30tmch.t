#!/usr/bin/env perl
# Create an template
use warnings;
use strict;

use lib 'lib', '../WSSSIG/lib', '../XMLWSS/lib';
use Test::More tests => 3;

my $testfile = "t/20ok.smd";

use Net::Domain::TMCH ();

my $tmch = Net::Domain::TMCH->new
  ( is_pilot => 1
  , cert_revocations => 't/tmch_pilot.crl'
  );
 
ok(defined $tmch, 'instantiate tmch object');
isa_ok($tmch, 'Net::Domain::TMCH');

my $smd = $tmch->smd
  ( $testfile
  , accept_expired => 1    # will taken 10 more years, but to never know
                           # how long this code lives.
  );
isa_ok($smd, 'Net::Domain::SMD::File');
