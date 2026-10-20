#!perl

# Front matter reaches the templates as `meta`: every key, as written, so a
# page can carry its own description, image or anything a site's templates
# read. The search page and the 404 get an empty hash.

use 5.010;
use strict;
use warnings;
use utf8;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PunkTest;
use File::Temp ();
use Encode ();

BEGIN {
    plan skip_all => 'needs Markdown::Simple 0.20+ with its C ABI'
        unless eval { require Markdown::Simple;
                      Markdown::Simple->can('_abi_ptr')
                      && Markdown::Simple::_abi_version() >= 1 };
    plan skip_all => 'needs Template::Stencil with its C ABI'
        unless eval { require Template::Stencil;
                      Template::Stencil->can('_abi_ptr') };
    plan skip_all => 'needs Search::Trigram for the search page'
        unless eval { require Search::Trigram;
                      Search::Trigram->can('_abi_ptr') };
}

sub body { my $r = shift; ref $r->[2] eq 'ARRAY' ? ($r->[2][0] // '') : undef }

sub spew {
    my ($file, $text) = @_;
    open my $fh, '>:raw', $file or die "$file: $!";
    print {$fh} Encode::encode('UTF-8', $text);
    close $fh;
}

my $tree = File::Temp->newdir;
my $tmpl = File::Temp->newdir;

spew("$tmpl/wrapper.tmpl",
     "<html>KIND={% kind %}\n{% content %}</html>\n");
spew("$tmpl/app.css", "body {}\n");
spew("$tmpl/page.tmpl", join '',
     "DESC=[{% meta.description %}]\n",
     "IMAGE=[{% meta.image %}]\n",
     "CUSTOM=[{% meta.x_custom %}]\n",
     "TAGS=[{% meta.tags %}]\n",
     "TITLE=[{% meta.title %}]\n",
     "{% if meta.description %}HAS_DESC{% end %}\n",
     "{% raw content %}\n");

spew("$tree/full.md", <<'MD');
---
title: Full Page
description: "A page with its own description"
image: /img/full.png
x_custom: anything at all
tags: [perl, xs]
---
# Full Page

Body text.
MD

spew("$tree/hostile.md", <<'MD');
---
description: <script>alert(1)</script> & "quotes"
---
# Hostile
MD

spew("$tree/unicode.md", <<'MD');
---
description: Café naïve 日本語
---
# Unicode
MD

spew("$tree/plain.md", "# Plain\n\nNo front matter here.\n");

{
    package MDMeta;
    use Punk;
    markdown '/d' => "$tree", template_dir => "$tmpl";
}
my $app = MDMeta->to_app;

{
    my $b = body(hit($app, path => '/d/full'));
    like $b, qr{DESC=\[A page with its own description\]},
        'a recognised SEO key reaches the template, quotes stripped';
    like $b, qr{IMAGE=\[/img/full\.png\]}, 'image arrives as written';
    like $b, qr{CUSTOM=\[anything at all\]},
        'a key the mount knows nothing about arrives too';
    like $b, qr{TAGS=\[\[perl, xs\]\]}, 'a list is passed as its string';
    like $b, qr{TITLE=\[Full Page\]}, 'the keys the mount reads are in meta as well';
    like $b, qr{HAS_DESC}, 'a template can branch on a meta key';
}

{
    my $b = body(hit($app, path => '/d/hostile'));
    unlike $b, qr{<script>alert}, 'a meta value is escaped by the template';
    like $b, qr{&lt;script&gt;}, '...as markup';
    like $b, qr{&amp;}, '...including an ampersand';
}

{
    my $b = Encode::decode('UTF-8', body(hit($app, path => '/d/unicode')));
    like $b, qr{DESC=\[Café naïve 日本語\]},
        'a UTF-8 value is encoded once, not twice';
}

{
    my $b = body(hit($app, path => '/d/plain'));
    like $b, qr{DESC=\[\]}, 'a page without front matter has an empty meta';
    unlike $b, qr{HAS_DESC}, '...that the branch sees as empty';
}

{
    my $b = body(hit($app, path => '/d/nope'));
    like $b, qr{KIND=notfound}, 'the 404 renders';
    like $b, qr{DESC=\[\]}, '...with an empty meta';

    $b = body(hit($app, path => '/d/search', query => 'q=page'));
    like $b, qr{KIND=search}, 'the search page renders';
    like $b, qr{DESC=\[\]}, '...with an empty meta';
}

# ---- reload re-reads the front matter ----------------------------------------

{
    my $rt = File::Temp->newdir;
    spew("$rt/p.md", "---\ndescription: before\n---\n# P\n");
    my $ra = do {
        package MDMetaReload;
        use Punk;
        markdown '/r' => "$rt", template_dir => "$tmpl", reload => 1;
        MDMetaReload->to_app;
    };
    like body(hit($ra, path => '/r/p')), qr{DESC=\[before\]}, 'reload: first read';

    spew("$rt/p.md", "---\ndescription: after\n---\n# P\n");
    my $t = time + 5;
    utime $t, $t, "$rt/p.md";
    like body(hit($ra, path => '/r/p')), qr{DESC=\[after\]},
        'reload: a changed key is picked up with the body';
    like body(hit($ra, path => '/r/p')), qr{DESC=\[after\]},
        '...and a second render from the kept front matter is not decoded twice';
}

{
    my $ut = File::Temp->newdir;
    spew("$ut/u.md", "---\ndescription: Crème\n---\n# U\n");
    my $ua = do {
        package MDMetaReloadUtf8;
        use Punk;
        markdown '/u' => "$ut", template_dir => "$tmpl", reload => 1;
        MDMetaReloadUtf8->to_app;
    };
    my $t = time + 5;
    utime $t, $t, "$ut/u.md";
    my $b = Encode::decode('UTF-8', body(hit($ua, path => '/u/u')));
    like $b, qr{DESC=\[Crème\]}, 'a UTF-8 value survives a reload render';
}

# ---- the shipped templates are unchanged by meta -----------------------------

{
    my $shipped = do {
        package MDMetaShipped;
        use Punk;
        markdown '/s' => "$tree", title => 'S';
        MDMetaShipped->to_app;
    };
    my $b = body(hit($shipped, path => '/s/full'));
    like $b, qr{<title>Full Page - S</title>}, 'the shipped wrapper still renders';
}

done_testing;
