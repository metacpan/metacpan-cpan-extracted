#!perl

# Search over a markdown mount.
#
# The index is a Search::Trigram built at boot, filled with each page's plain
# text through Markdown::Simple's strip entry so it indexes prose rather than
# tags. The search page is the one request path the mount does not serve from
# frozen bytes: the query string is parsed, the index queried through sg_abi
# into a stack array, and the hits rendered through the same shell as every
# other page.

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
    plan skip_all => 'needs Search::Trigram 0.02+ with its C ABI'
        unless eval { require Search::Trigram;
                      Search::Trigram->can('_abi_ptr')
                      && Search::Trigram::_abi_version() >= 1 };
}

my $DOCS = "$FindBin::Bin/test/docs";

{
    package MDSearch;
    use Punk;
    markdown '/docs' => $DOCS, title => 'Fixture Guide';
}

my $app = MDSearch->to_app;

sub body { my $r = shift; ref $r->[2] eq 'ARRAY' ? ($r->[2][0] // '') : '' }
sub search { body(hit($app, path => '/docs/search', query => $_[0] // '')) }

# Just the results list. The navigation is full of <li><a href="/docs/..."> of
# its own, so anything matching over the whole page counts the sidebar too.
sub results {
    my ($out) = @_;
    my ($block) = $out =~ m{(<ol class="punk-md-results">.*?</ol>)}s;
    return [] unless $block;
    return [ $block =~ m{<li><a href="([^"]+)"}g ];
}

# ---- the page exists and is a page ------------------------------------------

{
    my $r = hit($app, path => '/docs/search');
    is $r->[0], 200, 'the search page is served';
    like body($r), qr{punk-md-nav},
        'through the same shell, so it has the navigation';
    like body($r), qr{<input type="search" name="q"},
        'and a form to search with';
    like body($r), qr{Type a query},
        'an empty query prompts rather than listing everything';
}

# ---- a query that matches ----------------------------------------------------

{
    my $out = search('q=markdown');
    like $out, qr{<ol class="punk-md-results">}, 'a match produces results';
    like $out, qr{href="/docs/guide/intro"},
        'linking the page that contains the term';
    like $out, qr{class="punk-md-snippet"}, 'with a snippet';
}

{
    # A term that appears in exactly one fixture page, so ranking has an
    # unambiguous right answer.
    my $hits = results(search('q=zebra'));
    is $hits->[0], '/docs/guide/advanced',
        'a distinctive term ranks its own page first';
}

# ---- indexing is over prose, not markup -------------------------------------

{
    # The index is built from strip_markdown output, not from the rendered
    # HTML. If it were the HTML, the highlighter's own class names would be
    # searchable, which is both useless and confusing.
    #
    # Note this is a trigram index, so a query never has to appear verbatim to
    # score: what is being asserted is that a string which exists ONLY in the
    # markup contributes nothing an ordinary word does not.
    my $hits = results(search('q=esh'));
    is scalar @$hits, 0, 'highlighter class names are not in the index';
}

# ---- titles are indexed too --------------------------------------------------

{
    my $out = search('q=Introduction');
    like $out, qr{href="/docs/guide/intro"},
        'a page is findable by its title, not only its body';
}

# ---- draft pages stay out of the index --------------------------------------

{
    my $hits = results(search('q=Hidden'));
    is scalar( grep { m{/hidden} } @$hits ), 0,
        'a draft page is not indexed any more than it is served';
}

# ---- a query that matches nothing -------------------------------------------

{
    # Trigrams, so "nothing" means sharing no three-letter run with any
    # document, not merely being an unlikely word.
    my $out = search('q=qqqjjjxxx');
    is scalar @{ results($out) }, 0, 'a query sharing nothing lists nothing';
    like $out, qr{No results for}, 'and says so';
    like $out, qr{punk-md-nav}, 'while still rendering the whole shell';
}

# ---- the query is echoed safely ---------------------------------------------

{
    # The query is the one piece of untrusted input that reaches the page.
    my $out = search('q=%3Cscript%3Ealert(1)%3C%2Fscript%3E');
    unlike $out, qr{<script>alert}, 'the query is not echoed as markup';
    like $out, qr{&lt;script&gt;}, 'it is escaped';
}

{
    my $out = search('q=%22onmouseover%3D%22x');
    unlike $out, qr{value=""onmouseover}, 'a quote cannot break out of the input';
    like $out, qr{&quot;}, 'it is escaped too';
}

# ---- search can be turned off ------------------------------------------------

{
    {
        package MDNoSearch;
        use Punk;
        markdown '/docs' => $DOCS, title => 'No Search', search => 0;
    }
    my $off = MDNoSearch->to_app;
    my $page = body(hit($off, path => '/docs'));
    unlike $page, qr{punk-md-searchlink},
        'with search => 0 the header does not offer it';
}

# ---- a custom search path -----------------------------------------------------

{
    {
        package MDAltSearch;
        use Punk;
        markdown '/docs' => $DOCS, search_path => '/find';
    }
    my $alt = MDAltSearch->to_app;
    is hit($alt, path => '/docs/find')->[0], 200,
        'search_path moves the page';
    is hit($alt, path => '/docs/search')->[0], 404,
        'and it is not also at the default';
}

done_testing();
