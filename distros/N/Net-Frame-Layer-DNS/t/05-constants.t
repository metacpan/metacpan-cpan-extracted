use Test;
BEGIN { plan(tests => 2) }

use Net::Frame::Layer::DNS::Constants qw(:consts);

for my $c (sort(keys(%constant::declared))) {
    print "$c\n"
}

ok(NF_DNS_TYPE_A,1);
ok(NF_DNS_TYPE_AAAA,28);
