package Punk::Plugin::Feed;

use 5.010;
use strict;
use warnings;
use Punk::Feed ();

our $VERSION = '0.03';

1;

__END__

=head1 NAME

Punk::Plugin::Feed - Atom and RSS from an application's own rows

=head1 SYNOPSIS

    package MyApp;
    use Punk;

    use Punk::Plugin::Feed;          # for the `feed` keyword

    host 'https://example.com';

    plugin 'Feed' => { title => 'Example', author => 'A Name' };

    feed sub {
        map +{
            loc     => "/posts/$_->{id}",
            title   => $_->{title},
            updated => $_->{updated},
            summary => $_->{excerpt},
        }, MyApp->model('Post')->recent;
    };

    feed releases => sub { ... };    # a second, named feed

=head1 DESCRIPTION

A feed is a window on what an application published recently, in a form a
reader can poll. This builds one, in both formats readers speak, from a
callback the application supplies.

=head2 What it serves

    GET /feed.xml           Atom 1.0, the default feed
    GET /feed.rss           RSS 2.0, the default feed
    GET /feed/NAME.xml      Atom 1.0, a named feed
    GET /feed/NAME.rss      RSS 2.0, a named feed

From the site root regardless of any mount prefix, because a feed URL goes
into a C<< <link rel="alternate"> >> and into a reader's database, and neither
follows a prefix that moved.

C<path> moves the stem and C<format> decides which of the two are registered.
Routes are added only for feeds that were actually declared: an application
that loads the plugin and declares nothing serves no feed routes at all, rather
than a route that could only ever answer C<404>.

Every document is rendered at C<to_app> and served from frozen bytes, so a
request is a write of something that already exists.

=head2 base is configuration, and the application's host is its default

    host 'https://example.com';
    plugin 'Feed' => { title => 'Example' };            # base = the host

    plugin 'Feed' => { title => 'Example',              # explicit wins
                       base  => 'https://example.com' };

A feed's URLs are absolute. The obvious place to get the scheme and host is the
request that asked for the feed, and that is a host-header injection with a
long tail: a request carrying C<< Host: evil.example >> would produce a feed
naming that host for every item, the owner's own request would produce a
correct one so nothing would look wrong, and every reader that fetched the
poisoned copy would keep it for as long as somebody stayed subscribed.

So the request is never consulted. The base is an explicit C<base>, or the
application's declared L<Punk/host>. An application with neither croaks at
C<to_app> rather than at the C<plugin> line, so C<host> may be declared on
either side of it.

=head2 Several hosts

    host 'https://example.com', allow => [ '*.example.com' ];
    plugin 'Feed' => { title => 'Example' };

An application with a host allowlist serves a feed per tenant: a request from
an allowlisted host is answered with a document naming that host, carrying its
own C<ETag>. A host on neither the canonical origin nor the allowlist is handed
the canonical document, because the alternative is the injection above.

The entries are shared. A tenant document is rendered from the records the
build already collected, so the sections run once per C<ttl> however many hosts
ask, and it is not cached - a wildcard allow makes the set of hosts unbounded,
and a cache keyed by hostnames a client chooses is a memory leak with a name.

=head2 An entry with no date is not published

C<loc>, C<title> and C<updated> are all required, and an entry missing any of
them is dropped with a warning naming the feed and the value.

Atom makes all three mandatory, and a reader handed a document that violates
that rejects B<the whole document> rather than the offending entry - so one
unusable row must not be able to empty the feed. The tempting repair is to
default C<updated> to the build time, and it is worse: it tells every
subscriber that every item changed on every deploy, which is the fastest way to
be unsubscribed from.

An unparseable C<published> is dropped while the entry still goes in. A missing
publication date costs a reader nothing; losing the item would.

=head2 Encoding, then escaping

Two different jobs, in that order. A path holding a space is not a URL at all,
so escaping alone would produce a well-formed document containing an invalid
URL - one readers accept and then cannot follow.

A query string is encoded under its own rules. Percent-encoding the C<?> would
fold the query into the path, so C</article?id=5> would ask for a file
literally named C<article?id=5>: a C<404> for every subscriber, from a link
that reads correctly in the document. The C<&> joining two query pairs is
escaped to C<< &amp; >>, which in XML B<is> the character C<&>, so the URL a
reader reconstructs is the one the application wrote.

Then XML escaping over every emitted value without exception. One bare C<&>
makes the document not well-formed and a reader rejects B<all> of it, which
makes this a correctness problem before it is a security one.

