#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use Fetch ();
use Reverse::Proxy;

# The ABI compatibility RULE, which is the thing that broke.
#
# Reverse::Proxy 0.04 accepted the Fetch ABI only when the provider's
# abi_version was EQUAL to the version it had been built against. Fetch 0.14
# shipped ABI 2 - one member, appended - and every 0.04 installation refused
# to load, on every platform, with a message telling people to upgrade a Fetch
# that was already newer than required. Seven CPAN Testers reports, from
# 5.18.4 on Solaris to 5.45.1 on Linux, all identical.
#
# The table is append-only by rule, so a field this build knows about keeps
# its offset in every later version. That is what the version field is FOR: a
# consumer states its floor, and anything at or above it works.

my $want = Reverse::Proxy::_abi_want();
my $seen = Reverse::Proxy::_abi_seen();

cmp_ok($want, '>', 0, 'this build names the ABI version it was built against');
cmp_ok($seen, '>', 0,
    "the installed Fetch $Fetch::VERSION provides a C ABI (version $seen)");

ok(Reverse::Proxy::_abi_ok(),
    'and it is accepted - a NEWER provider must load, not be refused, or '
  . 'every release of Fetch becomes a breaking change for every consumer');

cmp_ok($seen, '>=', $want,
    'the provider is at or above the floor this build needs');

# The floor still means something: an OLDER provider genuinely lacks the
# fields, so it must still be refused. This asserts the direction of the
# comparison rather than that it was simply removed - a check of `1` would
# satisfy everything above and be just as broken the other way.
{
    my $ok_newer = ($seen + 5) >= $want;
    my $ok_older = ($want - 1) >= $want;
    ok($ok_newer, 'a provider newer than the floor is acceptable');
    ok(!$ok_older, 'a provider older than the floor is not');
}

note "built against ABI $want; Fetch $Fetch::VERSION provides ABI $seen";

done_testing;
