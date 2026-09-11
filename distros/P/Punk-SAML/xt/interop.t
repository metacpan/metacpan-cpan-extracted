#!perl

# A login against a real identity provider.
#
# Everything in t/ signs its fixtures with this distribution's own signer,
# through this distribution's own canonicaliser. That suite would pass
# whole if the c14n were wrong in a way both sides agreed on. Two things
# stand against that: File::Raw::XML's transcribed W3C exclusive-c14n
# vectors, which pin the canonicaliser against the specification, and this
# file, where the other side is somebody else's code.
#
# WRITTEN BLIND. There is no Keycloak on the machine this was written on,
# so it has never run. It is checked in because it is the shape the check
# takes and because phase 11 runs it against a real tenant; until it has
# gone green somewhere, treat a failure here as a bug in this file at
# least as readily as a bug in the distribution.
#
# ---- what it needs ----------------------------------------------------
#
#   docker compose -f xt/interop/docker-compose.yml up -d
#   PUNK_SAML_INTEROP_URL=http://localhost:8080 prove -lv xt/interop.t
#
# The compose file imports xt/interop/realm.json, which defines the realm,
# one user, and a SAML client whose entity id and assertion consumer URL
# are the two below. Change either and change the realm file with it.
#
#   PUNK_SAML_INTEROP_URL     Keycloak's base URL. UNSET SKIPS THE FILE.
#   PUNK_SAML_INTEROP_REALM   realm name, default punksaml
#   PUNK_SAML_INTEROP_USER    default jo
#   PUNK_SAML_INTEROP_PASS    default jo-password
#   PUNK_SAML_INTEROP_HOST    the SP host, default https://sp.example.com
#
# ---- and what it refuses to do ----------------------------------------
#
# Once PUNK_SAML_INTEROP_URL is set, a provider that does not answer is a
# FAILURE and not a skip. A docker test that skips itself when the
# container did not come up reports PASS for a run that tested nothing,
# which this family has been caught by before. The only skip here is the
# one taken before any test runs, by name, when the variable is unset.

use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;

my $BASE = $ENV{PUNK_SAML_INTEROP_URL};

BEGIN {
    plan skip_all => 'Keycloak is not configured: set PUNK_SAML_INTEROP_URL '
                   . 'to its base URL (see the header of this file)'
        unless $ENV{PUNK_SAML_INTEROP_URL};
    eval { require Punk; require Punk::Test; require Fetch;
           require File::Raw::XML; require Crypt::JWS; 1 }
        or plan skip_all => "Punk, Punk::Test, Fetch, File::Raw::XML and "
                          . "Crypt::JWS are required ($@)";
}

use Punk::SAML ();
use Punk::Plugin::SAML ();
use MIME::Base64 ();

$BASE =~ s{/+$}{};
my $REALM = $ENV{PUNK_SAML_INTEROP_REALM} || 'punksaml';
my $USER  = $ENV{PUNK_SAML_INTEROP_USER}  || 'jo';
my $PASS  = $ENV{PUNK_SAML_INTEROP_PASS}  || 'jo-password';
my $HOST  = $ENV{PUNK_SAML_INTEROP_HOST}  || 'https://sp.example.com';

my $DESCRIPTOR = "$BASE/realms/$REALM/protocol/saml/descriptor";

my $ua = Fetch->new(timeout => 20, cookie_jar => 1);

# ---- the provider is up, and is the one we meant -----------------------
#
# Asserted before anything else, so a run against a container that never
# started fails here with a clear reason instead of somewhere confusing.

{
    my $res = eval { $ua->get($DESCRIPTOR)->get };
    ok $res && $res->is_success,
        "the provider answers its metadata at $DESCRIPTOR"
        or BAIL_OUT("no metadata from $DESCRIPTOR: "
                  . ($@ || ($res ? $res->status : 'no response'))
                  . " - is the container up?");
    like $res->content, qr/EntityDescriptor/,
        'and what it answers is metadata';
    like $res->content, qr/X509Certificate/,
        'carrying at least one certificate, which is what we verify against';
}

# ---- an application configured from that metadata ----------------------
#
# `metadata` and not an explicit trio: reading somebody else's metadata is
# half of what this file is testing.

