use Test::More;
use Test::Fatal;

use strict;
use warnings;

BEGIN { use_ok("Net::LDNS" => qw(load_zonefile))}

my @rrs = load_zonefile("t/example.org");
is(scalar(@rrs), 16, 'All records loaded');
is($rrs[0]->type, 'SOA', 'SOA record first');
is($rrs[-1]->type, 'A', 'A record last');
is(lc($rrs[-1]->name), 'spencer.example.org.', 'Expected name last');

done_testing();