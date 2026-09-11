package SSODemo;

use strict;
use warnings;
use Punk;

# `use`, not just the plugin line in config: saml_idp and saml_login below
# are bareword calls, and perl has to know the names before it parses
# those lines. The plugin line runs at runtime of a body already compiled.
use Punk::Plugin::SAML;

our $VERSION = '0.01';

# Configuration lives in config/punk.yml, applied at the point this keyword
# sits - so everything declared below can rely on the views, database and
# plugins it registered. Anything in the file that is not a Punk keyword is
# yours, reachable through $app->config.
config 'config/punk.yml';

# Punk::Auth, with no model and no database: `auth_id` reads the signed
# session straight back, which is all this example needs. A real
# application says `auth model => 'User'` and gets $c->user with it.
auth session_key => 'user_id';

# Routes. A target string names a controller relative to
# SSODemo::Controller - 'Web::Root#index' is
# SSODemo::Controller::Web::Root::index - or pass a coderef inline.
#
# `name` is what lets everything else point at this route without spelling
# its path again: $c->url_for('home') in code, and the `url` hash in a
# template. Rename the path and the links follow; misspell the name and it
# fails at boot or in a test, not at a 404 nobody sees.
get '/' => 'Web::Root#index', { name => 'home' };

# ---- SAML single sign-on ---------------------------------------------
#
# The plugin itself is configured in config/punk.yml, under `plugins`.

# One identity provider: the demo one in ../IdP, which run.pl starts on
# port 5001. It will actually sign an assertion and post it back, so a
# login completes on one machine with no account anywhere.
#
# It authenticates nobody and its signing key is committed beside it.
# Read ../IdP/README.md before pointing anything at it.
#
# idp-metadata.xml beside this file is the same provider's metadata,
# saved, for when you want to boot with nothing else running:
#
#   saml_idp example => { metadata => 'file:idp-metadata.xml' };
#
# In a real deployment this is the provider's own metadata URL:
#
#   saml_idp okta => { metadata => 'https://example.okta.com/app/abc/sso/saml/metadata' };
#
# It is fetched once, at boot, before the server forks. A fetch that
# fails is a croak rather than a warning: an application whose only login
# is SAML cannot sign anyone in without its provider, and refusing to
# start says so at deploy time to the person deploying, rather than at
# the first login to a user as a 403.
#
# Check what this plugin reads from a provider before starting:
#
#   punk saml idp idp-metadata.xml
saml_idp example => { metadata => 'http://127.0.0.1:5001/idp/metadata' };

# The demo identity provider in ../IdP, which will actually sign an
# assertion and post it back - so the login completes on one machine with
# no account anywhere. Start it on 5001 and swap the line above for:
#
#   saml_idp example => { metadata => 'http://127.0.0.1:5001/idp/metadata' };
#
# See ../IdP/README.md. That provider authenticates nobody and its
# signing key is committed; it exists to prove this half works.

# The login mount. Declared once; every provider lives under it. This
# gives the application four routes:
#
#   GET  /saml/metadata        this application's own metadata
#   GET  /saml/login/:idp      start a login
#   GET  /saml/login           the same, when there is one provider
#   POST /saml/acs             where the provider answers
saml_login '/saml' => {
    on_login => sub {
        my ($c, $identity) = @_;

        # EVERY attribute value is an arrayref, always, including when
        # there is one value: SAML attributes are multi-valued, and an
        # API that returned a scalar for one and a list for two would be
        # the bug in this body on the day a user joins a second group.
        my $email = $identity->{attributes}{email}[0]
                 || $identity->{name_id};

        # A real application looks the user up in a model. This one keeps
        # them in memory, because the point here is the sign-in.
        my $user = user_for($email, $identity);

        # Without this the assertion has been verified and NOBODY HAS
        # BEEN SIGNED IN. It is the common mistake, and it looks like a
        # login that works followed by a guard that refuses.
        $c->login($user);

        # Returning nothing lets the plugin redirect to wherever the
        # login started - the `to` in the link that began it. Return a
        # response to answer for yourself instead.
        return;
    },

    # Optional. Without it a refusal renders "sign-in failed" with a 403
    # and no reason: a verifier that tells the far side which check it
    # failed is telling an attacker which one to work on next. The code
    # goes to the log either way.
    on_error => sub {
        my ($c, $error) = @_;
        warn "sso refused: $error->{code}\n";
        # render takes overrides as name => value pairs, not a hashref
        return $c->render('failed', {
            title => 'Sign-in failed',
            app   => 'SSODemo',
        }, status => 403);
    },
};

# A page that needs a signed-in user. auth_guard needs nothing SAML
# specific: it looks at the session, $c->login wrote it, and a SAML user
# is a user.
get '/me' => 'Web::Root#me', { name => 'me' };

# The in-memory user store, so the example has no database.
# Keyed by what $c->login records and $c->auth_id reads back, so the two
# halves agree with no database between them.
our %USERS;
sub user_for {
    my ($email, $identity) = @_;
    return $USERS{$email} ||= {
        id      => $email,
        email   => $email,
        name_id => $identity->{name_id},
        groups  => $identity->{attributes}{groups} || [],
    };
}

# Views and the /static mount come from config/punk.yml, so this file stays
# the routing table. Add a route with a coderef when it is not worth a
# controller method:
#
#   get '/health' => sub { $_[0]->json({ ok => 1 }) };
#
# Browsers and search engines request /favicon.ico at the site root, where
# the /static mount does not answer. One keyword serves it from frozen
# bytes, with a Cache-Control and an ETag (also settable from punk.yml):
#
#   favicon 'root/static/favicon.ico';

1;

__END__

