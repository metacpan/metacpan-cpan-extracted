use strict;
use warnings;

use Test2::V0;
use Retry::Policy;

my $p = Retry::Policy->new(
    max_attempts  => 5,
    base_delay_ms => 1,
    max_delay_ms  => 2,
    jitter        => 'none',
);

my $tries = 0;

my $out = $p->run(sub {
    $tries++;
    die "fail\n" if $tries < 3;
    return "ok";
});

is($out, "ok", "eventually succeeds");
is($tries, 3,  "retried until success");

my $p2 = Retry::Policy->new(
    max_attempts  => 5,
    base_delay_ms => 1,
    max_delay_ms  => 2,
    jitter        => 'none',
    retry_on      => sub { 0 },
);

my $tries2 = 0;

like(
    dies { $p2->run(sub { $tries2++; die "nope\n"; }) },
    qr/nope/,
    "no retry when retry_on returns false",
);

is($tries2, 1, "only one attempt");

done_testing;

