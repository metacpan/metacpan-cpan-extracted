#!/usr/local/bin/perl -w
# $Id: geography_countries.pl,v 1.1 2007/02/23 22:35:59 cmanley Exp $
use strict;
use blib;
use Telephony::CountryDialingCodes;

eval { require Geography::Countries; };
if ($@) {
	print 'Aborted because Geography::Countries is not installed.';
	exit(0);
}

my $o = Telephony::CountryDialingCodes->new();

my @countries = Geography::Countries::code2();
my @missing;
foreach my $code (sort (@countries)) {
	unless(defined($o->dialing_code($code))) {
		push(@missing,"$code - " . Geography::Countries::country($code));
	}
}
if (@missing) {
	print "The following Geography::Countries countries have no associated dialing code in Telephony::CountryDialingCodes:\n\t" . join("\n\t",@missing) . "\n";
	# Don't worry, it's normal to have some such as these:
	# BV - Bouvet Island
	# GS - South Georgia And The South Sandwich Islands
	# HM - Heard Island And Mcdonald Islands
	# PN - Pitcairn
	# SJ - Svalbard and Jan Mayen Islands
	# TF - French Southern Territories
	# TP - East Timor
	# UM - United States Minor Outlying Islands
	# YU - Yugoslavia
}
else {
	print "All Locale::Country countries have a dialing code in Telephony::CountryDialingCodes.\n";
}
