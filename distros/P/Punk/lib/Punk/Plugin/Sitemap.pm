package Punk::Plugin::Sitemap;

use 5.010;
use strict;
use warnings;
use Punk ();

our $VERSION = '0.28';

1;

__END__

=head1 NAME

Punk::Plugin::Sitemap - sitemap.xml and robots.txt from the route table

=head1 SYNOPSIS

    package MyApp;
    use Punk;

    use Punk::Plugin::Sitemap;          # for the `sitemap` keyword

    plugin 'Sitemap' => { base => 'https://example.com' };

    get '/'          => sub { ... };    # in the sitemap
    get '/about'     => sub { ... };    # in the sitemap
    get '/users/:id' => sub { ... };    # out: a capture is not a URL
    post '/orders'   => sub { ... };    # out: not a GET
    get '/admin'     => sub { ... }, { sitemap => 0 };   # out: opted out

    under '/account' => 'auth';                          # out: guarded

    sitemap users => sub {              # the ids the route table cannot know
        map { { loc => "/users/$_->{id}", lastmod => $_->{updated} } } @rows;
    };

=head1 DESCRIPTION

Punk compiles every route at boot, so an application already holds a complete
list of what it serves. A sitemap is that list with a filter over it, and this
is the filter.

Which means it cannot list a page the application does not serve, and it
cannot drift from the routes the way a hand-written file does.

=head2 What it refuses to list, which is the part that matters

A route is listed only when every one of these holds:

=over 4

=item * its method is C<GET> (or a C<route> that includes it)

=item * its path contains no capture - no C<:name>, no C<*splat>

=item * it carries no guard

=item * it did not say C<< sitemap => 0 >>

=back

Everything else is left out, and out is the safe direction. A page missing
from a sitemap is still crawled if anything links to it; a page wrongly
present is a crawler fetching a 404 or a login redirect on a schedule, for as
long as the site exists.

B<A route with a capture is not a URL.> C<< /users/:id >> names a shape, and
the ids are not something the route table knows. Those are supplied by the
application.

B<A guarded route is excluded without anyone maintaining a list.> C<under>
copies its guard chain into every route declared inside it, so the plugin can
see what somebody writing a sitemap by hand has to remember. Every
hand-written sitemap eventually lists a page behind a login; this one cannot.

=head2 base is required, and it is configuration

    plugin 'Sitemap' => { base => 'https://example.com' };

The sitemap protocol wants absolute URLs. The obvious place to get the scheme
and host is the request that asked for the sitemap, and that is a host-header
injection delivered to search engines: a request carrying
C<< Host: evil.example >> would produce a file naming that host for every page
on the site, and the owner could not see it, because their own request
produces a correct file.

So there is no default and no fallback. Starting without one croaks, for the
same reason C<session> refuses to start without a secret.

=head2 What it serves

    GET /sitemap.xml       the document, or an index over the parts
    GET /sitemap/1.xml     a part, when there is more than one
    GET /robots.txt        the disallow list, plus a C<Sitemap:> line
    
Both from the site root regardless of any mount prefix, because
C<< /sitemap.xml >> is a fixed location and a crawler will not look anywhere
else.

The document is rendered once, at C<to_app>, and served from memory - the
routes cannot change while the process runs, so a request is a write of bytes
that already exist.

B<The protocol caps a sitemap at 50,000 URLs and 50MB>, and past either one
crawlers reject the whole file rather than the excess. Both are counted as the
document is written and whichever binds first starts a new part; with more
than one part C<< /sitemap.xml >> becomes an index naming them. With one part
there is no index, because an index wrapping a single sitemap is a second
fetch for nothing.

A part number nobody generated is a C<404>, so a crawler following a stale
index is told the part is gone rather than handed an empty document.

=head2 Encoding, then escaping

Two different jobs, in that order. A path holding a space has to be
percent-encoded to be a URL at all, and escaping alone would produce a
well-formed document containing an invalid one. Encoding first also makes the
whole document ASCII, so a route path that is not valid UTF-8 cannot make it
unparseable.

Then XML escaping over every URL without exception. One bare C<&> makes the
document not well-formed, and a crawler rejects B<all> of it rather than the
offending entry - which makes this a correctness problem before it is a
security one.

There is no C<< <lastmod> >> on routes. "When did this static page last
change" is not something the route table knows, and stamping boot time would
tell crawlers every page changed on every deploy, which is the fastest way to
have the file ignored.

=head1 THE DYNAMIC HALF

    package MyApp;
    use Punk;
    use Punk::Plugin::Sitemap;          # for the keyword, see below

    plugin 'Sitemap' => { base => 'https://example.com', ttl => 3600 };

    get '/users/:id' => sub { ... };    # a shape, so it contributes nothing

    sitemap users => sub {              # the ids, which only the app knows
        my @u = MyApp->model('User')->all;
        return map { { loc => "/users/$_->{id}", lastmod => $_->{updated} } } @u;
    };

A section returns locations: a rooted path, or a hashref with C<loc> and an
optional C<lastmod>. Sections are emitted in declaration order after the route
half, each sorted, and the whole document is de-duplicated - so a page that is
both a static route and a section row appears once.

Declaring the same name twice B<replaces> rather than appends, keeping its
original position, so a base class can declare a section and a subclass
override it without the document reshuffling.

=head2 The keyword needs the `use`

C<< plugin 'Sitemap' >> runs at B<runtime> of the package body, long after
C<< sitemap users => sub {...} >> has been compiled - so a keyword installed
only there is one perl has already refused to parse. C<use> installs it at
compile time, which is why both lines are in the synopsis.

