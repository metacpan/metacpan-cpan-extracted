package Punk::Plugin::Challenge;

use 5.010;
use strict;
use warnings;
use Punk::Challenge ();    # one dist, one bootstrap: the plugin lives in its bundle

our $VERSION = '0.01';

1;

__END__

=head1 NAME

Punk::Plugin::Challenge - a proof of work challenge and a clearance cookie, with no third party

=head1 SYNOPSIS

    package MyApp;
    use Punk;
    use Punk::Plugin::Challenge;

    proxy;                                       # if there is one in front

    plugin 'Challenge' => {
        secret => secret('challenge.key'),
    };

    # everyone proves themselves before the login form
    challenge for => '/login', always => 1;

    # the rest of the site: past sixty requests a minute, a puzzle, not a 429
    challenge for => '/', after => { limit => 60, window => 60 };

    # one scope, as a guard, after the auth guard so a stranger sees login
    under('/account' => auth_guard)->under('' => challenge_guard(bits => 18));

=head1 DESCRIPTION

L<Punk::RateLimit> has two answers for a caller it does not like: a C<429>,
and C<block_ip>. Both refuse. This is the third answer: prove you are a
browser before anything is spent on you. The browser solves a proof-of-work
puzzle in JavaScript and is handed a signed clearance cookie that says it
did. No outbound call, no script from a foreign origin, no hole in a CSP
policy, nothing a privacy page has to explain.

B<Proof of work is a cost, not a wall.> A puzzle that takes a phone half a
second takes a GPU farm nothing. What it changes is the economics: a scraper
that was making ten thousand requests a minute for free now pays a CPU-second
for every clearance, and a clearance is bound to a network prefix so it
cannot be solved once and shared with a botnet. A program that solves the
puzzle is cleared exactly as a person is. Combined with C<rate_limit>, which
sets the ceiling per clearance, it turns "free" into "expensive". It does not
turn "possible" into "impossible".

Nothing here asks a human to read distorted text or find the traffic lights.
A screen reader user and a sighted one pass the same way, by waiting a
moment. That is the reason to build this rather than wrap somebody else's
widget.

=head1 THE KEYWORD

    challenge for    => '/api',          # path prefix; default '/'
              always => 1,               # every request without a clearance
              after  => { limit => 60, window => 60 },   # or: past this rate
              bits   => 18,              # this rule's difficulty
              tag    => 'api';           # counter namespace for `after`

A rule. Under C<always>, every request under the prefix without a clearance
is answered with the challenge. Under C<after>, requests are counted per
subject and the challenge is the answer past C<limit> in C<window> seconds:
a rate limit that degrades to a cost rather than a refusal, so the human who
happened to be behind the same NAT as the scraper proves it in a moment
while the scraper pays. A rule has C<always> or C<after>, not both; a rule
with neither croaks, because a rule that does nothing is a mistake and not a
default.

Declared more than once for layered rules, as C<rate_limit> is. Rules are
walked in declaration order and the first whose prefix covers the path
decides; nothing below it is consulted. A prefix covers itself and the paths
under it, so C</api> covers C</api/x> and not C</apiary>. The plugin's own
routes and every C<exempt> prefix are skipped first, and static files never
reach a rule at all: nobody solves a puzzle to fetch a stylesheet.

C<bits> unsaid is the plugin's default at the moment of the request, so a
rule declared above the C<plugin> line follows the difficulty set below it.
C<tag> unsaid is the prefix.

A rule runs after routing and ahead of a route's guards, so its challenge
is answered before C<auth_guard> has seen the request, and a path no route
matches is a C<404> that no rule ever sees. The challenge page discloses
nothing about the resource: it is the same page for a signed-in user and a
stranger, and a request the guard would have refused is refused one round
trip later, after the client has paid. Where an application does not want
that, L</THE GUARD> is the tool.

B<C<after> is inert without Hyperman.> The counter lives in Hyperman's
shared arena and fails open without one: every request is within the
limit, and an C<after> rule never fires. That is the right failure for a
rate limiter and a surprising one for a challenge, so an application with
an C<after> rule and no arena is told so once, at warning level, naming
the rule: at startup when Hyperman cannot be loaded at all, and otherwise
at the first request under the rule, because the arena exists only inside
a running Hyperman and a server that merely has Hyperman installed does
not have one. Serve with C<plackup -s Hyperman>, or Hyperman's own
C<run>, for C<after>. An C<always> rule works on any PSGI server.

=head1 THE GUARD

    under '/register' => challenge_guard;
    under('/account' => auth_guard)->under('' => challenge_guard(bits => 18));

