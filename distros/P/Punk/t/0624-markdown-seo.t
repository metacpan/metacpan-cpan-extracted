#!perl

# The shipped wrapper writes a page's SEO tags from its front matter:
# description, keywords, author, robots, canonical, Open Graph and Twitter.
# The origin for canonical and absolute image URLs is the app's `host`, passed
# in at compile, never the request's Host header.

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
sub head { my $b = body(shift); $b =~ s{</head>.*}{}s; $b }
sub count { my ($s, $re) = @_; my $n = () = $s =~ /$re/g; $n }

sub spew {
    my ($file, $text) = @_;
    open my $fh, '>:raw', $file or die "$file: $!";
    print {$fh} Encode::encode('UTF-8', $text);
    close $fh;
}

my $tree = File::Temp->newdir;
mkdir "$tree/sub";

spew("$tree/full.md", <<'MD');
---
title: Full Page
description: A page with "quotes" & <angles>
keywords: perl, xs
author: LNATION
robots: noindex, follow
image: /img/full.png
image_alt: A diagram
date: 2026-10-19
---
# Full Page

Body.
MD

spew("$tree/bare.md", "# Bare\n\nNothing in front.\n");

spew("$tree/canon.md", <<'MD');
---
canonical: https://elsewhere.example/original
og_type: book
---
# Canon
MD

spew("$tree/abs.md", "---\nimage: https://cdn.example/x.png\n---\n# Abs\n");
spew("$tree/rel.md", "---\nimage: pic.png\n---\n# Rel\n");
spew("$tree/sub/index.md", "---\nimage: s.png\n---\n# Sub\n");
spew("$tree/sub/leaf.md", "---\nimage: img/l.png\n---\n# Leaf\n");

{
    package MDSeo;
    use Punk;
    host 'https://ex.com/';
    markdown '/d' => "$tree", title => 'Site';
}
my $app = MDSeo->to_app;

# ---- every key ----------------------------------------------------------------

{
    my $h = head(hit($app, path => '/d/full'));
    my %want = (
        'name="description"'        => 'A page with &quot;quotes&quot; &amp; &lt;angles&gt;',
        'name="keywords"'           => 'perl, xs',
        'name="author"'             => 'LNATION',
        'name="robots"'             => 'noindex, follow',
        'property="og:type"'        => 'article',
        'property="og:title"'       => 'Full Page',
        'property="og:site_name"'   => 'Site',
        'property="og:url"'         => 'https://ex.com/d/full',
        'property="og:description"' => 'A page with &quot;quotes&quot; &amp; &lt;angles&gt;',
        'property="og:image"'       => 'https://ex.com/img/full.png',
        'property="og:image:alt"'   => 'A diagram',
        'name="twitter:card"'       => 'summary_large_image',
        'name="twitter:title"'      => 'Full Page',
        'name="twitter:description"'=> 'A page with &quot;quotes&quot; &amp; &lt;angles&gt;',
        'name="twitter:image"'      => 'https://ex.com/img/full.png',
        'name="twitter:image:alt"'  => 'A diagram',
        'property="article:published_time"' => '2026-10-19T00:00:00Z',
        'property="article:modified_time"'  => '2026-10-19T00:00:00Z',
    );
    for my $k (sort keys %want) {
        is count($h, qr{<meta \Q$k\E content="\Q$want{$k}\E">}), 1,
            "every key: $k once, with its value";
    }
    is count($h, qr{<link rel="canonical" href="https://ex\.com/d/full">}), 1,
        'every key: canonical from the host, prefix and url';
    unlike $h, qr{<angles>|"quotes"}, 'nothing in the head is unescaped';
}

# ---- no keys ------------------------------------------------------------------

{
    my $h = head(hit($app, path => '/d/bare'));
    for my $absent (qw(description keywords author robots og:description
                       og:image og:image:alt twitter:description
                       twitter:image article:published_time
                       article:modified_time)) {
        unlike $h, qr{(?:name|property)="\Q$absent\E"},
            "no keys: no $absent tag";
    }
    like $h, qr{<meta property="og:type" content="website">},
        'no keys: og:type is website without a date';
    like $h, qr{<meta property="og:title" content="Bare">}, 'no keys: og:title';
    like $h, qr{<meta property="og:site_name" content="Site">},
        'no keys: og:site_name';
    like $h, qr{<meta name="twitter:card" content="summary">},
        'no keys: the plain twitter card';
    like $h, qr{<link rel="canonical" href="https://ex\.com/d/bare">},
        'no keys: a canonical still comes from the host';
}

