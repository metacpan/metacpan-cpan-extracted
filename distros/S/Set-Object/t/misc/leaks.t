#!/usr/bin/perl -w

use Test::More tests => 9;

BEGIN{ use_ok Set::Object;
       Set::Object->import("set");
   }

use strict;
use Scalar::Util qw(weaken);

# first, a series of sanity checks...
my $internal;
{
    my $set = set();
    is($internal, undef, "no flat yet");

    $set->insert({ "hi" => "there" });
    $internal = $set->get_flat;
    is($internal, undef, "still no flat");

    $set->insert(1, 2, 3, 4);
    $internal = $set->get_flat;
    isnt($internal, undef, "aha, got something now");
    ok(exists($internal->{2}), "and it looks like the right one");

    weaken($internal);
    ok($internal, "didn't drop out of existence on weaken()");

    ok(!exists($internal->{5}), "sanity check");
    $set->insert(5);
    ok(exists($internal->{5}), "we've really got the right hash");
}

# when the set drops out of existence, the hashref should too
is($internal, undef, "internal hashref drops out of existence");

