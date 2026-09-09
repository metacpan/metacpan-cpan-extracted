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

my $SECRET = 'a' x 32;
my $idp = FakeIdP->new;

# The provider's metadata, so the boot path that READS metadata is the
# one under test rather than a hand-filled config. Written to a file,
# because `file:` is the source the suite can use without a network.
my $meta_file = "psaml-meta-$$.xml";
{
    my ($b) = $idp->pub =~ /-----BEGIN PUBLIC KEY-----(.*?)-----END/s;
    # metadata carries a certificate, not a bare key, so use the explicit
    # trio for the plugin and test the metadata reader in t/08
    1;
}

# The provider's details go through package globals rather than being
# interpolated into the source: a PEM certificate inside a sprintf'd
# heredoc is one escaping mistake away from an application that builds
# and then cannot verify anything.
our $IDP_ENTITY = $idp->entity_id;
our $IDP_CERTS  = $idp->certs;

my $pkg = 'SAMLRoutes';
my $built = eval <<'APP';
package SAMLRoutes;
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

saml_login '/saml' => { on_login => sub {
    my ($c, $identity) = @_;
    return;
} };

1;
APP
ok $built, 'an application with the SAML routes builds' or diag $@;

my $t = Punk::Test->new($pkg);

# ---- the metadata route ----------------------------------------------

{
    $t->get_ok('/saml/metadata');
    is $t->status, 200, 'the metadata route answers';
    is $t->header('Content-Type'), 'application/samlmetadata+xml',
        'with the media type the specification names, not application/xml';
    like $t->body, qr/EntityDescriptor/, 'and an EntityDescriptor';
    like $t->body, qr{entityID="https://app\.example\.com/saml/metadata"},
        'whose entity id is the metadata URL, as every setup screen expects';
    like $t->body, qr{Location="https://app\.example\.com/saml/acs"},
        'and whose ACS location is the one URL computed at on_compile';
}

# ---- starting a login -------------------------------------------------

