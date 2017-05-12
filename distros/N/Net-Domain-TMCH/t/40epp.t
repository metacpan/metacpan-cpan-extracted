#!/usr/bin/env perl
# Create an template
use warnings;
use strict;

use lib 'lib', '../WSSSIG/lib', '../XMLWSS/lib';
use Test::More tests => 5;

my $testfile = "t/40epp.xml";

use Net::Domain::TMCH ();
use Net::Domain::SMD  qw(SMD10_NS);
use XML::LibXML       ();

my $tmch = Net::Domain::TMCH->new
  ( is_pilot => 1
  , cert_revocations => 't/tmch_pilot.crl'
  );
 
ok(defined $tmch, 'instantiate tmch object');
isa_ok($tmch, 'Net::Domain::TMCH');

my $epp = XML::LibXML->load_xml(location => $testfile);
isa_ok($epp, 'XML::LibXML::Document');

my ($mark) = $epp->documentElement->getElementsByLocalName('signedMark');
isa_ok($mark, 'XML::LibXML::Element');

#warn $mark->toString(1);

# The example input, taken from the rfc, is not byte-by-byte correct
# enough to make the digest work.
eval {
  my $smd = $tmch->smd
    ( $mark
    , accept_expired => 1    # will taken 10 more years, but to never know
                             # how long this code lives.
    );
};
is "$@", "error: digest info of smd1 is wrong\n", "error in example";