An ordinary guard, in the C<auth_guard> shape: a reference return
short-circuits with the challenge, anything else continues. It exists
because a rule runs ahead of a route's guards, so a rule's challenge is
answered before C<auth_guard> has looked at the request. Where a stranger
should see the login page and not a puzzle, place the guard after
C<auth_guard>: C<under> takes one guard, and a second is a nested scope
with an empty prefix, whose guards run outer to inner, as above. Where the
order does not matter, write the rule.

C<bits> is the only option, validated at the declaration: a guard asking
for more than 22 is a site nobody can enter, and the first request is the
wrong time to learn that.

=head1 HELPERS

=over

=item $c->challenge_cleared(%opts)

True when the request carries a valid clearance at or above C<bits>, the
plugin's default unless given. For a handler that gates one expensive
branch itself.

=item $c->challenge_issue(%opts)

A fresh puzzle string for this request's subject, with C<bits> overridable.
What the rule and the guard use, exposed for an application rendering its
own page.

=item $c->challenge_clear(%opts)

Set the clearance cookie on the response, at C<bits>, and return its value.
What the verify route does after a correct solution, exposed for an
application that has decided on other evidence - a signed-in user, a paid
account - that this client has done enough.

=back

Each croaks on an unknown option. All three need the C<plugin> line, and
say so when it is missing.

=head1 THE ANSWER

A request that must prove itself is answered on its C<Accept>. A browser,
one that names C<text/html>, gets the interstitial: a C<503> carrying the
puzzle in a data attribute, C<Cache-Control: no-store> and C<Retry-After:
0>. C<503> and not C<403> or C<429>, deliberately: a search engine that
trips an C<after> rule on a crawl should come back later, and C<503> is the
code that says so; C<403> is the code that says "drop this URL from the
index".

Anything else, including a client with no preference, gets a C<403> with a
JSON body and a header; L</FOR API CLIENTS> has the shape. Every answer
carries C<Vary: Accept>.

The interstitial says "One moment" and nothing else, and shows no progress:
a bar that fills over half a second is noise, and one that fills over five
seconds on a slow phone is an invitation to tap something. The page changes
when it is done. It carries C<noindex>, because it is served at the URL of
whatever was requested, and a crawler that did index it would index "One
moment" as the page's content.

C<render> replaces it with the application's own page, receiving the
puzzle, the bits, the verify URL, the solver URL and the return path in a
hashref, as a coderef or the name of a context method.

=head1 OPTIONS

    plugin 'Challenge' => {
        secret     => '...',            # REQUIRED; a list to rotate: [ $new, $old ]
        prefix     => '/challenge',     # the verify route and the asset
        bits       => 16,               # default difficulty: leading zero bits
        ttl        => 3600,             # how long a clearance holds, seconds
        puzzle_ttl => 300,              # how long an issued puzzle may be solved
        bind       => 'prefix',         # prefix | ip | none
        cookie     => '_clearance',
        exempt     => [],               # path prefixes never challenged
        render     => undef,            # the interstitial: a coderef or a context method name
        assets     => 1,                # serve challenge.js
    };

An unknown option croaks, naming what was available. A misspelled option is
a setting that silently did not apply, and C<bitz =E<gt> 20> would leave the
whole site at the default while the operator believed it hardened.

=over

=item secret

Required, and never generated for you. The convenient thing is to mint one
when none is configured, and it is wrong: a pool of workers would each mint
their own, and a clearance issued by one would be refused by every other. The
visible symptom is a challenge page that comes back one time in four after
it was solved, which nobody connects to the configuration. Without it the
C<plugin> line croaks and names C<punk challenge key>, which prints one.

Not the session secret, even though one is usually to hand. The two rotate
for different reasons on different days, and a clearance surviving a session
secret rotation is what you want.

A list rotates: puzzles and clearances are issued with the first and
verified against each in turn. Rotation costs one extra check per stale
cookie for one C<ttl>, and then nothing.

=item prefix

Where the verify route and the solver script live. A rooted path; a trailing
slash is dropped. Anything else croaks.

=item bits

The default difficulty, as leading zero bits of the solution's hash, from 1
to 22; outside that it croaks. See L</DIFFICULTY> for what a number costs.

=item ttl

How long a clearance holds, in seconds. At least one.

=item puzzle_ttl

How long an issued puzzle may be solved, in seconds. A puzzle that sat in a
tab for an hour is stale, and the client gets a new one. At least one.

=item bind