There is no C<CDATA> anywhere. The tempting shape for an entry's HTML is
C<< <![CDATA[ ... ]]> >>, and content containing C<< ]]> >> breaks straight out
of it - a sequence that turns up on its own in code samples. Everything is
escaped instead, which is why Atom content goes out as C<< type="html" >>
carrying escaped markup rather than as C<type="xhtml">, where one unbalanced
C<< <br> >> would invalidate the feed.

=head2 Text arrives in three shapes and leaves in one

A document says C<encoding="UTF-8">, and a byte that is not UTF-8 makes it not
well-formed - fatal, for the same reason a bare C<&> is. Perl offers three
storage shapes for the same text and all three reach here:

=over 4

=item * a character string with a codepoint above 255, which is UTF-8 flagged

=item * a character string whose codepoints are all below 256, which is
B<unflagged> and one byte each, so C<"Caf\x{e9}"> is the single byte C<E9>

=item * a byte string that already is UTF-8 with the flag off, which is what
L<File::Raw::JSON> and L<Template::Stencil> hand back

=back

The last two cannot be told apart by their flags, so they are told apart by
their contents: a byte sequence that is valid UTF-8 is taken as UTF-8, and
anything else as latin-1 and upgraded. Valid UTF-8 is not something latin-1
prose falls into by accident.

Punk itself does not transcode, and being stricter here is deliberate. A page
with one bad byte renders with one bad character; a feed with one bad byte is
rejected whole.

=head2 A reader is a fetcher on a schedule

It will ask for this URL every few minutes for years, and between rebuilds the
answer is bytes that already exist. So every response carries both validators -
an C<ETag> over the rendered bytes and a C<Last-Modified> holding the newest
entry's date - and both are honoured. C<If-None-Match> is checked first and
wins outright when present; the date is understood too, because some readers
only ever send that one.

C<Cache-Control: max-age> follows from C<ttl>: telling a client to come back
sooner than the document can change is asking for a request that can only
produce a C<304>.

This is not left to L<Punk::Plugin::ConditionalGet>. The bytes and their
timestamp are both known at build time, and a plugin computing them again per
request would be redoing work this one already did.

=head2 ttl, and the staleness it buys

A section reads a database, so its answer changes while the process runs.
Running it per request would be a query nobody is watching, on a schedule
somebody else chooses; running it once at boot would produce a feed correct on
the day of the deploy and progressively wrong afterwards.

So it is rebuilt when C<ttl> seconds have passed, an hour by default, and B<the
document is stale by up to that long>. That is worth stating rather than
engineering away: a reader learning about a post an hour late is a reader
behaving normally.

There is no stampede to guard against inside a worker. Hyperman is
single-threaded and a worker serves its requests one after another, so the
second of two simultaneous requests finds what the first built. The cost across
a pool is one rebuild per worker per C<ttl>.

=head2 A rebuild that fails keeps the last good feed

A section that dies warns and contributes nothing, which on the first build
means an empty feed. On a B<rebuild> it means something else: the entries from
the last good build are kept, and a second warning says so.

Replacing them with nothing would publish an empty feed, and a reader handed
one concludes every item was deleted and says so to the person subscribed. A
database away for a minute must not look like a site that deleted its archive.

=head2 Atom or RSS

Both, by default, from one set of entries. What each format cannot say is worth
knowing before pointing readers at one:

RSS has a single date element, so an entry with both C<published> and
C<updated> loses one of them; it has no content element in the core
specification, so C<summary> is preferred and C<content> stands in only when
there is no summary. Atom has no C<language>, which is why that option is
documented as RSS-only rather than quietly ignored.

RSS specifies C<< <author> >> as an email address. A name is emitted there
instead, which every reader accepts and which does not publish the address.

The feed-level timestamp is the newest entry's date in both formats, and never
the build time. A rebuild that found nothing new produces the same bytes as the
one before it - otherwise every reader records a change on every C<ttl>. RSS's
element is called C<< <lastBuildDate> >>, and the name is the trap.

=head2 An id should outlive a URL

An entry's identifier defaults to its absolute URL, which is right for most
sites and needs no configuration. What it costs is worth knowing: a post whose
URL changes is a post every subscriber sees twice.

C<id> is the escape hatch, and a C<tag:> URI is the durable form:

    id => "tag:example.com,2026:post/$_->{id}",

RSS marks a supplied id C<< isPermaLink="false" >>, because a C<tag:> URI is
not something a reader should try to fetch.

