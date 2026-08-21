#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Punk::Plugin::Sitemap;

# Which of an application's routes are actually URLs.
#
# Punk compiles every route at boot, so the application holds a complete list
# of what it serves and a sitemap is that list with a filter over it. This is
# the filter, and the assertions come in PAIRS: a filter that excludes
# everything passes "the guarded route is absent" on its own, so every
# exclusion is tested beside the inclusion it must not have taken with it.

# ---- the whole claim of phase 1 ----------------------------------------------
{
    package SiteApp;
    use Punk;

    plugin 'Sitemap' => { base => 'https://example.com' };

    get  '/'            => sub { $_[0]->text('home') };
    get  '/about'       => sub { $_[0]->text('about') };
    get  '/users/:id'   => sub { $_[0]->text('user') };      # a capture
    get  '/files/*path' => sub { $_[0]->text('file') };      # a splat
    post '/orders'      => sub { $_[0]->text('order') };     # not a GET
    get  '/admin'       => sub { $_[0]->text('admin') },
                           { sitemap => 0 };                 # opted out

    # guarded, and NOT opted out by hand - the plugin has to see the guard
    my $acct = under '/account' => sub { return };
    $acct->get('/settings' => sub { $_[0]->text('settings') });

    package main;
    SiteApp->to_app;
    my @p = Punk::Plugin::Sitemap->_paths(SiteApp->punk_app);
    my %in = map { $_ => 1 } @p;

    # the inclusions, so an "exclude everything" filter cannot pass
    ok($in{'/'},      'a static GET route is listed');
    ok($in{'/about'}, 'and so is another');

    ok(!$in{'/users/:id'},
        'a route with a CAPTURE is not listed - it names a shape, not a page, '
      . 'and the ids are not something the route table knows');
    ok(!$in{'/files/*path'}, 'nor is a splat');
    ok(!$in{'/orders'},
        'a POST is not listed - a crawler has no business fetching it');
    ok(!$in{'/admin'}, 'and a route that said sitemap => 0 is not listed');

    is_deeply(\@p, [ sort @p ],
        'the list is sorted, so two boots of one application produce a '
      . 'byte-identical sitemap and a deploy that changed nothing does not '
      . 'move its ETag');
}

# ---- the assertion an external tool could not make ----------------------------
# A page behind auth_guard listed in a sitemap is a crawler fetching a login
# redirect on a schedule, forever. Every hand-written sitemap has a few,
# because the person writing it is working from memory. Punk does not have to
# remember: `under($prefix, $guard)` copies the guard chain into every route
# declared inside it, so the filter can see it.
#
# The PAIR is the point. The same path, declared the same way, differing only
# in the guard.
{
    package GuardedApp;
    use Punk;
    plugin 'Sitemap' => { base => 'https://example.com' };
    my $g = under '/account' => sub { return };
    $g->get('/settings' => sub { $_[0]->text('x') });

    package UnguardedApp;
    use Punk;
    plugin 'Sitemap' => { base => 'https://example.com' };
    my $u = under '/account';
    $u->get('/settings' => sub { $_[0]->text('x') });

    package main;
    GuardedApp->to_app;
    UnguardedApp->to_app;

    my %guarded   = map { $_ => 1 } Punk::Plugin::Sitemap->_paths(GuardedApp->punk_app);
    my %unguarded = map { $_ => 1 } Punk::Plugin::Sitemap->_paths(UnguardedApp->punk_app);

    ok(!$guarded{'/account/settings'},
        'A GUARDED ROUTE IS ABSENT, and nobody said so - the guard chain is '
      . 'on the record, so the plugin sees what a human writing a sitemap by '
      . 'hand has to remember');
    ok($unguarded{'/account/settings'},
        'and the SAME path without the guard is present, so the exclusion is '
      . 'the guard and not the prefix');
}

