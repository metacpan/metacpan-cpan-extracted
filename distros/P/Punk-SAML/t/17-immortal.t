#!perl

# Nothing may spend a reference it does not own on one of perl's immortal
# SVs. Handing &PL_sv_undef to hv_store, or letting it become an SV *
# RETVAL - which xsubpp mortalises - buys a SvREFCNT_dec nobody paid for.
# From perl 5.20 the immortals are immune, sv_free resets their refcount,
# so the damage is invisible and every test passes. Before 5.20 the count
# really moves and the process dies when it reaches zero.
#
# This dist has already been bitten once: phase 4's `_state` returned
# &PL_sv_undef as RETVAL for a key that was not set, and it is the reason
# that XSUB now says XSRETURN_UNDEF. This file is what keeps it said.
#
# So assert the invariant rather than the symptom: the refcount of the
# immortal must not move across any number of these calls.
#
# WHERE THIS FILE CAN ACTUALLY FAIL, said plainly, because a gate nobody
# understands is a gate nobody maintains: on perl 5.20 and later it cannot.
# Those perls reset an immortal's refcount in sv_free, so a reference spent
# wrongly is invisible here and every assertion below passes whatever the
# XS does. This is a gate for the OLD PERLS ON THE SMOKERS - 5.10 to 5.18 -
# where the count really moves and the process eventually dies. Running it
# green on a modern perl says nothing; running it green on 5.16 says
# something. ASan and the old-perl build in phase 11 are the other half.
#
# Modelled on Punk-OAuth2's t/46-immortal-refcount.t, including the
# plain-Perl control it skips on: perls before 5.20 filled the slots
# av_extend allocated with &PL_sv_undef and released them on free, so an
# ordinary array hole spends immortal references by itself and a leak
# cannot be told from the interpreter's own bookkeeping.

use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;

BEGIN {
    plan skip_all => 'Devel::Peek required to read an immortal refcount'
        unless eval { require Devel::Peek; 1 };
    eval { require Punk; Punk->VERSION('0.45'); require Punk::Test;
           require File::Raw::XML; require Crypt::JWS; 1 }
        or plan skip_all => "Punk, Punk::Test, File::Raw::XML and Crypt::JWS required ($@)";
}

use Punk::SAML ();
use Punk::SAML::Response ();
use Punk::SAML::Metadata ();
use Punk::Plugin::SAML ();
use FakeIdP ();

# Devel::Peek dumps to STDERR; \undef is PL_sv_undef itself, so the last
# REFCNT in the dump is the immortal's.
sub immortal_refcount {
    my $out = '';
    open my $save, '>&', \*STDERR or return;
    close STDERR;
    open STDERR, '>', \$out       or do { open STDERR, '>&', $save; return };
    Devel::Peek::Dump(\undef);
    open STDERR, '>&', $save      or return;
    my @n = $out =~ /REFCNT = (\d+)/g;
    return $n[-1];
}

plan skip_all => 'cannot read the immortal refcount on this perl'
    unless defined immortal_refcount() && immortal_refcount() =~ /^\d+$/;

{
    my $before = immortal_refcount();
    for (1 .. 20) { my @a; $a[3] = 1; }
    plan skip_all => 'this perl spends immortal references on ordinary '
        . 'array holes (before 5.20 av_extend filled unused slots with '
        . '&PL_sv_undef), so its own bookkeeping cannot be told from a leak'
        if $before != immortal_refcount();
}

sub holds_steady {
    my ($name, $code, $n) = @_;
    $n ||= 50;
    $code->() for 1 .. 3;              # warm up: one-off setup is not a leak
    my $before = immortal_refcount();
    $code->() for 1 .. $n;
    my $spent = $before - immortal_refcount();
    is $spent, 0, $name
        or diag "spent $spent immortal references over $n calls"
              . " - fatal on perl before 5.20";
}

# ---- the application surface ------------------------------------------

