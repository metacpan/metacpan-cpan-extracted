use strict;
use warnings;

use Test::More tests => 6;
use Net::Whois::IANA;

my $iana = new Net::Whois::IANA;
my $ip = '202.12.29.13';
$iana->whois_query(-ip=>$ip,-whois=>'apnic');
ok(defined $iana);
is($iana->country(), 'AU');
$ip = '210.157.1.190';
ok(defined $iana);
$iana->whois_query(-ip=>$ip,-whois=>'apnic');
is($iana->country(), 'JP');
$ip = '202.205.109.205';
ok(defined $iana);
$iana->whois_query(-ip=>$ip,-whois=>'apnic');
is($iana->country(), 'CN');
