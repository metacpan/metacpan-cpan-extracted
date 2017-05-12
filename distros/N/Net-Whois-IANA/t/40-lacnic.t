use strict;
use warnings;

use Test::More tests => 6;
use Net::Whois::IANA;

my $iana = new Net::Whois::IANA;
my $ip = '200.16.98.2';
$iana->whois_query(-ip=>$ip,-whois=>'lacnic');
ok(defined $iana);
is($iana->country(), 'AR');
$ip = '200.77.236.16';
$iana->whois_query(-ip=>$ip,-whois=>'lacnic');
ok(defined $iana);
is($iana->country(), 'MX');
$ip = '200.189.169.141';
$iana->whois_query(-ip=>$ip,-whois=>'lacnic');
ok(defined $iana);
is($iana->country(), 'BR');
