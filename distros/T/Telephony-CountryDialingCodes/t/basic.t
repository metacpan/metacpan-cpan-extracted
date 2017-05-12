# $Id: basic.t,v 1.1 2007/02/23 23:46:58 cmanley Exp $
use strict;
use Test::More tests => 7;


# Test 1
use_ok('Telephony::CountryDialingCodes');


# Test 2
my $o;
eval {
	$o = Telephony::CountryDialingCodes->new();
};
ok($o, 'Create object');
if ($@) {
	BAIL_OUT("Can't complete tests if object creation failed. Error: $@");
}


# Test 3 - 6
my %pairs = (
	AS => 1,
	NL => 31,
);
foreach my $cc (keys %pairs) {
	my $dc = $pairs{$cc};
	is($o->dialing_code($cc), $dc, "Check if country code $cc has dialing code $dc");
	ok(grep("$cc", $o->country_codes($dc)), "Check if dialing code $dc belongs to country $cc");
}


# Test 7
my $phn = '+521234567890';
my $dialing_code = $o->extract_dialing_code($phn);
is($dialing_code, '52', "Extract dialing code from $phn");
