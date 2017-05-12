use strict;
use warnings;

use Test::More tests => 4;
use Net::Whois::IANA;

my $iana = new Net::Whois::IANA;
my $ip = '193.0.0.135';
$iana->whois_query(-ip => $ip, -whois => 'ripe');
ok(defined $iana);
is($iana->country(), 'NL');
$ip = '194.90.1.5';
$iana->whois_query(-ip => $ip, -whois => 'ripe');
ok(defined $iana);
is($iana->country(), 'IL');
