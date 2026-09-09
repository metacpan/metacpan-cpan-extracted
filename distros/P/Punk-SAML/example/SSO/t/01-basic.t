#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/../lib";
use Test::More;
use Punk::Test;

# The application is compiled once, at to_app, so a test that builds the app
# is testing the same frozen coderef the server runs - and one Punk::Test
# object is one browser: its cookie jar carries the session across every
# request below. See `perldoc Punk::Test` for the full assertion set.
chdir "$FindBin::Bin/.." or die "cannot chdir to the application root: $!\n";

my $t = Punk::Test->new('SSODemo');

$t->get_ok('/')
  ->status_is(200)
  ->content_like(qr/SSODemo/, 'renders the welcome page');

$t->get_ok('/no-such-page')->status_is(404);

# The sign-in link, one per configured provider.
$t->get_ok('/')->content_like(qr{/saml/login/example}, 'offers the provider');

# /me needs a signed-in user, and there is none yet.
$t->get_ok('/me')->status_is(303);

# This application's own metadata, which is what goes into the provider's
# console. Punk::Test does not follow the media type, so check it.
$t->get_ok('/saml/metadata')->status_is(200);
is $t->header('Content-Type'), 'application/samlmetadata+xml',
    'the metadata is served as application/samlmetadata+xml';
like $t->body, qr{Location="https://localhost:5000/saml/acs"},
    'and carries the assertion consumer URL the provider must be given';

# Starting a login: a redirect to the provider, and the flow cookie that
# remembers it. The cookie's attributes are the whole reason this
# application declares an https host.
$t->get_ok('/saml/login/example?to=/me')->status_is(302);
like $t->header('Location'), qr{^https://idp\.example\.com/sso\?SAMLRequest=},
    'redirects to the provider with a SAMLRequest';
my $set = $t->header('Set-Cookie');
like $set, qr/SameSite=None/, 'the flow cookie is SameSite=None';
like $set, qr/\bSecure\b/,    'and Secure, which SameSite=None requires';
like $set, qr{Path=/saml},    'and scoped to the login mount';

# The other half - the provider answering - needs a signed assertion, and
# signing one needs the provider's private key, which this example does
# not have: idp-metadata.xml carries the certificate only, exactly as a
# real provider's metadata does.
#
# Punk-SAML's own suite drives that half end to end against a fake
# provider it controls (t/09-routes.t). What is left for this example is
# a real provider, which is what the README describes.

done_testing();
