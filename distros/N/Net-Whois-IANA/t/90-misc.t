use strict;
use warnings;

use Test::More tests => 9;
use Net::Whois::IANA;

my $iana = new Net::Whois::IANA;
my $ip = '193.0.0.135';
$iana->whois_query(-ip => $ip);
ok($iana->is_mine('193.0.1.1'));
ok(! $iana->is_mine('193.0.8.1'));
ok($iana->is_mine('193.0.1.1', "193.0.1.0/25"));
ok(! $iana->is_mine('193.0.1.1', "193.0.1.128/25"));
my @ips = qw(193.0.0.135 192.228.29.1 202.12.29.13 200.16.98.2 196.216.2.1);
for my $ip (@ips) {
	$iana->whois_query(-ip => $ip);
	ok($iana->is_mine($ip), "own ip $ip is theirs ($iana->{QUERY}{server})");
}