What a puzzle and a clearance are tied to. C<prefix>, the default, is the
client's /24 for IPv4 and /64 for IPv6, so a phone moving within a carrier's
allocation keeps its clearance; the cost is that an office behind one NAT
shares one, which C<rate_limit> still bounds. C<ip> is the exact address.
C<none> is the empty string, and B<under C<none> a clearance solved once can
be shared with every host on the internet>; it is there for the deployment
that genuinely cannot see client addresses, and it is weaker. Anything else
croaks.

=item cookie

The clearance cookie's name. A cookie name, or a croak.

=item exempt

Path prefixes that are never challenged, whatever the rules say. Each must be
a rooted path.

=item render

Replaces the shipped interstitial: a coderef, or the name of a context
method, called with the context and a hashref of C<puzzle>, C<bits>,
C<verify>, C<script> and C<to>, and returning the response. The values are
not escaped, because the renderer knows its own context. Anything else
croaks.

=item assets

Whether the solver script is served under C<prefix>. Off for an application
that bundles it itself, which then answers for the URL the page references.

=back

=head1 DIFFICULTY

A solution is a nonce whose hash begins with C<bits> zero bits, so the
expected work is C<2 ** bits> hashes, and what a number costs depends on
who is paying. Measured with the shipped solver under node 26 on an Apple
M5 laptop, which hashes about 1.4 million times a second:

    bits    hashes       laptop
    12      4,096        3 ms
    16      65,536       50 ms
    18      262,144      0.2 s
    20      1,048,576    0.75 s
    22      4,194,304    3 s

The phone column is not printed because it has not been measured; the
release checklist measures it on real devices, and a slow phone is expected
to be several times slower than the laptop. B<The cost you set is paid by
the slowest phone of your slowest legitimate user, and by a bot at whatever
price a GPU charges.> Sixteen is the default. Nothing above 22 is accepted,
because at 24 a slow phone is a minute and the site is closed.

Every test in the distribution solves at eight bits, so that a loaded
machine cannot turn a test into a timeout, and nothing in it asserts on how
long a solve took.

=head1 CLEARANCE

A correct solution earns a clearance: a signed value carrying its expiry
and the difficulty that was solved, set as a cookie:

    Set-Cookie: _clearance=v1...; Path=/; Max-Age=3600; HttpOnly; SameSite=Lax; Secure

C<Secure> when the request came over https, which C<proxy> also gets right.
It is bound to the subject that solved it - the /24 or /64 under the default
C<bind> - and holds for C<ttl>. It is also accepted from an C<X-Clearance>
header, for a client without a cookie jar.

The difficulty is in the clearance so that raising a rule's C<bits>
invalidates the clearances that were bought cheaper, immediately, with no
state and no rotation: a clearance solved at sixteen does not pass a guard
asking for eighteen, and the client is told the higher number.

There is no replay set, and this is deliberate. A solved puzzle presented
twice within C<puzzle_ttl> is accepted twice, and that buys the presenter a
second clearance for the same subject with the same expiry as the one it
already holds, which is nothing. What people worry about, a clearance shared
across a botnet, C<bind> defends: a thousand hosts on a thousand prefixes
need a thousand solutions, each of which is the CPU-second the design
charges.

=head1 FOR API CLIENTS

A client that does not name C<text/html> gets this:

    HTTP/1.1 403 Forbidden
    X-Challenge: v1.1725600000.16.k3x-2f.Zm9vYmFy...
    Content-Type: application/json

    { "error": "challenge",
      "challenge": { "puzzle": "v1...", "bits": 16,
                     "verify": "/challenge/verify",
                     "header": "X-Challenge-Response" } }

The JSON names the header and the route so a client library does not have
to carry them as constants. Two ways to proceed:

=over

=item *

Solve, C<POST> the solution to C<verify> as C<{ "solution": "..." }>, and
keep the C<Set-Cookie>, or the same value from the C<{ "clearance": "..." }>
body, presenting it as C<X-Clearance> on every request. One solution per
C<ttl>.

=item *

Solve, and present the solution itself as C<X-Challenge-Response> on the
retried request. No cookie, no state on the client, and one solution per
C<puzzle_ttl>, since the same solution is accepted for that long. A client
that would rather burn CPU than keep a cookie can.

=back

Both are checked the same way. Neither grants anything the cookie does not.

From a shell, C<punk challenge solve> is the solver:

    $ curl -si https://example.com/api/x | grep X-Challenge
    X-Challenge: v1.1725600000.16.k3x-2f.Zm9vYmFy...
    $ punk challenge solve v1.1725600000.16.k3x-2f.Zm9vYmFy...
    v1.1725600000.16.k3x-2f.Zm9vYmFy....48213
    $ curl -si -H 'X-Challenge-Response: v1....48213' https://example.com/api/x

