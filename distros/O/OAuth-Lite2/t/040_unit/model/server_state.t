use strict;
use warnings;

use Test::More;

use lib 't/lib';

use TestServerState;

my $state1 = TestServerState->new(
    client_id    => q{cid_str},
    server_state => q{ss_str},
    expires_in   => 900,
    extra        => q{ext},
);

is($state1->client_id, q{cid_str});
is($state1->server_state, q{ss_str});
is($state1->expires_in, 900);
is($state1->extra, q{ext});

done_testing
