#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;

BEGIN {
    eval { require Punk; Punk->VERSION('0.45'); require Punk::Test;
           require File::Raw::XML; require Crypt::JWS; 1 }
        or plan skip_all => "Punk, Punk::Test, File::Raw::XML and Crypt::JWS required ($@)";
}

use Punk::SAML ();
use Punk::Plugin::SAML ();
use FakeIdP ();
use MIME::Base64 ();

# The replay check, and the hole it closes.
#
# Until 0.03 the POD listed "The assertion has not been presented before"
# among the ACS checks and nothing on the route performed it: the check
# lived in psaml_verify_response behind a `seen` callback, the ACS never
# supplied one, and `seen` was not a plugin option, so a deployer who
# tried to configure it got an unknown-option croak.
#
# What covered for it was the flow record, which the POD called "the
# defence against a replayed assertion". It is not. It is single-use per
# BROWSER: the ACS takes the record and writes the cookie back before it
# verifies anything, so the browser that just signed in cannot replay.
# An attacker holding a copy of the ACS POST as it went over the wire
# holds the cookie as it was BEFORE that, record and all. t/09 tested the
# first case and not the second, and the second is the one an attacker
# has.
#
# The two things tested here are therefore:
#   * the same request, replayed with the cookie AS CAPTURED, is refused
#   * an assertion with no bearer NotOnOrAfter is refused outright,
#     because nothing else in the document bounds it in time

my $idp = FakeIdP->new;
our $IDP_ENTITY = $idp->entity_id;
our $IDP_CERTS  = $idp->certs;

# on_error exposes the CODE, which is the whole point of the exercise: a
# 403 alone cannot tell `replay` from `unsolicited` from `expired`, and
# this file is about which one fired.
my $APP = <<'BODY';
use Punk;
use Punk::Plugin::SAML;
host 'https://app.example.com';
session secret => 'session-secret-here-32-bytes-ok!';
cache 'memory', max_bytes => '1M';
plugin 'SAML' => { secret => 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'%EXTRA% };
saml_idp okta => {
    entity_id => $main::IDP_ENTITY,
    sso_url   => 'https://idp.example.com/sso',
    certs     => $main::IDP_CERTS,
};
saml_login '/saml' => {
    on_login => sub { return },
    on_error => sub { my ($c, $e) = @_; $c->text("code=$e->{code}", 403) },
};
1;
BODY

my $n = 0;
sub build_app {
    my (%arg) = @_;
    my $pkg  = 'SAMLReplay' . ++$n;
    my $body = $APP;
    $body =~ s{%EXTRA%}{$arg{extra} // ''}e;
    $body =~ s/^cache .*\n//m if $arg{no_cache};
    my $ok = eval "package $pkg;\n$body";          ## no critic
    my $err = $@;

    # to_app only when the caller is testing the BOOT, because it compiles
    # the class and Punk::Test compiles it again on the first request:
    # on_compile would run twice and the second pass adds routes to a
    # router that is already closed ("cannot add after compile"). A test
    # that goes on to make requests therefore leaves the compile to
    # Punk::Test, which croaks loudly enough if on_compile refuses.
    if ($ok && $arg{compile}) {
        $ok  = eval { $pkg->to_app; 1 } ? 1 : 0;
        $err = $@ unless $ok;
    }
    return ($ok, $err, $pkg);
}

my $aid = 0;
sub fresh_id { '_assertion' . ++$aid }

# Start a login and hand back what the browser would be holding when it
# arrives at the ACS: the RelayState and the flow cookie AS SENT.
sub start_login {
    my ($pkg, $to) = @_;
    my $t = Punk::Test->new($pkg);
    $t->get_ok("/saml/login/okta?to=$to");
    my $loc = $t->header('Location') // '';
    my ($id)     = $loc =~ /RelayState=(_[0-9a-f]{32})/;
    my ($cookie) = ($t->header('Set-Cookie') // '') =~ /^_saml_flow=([^;]+)/;
    return ($id, $cookie);
}

sub post_acs {
    my ($pkg, $xml, $relay, $cookie) = @_;
    my $t = Punk::Test->new($pkg);
    $t->{jar}{_saml_flow} = $cookie if defined $cookie;
    $t->post_ok('/saml/acs', form => {
        SAMLResponse => MIME::Base64::encode_base64($xml, ''),
        (defined $relay ? (RelayState => $relay) : ()),
    });
    return $t;
}

# ---- THE CAPTURE. the request as it went over the wire, posted twice ---

{
    my ($ok, $err, $pkg) = build_app();
    ok $ok, 'an application with the default replay store builds' or diag $err;

    my ($flow, $cookie) = start_login($pkg, '/reports');
    my $id  = fresh_id();
    my $xml = $idp->sign($idp->response(in_response_to => $flow,
                                        assertion_id   => $id), $id);

    my $victim = post_acs($pkg, $xml, $flow, $cookie);
    is $victim->status, 303, 'the victim completes the login';
    is $victim->header('Location'), '/reports', '  ... and lands where asked';

    # The SAME bytes and the SAME cookie. This is a proxy log, a HAR
    # export, a TLS-terminating gateway's request log: everything the
    # attacker has and nothing he does not.
    my $replay = post_acs($pkg, $xml, $flow, $cookie);
    is $replay->status, 403,
        'the captured request replayed with the cookie AS CAPTURED is refused';
    is $replay->body, 'code=replay',
        '  ... as `replay`, and not as `unsolicited` by luck of the cookie';

    # Twice more, because "the second one fails" and "only the first one
    # ever works" are different claims and the second is the one that
    # matters.
    for my $again (3, 4) {
        my $r = post_acs($pkg, $xml, $flow, $cookie);
        is $r->body, 'code=replay', "  ... and attempt $again likewise";
    }
}

# The flow record still does its own job, which is a different job: the
# cookie the BROWSER holds after a login has no record in it, so a replay
# from the victim's own browser never reaches the replay check at all.
{
    my ($ok, undef, $pkg) = build_app();
    my ($flow, $cookie) = start_login($pkg, '/reports');
    my $id  = fresh_id();
    my $xml = $idp->sign($idp->response(in_response_to => $flow,
                                        assertion_id   => $id), $id);

    my $first = post_acs($pkg, $xml, $flow, $cookie);
    is $first->status, 303, 'the first POST succeeds';
    my ($after) = ($first->header('Set-Cookie') // '') =~ /^_saml_flow=([^;]+)/;

    my $second = post_acs($pkg, $xml, $flow, $after);
    is $second->body, 'code=unsolicited',
        'a replay with the cookie the BROWSER now holds is unsolicited, '
        . 'because the record went with the first POST';
}

# ---- IDP-INITIATED, where there is no flow record to cover for it ------

{
    my ($ok, $err, $pkg) = build_app(extra => ', allow_idp_initiated => 1');
    ok $ok, 'an application with allow_idp_initiated builds' or diag $err;

    my $id  = fresh_id();
    my $xml = $idp->sign($idp->response(in_response_to => undef,
                                        assertion_id   => $id), $id);

    is post_acs($pkg, $xml, undef, undef)->status, 303,
        'an unsolicited assertion is accepted once';
    is post_acs($pkg, $xml, undef, undef)->body, 'code=replay',
        '  ... and refused the second time. With no flow record at all, '
        . 'this check is the ONLY thing between one capture and unlimited '
        . 'logins';
}

# ---- the bearer window is REQUIRED ------------------------------------

{
    my ($ok, undef, $pkg) = build_app();

    my $id  = fresh_id();
    my ($flow, $cookie) = start_login($pkg, '/reports');
    my $xml = $idp->sign($idp->response(in_response_to => $flow,
                                        assertion_id   => $id,
                                        no_conf_window => 1), $id);
    is post_acs($pkg, $xml, $flow, $cookie)->body, 'code=xml_shape',
        'a bearer SubjectConfirmationData with no NotOnOrAfter is refused';
}

# The document that used to be good for ever.
#
# No NotOnOrAfter anywhere and an IssueInstant a year old. IssueInstant is
# not a freshness check and both windows were enforced only when present,
# so this verified exactly as well as one minted a second ago - and with
# allow_idp_initiated on, nothing bounded how often it could be presented.
{
    my ($ok, undef, $pkg) = build_app(extra => ', allow_idp_initiated => 1');

    my $id  = fresh_id();
    my $xml = $idp->sign($idp->response(in_response_to => undef,
                                        assertion_id   => $id,
                                        now            => time - 31_536_000,
                                        no_conf_window => 1,
                                        no_cond_window => 1), $id);
    is post_acs($pkg, $xml, undef, undef)->body, 'code=xml_shape',
        'a year-old assertion with no window at all is refused outright, '
        . 'and not on the strength of the replay cache remembering it';
}

# ---- the check runs AFTER verification, not before ---------------------

# An id read out of an unverified document is attacker-chosen. If the
# store were written before the signature was checked, anyone could fill
# it with whatever they liked - and, worse, burn an id the real provider
# was about to use.
{
    my ($ok, undef, $pkg) = build_app();

    my $id = fresh_id();
    my ($flow1, $cookie1) = start_login($pkg, '/reports');
    my $tampered = $idp->sign($idp->response(in_response_to => $flow1,
                                             assertion_id   => $id), $id);
    $tampered =~ s/jo\@example\.com/admin\@example.com/;
    my $r = post_acs($pkg, $tampered, $flow1, $cookie1);
    isnt $r->body, 'code=replay', 'a tampered assertion is not a replay';

    # the SAME id, this time in a document that verifies
    my ($flow2, $cookie2) = start_login($pkg, '/reports');
    my $good = $idp->sign($idp->response(in_response_to => $flow2,
                                         assertion_id   => $id), $id);
    is post_acs($pkg, $good, $flow2, $cookie2)->status, 303,
        'and it did not burn the id: the same id in a document that '
        . 'verifies is still accepted';
}

# ---- a store of the application's own ---------------------------------

{
    my @calls;
    our $SEEN = sub {
        my ($c, $id, $until) = @_;
        push @calls, [ $id, $until ];
        return @calls > 1;             # fresh once, then seen
    };
    my ($ok, $err, $pkg) = build_app(extra => ', seen => $main::SEEN');
    ok $ok, 'an application with a `seen` coderef builds' or diag $err;

    my ($flow, $cookie) = start_login($pkg, '/reports');
    my $id  = fresh_id();
    my $xml = $idp->sign($idp->response(in_response_to => $flow,
                                        assertion_id   => $id), $id);

    is post_acs($pkg, $xml, $flow, $cookie)->status, 303,
        'the coderef is believed when it says fresh';
    is scalar @calls, 1, '  ... and was called once';
    is $calls[0][0], $id, '  ... with the assertion id';
    cmp_ok $calls[0][1], '>', time, '  ... and the window to remember it to';

    my ($flow2, $cookie2) = start_login($pkg, '/reports');
    my $xml2 = $idp->sign($idp->response(in_response_to => $flow2,
                                         assertion_id   => fresh_id()),
                          '_assertion' . $aid);
    is post_acs($pkg, $xml2, $flow2, $cookie2)->body, 'code=replay',
        'and believed when it says seen';
}

# A store that BREAKS is not a store that says fresh.
{
    our $DEAD = sub { die "the replay store is on fire\n" };
    my ($ok, undef, $pkg) = build_app(extra => ', seen => $main::DEAD');

    my ($flow, $cookie) = start_login($pkg, '/reports');
    my $id  = fresh_id();
    my $xml = $idp->sign($idp->response(in_response_to => $flow,
                                        assertion_id   => $id), $id);
    is post_acs($pkg, $xml, $flow, $cookie)->body, 'code=config',
        'a store that dies refuses the login as `config`. Fail CLOSED: '
        . '"the store is broken" and "the assertion is fresh" must not '
        . 'produce the same login';
}

# ---- `seen` naming another store --------------------------------------

{
    my $ok = eval <<'APP';
package SAMLReplayNamed;
use Punk;
use Punk::Plugin::SAML;
host 'https://app.example.com';
session secret => 'session-secret-here-32-bytes-ok!';
cache 'memory', max_bytes => '1M';
cache saml => { backend => 'memory', max_bytes => '1M' };
plugin 'SAML' => { secret => 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
                   seen   => 'saml' };
saml_idp okta => {
    entity_id => $main::IDP_ENTITY,
    sso_url   => 'https://idp.example.com/sso',
    certs     => $main::IDP_CERTS,
};
saml_login '/saml' => {
    on_login => sub { return },
    on_error => sub { my ($c, $e) = @_; $c->text("code=$e->{code}", 403) },
};
1;
APP
    ok $ok, '`seen` may name one of the cache stores' or diag $@;

    # No to_app here: Punk::Test compiles it on the first request, and
    # compiling it twice runs on_compile twice against a closed router.
    # The login below is the proof that it booted.
    my ($flow, $cookie) = start_login('SAMLReplayNamed', '/reports');
    my $id  = fresh_id();
    my $xml = $idp->sign($idp->response(in_response_to => $flow,
                                        assertion_id   => $id), $id);
    is post_acs('SAMLReplayNamed', $xml, $flow, $cookie)->status, 303,
        '  ... and the login works through it';
    is post_acs('SAMLReplayNamed', $xml, $flow, $cookie)->body, 'code=replay',
        '  ... and the replay is caught by it';
}

# ---- the refusals at boot ---------------------------------------------

{
    my ($ok, $err) = build_app(no_cache => 1, compile => 1);
    ok !$ok, 'an application with no store for the replay check does not boot';
    like $err, qr/no `cache` store named 'default'/,
        '  ... and says which store it wanted';
    like $err, qr/4\.1\.4\.5/,
        '  ... and why it is a refusal and not a warning';
    like $err, qr/allow_replay/,
        '  ... and how to say you meant it';
}

{
    my ($ok, $err) = build_app(no_cache => 1, compile => 1, extra => ", seen => 'nope'");
    ok !$ok, '`seen` naming a store that was never declared does not boot';
    like $err, qr/no `cache` store named 'nope'/, '  ... naming it';
}

{
    my ($ok, $err) = build_app(no_cache => 1, compile => 1, extra => ', allow_replay => 1');
    ok $ok, 'allow_replay => 1 boots with no store at all' or diag $err;
}

{
    my ($ok, $err) = build_app(compile => 1, extra => ', seen => []');
    ok !$ok, '`seen` as anything but a coderef or a name is refused';
    like $err, qr/`seen` takes a coderef or the name/, '  ... saying what it takes';
}

# ---- allow_replay, which is the deployer saying they meant it ----------

{
    my ($ok, $err, $pkg) = build_app(extra => ', allow_replay => 1');
    ok $ok, 'an application with allow_replay builds' or diag $err;

    my ($flow, $cookie) = start_login($pkg, '/reports');
    my $id  = fresh_id();
    my $xml = $idp->sign($idp->response(in_response_to => $flow,
                                        assertion_id   => $id), $id);

    is post_acs($pkg, $xml, $flow, $cookie)->status, 303,
        'the login works';
    is post_acs($pkg, $xml, $flow, $cookie)->status, 303,
        '  ... and so does the replay, which is what the option MEANS. '
        . 'Written down so that nobody sets it thinking it is a tuning knob';
}

# ---- replay_until, on the identity ------------------------------------

{
    our @GOT;
    our $CAPTURE = sub { push @GOT, $_[1]; 0 };
    my $ok = eval <<'APP';
package SAMLReplayIdentity;
use Punk;
use Punk::Plugin::SAML;
host 'https://app.example.com';
session secret => 'session-secret-here-32-bytes-ok!';
cache 'memory', max_bytes => '1M';
plugin 'SAML' => { secret => 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' };
saml_idp okta => {
    entity_id => $main::IDP_ENTITY,
    sso_url   => 'https://idp.example.com/sso',
    certs     => $main::IDP_CERTS,
};
saml_login '/saml' => { on_login => sub {
    my ($c, $identity) = @_;
    push @main::GOT, $identity;
    return;
} };
1;
APP
    ok $ok, 'an application that keeps the identity builds' or diag $@;

    my ($flow, $cookie) = start_login('SAMLReplayIdentity', '/reports');
    my $id  = fresh_id();
    my $now = time;
    my $xml = $idp->sign($idp->response(in_response_to => $flow,
                                        assertion_id   => $id,
                                        now            => $now), $id);
    post_acs('SAMLReplayIdentity', $xml, $flow, $cookie);

    is scalar @GOT, 1, 'on_login saw the identity';
    my $i = $GOT[0];
    is $i->{assertion_id}, $id, 'the assertion id is on it';
    # FakeIdP puts the bearer window at now + 300
    is $i->{replay_until}, $now + 300,
        'and `replay_until` is the BEARER window, which is the one '
        . 'Profiles 4.1.4.5 names for how long to remember the id';
}

done_testing;
