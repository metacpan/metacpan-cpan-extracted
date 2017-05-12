#!/usr/bin/perl
use Number::Phone::DE::Mobile qw(checkmsisdn);

print "\n\n------------------------------------\nStart testing different MSISDNs:\n";
@testmsisdns = (	"00491791234567",
					"491791234567",
					"001791234567",
					"01791234567",
					"1791234567",
					"004917912345678",
					"4917912345678",
					"0017912345678",
					"017912345678",
					"17912345678",
					"invalid_msisdn_check" );

foreach $msisdn (@testmsisdns) {
	$newmsisdn = Number::Phone::DE::Mobile->checkmsisdn($msisdn);
	print "OLD: $msisdn\nNEW: $newmsisdn\n\n";
}
print <<EOM;
OLD = original MSISDN
NEW = should be the same MSISDN in xxyyyzzzzzzz format.


EOM
exit;