=head1 OPTIONS

    plugin 'Feed' => {
        title       => 'Example',              # REQUIRED
        author      => 'A Name',               # Atom wants one
        base        => 'https://example.com',  # default: the app's `host`
        path        => '/feed',                # the stem
        format      => 'both',                 # 'atom' | 'rss' | 'both'
        ttl         => 3600,                   # seconds
        limit       => 50,                     # entries per feed
        description => 'What this is',         # RSS description, Atom subtitle
        link        => '/',                    # the site alternate
        id          => undef,                  # Atom feed id; default self URL
        language    => 'en',                   # RSS only
        copyright   => undef,                  # RSS copyright, Atom rights
    };

An unknown option croaks. A misspelled option is a setting that silently did
not apply, and C<subtitle> written where C<description> was meant would leave a
feed without one until a reader complained.

C<title> is required and croaks at the C<plugin> line, because nothing declared
later can supply it. C<subtitle> is accepted as a spelling of C<description>,
since Atom and RSS disagree about the name of the same sentence.

C<limit> defaults to 50 and may not exceed 5000. A feed is a window on recent
items rather than an archive, and every byte is paid on every poll.

=head1 THE FEED KEYWORD

    feed sub { ... };                 # the default feed
    feed news => sub { ... };         # a named feed
    feed news => { title => 'News', limit => 10, entries => sub { ... } };

A section may also be a C<'Controller#method'> target, exactly as a route
target is, and is resolved by the same machinery:

    feed 'Web::Feed#posts';                      # the default feed
    feed news => 'Web::Feed#news';               # a named one
    feed news => { title => 'News', entries => 'Web::Feed#news' };

A section that reads a database belongs in a controller for the same reasons a
route handler does. The string is resolved at C<to_app>, so the controller may
be declared after the C<feed> line, and a target that names nothing croaks
there with Punk's own diagnostic.

One argument that is a bare string is a B<name> whose body was left off -
C<< feed 'news'; >> is the mistake it looks like. A string holding a C<#> is a
target for the default feed instead, which is how Punk tells the two apart
everywhere else.

A named feed may restate C<title>, C<description>, C<author>, C<link>, C<id>
and C<limit> for itself. It may not restate C<base>, C<ttl> or C<format>: those
are properties of the plugin, and a feed disagreeing about the origin would be
a feed pointing somewhere else.

Declaring a name twice B<replaces> rather than appends, keeping its original
position, so a base class can declare a feed and a subclass override it without
the route set reshuffling.

=head2 The entry

A section returns a list of hashrefs:

    {
        loc       => '/posts/1',          # REQUIRED, a rooted path
        title     => 'Hello',             # REQUIRED
        updated   => 1_700_000_000,       # REQUIRED
        published => '2026-01-01',        # optional
        id        => 'tag:...',           # optional
        summary   => 'plain text',        # optional
        content   => '<p>markup</p>',     # optional
        author    => 'Someone',           # optional
        category  => [ 'perl', 'xs' ],    # optional, string or arrayref
        enclosure => { url => '...', type => '...', length => 12 },
    }

Dates are an epoch, an ISO-8601 instant with an optional offset, or a bare
C<YYYY-MM-DD> read as midnight UTC. Epoch C<0> is a real date and is kept as
one.

C<loc> is a rooted path, or an absolute URL on the feed's own base, which is
reduced back to a path. It may not begin C<//>, which is protocol-relative and
names another host, and may hold no C<:> or C<*>, which would mean a section
returned the route pattern by mistake.

Fields this does not know about are ignored rather than refused: a section
mapping straight over database rows is the ordinary way to write one, and the
row carries columns a feed has no use for.

Entries are sorted newest first, C<loc> ascending where two share a date, and
then truncated to C<limit>. The tiebreak is not tidiness: without it a database
returning rows in its own order would make every rebuild a different file, and
a reader comparing bytes would report changes that did not happen.

=head1 HELPERS

=head2 $c->feed_links

The autodiscovery tags for a layout, escaped and ready to print:

    <link rel="alternate" type="application/atom+xml" title="Example"
          href="https://example.com/feed.xml">

Every declared feed, in the formats actually served. It exists because
autodiscovery is the only way a browser or a reader finds the feed from the
page, and hand-writing those attributes in a layout is where the URL goes stale
the first time C<path> changes.

=head1 SEE ALSO

L<Punk::Feed>, L<Punk::Plugin::Sitemap>, L<Punk>, L<Punk::Plugin>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
