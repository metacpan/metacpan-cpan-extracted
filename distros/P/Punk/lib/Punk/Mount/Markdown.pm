package Punk::Mount::Markdown;

use 5.010;
use strict;
use warnings;
use Punk ();

our $VERSION = '0.62';

1;

__END__

=head1 NAME

Punk::Mount::Markdown - a directory of markdown as a documentation site

=head1 SYNOPSIS

    package MyApp;
    use Punk;

    markdown '/docs' => 'docs', title => 'MyApp Guide';

    1;

=head1 DESCRIPTION

Point the C<markdown> keyword at a nested directory of C<.md> files and it
becomes a complete documentation site: rendered HTML with syntax-highlighted
code, a sidebar reflecting the directory tree, a per-page table of contents
built from the headings, ranked search, and the images sitting alongside the
markdown served as static files.

The whole site is built at boot. The tree is walked, every page is rendered
through L<Markdown::Simple> and wrapped by L<Template::Stencil>, the search
index is filled, and the finished bytes are frozen into a lookup table. A
request is then a hash hit and a response triplet, with no markdown parse, no
template render and no Perl frame. The cost of that is a startup pass linear
in the size of the tree, paid once per worker; see L</reload> for the edit
loop.

Building at boot also means a missing directory, an unreadable document or a
broken template fails at startup with the rest of your configuration, rather
than on whichever request first happens to reach it.

The mount rides Punk's ordinary mount table, so it behaves like C<static>
does: longest prefix wins, and a request served by the mount bypasses
before/after hooks, guards and CSRF.

=head1 URLS

A page's address is its path under the directory with the C<.md> dropped, and
an index file collapses to its containing directory:

    docs/index.md              ->  /docs
    docs/guide/intro.md        ->  /docs/guide/intro
    docs/guide/index.md        ->  /docs/guide

A request carrying a trailing slash or a C<.md> suffix is redirected to the
canonical form, so a document never has two addresses. Anything in the tree
that is not markdown is served as a static file with the same caching,
conditional-request and sendfile behaviour L<Punk::Static> gives it, which is
what makes a relative C<< ![](diagram.png) >> in a document work. A file
ending in C<.md> is never served that way, so a draft or an index cannot be
read as its source, and neither is anything whose name, or whose directory's
name, begins with a dot.

=head1 FRONT MATTER

A document may open with a restricted C<---> block:

    ---
    title: Getting Started
    nav: Start here
    order: 1
    ---

    # Getting Started

Recognised keys are C<title>, C<nav> (the sidebar label, when it should differ
from the title), C<order> (the sort key within a section), C<draft> (when
true, the page is skipped entirely), and C<date> and C<updated> (below).

A section's index page (F<guide/index.md> for the F<guide> directory) may also
name and place its section in the sidebar: C<section> is the group's label,
in place of the directory's name, and C<section_order> its position among
the sections. Sections without C<section_order> follow those with it, by
directory name:

    ---
    title: File::Raw::JSON
    section: JSON
    section_order: 2
    ---

Every key, recognised or not, is passed to the templates in C<meta>, as the
string it was written as, so a page can carry its own description, image or
anything else a site's templates want to read:

    ---
    title: Getting Started
    description: Install the framework and serve a first page.
    ---

    {% if meta.description %}<meta name="description" content="{% meta.description %}">{% end %}

An unknown key is never an error, so a document carrying front matter for some
other tool still renders. Values are not split or typed: C<tags: [a, b]>
arrives as the string C<[a, b]>.

This is deliberately not YAML. Running a YAML parser on every page at boot to
read two scalars would put a dependency on the C path for no benefit.

Where there is no C<title>, the first C<< # >> heading is used, and failing
that the filename with hyphens and underscores turned into spaces.

=head1 DATES

    ---
    date: 2026-10-19
    updated: 2026-10-21T09:30:00+01:00
    ---

C<date> and C<updated> take C<YYYY-MM-DD>, read as midnight UTC, or
C<YYYY-MM-DDTHH:MM> with optional C<:SS> and then C<Z> or a C<+HH:MM> /
C<-HH:MM> offset (a space may stand for the C<T>). Anything else, an
impossible day like C<2026-02-30> included, is a configuration error: the
application fails at boot naming the file and the value. Under C<reload>,
the same error reaches the request that read the bad edit. C<updated>
defaults to C<date>.

A dated page gets C<og:type> C<article> and the C<article:published_time>
and C<article:modified_time> tags (see L</SEO>), and its templates receive
C<date> and C<updated> as epochs, C<date_iso> and C<updated_iso> as
C<2026-10-19T00:00:00Z>, and C<date_human> and C<updated_human> as
C<19 October 2026> (in English, and in UTC; use the epoch for anything
else).