# ---- overrides ----------------------------------------------------------------

{
    my $h = head(hit($app, path => '/d/canon'));
    like $h, qr{<link rel="canonical" href="https://elsewhere\.example/original">},
        'canonical: front matter wins over the host';
    like $h, qr{<meta property="og:url" content="https://elsewhere\.example/original">},
        '...and og:url follows it';
    like $h, qr{<meta property="og:type" content="book">},
        'og_type: front matter wins';
}

# ---- image forms --------------------------------------------------------------

{
    my %img = (
        '/d/abs'      => 'https://cdn.example/x.png',
        '/d/rel'      => 'https://ex.com/d/pic.png',
        '/d/sub'      => 'https://ex.com/d/sub/s.png',
        '/d/sub/leaf' => 'https://ex.com/d/sub/img/l.png',
    );
    for my $p (sort keys %img) {
        like head(hit($app, path => $p)),
            qr{<meta property="og:image" content="\Q$img{$p}\E">},
            "image on $p resolves to $img{$p}";
    }
}

# ---- the request never supplies the origin ------------------------------------

{
    my $b = body(hit($app, path => '/d/bare',
                     env => { HTTP_HOST => 'evil.example',
                              SERVER_NAME => 'evil.example' }));
    unlike $b, qr{evil\.example}, 'a Host header changes nothing';
    is $b, body(hit($app, path => '/d/bare')), '...the body is the frozen one';
}

# ---- no host ------------------------------------------------------------------

{
    my $nh = do {
        package MDSeoNoHost;
        use Punk;
        markdown '/n' => "$tree", title => 'Site';
        MDSeoNoHost->to_app;
    };
    my $h = head(hit($nh, path => '/n/full'));
    unlike $h, qr{rel="canonical"}, 'no host: no canonical';
    unlike $h, qr{og:url}, 'no host: no og:url';
    like $h, qr{<meta property="og:image" content="/img/full\.png">},
        'no host: a rooted image stays rooted';
    like head(hit($nh, path => '/n/rel')),
        qr{<meta property="og:image" content="/n/pic\.png">},
        'no host: a relative image is rooted under the prefix';
    like head(hit($nh, path => '/n/canon')),
        qr{<link rel="canonical" href="https://elsewhere\.example/original">},
        'no host: an explicit canonical is still written';
}

# ---- the mount's own host wins ------------------------------------------------

{
    my $mh = do {
        package MDSeoMountHost;
        use Punk;
        host 'https://app.example';
        markdown '/m' => "$tree", host => 'https://docs.example';
        MDSeoMountHost->to_app;
    };
    like head(hit($mh, path => '/m/bare')),
        qr{<link rel="canonical" href="https://docs\.example/m/bare">},
        'a host on the mount wins over the app\'s';
}

# ---- not a page ---------------------------------------------------------------

{
    my $h = head(hit($app, path => '/d/nope'));
    unlike $h, qr{rel="canonical"|og:|twitter:},
        'the 404 carries no canonical and no social tags';
    $h = head(hit($app, path => '/d/search', query => 'q=page'));
    unlike $h, qr{rel="canonical"|og:|twitter:},
        'nor does the search page';
}

# ---- a UTF-8 description ------------------------------------------------------

{
    my $u = File::Temp->newdir;
    spew("$u/u.md", "---\ndescription: Café naïve 日本語\n---\n# U\n");
    my $ua = do {
        package MDSeoUtf8;
        use Punk;
        host 'https://ex.com';
        markdown '/u' => "$u";
        MDSeoUtf8->to_app;
    };
    my $h = Encode::decode('UTF-8', head(hit($ua, path => '/u/u')));
    like $h, qr{<meta name="description" content="Café naïve 日本語">},
        'a UTF-8 description is written once-encoded';
}

done_testing;