# ---- the guard is the ONE exclusion an application can argue with -------------
# A scope guard may be an authentication check or an ordinary filter, and Punk
# cannot read its intent, so the plugin assumes the first - which is the safe
# direction and is occasionally wrong. `sitemap => 1` is how a page says it is
# public anyway.
#
# Method and shape are NOT overridable: a POST is not a page and /users/:id is
# not a URL, so sitemap => 1 on either is a mistake rather than an instruction.
{
    package OverrideApp;
    use Punk;
    plugin 'Sitemap' => { base => 'https://example.com' };

    my $s = under '/docs' => sub { return };   # a filter, not auth
    $s->get('/public' => sub { $_[0]->text('x') }, { sitemap => 1 });
    $s->get('/hidden' => sub { $_[0]->text('x') });

    post '/nope'      => sub { $_[0]->text('x') }, { sitemap => 1 };
    get  '/thing/:id' => sub { $_[0]->text('x') }, { sitemap => 1 };

    package main;
    OverrideApp->to_app;
    my %in = map { $_ => 1 } Punk::Plugin::Sitemap->_paths(OverrideApp->punk_app);

    ok($in{'/docs/public'},
        'sitemap => 1 overrides an inferred guard exclusion');
    ok(!$in{'/docs/hidden'},
        'and its sibling under the same guard stays out');
    ok(!$in{'/nope'},
        'sitemap => 1 does NOT make a POST a page');
    ok(!$in{'/thing/:id'},
        'nor does it make a pattern a URL - those are mistakes, not '
      . 'instructions');
}

# ---- base is required, and it is configuration --------------------------------
# The sitemap protocol wants absolute URLs. Taking the host from the request
# would let `Host: evil.example` produce a file naming that host for every
# page on the site - delivered to search engines, and invisible to the owner,
# whose own request produces a correct file.
{
    my $err = do { local $@; eval {
        package NoBaseApp;
        use Punk;
        plugin 'Sitemap';
        get '/' => sub { $_[0]->text('x') };
        NoBaseApp->to_app;
    }; $@ };
    like($err, qr/\Q`base` is required\E/,
        'starting without a base croaks, the way session refuses to start '
      . 'without a secret');
    like($err, qr/somebody else's hostname/,
        'and the message says WHY rather than only what');

    {
        package BaseApp;
        use Punk;
        plugin 'Sitemap' => { base => 'https://example.com' };
        get '/' => sub { $_[0]->text('x') };
        package main;
        BaseApp->to_app;
        is(Punk::Plugin::Sitemap->_base(BaseApp->punk_app),
            'https://example.com', 'a configured base is kept as given');
    }
}

# ---- adding a fourth route option did not open the gate ----------------------
{
    my $err = do { local $@; eval {
        package BadOptApp;
        use Punk;
        get '/' => sub { $_[0]->text('x') }, { nonsuch => 1 };
        BadOptApp->to_app;
    }; $@ };
    like($err, qr/unknown route option 'nonsuch'/,
        'an unknown route option still croaks naming itself - `sitemap` was '
      . 'added to the known list, not the check removed');
}

