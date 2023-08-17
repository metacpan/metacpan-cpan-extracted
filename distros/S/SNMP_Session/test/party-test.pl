#!/usr/local/bin/perl
######################################################################
# Check that we can read the CMU SNMPv2 party definition file in
# /etc/party.conf.  Describe the party named "zeusmd5".  This is
# basically intended as a regression test for the party-parsing code.
######################################################################

require 5;

require 'Party.pm';

Party::read_cmu_party_database('/etc/party.conf');
Party->find ('zeusmsmd5')->describe (STDERR);

1;
