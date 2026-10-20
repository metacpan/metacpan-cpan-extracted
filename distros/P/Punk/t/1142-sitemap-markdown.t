#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp ();
use Punk::Plugin::Sitemap;

# A markdown mount's pages are in the sitemap with no section to write: the
# mount's page table is built before the sitemap is, and a docs tree or a
# blog is exactly the content a sitemap exists for. `robots: noindex` leaves
# a page out of the sitemap - and NOT into robots.txt, where a crawler could
# never fetch it to read the noindex. `sitemap => 0` leaves out the tree.

BEGIN {
    plan skip_all => 'needs Markdown::Simple 0.20+ with its C ABI'
        unless eval { require Markdown::Simple;
                      Markdown::Simple->can('_abi_ptr')
                      && Markdown::Simple::_abi_version() >= 1 };
    plan skip_all => 'needs Template::Stencil with its C ABI'
        unless eval { require Template::Stencil;
                      Template::Stencil->can('_abi_ptr') };
}

sub spew {
    my ($file, $text) = @_;
    open my $fh, '>:raw', $file or die "$file: $!";
    print {$fh} $text;
    close $fh;
}

sub locs { [ $_[0] =~ m{<loc>([^<]+)</loc>}g ] }
sub lastmod_of {
    my ($doc, $loc) = @_;
    return $doc =~ m{<loc>\Q$loc\E</loc>\s*<lastmod>([^<]+)</lastmod>} ? $1 : undef;
}

my $tree = File::Temp->newdir;
mkdir "$tree/sub";
spew("$tree/index.md",    "# Home of the docs\n");
spew("$tree/dated.md",    "---\ndate: 2026-10-01\n---\n# Dated\n");
spew("$tree/updated.md",  "---\ndate: 2026-09-01\nupdated: 2026-10-05T23:30:00-02:00\n---\n# Upd\n");
spew("$tree/plain.md",    "# Plain\n");
spew("$tree/hidden.md",   "---\nrobots: NoIndex, follow\n---\n# Hidden\n");
spew("$tree/draft.md",    "---\ndraft: 1\n---\n# Draft\n");
spew("$tree/sub/deep.md", "# Deep\n");
my $esc = "$tree"; $esc =~ s/'/\\'/g;

my $n = 0;
sub build {
    my ($decl) = @_;
    my $pkg = 'SiteMD' . ++$n;
    eval "package $pkg; use Punk; $decl; 1" or die $@;
    $pkg->to_app;
    return $pkg->punk_app;
}

# ---- listed, with lastmod ------------------------------------------------------

{
    my $app = build("plugin 'Sitemap' => { base => 'https://ex.com' };
                     get '/' => sub { \$_[0]->text('home') };
                     markdown '/docs' => '$esc', search => 0;");
    my $doc = Punk::Plugin::Sitemap->_doc($app);
    my %in = map { $_ => 1 } @{ locs($doc) };

    ok $in{'https://ex.com/'}, 'the route half is still there';
    ok $in{"https://ex.com/docs$_"}, "the page /docs$_ is listed"
        for ('', '/dated', '/updated', '/plain', '/sub/deep');
    ok !$in{'https://ex.com/docs/hidden'},
        'a page whose robots says noindex (any case) is not listed';
    ok !$in{'https://ex.com/docs/draft'}, 'a draft is not listed';
    is scalar(grep /\/docs/, keys %in), 5, 'and nothing else from the mount';

    is lastmod_of($doc, 'https://ex.com/docs/dated'), '2026-10-01',
        'lastmod from date:';
    is lastmod_of($doc, 'https://ex.com/docs/updated'), '2026-10-06',
        'lastmod from updated:, which wins, read in UTC';
    is lastmod_of($doc, 'https://ex.com/docs/plain'), undef,
        'an undated page has no lastmod';

    my $robots = Punk::Plugin::Sitemap->_robots($app);
    unlike $robots, qr{Disallow: /docs}, 'the noindex page is not disallowed';
}

# ---- opted out -----------------------------------------------------------------

{
    my $app = build("plugin 'Sitemap' => { base => 'https://ex.com' };
                     get '/' => sub { \$_[0]->text('home') };
                     markdown '/docs' => '$esc', search => 0, sitemap => 0;");
    my $doc = Punk::Plugin::Sitemap->_doc($app);
    unlike $doc, qr{/docs}, 'sitemap => 0 leaves out the whole tree';
    like $doc, qr{<loc>https://ex\.com/</loc>}, '...and only the tree';
}

{
    my $err = do { local $@;
        eval { build("markdown '/docs' => '$esc', search => 0, sitemap => 'no'") }; $@ };
    like $err, qr{markdown sitemap takes 0 or 1, not 'no'}, 'a bad sitemap value croaks';
}

# ---- once, beside a hand section ------------------------------------------------

{
    my $app = build("use Punk::Plugin::Sitemap;
                     plugin 'Sitemap' => { base => 'https://ex.com' };
                     markdown '/docs' => '$esc', search => 0;
                     sitemap extra => sub { { loc => '/docs/plain' }, { loc => '/elsewhere' } };");
    my $doc = Punk::Plugin::Sitemap->_doc($app);
    my $count = () = $doc =~ m{<loc>https://ex\.com/docs/plain</loc>}g;
    is $count, 1, 'a page a hand section also returns is listed once';
    like $doc, qr{<loc>https://ex\.com/elsewhere</loc>}, '...and the section still runs';
}

# ---- a disallow never shadows a listed page --------------------------------------

{
    my $app = build("plugin 'Sitemap' => { base => 'https://ex.com', disallow => ['/docs'] };
                     markdown '/docs' => '$esc', search => 0;");
    unlike(Punk::Plugin::Sitemap->_robots($app), qr{Disallow: /docs\b},
        'a disallow covering listed markdown pages is dropped, as for a route');
}

# ---- two mounts, and a mount at the root of its own prefix ----------------------

{
    my $app = build("plugin 'Sitemap' => { base => 'https://ex.com' };
                     markdown '/a' => '$esc/sub', search => 0;
                     markdown '/b' => '$esc', search => 0, sitemap => 0;");
    is_deeply locs(Punk::Plugin::Sitemap->_doc($app)), [ 'https://ex.com/a/deep' ],
        'each mount is read on its own, and its own opt-out is its own';
}

done_testing;
