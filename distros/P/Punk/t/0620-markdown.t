#!perl

# The `markdown` mount: a nested directory of .md files served as a
# documentation site.
#
# The site is built entirely at boot - tree walked, pages rendered, search
# index filled, response bytes frozen - so almost everything asserted here is
# a property of what to_app produced, not of the request that fetched it. The
# mount rides the ordinary mount table, so it inherits prefix dispatch and the
# rule that a mounted app bypasses hooks, guards and CSRF, exactly as `static`
# does; t/0122-mount.t owns that contract and this file does not repeat it.

use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PunkTest;

BEGIN {
    plan skip_all => 'needs Markdown::Simple 0.20+ with its C ABI'
        unless eval { require Markdown::Simple;
                      Markdown::Simple->can('_abi_ptr')
                      && Markdown::Simple::_abi_version() >= 1 };
    plan skip_all => 'needs Template::Stencil with its C ABI'
        unless eval { require Template::Stencil;
                      Template::Stencil->can('_abi_ptr') };
}

my $DOCS = "$FindBin::Bin/test/docs";

{
    package MDApp;
    use Punk;
    markdown '/docs' => $DOCS, title => 'Fixture Guide';
}

my $app = MDApp->to_app;

sub body { my $r = shift; ref $r->[2] eq 'ARRAY' ? ($r->[2][0] // '') : undef }
sub header {
    my ($r, $want) = @_;
    my $h = $r->[1];
    for (my $i = 0; $i < @$h; $i += 2) {
        return $h->[$i + 1] if lc $h->[$i] eq lc $want;
    }
    return undef;
}

# ---- url derivation ---------------------------------------------------------

{
    # index.md collapses to the directory it sits in, so the root index is the
    # mount itself rather than a second address alongside it.
    my $r = hit($app, path => '/docs');
    is $r->[0], 200, 'the mount root serves index.md';
    like body($r), qr{The front page of the fixture guide},
        'with that file rendered';

    is hit($app, path => '/docs/guide/intro')->[0], 200,
        'a nested page is at its path minus the .md';
    is hit($app, path => '/docs/reference/api')->[0], 200,
        'in every section';
    is hit($app, path => '/docs/index')->[0], 404,
        'the index file has no second address of its own';
}

{
    # A tree with no index file has nothing at its root, but answering the
    # mount's own address with a 404 while holding a navigation full of pages
    # helps nobody, so it goes to the first page instead.
    {
        package MDNoIndex;
        use Punk;
        markdown '/guide' => "$DOCS/guide";
    }
    my $ni = MDNoIndex->to_app;
    my $r = hit($ni, path => '/guide');
    is $r->[0], 301, 'a tree with no index file redirects at its root';
    is header($r, 'Location'), '/guide/intro',
        'to the first page in navigation order';
}

# ---- canonical addresses ----------------------------------------------------

{
    my $r = hit($app, path => '/docs/guide/intro/');
    is $r->[0], 301, 'a trailing slash redirects';
    is header($r, 'Location'), '/docs/guide/intro', 'to the canonical url';

    $r = hit($app, path => '/docs/guide/intro.md');
    is $r->[0], 301, 'so does a .md suffix';
    is header($r, 'Location'), '/docs/guide/intro', 'to the same place';
}

{
    # The canonical redirect names a url in a Location header, and PATH_INFO
    # arrives percent-DECODED, so redirecting to whatever was asked for would
    # echo bytes the client chose: "//evil/" is a protocol-relative 301 off
    # the site, and a decoded CR/LF ends the header and splits the response.
    # Only a path that IS a page may be named, so nothing else is ever echoed.
    my %evil = (
        'protocol-relative'  => '//evil.example/',
        'backslash'          => '/\\evil.example/',
        'CRLF'               => "/\r\nX-Injected: yes/",
        'CRLF under .md'     => "/\r\nX-Injected: yes.md",
        'tab'                => "/\t//evil.example/",
        'unknown page'       => '/docs/nope.md',
        'unknown dir'        => '/docs/nope/',
    );
    for my $why (sort keys %evil) {
        my $r = hit($app, path => $evil{$why});
        isnt $r->[0], 301, "no redirect for $why";
        is header($r, 'Location'), undef, "nothing echoed into Location for $why";
    }

    # and the same at a root mount, where there is no prefix to keep a
    # reflected path on-site
    {
        package MDRoot;
        use Punk;
        markdown '/' => $DOCS, title => 'Root Guide';
    }
    my $root = MDRoot->to_app;
    is hit($root, path => '/guide/intro/')->[0], 301,
        'a root mount still canonicalises a real page';
    is header(hit($root, path => '/guide/intro/'), 'Location'), '/guide/intro',
        'to the canonical url';
    my $r = hit($root, path => '//evil.example/');
    isnt $r->[0], 301, 'a root mount does not redirect to a protocol-relative path';
    is header($r, 'Location'), undef, 'and names nothing in Location';
}

# ---- titles -----------------------------------------------------------------

{
    my $b = body(hit($app, path => '/docs/guide/intro'));
    like $b, qr{<title>Introduction - Fixture Guide</title>},
        'front matter title wins, and the site title is appended';

    $b = body(hit($app, path => '/docs/reference/api'));
    like $b, qr{<title>API Reference - Fixture Guide</title>},
        'with no front matter the first H1 is the title';

    # guide/advanced.md has front matter but no title:, so the H1 supplies it
    $b = body(hit($app, path => '/docs/guide/advanced'));
    like $b, qr{<title>Advanced Usage - },
        'front matter without a title: still falls through to the H1';
}

# ---- front matter is consumed, not rendered ---------------------------------

{
    my $b = body(hit($app, path => '/docs/guide/intro'));
    unlike $b, qr{order:},  'the front matter block does not reach the page';
    unlike $b, qr{^---}m,   'nor its delimiters';
}

# ---- draft pages are not published ------------------------------------------

{
    is hit($app, path => '/docs/guide/hidden')->[0], 404,
        'a page marked draft is not served';
    unlike body(hit($app, path => '/docs')), qr{Hidden},
        'and does not appear in the navigation';
}

# ---- navigation -------------------------------------------------------------

{
    my $b = body(hit($app, path => '/docs/guide/intro'));

    like $b, qr{href="/docs"},                  'nav links the root';
    like $b, qr{href="/docs/guide/advanced"},   'and every other page';
    like $b, qr{href="/docs/reference/api"},    'across sections';

    like $b, qr{<summary>Guide</summary>},      'directories become sections';
    like $b, qr{<summary>Reference</summary>},  'one per top-level directory';

    # The nav is rebuilt per page at boot precisely so this works without
    # JavaScript.
    like $b, qr{href="/docs/guide/intro" class="current"},
        'the current page is marked';
    unlike $b, qr{href="/docs/guide/advanced" class="current"},
        'and only the current page';

    like $b, qr{>Start here</a>},
        'a front matter nav: label overrides the title in the sidebar';
    like $b, qr{<title>Introduction},
        'while the page title stays the title';
}

# ---- ordering ---------------------------------------------------------------

{
    my $b = body(hit($app, path => '/docs'));
    my ($nav) = $b =~ m{(<ul class="punk-md-nav">.*?</ul>\s*</nav>)}s;
    ok $nav, 'found the navigation block';

    my $intro    = index $nav, '/docs/guide/intro';
    my $advanced = index $nav, '/docs/guide/advanced';
    ok $intro >= 0 && $advanced >= 0, 'both guide pages are in it';
    ok $intro < $advanced,
        'front matter order: sorts within a section, beating the alphabet';

    # The index file is the landing page for what it sits in, so it leads.
    # Without that it sorts last on an absent order:, and the front page of a
    # guide arrives underneath the pages it introduces.
    my $root = index $nav, '"/docs"';
    ok $root >= 0, 'the root page is in the navigation';
    ok $root < $intro, 'and leads it, having no explicit order of its own';
}

# ---- headings, anchors and the table of contents ----------------------------

{
    my $b = body(hit($app, path => '/docs/guide/intro'));
    like $b, qr{<h1 id="introduction">}, 'headings carry anchors';
    like $b, qr{<h2 id="details">},      'at every level that matters';

    like $b, qr{class="punk-md-toc"},    'a table of contents is built';
    like $b, qr{<a href="#details">Details</a>},
        'linking the anchors actually emitted';
    unlike $b, qr{<a href="#introduction">},
        'h1 is the page title and is left out of the contents';
}

# ---- syntax highlighting ----------------------------------------------------

{
    my $b = body(hit($app, path => '/docs/guide/intro'));
    like $b, qr{<code class="language-perl">}, 'fenced code keeps its language';
    like $b, qr{class="esh-},                  'and is highlighted';
}

# ---- assets in the tree -----------------------------------------------------

{
    # Served by the same ps_serve_file the static mount uses, which is what
    # makes a relative image reference in a document work.
    my $r = hit($app, path => '/docs/guide/diagram.png');
    is $r->[0], 200, 'a non-markdown file in the tree is served';
    is header($r, 'Content-Type'), 'image/png', 'with its own content type';
    ok defined header($r, 'Last-Modified'), 'and a Last-Modified';

    my $r2 = hit($app, path => '/docs/guide/diagram.png',
                 env => { HTTP_IF_MODIFIED_SINCE => header($r, 'Last-Modified') });
    is $r2->[0], 304, 'and answers a conditional request';

    # one range case proves the shared path: the asset serves 206 exactly
    # like a static mount, because it is literally the same function
    my $r3 = hit($app, path => '/docs/guide/diagram.png',
                 env => { HTTP_RANGE => 'bytes=0-3' });
    is $r3->[0], 206, 'an asset range is a 206';
    is header($r3, 'Content-Range'),
       'bytes 0-3/' . header($r, 'Content-Length'), 'with Content-Range';
}

# ---- the shipped stylesheet -------------------------------------------------

{
    my $r = hit($app, path => '/docs/_punk/app.css');
    is $r->[0], 200, 'the stylesheet is served from the assets path';
    is header($r, 'Content-Type'), 'text/css; charset=utf-8',
        'as css, not as a document';
    like body($r), qr{punk-md-nav}, 'and is the real stylesheet';
    like body(hit($app, path => '/docs')), qr{href="/docs/_punk/app.css"},
        'which is what the page links';
}

# ---- bytes, not characters --------------------------------------------------

{
    # A PSGI body must be octets: if the UTF-8 flag were set anywhere on this
    # path, Content-Length would count characters and disagree with the wire.
    my $r = hit($app, path => '/docs/reference/unicode');
    is $r->[0], 200, 'a non-ASCII page renders';
    my $b = body($r);
    ok !utf8::is_utf8($b), 'the body is bytes, not characters';
    is header($r, 'Content-Length'), length $b,
        'so Content-Length matches the byte count exactly';
    like $b, qr/Caf\xc3\xa9/, 'and the octets came through unchanged';
}

# ---- method handling --------------------------------------------------------

{
    my $r = hit($app, path => '/docs', method => 'HEAD');
    is $r->[0], 200, 'HEAD is answered';
    is body($r), '', 'with no body';
    ok header($r, 'Content-Length') > 0,
        'but the Content-Length the GET would have sent';

    $r = hit($app, path => '/docs', method => 'POST');
    is $r->[0], 405, 'anything else is refused';
    is header($r, 'Allow'), 'GET, HEAD', 'naming what is allowed';
}

# ---- not found --------------------------------------------------------------

{
    my $r = hit($app, path => '/docs/nothing/here');
    is $r->[0], 404, 'an unknown page is a 404';
    like body($r), qr{punk-md-nav},
        'rendered through the same shell, so it is navigable';
    is header($r, 'Content-Type'), 'text/html; charset=utf-8',
        'and is a document, not a bare string';
}

# ---- the template contract ---------------------------------------------------

{
    # A custom template_dir has to supply page.tmpl, wrapper.tmpl and app.css,
    # and one page.tmpl renders all three kinds of response. `kind` is what
    # lets it tell them apart, so it is part of the documented surface.
    my $dir = "$FindBin::Bin/test/mdtmpl-$$";
    mkdir $dir or die "cannot make $dir: $!";

    open my $w, '>', "$dir/wrapper.tmpl" or die $!;
    print {$w} "<html><body>KIND={% kind %} TITLE={% title %}\n"
             . "{% content %}</body></html>\n";
    close $w;

    open my $p, '>', "$dir/page.tmpl" or die $!;
    print {$p} "<main>{% raw content %}</main>\n";
    close $p;

    open my $c, '>', "$dir/app.css" or die $!;
    print {$c} "body { color: rebeccapurple }\n";
    close $c;

    my $ok = eval {
        package MDCustom;
        use Punk;
        markdown '/d' => $DOCS, template_dir => $dir;
        1;
    };
    my $custom = eval { MDCustom->to_app };
    ok $ok && $custom, 'a template_dir with those three files boots'
        or diag $@;

    SKIP: {
        skip 'custom mount did not build', 5 unless $custom;

        my $page = body(hit($custom, path => '/d/guide/intro'));
        like $page, qr{KIND=page}, 'a document renders with kind=page';
        like $page, qr{<main>.*Introduction}s, 'through the custom page.tmpl';
        unlike $page, qr{punk-md-nav},
            'and the shipped templates are not used at all';

        like body(hit($custom, path => '/d/search')), qr{KIND=search},
            'the search page renders with kind=search';
        like body(hit($custom, path => '/d/nope')), qr{KIND=notfound},
            'and the 404 with kind=notfound';

        my $css = hit($custom, path => '/d/_punk/app.css');
        like body($css), qr{rebeccapurple},
            'app.css is taken from the custom directory too';
    }

    unlink glob "$dir/*";
    rmdir $dir;
}

# ---- traversal --------------------------------------------------------------

{
    for my $path ('/docs/../Punk.xs', '/docs/guide/../../../etc/passwd') {
        my $r = hit($app, path => $path);
        is $r->[0], 404, "a .. segment is refused ($path)";
    }
}

# ---- boot-time failures are boot-time --------------------------------------

{
    my $err = do {
        local $@;
        eval {
            package MDBad;
            use Punk;
            markdown '/nope' => '/no/such/directory/anywhere';
            MDBad->to_app;
        };
        $@;
    };
    like $err, qr/not a directory/,
        'pointing the mount at nothing fails at to_app, not on a request';
}

done_testing();
