#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Punk::Test;

# The Origin check on the WebSocket handshake.
#
# An upgrade is a GET carrying the user's cookies that gets no preflight and
# is not covered by the same-origin policy, so without this check any page
# anywhere can open an authenticated socket. CORS cannot stand in for it:
# CORS refuses nothing, it omits headers and leaves the decision to a browser
# that does not make one for ws://.
#
# There is no live server here and none is needed: a refused upgrade answers
# 403 before anything touches the socket, and an allowed one runs on to the
# 501 that says this server cannot upgrade. So 403 means refused and 501
# means the check passed - the two are never ambiguous.

my $KEY = 'dGhlIHNhbXBsZSBub25jZQ==';        # the RFC 6455 example key

sub upgrade {
    my (%h) = @_;
    return {
        'Upgrade'               => 'websocket',
        'Connection'            => 'Upgrade',
        'Sec-WebSocket-Key'     => $KEY,
        'Sec-WebSocket-Version' => 13,
        %h,
    };
}

{
    package OrgApp;
    use Punk;

    my $cb = sub { my ($c, $ws) = @_; return };

    websocket '/open'   => $cb;
    websocket '/any'    => $cb, { origin => 0 };
    websocket '/listed' => $cb, { origin => [ 'app.example.com',
                                              '*.trusted.tld',
                                              'dev.local:3000' ] };
    websocket '/one'    => $cb, { origin => 'Partner.Example' };
    websocket '/code'   => $cb, { origin => sub {
        my ($c, $origin) = @_;
        return $origin =~ m{^https://ok\.};
    } };
    get '/plain' => sub { $_[0]->text('plain ok') };
}

my $t = Punk::Test->new('OrgApp');

# ---- the default: same origin, and nothing else ------------------------------

$t->get_ok('/open', headers => upgrade(), name => 'no Origin at all')
  ->status_is(501,
    'a client that sends no Origin is not a browser and is not refused');

$t->get_ok('/open', headers => upgrade(Origin => 'http://localhost'),
           name => 'Origin matching Host')
  ->status_is(501, 'the page the application itself served may connect');

$t->get_ok('/open', headers => upgrade(Origin => 'https://evil.example'),
           name => 'a stranger')
  ->status_is(403, 'a page on another origin may not');
$t->content_like(qr/origin not allowed/, 'and is told why');

$t->get_ok('/open', headers => upgrade(Origin => 'http://localhost:8080'),
           name => 'another port')
  ->status_is(403, 'a different port is a different origin');

$t->get_ok('/open', headers => upgrade(Origin => 'null'),
           name => 'an opaque origin')
  ->status_is(403,
    'null - a sandboxed frame, a data: URL, a redirect - is refused');

$t->get_ok('/open', headers => upgrade(Origin => 'https://evil.example/x'),
           name => 'a URL where an origin belongs')
  ->status_is(403, 'an origin has no path');

$t->get_ok('/open', headers => upgrade(Origin => 'https://ev il.example'),
           name => 'a space in the host')
  ->status_is(403, 'a byte that cannot be in a hostname is refused');

$t->get_ok('/open', headers => upgrade(Origin => 'HTTP://LOCALHOST'),
           name => 'case')
  ->status_is(501, 'a host is compared case-insensitively');

# The check is only the handshake's; ordinary requests are untouched.
$t->get_ok('/plain', headers => { Origin => 'https://evil.example' })
  ->status_is(200, 'an ordinary GET from any origin is not the WS check');

# ---- origin => 0, the way out ------------------------------------------------

$t->get_ok('/any', headers => upgrade(Origin => 'https://evil.example'),
           name => 'origin => 0')
  ->status_is(501, 'a route that says 0 serves any origin');

# ---- a list ------------------------------------------------------------------

$t->get_ok('/listed', headers => upgrade(Origin => 'https://app.example.com'),
           name => 'a listed host')
  ->status_is(501, 'a named origin connects');

$t->get_ok('/listed', headers => upgrade(Origin => 'https://a.trusted.tld'),
           name => 'a wildcard')
  ->status_is(501, '*.trusted.tld covers a label in front');

$t->get_ok('/listed', headers => upgrade(Origin => 'https://trusted.tld'),
           name => 'the bare suffix')
  ->status_is(403, 'and not the suffix on its own');

$t->get_ok('/listed', headers => upgrade(Origin => 'http://dev.local:3000'),
           name => 'a port in the entry')
  ->status_is(501, 'an entry naming a port matches that port');

$t->get_ok('/listed', headers => upgrade(Origin => 'http://dev.local:3001'),
           name => 'the wrong port')
  ->status_is(403, 'and not another');

$t->get_ok('/listed', headers => upgrade(Origin => 'https://other.example'),
           name => 'unlisted')
  ->status_is(403, 'an origin nobody named is refused');

$t->get_ok('/listed', headers => upgrade(Origin => 'http://localhost'),
           name => 'same origin still')
  ->status_is(501, 'a list adds to same-origin, it does not replace it');

# ---- the one-string form -----------------------------------------------------

$t->get_ok('/one', headers => upgrade(Origin => 'https://partner.example'),
           name => 'a bare string')
  ->status_is(501, 'one origin need not be written as a list');

$t->get_ok('/one', headers => upgrade(Origin => 'https://other.example'),
           name => 'not that string')
  ->status_is(403, 'and it is still the only one');

# ---- a coderef ---------------------------------------------------------------

$t->get_ok('/code', headers => upgrade(Origin => 'https://ok.example'),
           name => 'the coderef says yes')
  ->status_is(501, 'a coderef decides for itself');

$t->get_ok('/code', headers => upgrade(Origin => 'https://no.example'),
           name => 'the coderef says no')
  ->status_is(403, 'and refusing is a 403 like any other');

# ---- the canonical host and its allowlist ------------------------------------

{
    package HostApp;
    use Punk;
    host 'https://example.com', allow => [ '*.example.com' ];
    websocket '/s' => sub { return };
}

my $h = Punk::Test->new('HostApp');

$h->get_ok('/s', headers => upgrade(Origin => 'https://example.com',
                                    Host   => 'example.com'),
           name => 'the canonical origin')
  ->status_is(501, 'the origin the application declared connects');

$h->get_ok('/s', headers => upgrade(Origin => 'https://tenant.example.com',
                                    Host   => 'example.com'),
           name => 'an allowed host')
  ->status_is(501,
    'a host that may stand in for the canonical one may talk back to it');

$h->get_ok('/s', headers => upgrade(Origin => 'https://evil.example',
                                    Host   => 'example.com'),
           name => 'a stranger against a declared host')
  ->status_is(403, 'and nothing else does');

$h->get_ok('/s', headers => upgrade(Origin => 'http://example.com',
                                    Host   => 'other.example'),
           name => 'the declared scheme')
  ->status_is(403,
    'the canonical origin is matched with its scheme, which was declared');

# ---- what the keyword refuses at boot ----------------------------------------

for my $case (
    [ 'undef'        => 'undef',            qr/websocket origin is undef/ ],
    [ 'a bad entry'  => "[ 'not a host' ]", qr/is not a hostname/         ],
    [ 'a bad string' => "'http://x.com'",   qr/is not a hostname/         ],
) {
    my ($what, $spell, $want) = @$case;
    my $n = $what; $n =~ s/\W+/_/g;
    eval qq{
        package Bad_$n;
        use Punk;
        websocket '/x' => sub { 1 }, { origin => $spell };
        1;
    };
    like($@, $want, "$what croaks at the keyword");
}

{
    my $ok = eval q{
        package GoodOpt;
        use Punk;
        websocket '/x' => sub { 1 }, { origin => 0, protocols => ['v1'] };
        1;
    };
    ok($ok, 'origin sits beside the options that were already there') or diag $@;
}

# ---- Upgrade and Connection are token lists ------------------------------------
{
    my $o = Punk::Test->new('OrgApp');
    my @no = ([ Upgrade => 'notwebsocket' ],
              [ Upgrade => 'websocketx' ],
              [ Upgrade => 'web socket' ],
              [ Upgrade => '' ],
              [ Connection => 'noupgrade' ],
              [ Connection => 'keep-alive' ]);
    for my $case (@no) {
        $o->get_ok('/any', headers => upgrade(@$case),
                   name => "$case->[0]: '$case->[1]'")
          ->status_is(400, "$case->[0]: '$case->[1]' is not a websocket upgrade");
    }
    my @yes = ([ Upgrade => 'WebSocket' ],
               [ Upgrade => 'h2c, websocket' ],
               [ Upgrade => 'websocket/13' ],
               [ Connection => 'keep-alive, Upgrade' ],
               [ Connection => 'UPGRADE ,keep-alive' ]);
    for my $case (@yes) {
        $o->get_ok('/any', headers => upgrade(@$case),
                   name => "$case->[0]: '$case->[1]'")
          ->status_isnt(400, "$case->[0]: '$case->[1]' is");
    }
}

done_testing;
