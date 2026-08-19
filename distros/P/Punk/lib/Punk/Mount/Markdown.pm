package Punk::Mount::Markdown;

use 5.010;
use strict;
use warnings;
use Punk ();

our $VERSION = '0.20';

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
what makes a relative C<< ![](diagram.png) >> in a document work.

=head1 FRONT MATTER

A document may open with a restricted C<---> block:

    ---
    title: Getting Started
    nav: Start here
    order: 1
    ---

    # Getting Started

Recognised keys are C<title>, C<nav> (the sidebar label, when it should differ
from the title), C<order> (the sort key within a section) and C<draft> (when
true, the page is skipped entirely). Anything else is ignored rather than an
error, so a document carrying front matter for some other tool still renders.

This is deliberately not YAML. Running a YAML parser on every page at boot to
read two scalars would put a dependency on the C path for no benefit.

Where there is no C<title>, the first C<< # >> heading is used, and failing
that the filename with hyphens and underscores turned into spaces.

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

=item * C<sort> - C<order> (default) groups pages by section and orders them
by front-matter C<order:>, or C<alpha> to keep the plain path order.

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

=back

The navigation and the table of contents arrive as ready HTML rather than as
data to loop over because Stencil has no recursion and no dynamic includes, so
an arbitrarily deep tree cannot be walked in a template. They are rebuilt per
page at boot, which is what lets the current entry carry a C<current> class
without any JavaScript.

If you only want to restyle the site, supply your own F<app.css> and leave the
templates alone: copy the shipped F<templates/> directory, replace the
stylesheet, and point C<template_dir> at your copy.

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