my $idp = FakeIdP->new;
our $IDP_ENTITY = $idp->entity_id;
our $IDP_CERTS  = $idp->certs;

my $built = eval <<'APP';
package SAMLImmortal;
use Punk;
use Punk::Plugin::SAML;
host 'https://app.example.com';
session secret => 'session-secret-here-32-bytes-ok!';
plugin 'SAML' => { secret => 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' };
saml_idp okta => {
    entity_id => $main::IDP_ENTITY,
    sso_url   => 'https://idp.example.com/sso',
    certs     => $main::IDP_CERTS,
};
saml_login '/saml' => { on_login => sub { return } };
1;
APP
ok $built, 'the application builds' or diag $@;
Punk::Test->new('SAMLImmortal');           # to_app, so on_compile has run
my $app = SAMLImmortal->punk_app;

# THE ONE THAT ALREADY HAPPENED. A key that is not set is the branch with
# nothing to return, which is where an immortal reaches RETVAL.
holds_steady '_state on a key that is not set owns no immortal', sub {
    my $v = Punk::Plugin::SAML->_state($app, 'punk_saml.no_such_key');
};

holds_steady '_state on a key that is set owns no immortal', sub {
    my $v = Punk::Plugin::SAML->_state($app, 'punk_saml.opts');
};

# ---- the verifier ------------------------------------------------------
#
# Every refusal builds an error and unwinds, and several of them pass an
# absent optional through the argument list as an immortal.

my %base = (
    idp            => 'okta',
    entity_id      => $idp->sp_entity,
    idp_entity_id  => $idp->entity_id,
    acs_url        => $idp->acs,
    certs          => $idp->certs,
    in_response_to => '_flow1',
);
my $GOOD = $idp->sign($idp->response, '_assertion1');

holds_steady 'a successful verification owns no immortal', sub {
    my $id = eval { Punk::SAML::Response->verify($GOOD, %base) };
}, 20;

for my $case (
    ['a parse refusal',     'not xml at all<<<'],
    ['a shape refusal',     '<foo/>'],
    ['an unsigned document', scalar $idp->response],
) {
    my ($name, $xml) = @$case;
    holds_steady "$name owns no immortal", sub {
        eval { Punk::SAML::Response->verify($xml, %base) };
    };
}

# an OPTIONAL that is absent: in_response_to undef is the argument that
# reaches the checks as an immortal rather than as a string
holds_steady 'an absent in_response_to owns no immortal', sub {
    eval { Punk::SAML::Response->verify($GOOD, %base, in_response_to => undef) };
};

# ---- the builders ------------------------------------------------------

holds_steady 'metadata with every optional absent owns no immortal', sub {
    my $md = Punk::SAML::Metadata->build(
        entity_id => 'https://app.example.com/saml/metadata',
        acs_url   => 'https://app.example.com/saml/acs');
};

# ---- the helpers -------------------------------------------------------
#
# saml_url with no `to` is the other shape of the same branch: an optional
# that is simply not there.

# Punk::Test only offers the asserting forms, and hand-building a PSGI
# env to avoid them is the thing this family has a rule against. So each
# round emits its own passing assertion and the counts here are small: ten
# rounds is plenty to move a refcount that moves once per call, and the
# alternative is sixty lines of noise for no more coverage.
holds_steady 'the login route owns no immortal', sub {
    Punk::Test->new('SAMLImmortal')->get_ok('/saml/login/okta');
}, 10;

holds_steady 'the metadata route owns no immortal', sub {
    Punk::Test->new('SAMLImmortal')->get_ok('/saml/metadata');
}, 10;

# the ACS with as little as it will accept: no cookie, no RelayState.
# Every optional absent at once, which is the arrangement most likely to
# reach a branch that hands back an immortal.
holds_steady 'the ACS with no cookie and no RelayState owns no immortal', sub {
    Punk::Test->new('SAMLImmortal')
        ->post_ok('/saml/acs', form => { SAMLResponse => 'bm90eG1s' });
}, 10;

done_testing();