# ---- phase 2: the document ---------------------------------------------------
# Rendered once at to_app and served from memory: the route half changes only
# when the routes do, which is never while the process runs.
{
    package DocApp;
    use Punk;
    plugin 'Sitemap' => { base => 'https://example.com/' };   # trailing slash
    get '/'      => sub { $_[0]->text('x') };
    get '/about' => sub { $_[0]->text('x') };

    package main;
    my $app = DocApp->to_app;
    my $doc = Punk::Plugin::Sitemap->_doc(DocApp->punk_app);

    like($doc, qr/^<\?xml version="1\.0" encoding="UTF-8"\?>/, 'an XML prolog');
    like($doc, qr{<urlset xmlns="http://www\.sitemaps\.org/schemas/sitemap/0\.9">},
        'and the urlset namespace the protocol requires');
    like($doc, qr{<loc>https://example\.com/</loc>}, 'the root page is a URL');
    like($doc, qr{<loc>https://example\.com/about</loc>}, 'and so is /about');

    unlike($doc, qr{//about},
        'a trailing slash on the base does not double the one every path '
      . 'starts with - https://x//about is a different URL to a crawler');

    unlike($doc, qr{sitemap\.xml},
        'the sitemap does not list ITSELF, which would be noise a crawler '
      . 'follows');

    is(Punk::Plugin::Sitemap->_parts(DocApp->punk_app), 1,
        'one part, so there is no index - an index wrapping a single sitemap '
      . 'is a second fetch for nothing');

    my $r = $app->({ REQUEST_METHOD => 'GET', PATH_INFO => '/sitemap.xml',
                     SCRIPT_NAME => '', QUERY_STRING => '', SERVER_NAME => 'l',
                     SERVER_PORT => 80, 'psgi.url_scheme' => 'http',
                     'psgi.input' => undef, 'psgi.errors' => \*STDERR });
    is($r->[0], 200, 'and it is served');
    my %hdr = @{ $r->[1] };
    is($hdr{'Content-Type'}, 'application/xml; charset=utf-8', 'as XML');
    is($hdr{'Content-Length'}, length($r->[2][0]),
        'with a Content-Length that matches the bytes');
    is($r->[2][0], $doc, 'and the bytes are the ones built at boot');
}

# ---- encoding, then escaping, in that order ----------------------------------
# Two different jobs. A path holding a space has to be percent-encoded to be a
# URL at all; escaping alone would produce a well-formed document containing an
# invalid URL. One unescaped `&` makes the document not well-formed, and a
# crawler rejects ALL of it rather than the offending entry.
{
    package EncApp;
    use Punk;
    plugin 'Sitemap' => { base => 'https://example.com' };
    get '/a b'   => sub { $_[0]->text('x') };
    get '/r&d'   => sub { $_[0]->text('x') };
    get '/caf'.chr(0xC3).chr(0xA9) => sub { $_[0]->text('x') };   # café, UTF-8

    package main;
    EncApp->to_app;
    my $doc = Punk::Plugin::Sitemap->_doc(EncApp->punk_app);

    like($doc, qr{<loc>https://example\.com/a%20b</loc>},
        'a space is percent-encoded');
    like($doc, qr{<loc>https://example\.com/r%26d</loc>},
        'and so is an ampersand, which is why the escaper rarely fires on '
      . 'this half');
    like($doc, qr{<loc>https://example\.com/caf%C3%A9</loc>},
        'and a non-ASCII byte, which also makes the whole document ASCII - '
      . 'so a path that is not valid UTF-8 cannot make it unparseable');

    unlike($doc, qr/&(?!amp;|lt;|gt;|quot;|apos;)/,
        'no bare ampersand survives anywhere in the document');

    # the assertion that matters: a real parser accepts it
    SKIP: {
        skip 'XML::Parser not installed', 1 unless eval { require XML::Parser; 1 };
        my $ok = eval { XML::Parser->new(Style => 'Tree')->parse($doc); 1 };
        ok($ok, 'and a real XML parser accepts the document') or diag $@;
    }
}

# ---- the protocol's limits ---------------------------------------------------
# 50,000 URLs and 50MB uncompressed, and past either one crawlers reject the
# file - the WHOLE file, not the excess. Tested at the real cap rather than a
# lowered one: 60,000 routes boot and render in under two tenths of a second.
{
    package BigApp;
    use Punk;
    plugin 'Sitemap' => { base => 'https://example.com' };
    get "/p$_" => sub { $_[0]->text('x') } for 1 .. 60_000;

    package main;
    BigApp->to_app;
    my $app_h = BigApp->punk_app;

    is(Punk::Plugin::Sitemap->_parts($app_h), 2,
        '60,000 URLs split into TWO parts rather than one file every crawler '
      . 'would reject');

    my $one = Punk::Plugin::Sitemap->_doc($app_h, 1);
    my $two = Punk::Plugin::Sitemap->_doc($app_h, 2);
    is(scalar(() = $one =~ /<url>/g), 50_000, 'the first part holds the cap');
    is(scalar(() = $two =~ /<url>/g), 10_000, 'and the rest are in the second');
    like($one, qr/<\/urlset>\s*\z/, 'each part is closed properly');
    like($two, qr/<\/urlset>\s*\z/, 'both of them');

    my $idx = Punk::Plugin::Sitemap->_doc($app_h);
    like($idx, qr/<sitemapindex/,
        'and /sitemap.xml is now an INDEX rather than a urlset');
    like($idx, qr{<loc>https://example\.com/sitemap/1\.xml</loc>},
        'naming the first part');
    like($idx, qr{<loc>https://example\.com/sitemap/2\.xml</loc>},
        'and the second');
}

# ---- a part nobody generated is a 404 ----------------------------------------
{
    package SmallApp;
    use Punk;
    plugin 'Sitemap' => { base => 'https://example.com' };
    get '/' => sub { $_[0]->text('x') };

    package main;
    my $app = SmallApp->to_app;
    my $hit = sub {
        $app->({ REQUEST_METHOD => 'GET', PATH_INFO => $_[0], SCRIPT_NAME => '',
                 QUERY_STRING => '', SERVER_NAME => 'l', SERVER_PORT => 80,
                 'psgi.url_scheme' => 'http', 'psgi.input' => undef,
                 'psgi.errors' => \*STDERR });
    };
    is($hit->('/sitemap/1.xml')->[0], 200, 'part 1 exists and is served');
    is($hit->('/sitemap/9.xml')->[0], 404,
        'a part nobody generated is a 404 and not an empty document - a '
      . 'crawler following a stale index should be told it is gone');
}

# ---- phase 3: the dynamic half -----------------------------------------------
# The route table cannot know ids, so /users/:id contributes nothing on its
# own. The `sitemap` keyword is where the application supplies them.
{
    package DynApp;
    use Punk;
    use Punk::Plugin::Sitemap;

    plugin 'Sitemap' => { base => 'https://example.com', ttl => 1 };

    get '/'          => sub { $_[0]->text('x') };
    get '/users/:id' => sub { $_[0]->text('x') };

    our @rows = ({ id => 1, up => '2026-08-20' },
                 { id => 2, up => '2026-08-19T10:00:00Z' });
    our $ran = 0;

    sitemap users => sub {
        $ran++;
        return map { { loc => "/users/$_->{id}", lastmod => $_->{up} } } @rows;
    };

    package main;
    DynApp->to_app;
    my $doc = Punk::Plugin::Sitemap->_doc(DynApp->punk_app);

    like($doc, qr{<loc>https://example\.com/users/1</loc>},
        'a section supplies the URLs the route table could not know');
    like($doc, qr{<lastmod>2026-08-20</lastmod>}, 'with a date');
    like($doc, qr{<lastmod>2026-08-19T10:00:00Z</lastmod>},
        'and a full W3C datetime');
    like($doc, qr{<loc>https://example\.com/</loc>},
        'and the route half is still there beside it');

    my @locs = $doc =~ m{<loc>([^<]+)</loc>}g;
    is_deeply(\@locs, [ sort @locs ],
        'the whole document stays sorted, so a section returning rows in '
      . 'database order does not make every regeneration a different file');
}

# ---- once per TTL, then a refresh with no restart ----------------------------
{
    package TtlApp;
    use Punk;
    use Punk::Plugin::Sitemap;
    plugin 'Sitemap' => { base => 'https://example.com', ttl => 1 };
    get '/' => sub { $_[0]->text('x') };
    our @rows = ({ id => 1 });
    our $ran = 0;
    sitemap users => sub { $ran++; map { "/users/$_->{id}" } @rows };

    package main;
    TtlApp->to_app;
    Punk::Plugin::Sitemap->_doc(TtlApp->punk_app) for 1 .. 4;
    is($TtlApp::ran, 1,
        'four reads inside the TTL run the section ONCE - a section reads a '
      . 'database, and running it per request would be a query nobody is '
      . 'watching on a schedule somebody else chooses');

    push @TtlApp::rows, { id => 3 };
    sleep 2;
    my $doc = Punk::Plugin::Sitemap->_doc(TtlApp->punk_app);
    is($TtlApp::ran, 2, 'and the section runs again once the TTL has passed');
    like($doc, qr{/users/3},
        'so a row added while the process ran appears WITHOUT a restart, '
      . 'which is the whole point of the dynamic half');
}

# ---- a section returns data that goes into a structured document -------------
# So every field is checked on the way in. The route half needs none of this,
# because its paths are declarations; a section's are database rows.
{
    package BadApp;
    use Punk;
    use Punk::Plugin::Sitemap;
    plugin 'Sitemap' => { base => 'https://example.com' };
    get '/' => sub { $_[0]->text('x') };
    sitemap bad => sub {
        return ('/ok',
                '//evil.example/x',          # protocol-relative: another host
                'https://evil.example/y',    # absolute
                '/users/:id',                # the pattern, by mistake
                'no-leading-slash',
                "/ctl\x0aInjected",          # a control byte
                '/back\\slash',
                { loc => '/dated',   lastmod => '2026-08-20' },
                { loc => '/baddate', lastmod => 'last tuesday' });
    };

    package main;
    my @warns;
    my $doc = do {
        local $SIG{__WARN__} = sub { push @warns, $_[0] };
        BadApp->to_app;
        Punk::Plugin::Sitemap->_doc(BadApp->punk_app);
    };

    like($doc, qr{<loc>https://example\.com/ok</loc>}, 'a good loc goes in');

    unlike($doc, qr{evil\.example},
        'a protocol-relative or absolute loc naming ANOTHER HOST is dropped - '
      . 'that is somebody else\'s pages published under your name');
    unlike($doc, qr{:id},
        'a loc still holding a capture is dropped, because a section returned '
      . 'the pattern by mistake');
    unlike($doc, qr{no-leading-slash}, 'and an unrooted path is dropped');
    unlike($doc, qr{Injected},
        'and one carrying a control byte, which is the bug class '
      . 'reference_reflected_request_bytes exists for');
    unlike($doc, qr{backslash|back\\}, 'and one carrying a backslash');

    is(scalar(grep { /is dropped/ } @warns), 6,
        'each refusal warns rather than passing silently');

    like($doc, qr{<loc>https://example\.com/dated</loc><lastmod>2026-08-20</lastmod>},
        'a valid lastmod is emitted');
    like($doc, qr{<loc>https://example\.com/baddate</loc></url>},
        'an unparseable one is DROPPED while the URL still goes in - one bad '
      . 'date would invalidate the whole document, and losing the page would '
      . 'cost more than losing the date');
}

# ---- a section that dies degrades the sitemap, not the site -------------------
{
    package DeadApp;
    use Punk;
    use Punk::Plugin::Sitemap;
    plugin 'Sitemap' => { base => 'https://example.com' };
    get '/' => sub { $_[0]->text('x') };
    sitemap boom => sub { die "the database is gone\n" };
    sitemap fine => sub { '/still-here' };

    package main;
    my @warns;
    my $doc = do {
        local $SIG{__WARN__} = sub { push @warns, $_[0] };
        DeadApp->to_app;
        Punk::Plugin::Sitemap->_doc(DeadApp->punk_app);
    };
    like($doc, qr{<loc>https://example\.com/</loc>},
        'a section that died does not take the document with it');
    like($doc, qr{/still-here}, 'and the other sections still contribute');
    is(scalar(grep { /died/ } @warns), 1, 'the failure is warned about');
}

# ---- a named section is replaced, not appended -------------------------------
{
    package DupApp;
    use Punk;
    use Punk::Plugin::Sitemap;
    plugin 'Sitemap' => { base => 'https://example.com' };
    get '/' => sub { $_[0]->text('x') };
    sitemap pages => sub { '/first' };
    sitemap pages => sub { '/second' };      # a base class, then a subclass

    package main;
    DupApp->to_app;
    my $doc = Punk::Plugin::Sitemap->_doc(DupApp->punk_app);
    unlike($doc, qr{/first},  'redeclaring a section REPLACES it');
    like($doc,   qr{/second}, 'so an override wins rather than doubling');
}

# ---- an app with no sections keeps phase 2 exactly ---------------------------
{
    package StaticApp;
    use Punk;
    plugin 'Sitemap' => { base => 'https://example.com' };
    get '/' => sub { $_[0]->text('x') };

    package main;
    StaticApp->to_app;
    my $a = Punk::Plugin::Sitemap->_doc(StaticApp->punk_app);
    sleep 1;
    my $b = Punk::Plugin::Sitemap->_doc(StaticApp->punk_app);
    is($a, $b,
        'with no sections the document is never rebuilt - routes cannot '
      . 'change while the process runs, so there is nothing to refresh');
}

# ---- phase 4: robots.txt -----------------------------------------------------
# The same decision, made once, spelled twice. Written apart the two drift
# within a release, and the drift is silent in both directions.
{
    package RobotsApp;
    use Punk;
    use Punk::Plugin::Sitemap;
    plugin 'Sitemap' => { base => 'https://example.com',
                          disallow => ['/private'] };

    get '/'      => sub { $_[0]->text('x') };
    get '/about' => sub { $_[0]->text('x') };
    get '/admin' => sub { $_[0]->text('x') }, { sitemap => 0 };

    my $acct = under '/account' => sub { return };
    $acct->get('/settings'  => sub { $_[0]->text('x') });
    $acct->get('/orders/:id' => sub { $_[0]->text('x') });

    package main;
    my $app = RobotsApp->to_app;
    my $txt = Punk::Plugin::Sitemap->_robots(RobotsApp->punk_app);

    like($txt, qr/^User-agent: \*$/m, 'a user-agent line');
    like($txt, qr{^Disallow: /admin$}m, 'a route that opted out is disallowed');
    like($txt, qr{^Disallow: /account/settings$}m, 'and a guarded one');
    like($txt, qr{^Disallow: /private$}m, 'and whatever `disallow` added');

    like($txt, qr{^Disallow: /account/orders/$}m,
        'a guarded route with a CAPTURE is disallowed as a prefix - nobody '
      . 'benefits from Disallow: /account/orders/:id, and the prefix is '
      . 'exactly the set the route matches');

    like($txt, qr{^Sitemap: https://example\.com/sitemap\.xml$}m,
        'and the Sitemap line, which is what most hand-written robots.txt '
      . 'files are missing');

    unlike($txt, qr{^Disallow: /sitemap\.xml$}m,
        'the sitemap is NOT disallowed while the Sitemap line advertises it - '
      . 'that self-contradiction is the whole thing this phase exists to '
      . 'prevent');
    unlike($txt, qr{^Disallow: /robots\.txt$}m,
        'and robots.txt does not disallow itself');

    my $r = $app->({ REQUEST_METHOD => 'GET', PATH_INFO => '/robots.txt',
                     SCRIPT_NAME => '', QUERY_STRING => '', SERVER_NAME => 'l',
                     SERVER_PORT => 80, 'psgi.url_scheme' => 'http',
                     'psgi.input' => undef, 'psgi.errors' => \*STDERR });
    is($r->[0], 200, 'it is served from the site root');
    my %hdr = @{ $r->[1] };
    is($hdr{'Content-Type'}, 'text/plain; charset=utf-8', 'as text/plain');
}

# ---- THE GATE: the two cannot disagree ---------------------------------------
# Every path the sitemap lists must be crawlable, and everything excluded must
# be disallowed. Asserted as a property over the whole document rather than as
# a handful of examples, because the failure this prevents is one nobody
# notices.
{
    package AgreeApp;
    use Punk;
    use Punk::Plugin::Sitemap;
    plugin 'Sitemap' => { base => 'https://example.com' };

    get '/'         => sub { $_[0]->text('x') };
    get '/docs'     => sub { $_[0]->text('x') };
    get '/docs/faq' => sub { $_[0]->text('x') };
    get '/secret'   => sub { $_[0]->text('x') }, { sitemap => 0 };
    my $g = under '/inner' => sub { return };
    $g->get('/page' => sub { $_[0]->text('x') });

    package main;
    AgreeApp->to_app;
    my $h   = AgreeApp->punk_app;
    my $txt = Punk::Plugin::Sitemap->_robots($h);
    my $doc = Punk::Plugin::Sitemap->_doc($h);

    my @dis = $txt =~ /^Disallow: (\S+)$/mg;
    my @loc = $doc =~ m{<loc>https://example\.com([^<]*)</loc>}g;
    $_ = '/' for grep { $_ eq '' } @loc;

    my @shadowed;
    for my $l (@loc) {
        push @shadowed, $l for grep { index($l, $_) == 0 } @dis;
    }
    is_deeply(\@shadowed, [],
        'NO Disallow prefix shadows a URL the sitemap lists - a crawler is '
      . 'never told both to fetch a page and to leave it alone')
        or diag "listed: @loc\ndisallowed: @dis";

    my %dis = map { $_ => 1 } @dis;
    ok($dis{'/secret'}, 'and everything excluded IS disallowed: the opt-out');
    ok($dis{'/inner/'} || $dis{'/inner/page'}, 'and the guarded page');
}

# ---- staging ------------------------------------------------------------------
{
    package StagingApp;
    use Punk;
    use Punk::Plugin::Sitemap;
    plugin 'Sitemap' => { base => 'https://staging.example.com',
                          disallow_all => 1 };
    get '/' => sub { $_[0]->text('x') };

    package main;
    StagingApp->to_app;
    my $txt = Punk::Plugin::Sitemap->_robots(StagingApp->punk_app);

    like($txt, qr{^Disallow: /$}m,
        'disallow_all shuts the whole site out - a staging environment being '
      . 'indexed is routine, embarrassing and slow to undo');
    unlike($txt, qr{^Sitemap:}m,
        'and it emits NO Sitemap line, because advertising a sitemap while '
      . 'disallowing everything says two opposite things');
}

done_testing;
