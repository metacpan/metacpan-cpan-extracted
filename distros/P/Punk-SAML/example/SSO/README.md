# SSODemo

A Punk application signing users in through SAML 2.0, generated with
`punk new SSODemo` and wired up with `Punk::Plugin::SAML`.

    plackup app.psgi
    # or, for the event loop Punk is built for:
    hyperman app.psgi

## What is here

| | |
|---|---|
| `lib/SSODemo.pm` | the routing table, and the three SAML declarations |
| `config/punk.yml` | `host`, the session, and the plugin's own `secret` |
| `idp-metadata.xml` | an example provider, so this boots with no network |
| `lib/SSODemo/Controller/Web/Root.pm` | the front page and `/me` |

The plugin adds four routes of its own under `/saml`:

    GET  /saml/metadata        this application's metadata
    GET  /saml/login/:idp      start a login
    GET  /saml/login           the same, when there is one provider
    POST /saml/acs             where the provider answers

## It requires https, and that is not a preference

`config/punk.yml` says `host: https://localhost:5000`. The identity
provider answers by POSTing to `/saml/acs` from its own origin. That is a
cross-site POST, and a cookie with `SameSite=Lax` is not sent on one - so
the cookie remembering the login has to be `SameSite=None`, and browsers
drop such a cookie unless it is also `Secure`.

Over plain http nothing fails at startup and every login fails at the
assertion consumer with `unsolicited`. The plugin refuses to boot
instead. To run this locally either use a local https certificate, or
drive it with `Punk::Test`, which does not go through a browser.

## Pointing it at a real provider

Two values go into the provider's console. Both come from this
application's own metadata:

    punk saml metadata

The `AssertionConsumerService` `Location` is the ACS URL - providers call
it the Reply URL or the Single Sign-On URL. The `entityID` is the entity
id - the Identifier, or the Audience URI. Give the provider both exactly
as printed: it compares them character for character.

Their metadata URL comes back, and replaces the file:

    saml_idp example => { metadata => 'https://.../metadata' };

Check it before starting the application:

    punk saml idp https://.../metadata

which prints the entity id, the single sign-on URL, each signing
certificate's fingerprint and the name id formats - or the reason the
metadata was refused. A provider this plugin cannot use fails there, at a
terminal, rather than at a user's first login.

Metadata is read once, at boot, before the server forks. A fetch that
fails is a croak: an application whose only login is SAML cannot sign
anyone in without its provider.

## When a login fails

The browser gets "sign-in failed" and no reason, deliberately: a verifier
that tells the far side which check it failed is telling an attacker
which one to work on next. The code goes to the application log.

For the ticket that says SSO stopped working, save the POST body from the
browser's network tab and ask:

    punk saml verify saved-response.txt

which prints the first check that refused, with its code - `audience`,
`expired`, `unknown_issuer`. The codes are listed in
`perldoc Punk::SAML::Error`.

## What this example does not show

Signing in for real, end to end. That needs a provider willing to sign an
assertion, and `idp-metadata.xml` carries a certificate only - exactly as
a real provider's metadata does, since nobody publishes their private
key. `t/01-basic.t` drives everything up to the redirect and back down
from the metadata route; Punk-SAML's own suite drives the other half
against a fake provider it controls.

## See also

    perldoc Punk::Plugin::SAML
