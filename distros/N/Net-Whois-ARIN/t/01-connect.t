
use strict;
use warnings;

use Test::More tests => 10;

use_ok 'Net::Whois::ARIN';

can_ok "Net::Whois::ARIN", "new";

my $w = Net::Whois::ARIN->new(
    -hostname=> 'whois.arin.net',
    -port    => 43,
    -timeout => 15,
    -retries => 2,
);

isa_ok $w, 'Net::Whois::ARIN';

can_ok $w, "query";
can_ok $w, "network";
can_ok $w, "asn";
can_ok $w, "contact";
can_ok $w, "domain";
can_ok $w, "customer";
can_ok $w, "organization";

exit;

