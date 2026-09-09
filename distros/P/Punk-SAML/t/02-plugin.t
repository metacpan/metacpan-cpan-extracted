#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require Punk; Punk->VERSION('0.45'); 1 }
        or plan skip_all => "Punk 0.45 is required ($@)";
    eval { require Punk::Test; 1 }
        or plan skip_all => "Punk::Test is required ($@)";
}

use Punk::SAML ();
use Punk::Plugin::SAML ();

# Everything in phase 4 is the surface: the register, the keywords, the
# option table and the two helpers. Nothing here makes a request, because
# nothing here mounts a route - that is phase 8. What this proves is that
# the declarations are recorded, and that every refusal refuses.

my $SECRET = 'a' x 32;

# A metadata document on disk.
#
# Phase 4 recorded `metadata` and fetched nothing; phase 8's on_compile
# resolves every provider before the fork, so an app that names an https
# metadata URL and then compiles will try to reach it. These tests are
# about the KEYWORDS, not the network, so the source is a file.
my $META = "psaml-t02-meta-$$.xml";
{
    my $cert = do {
        my $c = `openssl req -x509 -newkey rsa:2048 -keyout /dev/null -nodes -subj "/CN=t02" -days 3650 2>/dev/null`;
        my ($b) = ($c // '') =~ /-----BEGIN CERTIFICATE-----(.*?)-----END/s;
        $b // '';
    };
    $cert =~ s/\s+//g;
    plan skip_all => 'openssl is required to build a metadata fixture'
        unless $cert;
    open my $fh, '>', $META or die $!;
    print {$fh} qq{<md:EntityDescriptor }
      . qq{xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata" }
      . qq{xmlns:ds="http://www.w3.org/2000/09/xmldsig#" }
      . qq{entityID="https://idp.example.com/entity">}
      . qq{<md:IDPSSODescriptor protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">}
      . qq{<md:KeyDescriptor use="signing"><ds:KeyInfo><ds:X509Data>}
      . qq{<ds:X509Certificate>$cert</ds:X509Certificate>}
      . qq{</ds:X509Data></ds:KeyInfo></md:KeyDescriptor>}
      . qq{<md:SingleSignOnService }
      . qq{Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect" }
      . qq{Location="https://idp.example.com/sso"/>}
      . qq{</md:IDPSSODescriptor></md:EntityDescriptor>};
    close $fh;
}
END { unlink $META if $META }
my $META_SRC = "file:$META";

# Build an application in a fresh package each time, so a croak in one
# does not leave a half-registered application behind for the next.
my $n = 0;
sub build {
    my (%arg) = @_;
    my $pkg = 'SAMLTest' . ++$n;
    my $host = exists $arg{host} ? $arg{host} : 'https://app.example.com';
    # `use Punk::Plugin::SAML` at compile time, because saml_idp and
    # saml_login are bareword calls and perl has to know the names before
    # it parses those lines. The plugin line alone is too late: it runs at
    # runtime of a body that is already compiled.
    my $code = "package $pkg; use Punk; use Punk::Plugin::SAML;\n";
    $code .= "host '$host';\n" if defined $host;
    $code .= $arg{body};
    $code .= "\n1;";
    my $ok = eval "$code";                     ## no critic
    my $err = $@;
    # on_compile runs at to_app, not at package compile, and everything
    # that needs `host` or needs every keyword to have been seen is
    # deferred to it. So the build is not finished until the app is
    # compiled, and the refusals that belong there surface here.
    if ($ok && !$arg{no_compile}) {
        $ok = eval { $pkg->to_app; 1 } ? 1 : 0;
        $err = $@ unless $ok;
    }
    return ($ok, $err, $pkg);
}

sub app_of { my $p = shift; return $p->punk_app }

# ---- the happy path --------------------------------------------------

{
    my ($ok, $err, $pkg) = build(body => <<"BODY");
plugin 'SAML' => { secret => '$SECRET' };
saml_idp okta  => { metadata => '$META_SRC' };
saml_idp entra => {
    entity_id => 'https://sts.example.net/x',
    sso_url   => 'https://sts.example.net/sso',
    certs     => 'PEMPEMPEM',
};
saml_login '/saml' => { on_login => sub { 1 } };
BODY
    ok $ok, 'an application with the plugin, two providers and a login builds'
        or diag $err;

    my $app = app_of($pkg);
    my $opts = Punk::Plugin::SAML->_state($app, 'punk_saml.opts');
    is ref($opts), 'HASH', 'the options are recorded';
    is $opts->{secret}, $SECRET, 'the secret is kept';
    is $opts->{prefix}, '/saml', 'prefix defaults';
    is $opts->{require_signed}, 'either', 'require_signed defaults';
    is $opts->{skew}, 120, 'skew defaults';
    is $opts->{flow_ttl}, 600, 'flow_ttl defaults';
    is $opts->{max_response}, 262144, 'max_response defaults';
    is $opts->{metadata}, 1, 'metadata is on by default';
    is $opts->{allow_sha1}, 0, 'sha1 is off';
    is $opts->{allow_idp_initiated}, 0, 'idp-initiated is off';
    is $opts->{default_to}, '/', 'default_to defaults';

    my $idps = Punk::Plugin::SAML->_state($app, 'punk_saml.idps');
    is ref($idps), 'HASH', 'the providers are recorded';
    is_deeply [sort keys %$idps], ['entra', 'okta'], 'both of them';
    is $idps->{okta}{metadata}, $META_SRC,
        'the metadata form is kept';
    is_deeply $idps->{entra}{certs}, ['PEMPEMPEM'],
        'a single cert is normalised to an arrayref';

    my $order = Punk::Plugin::SAML->_state($app, 'punk_saml.idp_order');
    is_deeply $order, ['okta', 'entra'], 'declaration order is kept';

    my $login = Punk::Plugin::SAML->_state($app, 'punk_saml.login');
    is $login->{path}, '/saml', 'the mount is recorded';
    is ref($login->{on_login}), 'CODE', 'and on_login with it';

    # on_compile has run by now if the app compiled
    is(Punk::Plugin::SAML->_state($app, 'punk_saml.acs'),
       'https://app.example.com/saml/acs', 'the ACS URL is derived once');
    is(Punk::Plugin::SAML->_state($app, 'punk_saml.entity_id'),
       'https://app.example.com/saml/metadata',
       'entity_id defaults to the metadata URL');
}

# a trailing slash on the mount does not produce a doubled one
{
    my ($ok, $err, $pkg) = build(body => <<"BODY");
plugin 'SAML' => { secret => '$SECRET' };
saml_idp okta => { metadata => '$META_SRC' };
saml_login '/auth/saml/' => { on_login => sub { 1 } };
BODY
    ok $ok, 'a mount with a trailing slash builds' or diag $err;
    my $app = app_of($pkg);
    is(Punk::Plugin::SAML->_state($app, 'punk_saml.mount'), '/auth/saml',
       'the mount is normalised');
    is(Punk::Plugin::SAML->_state($app, 'punk_saml.acs'),
       'https://app.example.com/auth/saml/acs', 'and the ACS URL with it');
}

# an explicit entity_id wins over the derived one
{
    my ($ok, undef, $pkg) = build(body => <<"BODY");
plugin 'SAML' => { secret => '$SECRET', entity_id => 'urn:my:sp' };
saml_idp okta => { metadata => '$META_SRC' };
saml_login '/saml' => { on_login => sub { 1 } };
BODY
    ok $ok, 'an explicit entity_id builds';
    is(Punk::Plugin::SAML->_state(app_of($pkg), 'punk_saml.entity_id'),
       'urn:my:sp', 'and is used as given');
}

# saml_idp before saml_login, and after: either order works, because
# on_compile is where the two are reconciled
{
    my ($ok, $err) = build(body => <<"BODY");
plugin 'SAML' => { secret => '$SECRET' };
saml_login '/saml' => { on_login => sub { 1 } };
saml_idp okta => { metadata => '$META_SRC' };
BODY
    ok $ok, 'saml_login may be declared before saml_idp' or diag $err;
}

# ---- the refusals ----------------------------------------------------

my @refusals = (
    ['no secret',
     "plugin 'SAML' => {};",
     qr/`secret` is required/],
    ['an empty secret list',
     "plugin 'SAML' => { secret => [] };",
     qr/`secret` was an empty list/],
    ['a secret that is a hashref',
     "plugin 'SAML' => { secret => {} };",
     qr/`secret` takes a string/],
    ['an unknown option',
     "plugin 'SAML' => { secret => '$SECRET', require_signd => 'both' };",
     qr/unknown option 'require_signd'/],
    ['a bad require_signed',
     "plugin 'SAML' => { secret => '$SECRET', require_signed => 'yes' };",
     qr/`require_signed` takes assertion, response, either or both/],
    ['a negative skew',
     "plugin 'SAML' => { secret => '$SECRET', skew => -1 };",
     qr/`skew` must be zero or more/],
    ['sign_requests with no key',
     "plugin 'SAML' => { secret => '$SECRET', sign_requests => 1 };",
     qr/`sign_requests` needs `key`/],
    ['sign_metadata with a key but no cert',
     "plugin 'SAML' => { secret => '$SECRET', sign_metadata => 1, key => 'x' };",
     qr/`sign_metadata` needs `key` and `cert`/],
    ['saml_idp with both forms',
     "plugin 'SAML' => { secret => '$SECRET' };\n"
     . "saml_idp okta => { metadata => '$META_SRC', sso_url => 'https://i/s' };",
     qr/exclusive/],
    ['saml_idp with neither',
     "plugin 'SAML' => { secret => '$SECRET' };\nsaml_idp okta => {};",
     qr/needs either `metadata`/],
    ['saml_idp with an unknown setting',
     "plugin 'SAML' => { secret => '$SECRET' };\n"
     . "saml_idp okta => { metadata => '$META_SRC', certz => 1 };",
     qr/unknown saml_idp setting 'certz'/],
    ['a duplicate provider name',
     "plugin 'SAML' => { secret => '$SECRET' };\n"
     . "saml_idp okta => { metadata => '$META_SRC' };\n"
     . "saml_idp okta => { metadata => '$META_SRC' };",
     qr/declared twice/],
    ['saml_login without on_login',
     "plugin 'SAML' => { secret => '$SECRET' };\n"
     . "saml_idp okta => { metadata => '$META_SRC' };\n"
     . "saml_login '/saml' => {};",
     qr/needs `on_login`/],
    ['on_login that is not a coderef',
     "plugin 'SAML' => { secret => '$SECRET' };\n"
     . "saml_idp okta => { metadata => '$META_SRC' };\n"
     . "saml_login '/saml' => { on_login => 'nope' };",
     qr/needs `on_login`/],
    ['on_error that is not a coderef',
     "plugin 'SAML' => { secret => '$SECRET' };\n"
     . "saml_idp okta => { metadata => '$META_SRC' };\n"
     . "saml_login '/saml' => { on_login => sub {1}, on_error => 'x' };",
     qr/`on_error` takes a coderef/],
    ['a second saml_login',
     "plugin 'SAML' => { secret => '$SECRET' };\n"
     . "saml_idp okta => { metadata => '$META_SRC' };\n"
     . "saml_login '/a' => { on_login => sub {1} };\n"
     . "saml_login '/b' => { on_login => sub {1} };",
     qr/declared twice/],
    ['saml_login with no provider',
     "plugin 'SAML' => { secret => '$SECRET' };\n"
     . "saml_login '/saml' => { on_login => sub {1} };",
     qr/no saml_idp is/],
);

for my $r (@refusals) {
    my ($name, $body, $want) = @$r;
    my ($ok, $err) = build(body => $body);
    ok !$ok, "refused: $name";
    like $err, $want, "  ... and says why: $name";
}

# host is its own group: it is refused at on_compile, and the message has
# to explain the failure it prevents, because the alternative failure is
# silent.
{
    my ($ok, $err) = build(host => 'http://app.example.com', body => <<"BODY");
plugin 'SAML' => { secret => '$SECRET' };
saml_idp okta => { metadata => '$META_SRC' };
saml_login '/saml' => { on_login => sub { 1 } };
BODY
    ok !$ok, 'refused: an http host';
    like $err, qr/`host` must be https/, '  ... naming the scheme';
    like $err, qr/SameSite=None/, '  ... and the cookie that needs it';
}
{
    my ($ok, $err) = build(host => undef, body => <<"BODY");
plugin 'SAML' => { secret => '$SECRET' };
saml_idp okta => { metadata => '$META_SRC' };
saml_login '/saml' => { on_login => sub { 1 } };
BODY
    ok !$ok, 'refused: no host at all';
    like $err, qr/no `host`/, '  ... naming what is missing';
}

# ---- the helpers -----------------------------------------------------

{
    # no_compile: Punk::Test calls to_app itself, and to_app compiles once
    # per class - a second call croaks with "already compiled".
    my ($ok, $err, $pkg) = build(no_compile => 1, body => <<"BODY");
plugin 'SAML' => { secret => '$SECRET' };
saml_idp okta  => { metadata => '$META_SRC' };
saml_idp entra => { metadata => '$META_SRC' };
saml_login '/saml' => { on_login => sub { 1 } };

get '/idps' => sub { my \$c = shift; \$c->text(join ',', \$c->saml_idps) };
get '/one'  => sub { my \$c = shift; \$c->text(\$c->saml_url('okta')) };
get '/to'   => sub { my \$c = shift;
                     \$c->text(\$c->saml_url('entra', to => '/reports?a=1')) };
get '/bad'  => sub { my \$c = shift;
                     \$c->text(eval { \$c->saml_url('nope') } || "E: \$@") };
BODY
    ok $ok, 'an application with the helpers builds' or diag $err;

    my $t = Punk::Test->new($pkg);
    $t->get_ok('/idps');
    is $t->body, 'okta,entra', 'saml_idps answers in declaration order';
    $t->get_ok('/one');
    is $t->body, '/saml/login/okta', 'saml_url builds the login URL';
    $t->get_ok('/to');
    is $t->body, '/saml/login/entra?to=%2Freports%3Fa%3D1',
        'and percent-encodes `to`';
    $t->get_ok('/bad');
    like $t->body, qr/no saml_idp named 'nope'.*okta, entra/,
        'an unknown provider croaks naming the configured ones';
}

done_testing();
