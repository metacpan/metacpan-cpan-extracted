#!perl

# $app->markdown_pages($prefix): a markdown mount's pages, in its order, as
# fresh data - for a landing page, an index or a feed built from the same
# table the mount serves.

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
}

sub body { my $r = shift; ref $r->[2] eq 'ARRAY' ? ($r->[2][0] // '') : undef }

sub spew {
    my ($file, $text) = @_;
    open my $fh, '>:raw', $file or die "$file: $!";
    print {$fh} Encode::encode('UTF-8', $text);
    close $fh;
}

my $n = 0;
sub build {
    my ($decl) = @_;
    my $pkg = 'MDPages' . ++$n;
    eval "package $pkg; use Punk; $decl; 1" or die $@;
    my $app = $pkg->to_app;
    return ($pkg, $app);
}

my $tree = File::Temp->newdir;
mkdir "$tree/sub";
spew("$tree/older.md", <<'MD');
---
title: Older Post
date: 2026-10-01
description: The older one, described.
tags: [perl, xs]
---
# Older Post

Body of the older post.
MD
spew("$tree/newer.md", <<'MD');
---
date: 2026-10-19
updated: 2026-10-21
order: 1
---
# Newer Post

The first paragraph of the newer post.

A second paragraph.
MD
spew("$tree/sub/note.md", "# A Note\n\nUndated words.\n");
spew("$tree/draft.md", "---\ndraft: 1\ndate: 2026-12-01\n---\n# Draft\n");
spew("$tree/long.md", "# Long\n\na" . ('é' x 150) . " tail\n");

my $esc = "$tree"; $esc =~ s/'/\\'/g;

# ---- the shape ----------------------------------------------------------------

{
    my ($pkg) = build("markdown '/blog' => '$esc', sort => 'date', search => 0");
    my $pages = $pkg->punk_app->markdown_pages('/blog');
    is ref $pages, 'ARRAY', 'an arrayref';
    is_deeply [ map $_->{url}, @$pages ],
        [ '/blog/newer', '/blog/older', '/blog/long', '/blog/sub/note' ],
        'in the mount\'s order (date), the draft absent';

    my ($newer) = grep $_->{path} eq '/newer', @$pages;
    is_deeply [ sort keys %$newer ],
        [ qw(date meta path summary title updated url) ], 'each page has the seven keys';
    is $newer->{title}, 'Newer Post', 'title from the H1';
    is $newer->{date},    1792368000, 'date as the epoch';
    is $newer->{updated}, 1792540800, 'updated as the epoch';
    is $newer->{summary},
        'The first paragraph of the newer post. A second paragraph.',
        'summary from the body, the title dropped, whitespace collapsed';
    is $newer->{meta}{order}, '1', 'meta holds every front-matter key';

    my ($older) = grep $_->{path} eq '/older', @$pages;
    is $older->{summary}, 'The older one, described.',
        'summary from description when there is one';
    is $older->{meta}{tags}, '[perl, xs]', 'a list stays its string';
    is $older->{updated}, $older->{date}, 'updated defaults to the date';

    my ($note) = grep $_->{path} eq '/sub/note', @$pages;
    ok !defined $note->{date}, 'an undated page has an undef date';
    ok !defined $note->{updated}, '...and updated';
    is_deeply $note->{meta}, {}, '...and an empty meta';

    my ($long) = grep $_->{path} eq '/long', @$pages;
    like $long->{summary}, qr/\.\.\.\z/, 'a long summary is cut with ...';
    ok utf8::is_utf8($long->{summary}), 'summary is characters';
    my $bytes = Encode::encode('UTF-8', substr($long->{summary}, 0, -3));
    ok length($bytes) <= 200, 'cut to 200 bytes';
    ok eval { Encode::decode('UTF-8', $bytes, Encode::FB_CROAK); 1 },
        '...on a UTF-8 boundary';
}

# ---- the other orders ---------------------------------------------------------

{
    my ($pkg) = build("markdown '/d' => '$esc', search => 0");
    is_deeply [ map $_->{path}, @{ $pkg->punk_app->markdown_pages('/d') } ],
        [ '/newer', '/long', '/older', '/sub/note' ],
        'sort order: by section, then order:, then path';
}
{
    my ($pkg) = build("markdown '/d' => '$esc', sort => 'alpha', search => 0");
    is_deeply [ map $_->{path}, @{ $pkg->punk_app->markdown_pages('/d') } ],
        [ '/long', '/newer', '/older', '/sub/note' ],
        'sort alpha: by path';
}

# ---- copies -------------------------------------------------------------------

{
    my ($pkg, $app) = build("markdown '/c' => '$esc', search => 0, title => 'S'");
    my $first = $pkg->punk_app->markdown_pages('/c');
    $_->{title} = 'CHANGED', $_->{meta}{x} = 1, $_->{url} = 'x' for @$first;
    my $again = $pkg->punk_app->markdown_pages('/c');
    isnt $again->[0]{title}, 'CHANGED', 'editing the list does not edit the next one';
    ok !exists $again->[0]{meta}{x}, '...nor its meta';
    unlike body(hit($app, path => '/c/older')), qr/CHANGED/,
        '...nor the page served';
}

# ---- characters ---------------------------------------------------------------

{
    my $u = File::Temp->newdir;
    spew("$u/u.md", "---\ndescription: Café 日本\n---\n# Naïve\n");
    my $ue = "$u"; $ue =~ s/'/\\'/g;
    my ($pkg) = build("markdown '/u' => '$ue', search => 0");
    my ($p) = @{ $pkg->punk_app->markdown_pages('/u') };
    is $p->{title}, 'Naïve', 'a UTF-8 title arrives as characters';
    is $p->{meta}{description}, 'Café 日本', '...and a meta value';
    is $p->{summary}, 'Café 日本', '...and the summary';
}

# ---- where it looks ----------------------------------------------------------

{
    my ($pkg) = build("markdown '/a' => '$esc', search => 0; "
                    . "markdown '/b' => '$esc/sub', search => 0; "
                    . "static '/s' => '$esc'");
    is scalar @{ $pkg->punk_app->markdown_pages('/a') }, 4, 'two mounts: the first';
    is_deeply [ map $_->{url}, @{ $pkg->punk_app->markdown_pages('/b') } ],
        [ '/b/note' ], '...and the second, kept apart';
    is scalar @{ $pkg->punk_app->markdown_pages('/a/') }, 4,
        'a trailing slash on the prefix is ignored';

    my $err = do { local $@; eval { $pkg->punk_app->markdown_pages('/s') }; $@ };
    like $err, qr{no markdown mount at '/s' \(markdown mounts: /a, /b\)|no markdown mount at '/s' \(markdown mounts: /b, /a\)},
        'a static mount is not mistaken for one, and the error names those there are';

    $err = do { local $@; eval { $pkg->punk_app->markdown_pages('/nope') }; $@ };
    like $err, qr{no markdown mount at '/nope'}, 'an unknown prefix croaks';
}

{
    my ($pkg) = build("get '/' => sub { \$_[0]->text('x') }");
    my $err = do { local $@; eval { $pkg->punk_app->markdown_pages('/blog') }; $@ };
    like $err, qr{no markdown mount at '/blog' \(there are none\)},
        'an app without markdown mounts says so';
}

{
    my $pkg = 'MDPagesEarly';
    eval "package $pkg; use Punk; markdown '/e' => '$esc', search => 0; 1" or die $@;
    my $err = do { local $@; eval { $pkg->punk_app->markdown_pages('/e') }; $@ };
    like $err, qr{has not been compiled yet}, 'before to_app it croaks naming why';
}

# ---- from a route, and a route at the mount's own prefix -----------------------

{
    my (undef, $app) = build(
        "markdown '/blog' => '$esc', sort => 'date', search => 0; "
      . "get '/blog' => sub { my \$c = shift; "
      . "  \$c->text(join ',', map \$_->{title}, \@{ \$c->app->markdown_pages('/blog') }) }");
    my $r = hit($app, path => '/blog');
    is $r->[0], 200, 'a route at the mount\'s prefix answers it';
    is body($r), 'Newer Post,Older Post,Long,A Note',
        '...with the list read through $c->app';
    is hit($app, path => '/blog/older')->[0], 200,
        '...and the mount still serves the pages under it';
}

# ---- reload -------------------------------------------------------------------

{
    my $d = File::Temp->newdir;
    spew("$d/r.md", "---\ndescription: before\ndate: 2026-10-01\n---\n# R\n");
    my $de = "$d"; $de =~ s/'/\\'/g;
    my ($pkg, $app) = build("markdown '/r' => '$de', search => 0, reload => 1");
    is $pkg->punk_app->markdown_pages('/r')->[0]{summary}, 'before', 'reload: first';
    spew("$d/r.md", "---\ndescription: after\ndate: 2026-10-02\n---\n# R\n");
    my $t = time + 5;
    utime $t, $t, "$d/r.md";
    hit($app, path => '/r/r');
    my ($p) = @{ $pkg->punk_app->markdown_pages('/r') };
    is $p->{summary}, 'after', 'reload: meta follows the re-read page';
    is $p->{date}, 1790899200, '...and so does the date';
}

done_testing;