In a page, C<window.PunkChallenge.solve(puzzle)> returns a promise of the
solution string, for a single-page application handling the C<403> from
its own C<fetch> calls; it is the same code the interstitial runs.

=head1 ROUTES

Two, under C<prefix>:

    GET  /challenge/challenge.js    the solver
    POST /challenge/verify          a solution in; a clearance out

The solver is served with C<Cache-Control: public, max-age=31536000,
immutable>, and the page references it with the release version in its
query, so a new release is a new URL and an old cache is never wrong.
C<assets =E<gt> 0> leaves it out, for an application that bundles the file
itself.

There is no page route. The interstitial is rendered by the rule or the
guard that demanded it, with the puzzle already in it, so the browser makes
one request and gets a page it can start solving.

C<verify> accepts a form, with C<solution> and C<to>, or JSON, as
C<{ "solution": "..." }>, decided by C<Content-Type>. On a correct solution
for this request's subject it sets the clearance cookie at the puzzle's
difficulty, and then a form is a C<303> to C<to> when that is a same-origin
path and to C</> when it is anything else, and JSON is a C<200> with
C<{ "clearance": "..." }>. On anything else it answers as a rule does: a
fresh challenge, the page for a browser and the JSON for a program. A wrong
solution costs the client a new solve, not a lockout; there is no counter
of failures, because a failure is already the client's CPU wasted. The body
is capped well above the size of any solution.

=head1 BEHIND A REVERSE PROXY

B<If this application runs behind nginx, an ELB or a CDN, declare
L<Punk/proxy> or this plugin is wrong in a way that is worse than not
having it.>

Without C<proxy>, C<REMOTE_ADDR> is the proxy on every request, so every
client on the internet is one subject. Under C<after>, the whole site trips
at once. Under C<always>, B<one visitor solves the puzzle and the clearance
is valid for everybody>, because the clearance is bound to the subject and
there is one subject. A challenge that a scraper's first request clears for
the rest of the botnet is worse than no challenge, because the operator
believes it is working.

Declare C<proxy> and nothing here changes: the plugin reads C<REMOTE_ADDR>,
which that keyword has already made correct. There is no option to read a
forwarded header here instead, and none will be added; the reason is in
L<Punk::RateLimit>'s own warning, and it is that nothing validates the
header.

=head1 SEARCH ENGINES

A challenge is a wall to any crawler, since none of them run the solver.
That is what C<always> on a public page means: do not put one on a page you
want indexed. C<after> is the right shape for public pages: a well-behaved
crawler paces itself under any sane limit, and one that does not gets a
C<503> and comes back slower, which is what C<503> is for.

There is no option to let a crawler through by user agent, because the user
agent is a string anyone can send, and offering the option would be
offering the bypass.

=head1 WITH CSP

The interstitial has no inline script and no inline style. Its parameters
travel in data attributes and the solver is a same-origin file, so the page
works under L<Punk::Plugin::CSP>'s default policy without a nonce and
without this plugin knowing that one exists. The solver runs its work in a
Worker built from a Blob, and falls back to running inline where a Worker
cannot be had.

=head1 WITH CSRF

C<verify> is a C<POST> without a session that changes nothing but its own
cookie, so it is not a CSRF target and C<csrf> does not check it. The plugin
puts its own prefix on the exempt list at compile, whichever side of the
C<plugin> line the C<csrf> keyword sat on; nothing has to be configured.

=head1 WHAT THIS DOES NOT DO

Not a bot detector: it has no opinion about who is asking, only about
whether they paid. Not a CAPTCHA: nothing here distinguishes a human from a
program, and a program that solves the puzzle is cleared exactly as a person
is. Not a replacement for C<rate_limit>: it is the thing you put in front of
the limit so the limit is spent on paid-for requests. Fingerprinting,
behavioural scoring and reputation lists all belong above it, and a plugin
that grew them would be the hosted service it was built to avoid.

Not escalation, either. Difficulty that rises with abuse is easy to build
on the same counter, and its failure mode is that the C<bits> a client is
asked for then depend on a counter the client can influence, so an attacker
raises the difficulty for everybody behind its own NAT. Two rules with two
difficulties is the way to say "the API costs more".

=head1 SEE ALSO

L<Punk::Challenge>, L<Punk::Challenge::Token>, L<Punk::Challenge::Solver>,
L<Punk::Command::Challenge>.

L<Punk::RateLimit>, L<Punk::Plugin::CSP>, L<Punk::CSRF>, L<Punk/proxy>,
L<Punk>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