our $IDENTITY;
our $ERROR;
my $built = eval qq{
package SAMLInterop;
use Punk;
use Punk::Plugin::SAML;
host '$HOST';
session secret => 'interop-session-secret-32-bytes!';
plugin 'SAML' => { secret => 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb' };
saml_idp keycloak => { metadata => '$DESCRIPTOR' };
saml_login '/saml' => {
    on_login => sub { \$main::IDENTITY = \$_[1]; return },
    on_error => sub { \$main::ERROR    = \$_[1]; return },
};
1;
};                                                     ## no critic
ok $built, 'an application configured from the live metadata builds'
    or BAIL_OUT("could not build against $DESCRIPTOR: $@");

my $t = Punk::Test->new('SAMLInterop');

# ---- start the login ---------------------------------------------------

$t->get_ok('/saml/login/keycloak?to=/landed');
is $t->status, 302, 'the login route redirects to the provider';
my $sso = $t->header('Location');
like $sso, qr/\bSAMLRequest=/, 'with a SAMLRequest';
my ($flow_cookie) = ($t->header('Set-Cookie') // '') =~ /^_saml_flow=([^;]+)/;
ok defined $flow_cookie, 'and a flow cookie to carry the request id';

my ($relay) = $sso =~ /RelayState=([^&]+)/;
ok defined $relay, 'and a RelayState';
$relay =~ s/%([0-9A-Fa-f]{2})/chr hex $1/ge;

# ---- sign in, without a browser ---------------------------------------
#
# The provider's login page is an ordinary form, so Fetch can fill it in.
# This is where somebody else's code decides whether our AuthnRequest was
# acceptable: a request it will not parse never reaches a login page.

my $login_page = do {
    my $res = eval { $ua->get($sso)->get };
    ok $res && $res->is_success, 'the provider accepted the AuthnRequest'
        or BAIL_OUT('the provider would not show a login page: '
                  . ($@ || ($res ? $res->status . ' ' . $res->content : 'no response')));
    $res->content;
};

my ($action) = $login_page =~ /<form[^>]*\baction="([^"]+)"/i;
ok $action, 'the login page carries a form';
$action =~ s/&amp;/&/g;
$action = "$BASE$action" if $action =~ m{^/};

my $res = eval {
    $ua->post($action,
        headers => { 'Content-Type' => 'application/x-www-form-urlencoded' },
        body    => join '&',
            'username=' . _enc($USER),
            'password=' . _enc($PASS),
            'credentialId=')->get;
};
ok $res, 'the credentials were posted' or BAIL_OUT("posting them died: $@");

# Keycloak answers a successful login with a self-submitting form carrying
# the Response. That form is what a browser would POST to our ACS.
my $body = $res->content // '';
my ($saml_response) = $body =~ /name="SAMLResponse"[^>]*\bvalue="([^"]*)"/is;
$saml_response = $1 if !$saml_response
    && $body =~ /\bvalue="([^"]*)"[^>]*name="SAMLResponse"/is;
ok $saml_response, 'the provider issued a SAMLResponse'
    or diag "what came back instead:\n" . substr($body, 0, 2000);

my ($their_relay) = $body =~ /name="RelayState"[^>]*\bvalue="([^"]*)"/is;
$their_relay = $relay unless defined $their_relay && length $their_relay;
$their_relay =~ s/&amp;/&/g;
$saml_response =~ s/&#(\d+);/chr $1/ge;
$saml_response =~ s/&amp;/&/g;

# ---- and hand it to the plugin -----------------------------------------

my $acs = Punk::Test->new('SAMLInterop');
$acs->{jar}{_saml_flow} = $flow_cookie;
$acs->post_ok('/saml/acs', form => {
    SAMLResponse => $saml_response,
    RelayState   => $their_relay,
});

is $acs->status, 303, 'a real provider assertion is accepted'
    or diag 'refused as ' . ($ERROR ? "$ERROR->{code}: $ERROR->{message}"
                                    : 'no error recorded');
is $acs->header('Location'), '/landed',
    'and lands where the login asked to go';

ok $IDENTITY, 'on_login received an identity';
SKIP: {
    skip 'no identity to inspect', 3 unless $IDENTITY;
    ok defined $IDENTITY->{name_id} && length $IDENTITY->{name_id},
        'with a name id';
    is ref $IDENTITY->{attributes}, 'HASH', 'and an attribute map';
    # one assertion over all of them, so the count here is fixed whatever
    # the realm happens to send: a SKIP block whose length depends on the
    # data is a plan that does not add up on the day the data changes
    my @bad = grep { ref $IDENTITY->{attributes}{$_} ne 'ARRAY' }
              sort keys %{ $IDENTITY->{attributes} };
    is_deeply \@bad, [],
        'and every attribute value is an arrayref, as the contract says';
}

sub _enc {
    my ($s) = @_;
    $s =~ s{([^A-Za-z0-9\-_.~])}{sprintf '%%%02X', ord $1}ge;
    return $s;
}

done_testing();
