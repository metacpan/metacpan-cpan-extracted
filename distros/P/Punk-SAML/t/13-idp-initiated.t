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

# Identity-provider-initiated login: the user starts at the provider's
# dashboard and arrives at the ACS with a Response nobody asked for.
#
# It is off by default, and that is a security decision rather than a
# convenience one. With no flow record there is no request id to match,
# so the only thing tying the Response to this browser is the signature -
# which an attacker who obtained a valid Response for their OWN account
# also has. Turning it on is a deployment saying it accepts that.
#
# The other half is RelayState. On an SP-initiated login it is an opaque
# flow id and is never a URL. Here it is the provider's own value and IS
# read as a path, which makes this the one place in the distribution
# where an attacker-influenced string reaches a redirect. Hence safe_path,
# and hence most of this file.

my $idp = FakeIdP->new;
our $IDP_ENTITY = $idp->entity_id;
our $IDP_CERTS  = $idp->certs;

# Two applications, identical but for the one option, so the difference in
# behaviour below cannot come from anything else.
for my $pkg (qw(SAMLIdpOff SAMLIdpOn)) {
    my $allow = $pkg eq 'SAMLIdpOn' ? 1 : 0;
    my $ok = eval qq{
package $pkg;
use Punk;
use Punk::Plugin::SAML;
host 'https://app.example.com';
session secret => 'session-secret-here-32-bytes-ok!';
plugin 'SAML' => { secret => 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
                   allow_idp_initiated => $allow };
saml_idp okta => {
    entity_id => \$main::IDP_ENTITY,
    sso_url   => 'https://idp.example.com/sso',
    certs     => \$main::IDP_CERTS,
};
saml_login '/saml' => { on_login => sub { return } };
1;
};                                             ## no critic
    ok $ok, "$pkg builds" or diag $@;
}

# An unsolicited Response: no InResponseTo, because nothing was asked.
sub unsolicited {
    my (%o) = @_;
    return $idp->sign($idp->response(in_response_to => undef, %o),
                      '_assertion1');
}

# POST it with no flow cookie, which is the whole point: the browser never
# started a login here.
sub post_to {
    my ($pkg, $xml, $relay) = @_;
    my $t = Punk::Test->new($pkg);
    $t->post_ok('/saml/acs', form => {
        SAMLResponse => MIME::Base64::encode_base64($xml, ''),
        (defined $relay ? (RelayState => $relay) : ()),
    });
    return $t;
}

# ---- off by default ---------------------------------------------------

{
    my $r = post_to('SAMLIdpOff', unsolicited(), '/reports');
    is $r->status, 403, 'an unsolicited Response is refused by default';
    like $r->body, qr/Sign-in failed/, '  ... with the failure page';
    unlike $r->body, qr/unsolicited|allow_idp_initiated/,
        '  ... which names neither the code nor the option, because the '
        . 'browser is not who needs to know';
}

# ---- allowed when the deployment has said so --------------------------

{
    my $r = post_to('SAMLIdpOn', unsolicited(), '/reports');
    is $r->status, 303, 'and accepted when allow_idp_initiated is on'
        or diag $r->body;
    is $r->header('Location'), '/reports',
        'landing where RelayState asked, which here IS read as a path';
}

# every other check still runs: turning this on does not turn off the
# signature, and a suite that only proved the happy path would not say so
{
    my $x = unsolicited();
    $x =~ s/jo\@example\.com/admin\@example.com/;
    my $r = post_to('SAMLIdpOn', $x, '/reports');
    is $r->status, 403,
        'a tampered unsolicited Response is still refused';
}

{
    my $other = FakeIdP->new;
    my $x = $other->sign($other->response(in_response_to => undef),
                         '_assertion1');
    my $r = post_to('SAMLIdpOn', $x, '/reports');
    is $r->status, 403,
        'and one signed by a key this application does not know';
}

# ---- RelayState through safe_path -------------------------------------
#
# The one place a value from outside reaches a redirect. `default_to` is
# `/` here, which is where anything that is not a path has to land.

for my $case (
    ['/reports',             '/reports', 'an ordinary path is kept'],
    ['//evil.example',       '/', 'a scheme-relative URL is not a path'],
    ['https://evil.example', '/', 'an absolute URL is not a path'],
    ['',                     '/', 'an empty RelayState falls back to default_to'],
) {
    my ($relay, $want, $why) = @$case;
    my $r = post_to('SAMLIdpOn', unsolicited(), $relay);
    is $r->status, 303, "RelayState '$relay' completes the login";
    is $r->header('Location'), $want, "  ... and lands on $want: $why";
}

# no RelayState at all, which is what a provider sends when the deployment
# never configured one
{
    my $r = post_to('SAMLIdpOn', unsolicited(), undef);
    is $r->status, 303, 'no RelayState at all completes the login';
    is $r->header('Location'), '/', '  ... and lands on default_to';
}

done_testing();
