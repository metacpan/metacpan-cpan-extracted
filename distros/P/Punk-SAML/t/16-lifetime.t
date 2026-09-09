#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;

BEGIN {
    eval { require File::Raw::XML; require Crypt::JWS; 1 }
        or plan skip_all => "File::Raw::XML and Crypt::JWS are required ($@)";
}

# Every verification parses one frx_doc and must free it on EVERY exit,
# including the ones that leave through a croak from the middle of the
# checks. There are a dozen of those and they were written one at a time,
# which is exactly the shape of code that grows an early return without a
# free.
#
# Two gates, because one leak is two different things - the same split
# File::Raw::XML's own t/15-leak.t makes, for the same reason.
#
# Test::LeakTrace counts SVs the interpreter still holds after a block: a
# mortal that was never mortalised, an error object returned +1 twice, the
# identity hash built and dropped. It sees the seam and none of the C.
#
# THE DOCUMENT IS INVISIBLE TO IT. An frx_doc is an arena behind an IV, so
# one leaked by a refusal that returns before its SAVEDESTRUCTOR_X frees no
# SV and passes no_leaks_ok every time. That shows only as resident size,
# which is the second gate.
#
# Neither is a proof - ASan in phase 11 is the proof - but this is the pair
# that goes red in CI on the day somebody adds an early return to
# psaml_response.h.

# At compile time: no_leaks_ok is prototyped (&;$), and imported at runtime
# the `{` opening its block parses as an anonymous hash instead. A family
# memory, and it costs a whole file when it bites.
our $HAVE_LT;
BEGIN { $HAVE_LT = eval { require Test::LeakTrace; Test::LeakTrace->import; 1 } ? 1 : 0 }

use Punk::SAML ();
use Punk::SAML::Response ();
use FakeIdP ();

my $HAVE_PT = eval {
    require Proc::ProcessTable;
    my $t = Proc::ProcessTable->new(enable_ttys => 0);
    grep { $_ eq 'rss' } $t->fields or die "no rss field\n";
    1;
};
my $PT = $HAVE_PT ? Proc::ProcessTable->new(enable_ttys => 0) : undef;

sub _rss_raw {
    return undef unless $PT;
    for my $p (@{ $PT->table }) { return $p->rss if $p->pid == $$ }
    return undef;
}

# The unit is MEASURED, not assumed: Proc::ProcessTable's rss is bytes on
# some platforms and KiB on others and documents neither. Assuming wrong
# scales every threshold by 1024 and the gate still says PASS.
my $RSS_IS_KIB = 1;
if ($PT) {
    my $before = _rss_raw() // 0;
    my $blob   = 'x' x (32 * 1024 * 1024);
    substr($blob, 0, 1) = 'y';
    my $moved  = (_rss_raw() // 0) - $before;
    $RSS_IS_KIB = $moved > 4 * 1024 * 1024 ? 0 : 1;
}
sub rss_kb {
    my $r = _rss_raw();
    return undef unless defined $r;
    return $RSS_IS_KIB ? $r : int($r / 1024);
}

# ---- the fixtures, one per exit path ----------------------------------

my $idp = FakeIdP->new;
my %base = (
    idp            => 'okta',
    entity_id      => $idp->sp_entity,
    idp_entity_id  => $idp->entity_id,
    acs_url        => $idp->acs,
    certs          => $idp->certs,
    in_response_to => '_flow1',
);

my $GOOD = $idp->sign($idp->response, '_assertion1');

# Each of these leaves the verifier at a different point, and the point is
# the coverage: a document freed correctly on the happy path and leaked on
# the fourth refusal is exactly the bug this file is for.
my %REFUSAL = (
    xml_parse      => 'not xml at all<<<',
    xml_shape      => '<foo/>',
    no_signature   => scalar $idp->response,
    unknown_issuer => $idp->sign($idp->response(issuer => 'https://elsewhere/'),
                                 '_assertion1'),
    bad_digest     => do { (my $x = $GOOD) =~ s/jo\@example\.com/admin\@x.com/; $x },
    bad_signature  => $idp->sign($idp->response, '_assertion1',
                                 ref_uri => '#_response1'),
    alg_refused    => $idp->sign($idp->response, '_assertion1',
                          sig_alg => 'http://www.w3.org/2000/09/xmldsig#rsa-sha1'),
);

sub verify_good { return scalar eval { Punk::SAML::Response->verify($GOOD, %base) } }
sub refuse {
    my ($xml) = @_;
    local $@;
    eval { Punk::SAML::Response->verify($xml, %base) };
    return $@;
}

# the fixtures are asserted to fail the way they are named, so a typo does
# not quietly turn six exit paths into six copies of the same one
ok verify_good(), 'the control verifies' or diag $@;
for my $code (sort keys %REFUSAL) {
    my $e = refuse($REFUSAL{$code});
    is +(ref $e ? $e->{code} : ''), $code,
        "the $code fixture really does leave through $code";
}

# ---- the SV gate ------------------------------------------------------

SKIP: {
    skip 'Test::LeakTrace is not installed; the SV seam is not gated',
        1 + scalar(keys %REFUSAL) unless $HAVE_LT;

    # the first pass through any of these interns strings and fills
    # caches, and that one-time allocation is not a leak
    for (1 .. 3) {
        verify_good();
        refuse($_) for values %REFUSAL;
    }

    no_leaks_ok { verify_good() } 'a successful verification leaks no SV';

    for my $code (sort keys %REFUSAL) {
        my $xml = $REFUSAL{$code};
        no_leaks_ok { eval { Punk::SAML::Response->verify($xml, %base) }; 1 }
            "the $code refusal leaks no SV";
    }
}

# ---- the document gate ------------------------------------------------
#
# The counts are deliberately uneven. A full verification is two RSA
# operations and runs at a few thousand a second, so a hundred thousand of
# them would be a test nobody waits for; the refusals that stop before the
# cryptography are cheap and get the volume. A document leaked once per
# refusal at this size shows well inside these numbers.

SKIP: {
    skip 'Proc::ProcessTable is not installed; the document is not gated', 2
        unless $HAVE_PT;
    skip 'Proc::ProcessTable lists no row for this process', 2
        unless defined rss_kb();

    my @xml = values %REFUSAL;

    # warm every allocator first, so what is measured is steady state
    for (1 .. 2_000) { refuse($_) for @xml }
    my $before = rss_kb();
    for (1 .. 20_000) { refuse($_) for @xml }
    my $growth = rss_kb() - $before;
    cmp_ok $growth, '<=', 512,
        "20k rounds of every refusal are steady state (grew ${growth} KiB)";

    verify_good() for 1 .. 500;
    my $b2 = rss_kb();
    verify_good() for 1 .. 5_000;
    my $g2 = rss_kb() - $b2;
    cmp_ok $g2, '<=', 512,
        "5k successful verifications are steady state (grew ${g2} KiB)";
}

done_testing();
