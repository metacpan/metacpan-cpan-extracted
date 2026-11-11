#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use File::Temp ();
use Test::More;
use PunkTest;

# The markdown mount's edges: front matter that is never closed, a date
# that is not one, a page with no heading to take a title from, a table of
# contents with third-level entries, a page file that cannot be read, and
# the mounted app handed something that is not a PSGI env.

BEGIN {
    plan skip_all => 'needs Markdown::Simple 0.20+ with its C ABI'
        unless eval { require Markdown::Simple; Markdown::Simple->can('_abi_ptr') && Markdown::Simple::_abi_version() >= 1 };
    plan skip_all => 'needs Template::Stencil with its C ABI'
        unless eval { require Template::Stencil; Template::Stencil->can('_abi_ptr') };
}

my $DOCS = File::Temp::tempdir(CLEANUP => 1);
sub spew { my ($f, $s) = @_; open my $fh, '>', $f or die "$f: $!"; print $fh $s; close $fh }
spew("$DOCS/index.md",    "# Edges\n\nThe front page.\n");
spew("$DOCS/unclosed.md", "---\ntitle: Never closed\ndate: 2024-01-02\n\n# Unclosed\n\nBody after a front matter that never ends.\n");
spew("$DOCS/noh1.md",     "Just a paragraph, no heading anywhere.\n");
spew("$DOCS/toc.md",      "# Toc\n\n## First\n\ntext\n\n### Deeper\n\ntext\n\n## Second\n\ntext\n");
spew("$DOCS/quoted.md",   "---\ntitle: \"Quoted title\"\nrobots: 'noindex'\n---\n# Quoted\n\nbody\n");

{
    package MDEdge;
    use Punk;
    markdown '/docs' => $DOCS, title => 'Edge Guide';
    package main;
}
my $app = MDEdge->to_app;
sub body { my $r = shift; ref $r->[2] eq 'ARRAY' ? join('', @{ $r->[2] }) : '' }

{
    my $r = hit($app, path => '/docs/unclosed');
    is($r->[0], 200, 'a page whose front matter never closes still renders');
    like(body($r), qr/title: Never closed/, 'with the would-be front matter as content');
    like(body($r), qr/Unclosed/, 'and the body');
}
{
    my $bad = File::Temp::tempdir(CLEANUP => 1);
    spew("$bad/index.md", "# Bad\n");
    spew("$bad/baddate.md", "---\ntitle: Bad date\ndate: 2024-13-45\n---\n# Bad date\n");
    my $e = '';
    eval qq{ package MDBad; use Punk; markdown '/b' => '$bad'; MDBad->to_app } or $e = $@;
    like($e, qr/baddate\.md has date '2024-13-45', which is not YYYY-MM-DD or ISO-8601/, 'a date that is not one is a boot error');
    spew("$bad/baddate.md", "---\ntitle: Bad time\nupdated: 2024-02-28T25:61\n---\n# Bad time\n");
    $e = '';
    eval qq{ package MDBad2; use Punk; markdown '/b' => '$bad'; MDBad2->to_app } or $e = $@;
    like($e, qr/which is not YYYY-MM-DD or ISO-8601/, 'and so is a time that is not one');
}
{
    my $r = hit($app, path => '/docs/noh1');
    is($r->[0], 200, 'a page with no heading renders');
    like(body($r), qr/<title>.*noh1.*<\/title>|<title>.*Edge Guide.*<\/title>/s, 'the title falls back to the file or the guide');
}
{
    my $r = hit($app, path => '/docs/toc');
    is($r->[0], 200, 'a page with a table of contents renders');
    like(body($r), qr/class="lvl2"/, 'second-level entries');
    like(body($r), qr/class="lvl3"/, 'and third-level entries');
}
{
    my $r = hit($app, path => '/docs/quoted');
    like(body($r), qr/Quoted title/, 'a quoted front matter value is unquoted');
}
{
    my $raw = Punk::Mount::Markdown->app($DOCS);
    my $e = '';
    eval { $raw->('not an env'); 1 } or $e = $@;
    like($e, qr/the app takes a PSGI env hashref/, 'the mounted app refuses what is not an env');
}
SKIP: {
    skip 'root can read anything', 2 if $> == 0;
    spew("$DOCS/secret.md", "# Secret\n");
    my $app2 = eval qq{ package MDEdge2; use Punk; markdown '/d' => '$DOCS', reload => 1; MDEdge2->to_app };
    my $e = $@;
    is(hit($app2, path => '/d/secret')->[0], 200, 'a readable page serves');
    chmod 0000, "$DOCS/secret.md";
    utime(time + 10, time + 10, "$DOCS/secret.md");
    if ($app2) {
        my $err = '';
        eval { hit($app2, path => '/d/secret'); 1 } or $err = $@;
        like($err, qr/cannot read '.*secret\.md'/, 'a page that became unreadable fails the request that re-renders it, by name');
    }
    else {
        like($e, qr/cannot read '.*secret\.md'/, 'a page that cannot be read is a boot error');
    }
    chmod 0644, "$DOCS/secret.md";
}

done_testing;