Without the C<use>, the parenthesised form still works, because perl resolves
a call with parentheses at runtime:

    sitemap('users' => sub { ... });

=head2 ttl, and the staleness it buys

A section reads a database, so its answer changes while the process runs.
Running it per request would be a query nobody is watching, on a schedule
somebody else chooses; running it once at boot would produce a sitemap correct
on the day of the deploy and progressively wrong afterwards.

So it is rebuilt when C<ttl> seconds have passed, an hour by default, and B<the
document is stale by up to that long>. That is fine and worth saying rather
than engineering away: a crawler learning about a page an hour late is a
crawler behaving normally, and no search engine promises to fetch a sitemap
promptly.

There is no stampede to guard against. Hyperman is single-threaded and a
worker serves its requests one after another, so the second of two
simultaneous crawler requests finds what the first built. The cost across a
pool is one rebuild per worker per C<ttl>.

An application with B<no> sections is never rebuilt at all: the routes cannot
change, so there is nothing to refresh.

=head2 What a section may not return

A section returns data that goes straight into a structured document, so every
field is checked. The route half needs none of this, because its paths are
declarations; a section's are database rows.

A C<loc> is dropped, with a warning, unless it is a rooted, same-origin,
concrete path:

=over 4

=item * it must start with C</> - the base supplies the origin

=item * it must not start with C<//>, which is protocol-relative and names
another host. C<//evil.example/x> in your sitemap is somebody else's pages
published under your name.

=item * it must hold no C<:> or C<*>, which would mean the section returned
the route B<pattern> by mistake and a literal C<:id> would go in the file

=item * no control bytes and no backslash

=back

C<$c-E<gt>safe_path> encodes the same rules for redirects, for the same
reason: bytes the application did not write, reaching somewhere structured.

An unparseable C<lastmod> is dropped while B<the URL still goes in>. One bad
date invalidates the whole document, and losing the page would cost more than
losing the date.

A section that dies warns and contributes nothing, rather than taking the
request with it - a failed section degrades the sitemap, not the site. One
returning more than 50,000 locations is truncated there, because an unbounded
C<SELECT> on a table that grew is how this becomes an out-of-memory rather
than a large file.

=head1 ROBOTS.TXT

    GET /robots.txt

B<It is not access control.> It is a request to well-behaved crawlers, ignored
by everything else, and a C<Disallow> line is a signpost to anything hostile -
a published list of the paths worth attacking. The guarding is C<auth_guard>'s
job; this only tells Google not to bother.

It is generated here rather than by hand, and from the same pass over the same
records as the sitemap, because they are two spellings of one decision.
Written apart they drift within a release, and the drift is silent both ways:
a path disallowed but listed is a crawler told two things, and a path excluded
but not disallowed is crawled anyway - which is how a staging environment ends
up indexed.

    User-agent: *
    Disallow: /account/orders/
    Disallow: /account/settings
    Disallow: /admin

    Sitemap: https://example.com/sitemap.xml

Three sources: guarded routes, routes that said C<< sitemap => 0 >>, and
whatever C<disallow> added. Plus the C<Sitemap:> line, which is how a crawler
finds the sitemap without being told and is the line most hand-written
C<robots.txt> files are missing.

B<A guarded route with a capture is disallowed as a prefix.> Nobody benefits
from C<< Disallow: /account/orders/:id >>, so the path is truncated at the
first capture and the prefix stands for everything under it - which is exactly
the set the route matches.

B<Nothing the sitemap lists can be disallowed.> Every candidate is checked
against the listed URLs first, so a C<Disallow> can never shadow a page the
same file is advertising. That is enforced rather than tested for afterwards.

The plugin's own routes are kept out of both. They are absent from the sitemap
because a sitemap listing itself is noise, and absent from C<Disallow> because
forbidding C<< /sitemap.xml >> while the C<Sitemap:> line advertises it is the
exact contradiction this section exists to prevent.

=head1 OPTIONS

=head2 disallow

An arrayref of extra prefixes for C<robots.txt>, for anything the route table
cannot see - a mounted PSGI app, a static directory.

=head2 disallow_all

    plugin 'Sitemap' => { base => ..., disallow_all => 1 };   # staging

    User-agent: *
    Disallow: /

A staging environment being indexed is routine, embarrassing and slow to undo,
and it is usually caused by a C<robots.txt> copied from production. This is one
flag, driven from the config that already differs between environments.

No C<Sitemap:> line is emitted with it, because advertising a sitemap while
disallowing everything says two opposite things.

=head2 ttl

Seconds before a dynamic section is run again. An hour by default, and
irrelevant to an application with no sections.

=head2 base

Required. The scheme and host every path is joined onto. A trailing slash is
trimmed, since every path already starts with one and C<https://x//about> is a
different URL to a crawler.

=head1 ROUTE OPTIONS

=head2 sitemap => 0

Keeps a route out.

=head2 sitemap => 1

Puts a route in despite a guard.

This is not the opt-in half of a pair - inclusion is already the default for a
route that says nothing, and an opt-in default would mean an empty sitemap
until somebody remembered, which looks like an answer and is not.

It exists because a scope guard may be an authentication check or may be an
ordinary filter, and Punk cannot read its intent. The plugin assumes the
first, because that is the safe direction, and this is how an application says
a page is public anyway.

The method and the shape are B<not> overridable. C<< sitemap => 1 >> on a
C<POST> or on C<< /users/:id >> does nothing, because a POST is not a page and
a pattern is not a URL - those are mistakes rather than instructions.

=head1 SEE ALSO

L<Punk>, L<Punk::Plugin>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
