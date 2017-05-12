# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-DNS-ZoneParse.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 8;
BEGIN {
	use_ok('Net::DNS::ZoneParse');
	use_ok('Net::DNS::ZoneParse::Zone');
	use_ok('Net::DNS::ZoneParse::Parser::Native');
	SKIP: {
		eval { require Net::DNS::Zone::Parser; };
		skip "Net::DNS::Zone::Parser isn't installed", 1 if $@;
		use_ok('Net::DNS::ZoneParse::Parser::NetDNSZoneParser');
	}
	SKIP: {
		eval { require Net::DNS::ZoneFile::Fast; };
		skip "Net::DNS::ZoneFile::Fast isn't installed", 1 if $@;
		use_ok('Net::DNS::ZoneParse::Parser::NetDNSZoneFileFast');
	}
	SKIP: {
		eval { require DNS::ZoneParse; };
		skip "DNS::ZoneParse isn't installed", 2 if($@);
		use_ok('Net::DNS::ZoneParse::Parser::DNSZoneParse');
		use_ok('Net::DNS::ZoneParse::Generator::DNSZoneParse');
	}
	use_ok('Net::DNS::ZoneParse::Generator::Native');
};

#########################
