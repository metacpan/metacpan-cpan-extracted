#!/usr/local/bin/perl -w
# $Id: locale_country.pl,v 1.1 2007/02/23 22:35:59 cmanley Exp $
use strict;
use blib;
use Telephony::CountryDialingCodes;

eval { require Locale::Country; };
if ($@) {
	print 'Aborted because Locale::Country is not installed.';
	exit(0);
}

my $o = Telephony::CountryDialingCodes->new();

my @countries = Locale::Country::all_country_codes();
my @missing;
foreach my $code (sort (@countries)) {
	unless(defined($o->dialing_code($code))) {
		push(@missing,"$code - " . Locale::Country::code2country($code));
	}
}
if (@missing) {
	print "The following Locale::Country countries have no associated dialing code in Telephony::CountryDialingCodes:\n\t" . join("\n\t",@missing) . "\n";
	# Don't worry, it's normal to have some such as these:
	# ax - Aland Islands
	# bv - Bouvet Island
	# cs - Serbia and Montenegro
	# fx - France, Metropolitan
	# gs - South Georgia and the South Sandwich Islands
	# hm - Heard Island and McDonald Islands
	# pn - Pitcairn
	# sj - Svalbard and Jan Mayen
	# tf - French Southern Territories
	# um - United States Minor Outlying Islands
}
else {
	print "All Locale::Country countries have a dialing code in Telephony::CountryDialingCodes.\n";
}
