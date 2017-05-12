#!/usr/local/bin/perl

use strict;
use MobilePhone::MCC;

my $mcc = new MobilePhone::MCC('jp');
print "----------------------$/";
print "\$\@ = " . $@ . $/;
print "mcc = ". $mcc . $/;
print "country = ". $mcc->country . $/;
print "country_name = ". $mcc->country_name . $/;
print "\$\@ = ". $@ . $/;
print "----------------------$/";
#print $mcc;
#my $mcc = new Mobile::Network::Code::MCC();
#print join $/, $mcc->country('gb'),"$mcc", $mcc->mcc;

