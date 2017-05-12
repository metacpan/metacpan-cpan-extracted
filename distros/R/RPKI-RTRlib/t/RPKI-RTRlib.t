
use strict;
use warnings;

use Test::More tests => 13;
BEGIN { use_ok('RPKI::RTRlib') };


my $conf = RPKI::RTRlib::start("195.13.63.18","8282");

# test validate()
my $result = RPKI::RTRlib::validate($conf,"12654","93.175.146.0","24");#Valid
ok($result == 0, 'validate() - Valid');
$result = RPKI::RTRlib::validate($conf,"12654","93.175.147.0","24");#Invalid AS
ok($result == 2, 'validate() - Invalid AS');
$result = RPKI::RTRlib::validate($conf,"196615","93.175.147.0","25");#Invalid length
ok($result == 2, 'validate() - Invalid length');
$result = RPKI::RTRlib::validate($conf,"12654","2001:7fb:ff03::","48");#NotFound
ok($result == 1, 'validate() - NotFound');



# test validate_r()
$result = RPKI::RTRlib::validate_r($conf,"12654","93.175.146.0","24");#Valid
ok($result->{state} == 0, 'validate_r() - Valid');
ok(equalsROA($result->{roas}->[0],"12654","93.175.146.0","24","24"), 'validate_r() - Valid');

$result = RPKI::RTRlib::validate_r($conf,"12654","93.175.147.0","24");#Invalid AS
ok($result->{state} == 2, 'validate_r() - Invalid AS');
ok(equalsROA($result->{roas}->[0],"196615","93.175.147.0","24","24"), 'validate_r() - Invalid AS');

$result = RPKI::RTRlib::validate_r($conf,"196615","93.175.147.0","25");#Invalid length
ok($result->{state} == 2, 'validate_r() - Invalid length');
ok(equalsROA($result->{roas}->[0],"196615","93.175.147.0","24","24"), 'validate_r() - Invalid length');

$result = RPKI::RTRlib::validate_r($conf,"12654","2001:7fb:ff03::","48");#NotFound
ok($result->{state} == 1, 'validate_r() - NotFound');
ok(scalar(@{$result->{roas}}) == 0, 'validate_r() - NotFound');

RPKI::RTRlib::stop($conf);


sub equalsROA{
	my $roa = shift(@_);
	my $asn = shift(@_);
	my $prefix = shift(@_);
	my $min = shift(@_);
	my $max = shift(@_);
	
	return ($roa->{asn} eq $asn &&
		$roa->{prefix} eq $prefix &&
		$roa->{min} eq $min &&
		$roa->{max} eq $max);
}