C<< sort => 'date' >> orders the pages newest first, which is what a blog
wants. Sections are ignored, so a nested page sorts among the rest; pages with
the same date go by title and then by path, so the order is the same on every
filesystem; undated pages come last, in path order. The sidebar follows the
same order, and a mount with no index file redirects its root to the newest
page.

=head1 LISTING

    get '/blog' => sub {
        my $c = shift;
        $c->render('blog_index', { posts => $c->app->markdown_pages('/blog') });
    };

C<< $app->markdown_pages($prefix) >> returns the pages of the markdown mount at
that prefix, in the mount's order (newest first under C<< sort => 'date' >>),
as an arrayref of hashrefs:

    {
        url     => '/blog/hello',     # the prefix and the page: what a link wants
        path    => '/hello',          # under the mount; '/' for the root page
        title   => 'Hello',
        date    => 1792368000,        # epoch, or undef
        updated => 1792368000,        # epoch, or undef
        summary => '...',             # description, else the start of the text
        meta    => { ... },           # every front-matter key
    }

Drafts are not in it. C<summary> is the front-matter C<description>, or else
the page's plain text with its leading title dropped and its whitespace
collapsed, cut to 200 bytes with C<...>. Every string is characters, not
bytes, and every value is a copy: changing the list changes nothing served.
Under C<reload>, C<meta>, C<date> and C<updated> follow the last re-read of
each page; a new file still needs a restart.

The pages are built when the application compiles, so calling it before
C<to_app> croaks; from a route, or from anything that runs after
C<to_app>, it is ready. An unknown prefix croaks naming the markdown mounts
there are.

A route declared at the mount's own prefix (C<< get '/blog' >> beside
C<< markdown '/blog' >>) answers that address, since an exact route is
matched before any mount; the pages under it are still the mount's.

The application object is C<< $c->app >> in a route and
C<< MyApp->punk_app >> outside one.

=head1 SEO

The shipped wrapper writes a page's search and social tags from its front
matter, so a page's description or share image is one line at its top:

    ---
    title: Getting Started
    description: Install the framework and serve a first page.
    image: /img/start.png
    image_alt: A terminal running punk new
    ---

=over 4

=item * C<description> - C<< <meta name="description"> >>, C<og:description>
and C<twitter:description>.

=item * C<canonical> - C<< <link rel="canonical"> >> and C<og:url>. Without
it, the application's C<host> joined to the page's address; with neither,
no canonical is written.

=item * C<image> - C<og:image> and C<twitter:image>, and the large Twitter
card. A full C<http(s)://> URL is used as it is, a rooted path is put on the
C<host>, and anything else is taken as beside the source file, so
C<image: diagram.png> in F<docs/guide/intro.md> is
C<https://example.com/docs/guide/diagram.png>.

=item * C<image_alt> - C<og:image:alt> and C<twitter:image:alt>.

=item * C<robots>, C<keywords>, C<author> - the tags of those names.

=item * C<og_type> - C<og:type>. Without it, C<article> for a page with a
C<date>, otherwise C<website>.

=back

C<og:title>, C<og:site_name>, C<twitter:title> and C<twitter:card> are
always written for a page; the search page and the 404 have none of these.
Every value is escaped for the attribute it sits in.

The origin is the application's C<host> (or a C<host> option on the mount,
which wins), never the request's: the pages are built at boot, before there
is a request, and a canonical taken from a Host header would hand a cache
somebody else's hostname.

A C<template_dir> of your own receives the same values: C<meta>, and the
worked-out C<host>, C<canonical>, C<image>, C<og_type> and C<twitter_card>.

=head1 OPTIONS

    markdown '/docs' => 'docs',
        title    => 'MyApp Guide',
        reload   => 1,
        edit_url => 'https://github.com/me/app/edit/main/docs/%s';

=over 4

=item * C<title> - the site name, shown in the header and the page title.
Defaults to the mount prefix.

=item * C<index> - the filename that means "this directory". Default
C<index.md>.

=item * C<recursive> - descend into subdirectories. Default true.