my ($flow_id, $flow_cookie);
{
    $t->get_ok('/saml/login/okta?to=/reports');
    is $t->status, 302, 'the login route redirects';
    my $loc = $t->header('Location');
    like $loc, qr{^https://idp\.example\.com/sso\?SAMLRequest=},
        'to the provider, with a SAMLRequest';
    like $loc, qr{&RelayState=_[0-9a-f]{32}},
        'and a RelayState that is an opaque id, never a URL';
    ($flow_id) = $loc =~ /RelayState=(_[0-9a-f]{32})/;

    my $set = $t->header('Set-Cookie');
    like $set, qr/^_saml_flow=/, 'a flow cookie is set';
    like $set, qr/SameSite=None/,
        'SameSite=None, the only value sent on the cross-site POST';
    like $set, qr/\bSecure\b/,
        'Secure, which SameSite=None requires or the browser drops it';
    like $set, qr{Path=/saml},
        'scoped to the mount, so no other request carries it';
    like $set, qr/HttpOnly/, 'HttpOnly, because nothing in the page needs it';
    like $set, qr/Max-Age=600/, 'and Max-Age from flow_ttl';
    ($flow_cookie) = $set =~ /^_saml_flow=([^;]+)/;
}

# the single-provider form
{
    $t->get_ok('/saml/login');
    is $t->status, 302, '/saml/login works when there is exactly one provider';
}

# ---- the ACS, end to end ----------------------------------------------

sub post_acs {
    my ($xml, $relay, $cookie) = @_;
    my $t2 = Punk::Test->new($pkg);
    $t2->{jar}{_saml_flow} = $cookie if defined $cookie;
    $t2->post_ok('/saml/acs', form => {
        SAMLResponse => MIME::Base64::encode_base64($xml, ''),
        (defined $relay ? (RelayState => $relay) : ()),
    });
    return $t2;
}

{
    my $xml = $idp->sign($idp->response(in_response_to => $flow_id),
                         '_assertion1');
    my $r = post_acs($xml, $flow_id, $flow_cookie);
    is $r->status, 303, 'a valid assertion is accepted and redirects'
        or diag $r->body;
    is $r->header('Location'), '/reports',
        'to where the login started, which came from the flow record';
}

# the flow record is SINGLE USE.
#
# The ACS deletes the record and writes the cookie back BEFORE it verifies
# anything, so the browser that just completed a login is holding a cookie
# with no record in it. Replaying the same Response with THAT cookie -
# which is what a real replay has to work with - finds nothing to match
# and is `unsolicited`.
#
# The earlier version of this test posted the cookie from before the first
# POST and accepted either a 303 or a 403, which is not an assertion.
{
    my $xml = $idp->sign($idp->response(in_response_to => $flow_id),
                         '_assertion1');
    my $first = post_acs($xml, $flow_id, $flow_cookie);
    is $first->status, 303, 'the first POST of a flow succeeds';

    my ($after) = ($first->header('Set-Cookie') // '') =~ /^_saml_flow=([^;]+)/;
    ok defined $after, 'the ACS wrote the flow cookie back';
    isnt $after, $flow_cookie, 'and it changed, because the record was taken';

    my $second = post_acs($xml, $flow_id, $after);
    is $second->status, 403,
        'the same Response with the cookie the browser now holds is refused';
    like $second->body, qr/Sign-in failed/, '  ... with the failure page';
}

# no cookie at all
{
    my $xml = $idp->sign($idp->response(in_response_to => $flow_id),
                         '_assertion1');
    my $r = post_acs($xml, $flow_id, undef);
    is $r->status, 403, 'no flow cookie is refused';
    like $r->body, qr/Sign-in failed/, 'with the failure page';
    unlike $r->body, qr/unsolicited|in_response_to|signature/,
        'and the page carries no reason at all';
}

# a tampered assertion
{
    my $xml = $idp->sign($idp->response(in_response_to => $flow_id),
                         '_assertion1');
    $xml =~ s/jo\@example\.com/admin\@example.com/;
    my $r = post_acs($xml, $flow_id, $flow_cookie);
    is $r->status, 403, 'a tampered assertion is refused';
}

# ---- on_error ---------------------------------------------------------

{
    my $ok = eval <<'APP';
package SAMLRoutesErr;
use Punk;
use Punk::Plugin::SAML;
host 'https://app.example.com';
session secret => 'session-secret-here';
plugin 'SAML' => { secret => 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' };
saml_idp okta => { entity_id => 'https://idp.example.com/entity',
                   sso_url   => 'https://idp.example.com/sso',
                   certs     => 'not a cert' };
saml_login '/saml' => {
    on_login => sub { return },
    on_error => sub { my ($c, $e) = @_; $c->text("code=$e->{code}", 418) },
};
1;
APP
    ok $ok, 'an application with on_error builds' or diag $@;
    my $t3 = Punk::Test->new('SAMLRoutesErr');
    $t3->post_ok('/saml/acs', form => { SAMLResponse => 'bm90eG1s' });
    is $t3->status, 418, 'on_error replaces the failure page';
    like $t3->body, qr/^code=/, 'and receives the Punk::SAML::Error';
}

# ---- csrf ------------------------------------------------------------

{
    my $ok = eval <<'APP';
package SAMLRoutesCsrf;
use Punk;
use Punk::Plugin::SAML;
host 'https://app.example.com';
session secret => 'session-secret-here';
csrf;
plugin 'SAML' => { secret => 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' };
saml_idp okta => { entity_id => 'https://i/e', sso_url => 'https://i/s',
                   certs => 'x' };
saml_login '/saml' => { on_login => sub { return } };
1;
APP
    ok $ok, 'an application with csrf on builds' or diag $@;
    # Punk::Test compiles the app, and the exempt path is added at
    # on_compile, which is to_app time. Reading punk_app without
    # compiling reads the application before the plugin has spoken.
    Punk::Test->new('SAMLRoutesCsrf');
    my $app = SAMLRoutesCsrf->punk_app;
    my $ex = $app->{csrf}{exempt};
    ok $ex && grep({ $_ eq '/saml/acs' } @$ex),
        'the ACS path is added to csrf exempt: it is the one request that '
        . 'is supposed to look like a forgery';
}

# ---- a hostile `to` ---------------------------------------------------
#
# `to` arrives in a query string, is carried across the provider in the
# flow record, and comes back as the target of a 303. An open redirect
# here is worth more to an attacker than usual: the victim arrives at it
# having just authenticated, which is exactly when they trust the page.
#
# The whole round trip is driven rather than reading the record, because
# what matters is the Location header a browser would follow.

sub login_and_land {
    my ($to) = @_;
    my $enc = $to;
    $enc =~ s{([^A-Za-z0-9\-_.~/])}{sprintf '%%%02X', ord $1}ge;

    my $t1 = Punk::Test->new($pkg);
    $t1->get_ok("/saml/login/okta?to=$enc");
    my $loc = $t1->header('Location');
    my ($id)     = $loc =~ /RelayState=(_[0-9a-f]{32})/;
    my ($cookie) = ($t1->header('Set-Cookie') // '') =~ /^_saml_flow=([^;]+)/;

    my $xml = $idp->sign($idp->response(in_response_to => $id), '_assertion1');
    my $r = post_acs($xml, $id, $cookie);
    return ($r->status, $r->header('Location'));
}

for my $case (
    ['//evil.example',       '/', 'a scheme-relative URL is not a path'],
    ['https://evil.example', '/', 'an absolute URL is not a path'],
    ['/fine',            '/fine', 'and an ordinary path is kept'],
) {
    my ($to, $want, $why) = @$case;
    my ($status, $loc) = login_and_land($to);
    is $status, 303, "to=$to completes the login";
    is $loc, $want, "  ... and lands on $want: $why";
}

unlink $meta_file;
done_testing();
