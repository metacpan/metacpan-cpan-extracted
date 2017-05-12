use strict;
use warnings;

use Test::More tests => 4;
use Net::Whois::IANA;

my $iana = new Net::Whois::IANA;
my $ip = '192.149.252.43';

$iana->whois_query(-ip => $ip, -whois => 'arin');
ok(defined $iana);
is($iana->country(), 'US');
$ip = '192.228.29.1';
$iana->whois_query(-ip => $ip, -whois => 'arin');
ok(defined $iana);
is($iana->country(), 'CA');