=item * C<sort> - C<order> (default) groups pages by section (placed by a
section index's C<section_order:>, then by name) and orders them by
front-matter C<order:>, C<alpha> keeps the plain path order, and C<date>
puts the newest first (see L</DATES>). Any other value fails at boot.

=item * C<reload> - re-stat a page on request and re-render it when the source
has changed. Off by default, since the point of the mount is that pages are
frozen; turn it on for the edit loop under C<punk dev>.

=item * C<highlight> - syntax-highlight fenced code blocks. Default true.

=item * C<gfm> - GitHub Flavored Markdown. Default true.

=item * C<toc> - build a per-page table of contents from the C<h2> and C<h3>
headings. Default true.

=item * C<search> - build a L<Search::Trigram> index at boot and serve a search
page from it. Default true.

=item * C<search_path> - where that page lives, relative to the mount. Default
C</search>.

=item * C<template_dir> - your own templates instead of the shipped ones. The
directory must supply F<page.tmpl>, F<wrapper.tmpl> and F<app.css>; see
L</TEMPLATES>.

=item * C<wrapper> - the wrapper template name. Default C<wrapper.tmpl>.

=item * C<assets> - where the shipped stylesheet is served from, relative to
the mount. Default C</_punk>.

=item * C<footer> - raw HTML for the page footer.

=item * C<host> - the origin for canonical and image URLs. Defaults to the
application's C<host>; see L</SEO>.

=item * C<vars> - a hashref of the site's own values, given to every page's
templates beside the mount's: a site name, its links, anything a shared
header or footer reads. Strings, arrays and hashes are all fine. Copied at
boot, so changing the hash afterwards changes nothing. A name the mount fills
itself (C<title>, C<url>, C<meta>, C<canonical> and the rest of L</TEMPLATES>)
is refused at boot rather than silently shadowed.

    markdown '/blog' => 'posts',
        template_dir => 'root/templates/post',
        vars         => { site_name => 'Example', links => \@links };

=item * C<filters> - a hashref of C<< name => coderef >>, handed to the
mount's L<Template::Stencil> as its C<filters>, so its templates can use the
site's own: C<< {% raw title | json %} >> for structured data, say. A
template using a filter that is not registered fails at boot naming it.

=item * C<sitemap> - C<0> keeps the pages out of L<Punk::Plugin::Sitemap>,
which otherwise lists them with a C<< <lastmod> >> from C<updated:> or
C<date:>, leaving out any page whose C<robots:> says C<noindex>. Default C<1>.

=item * C<headers> - a hashref of extra response headers to send with every
page.

=back

=head1 TEMPLATES

The shell is rendered by L<Template::Stencil>. The shipped templates live in
F<templates/> beside this module; point C<template_dir> at a directory of your
own and it replaces them, so that directory has to supply all three files:

=over 4

=item * F<page.tmpl>

The body of a page. It receives the data below and is expected to emit
C<< {% raw content %} >> somewhere. B<This one template renders all three
kinds of response> - a document, the search results and the 404 - so branch on
C<kind> if they should differ.

=item * F<wrapper.tmpl>

The surrounding document: C<< <html> >>, the header, the sidebar, and
C<< {% content %} >> where F<page.tmpl>'s output is slotted in. It receives
the same data. Rename it with the C<wrapper> option if you would rather call
it something else.

=item * F<app.css>

The stylesheet, served from the mount's C<assets> path. It is read verbatim
rather than rendered, so it is a plain CSS file and its braces mean nothing to
the template engine. It lives with the templates because a caller replacing
the shell almost always wants to replace its styling too.

=back

Both templates receive:

=over 4

=item * C<kind> - C<page>, C<search> or C<notfound>

=item * C<title> - the page title

=item * C<site_title> - the site name, from the C<title> option

=item * C<content> - the rendered markdown, to be emitted with
C<< {% raw content %} >>

=item * C<nav> - the sidebar HTML, likewise raw

=item * C<toc> - the table of contents HTML, likewise raw, or empty

=item * C<url> - the current page's mount-relative address

=item * C<prefix> - the mount prefix, for building links

=item * C<search> - true when a search index was built

=item * C<search_path>, C<assets> - both mount-relative

=item * C<footer> - raw HTML, or empty

=item * C<meta> - the page's front matter, every key; an empty hash on the
search page and the 404

=item * C<host>, C<canonical>, C<image>, C<og_type>, C<twitter_card> - the
SEO values worked out from it; see L</SEO>

=item * C<date>, C<updated>, C<date_iso>, C<updated_iso>, C<date_human>,
C<updated_human> - on a dated page; see L</DATES>

=back

The navigation and the table of contents arrive as ready HTML rather than as
data to loop over because Stencil has no recursion and no dynamic includes, so
an arbitrarily deep tree cannot be walked in a template. They are rebuilt per
page at boot, which is what lets the current entry carry a C<current> class
without any JavaScript.

If you only want to restyle the site, supply your own F<app.css> and leave the
templates alone: copy the shipped F<templates/> directory, replace the
stylesheet, and point C<template_dir> at your copy.

=head1 METHODS

=head2 app($dir, \%opts?, $prefix?)

    my $psgi = Punk::Mount::Markdown->app('docs', { title => 'Guide' }, '/docs');

Builds the whole site from C<$dir> with the L</OPTIONS> and returns the PSGI
coderef that serves it under C<$prefix>. What the C<markdown> keyword
compiles to at C<to_app>; call it directly to serve a site from another
PSGI stack. Croaks when C<$dir> is not a directory, and on anything that
fails to build.

=head1 SEE ALSO

L<Punk>, L<Punk::Static>, L<Markdown::Simple>, L<Template::Stencil>,
L<Search::Trigram>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2026 LNATION.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut
